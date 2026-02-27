/**
 * EscoPay Cloud Functions
 *
 * Handles:
 * 1. pawaPayWebhook   – HTTP trigger that processes PawaPay deposit/payout callbacks.
 *    - On deposit COMPLETED (Buy Crypto flow): sends ERC-20 tokens to the buyer's wallet.
 *    - On deposit COMPLETED (Fiat Escrow flow): marks the escrow as funded.
 *    - On payout callback: updates the escrow payout status.
 *
 * 2. onFiatEscrowCompleted – Firestore trigger on escrows/{escrowId}.
 *    - When a fiat escrow's status changes to "completed", initiates a PawaPay
 *      payout to the seller's phone using sellerProvider and fiatCurrency.
 *
 * Required environment variables (set via Firebase Secret Manager or .env):
 *   PAWAPAY_API_KEY        – PawaPay bearer token
 *   PAWAPAY_SANDBOX        – "true" for sandbox, "false" for production
 *   HOT_WALLET_PRIVATE_KEY – Ethereum private key for the hot wallet
 *   POLYGON_RPC_URL        – Polygon JSON-RPC endpoint (e.g. from Alchemy/Infura)
 *   IS_TESTNET             – "true" to use Mumbai token addresses
 */

import * as admin from "firebase-admin";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { ethers } from "ethers";
import axios from "axios";
import { v4 as uuidv4 } from "uuid";

admin.initializeApp();

const db = admin.firestore();

// ---------------------------------------------------------------------------
// Config (populated from Cloud Functions environment / Secret Manager)
// ---------------------------------------------------------------------------
const PAWAPAY_API_KEY = process.env.PAWAPAY_API_KEY ?? "";
const PAWAPAY_BASE_URL =
  process.env.PAWAPAY_SANDBOX === "true"
    ? "https://api.sandbox.pawapay.io"
    : "https://api.pawapay.io";
const HOT_WALLET_PRIVATE_KEY = process.env.HOT_WALLET_PRIVATE_KEY ?? "";
const POLYGON_RPC_URL =
  process.env.POLYGON_RPC_URL ?? "https://polygon-rpc.com";
const IS_TESTNET = process.env.IS_TESTNET === "true";

// Token contract addresses (Polygon Mainnet vs Mumbai Testnet)
const TOKEN_ADDRESSES: Record<string, string> = {
  USDT: IS_TESTNET
    ? "0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832"
    : "0xc2132D05D31c914a87C6611C10748AEb04B58e8F",
  USDC: IS_TESTNET
    ? "0x0FA8781a83E46826621b3BC094Ea2A0212e71B23"
    : "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174",
};

// Minimal ERC-20 ABI for transfers
const ERC20_ABI = [
  "function transfer(address to, uint256 value) returns (bool)",
  "function balanceOf(address owner) view returns (uint256)",
  "function decimals() view returns (uint8)",
];

// ---------------------------------------------------------------------------
// PawaPay webhook event shape
// ---------------------------------------------------------------------------
interface PawaPayEvent {
  depositId?: string;
  payoutId?: string;
  status?: string;
  amount?: string;   // fiat amount as string e.g. "10000"
  currency?: string; // e.g. "RWF"
}

// ---------------------------------------------------------------------------
// Helper: send ERC-20 tokens from hot wallet to a recipient address
// ---------------------------------------------------------------------------
async function sendCrypto(params: {
  toAddress: string;
  tokenSymbol: string;
  amount: number;
}): Promise<string> {
  const { toAddress, tokenSymbol, amount } = params;

  if (!HOT_WALLET_PRIVATE_KEY) {
    throw new Error("HOT_WALLET_PRIVATE_KEY not configured");
  }

  const tokenAddress = TOKEN_ADDRESSES[tokenSymbol.toUpperCase()];
  if (!tokenAddress) {
    throw new Error(`Unsupported token: ${tokenSymbol}`);
  }

  if (!ethers.isAddress(toAddress)) {
    throw new Error(`Invalid recipient address: ${toAddress}`);
  }

  const provider = new ethers.JsonRpcProvider(POLYGON_RPC_URL);
  const wallet = new ethers.Wallet(HOT_WALLET_PRIVATE_KEY, provider);
  const contract = new ethers.Contract(tokenAddress, ERC20_ABI, wallet);

  const decimals: number = await contract.decimals();
  const amountInSmallestUnit = ethers.parseUnits(amount.toFixed(decimals), decimals);

  const tx = await contract.transfer(toAddress, amountInSmallestUnit);
  const receipt = await tx.wait(1);

  return receipt?.hash ?? tx.hash;
}

// ---------------------------------------------------------------------------
// Helper: initiate a PawaPay payout (send money to a phone number)
// ---------------------------------------------------------------------------
async function initPawaPayPayout(params: {
  phoneNumber: string;
  provider: string;
  amount: number;
  currency: string;
  clientReference?: string;
}): Promise<string> {
  const { phoneNumber, provider, amount, currency, clientReference } = params;
  const payoutId = uuidv4();
  const cleanPhone = phoneNumber.replace(/[^0-9]/g, "");

  const body: Record<string, unknown> = {
    payoutId,
    amount: amount.toFixed(0),
    currency,
    recipient: {
      type: "MMO",
      accountDetails: {
        phoneNumber: cleanPhone,
        provider,
      },
    },
  };

  if (clientReference) body.clientReferenceId = clientReference;

  const response = await axios.post(`${PAWAPAY_BASE_URL}/v2/payouts`, body, {
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${PAWAPAY_API_KEY}`,
    },
    timeout: 30000,
  });

  return (response.data.payoutId as string | undefined) ?? payoutId;
}

// ---------------------------------------------------------------------------
// HTTP Function: PawaPay webhook receiver
// Endpoint: https://europe-west1-escopay-7b5b7.cloudfunctions.net/pawaPayWebhook
// Configure this URL in your PawaPay dashboard under Webhook settings.
// ---------------------------------------------------------------------------
export const pawaPayWebhook = onRequest(
  { region: "europe-west1", cors: false },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const event = req.body as PawaPayEvent;
    const status = event.status;

    console.log("PawaPay webhook:", JSON.stringify({ status, depositId: event.depositId, payoutId: event.payoutId }));

    // ── Handle deposit callback ────────────────────────────────────────────
    if (event.depositId && status === "COMPLETED") {
      const depositId = event.depositId;
      const fiatAmount = parseFloat(event.amount ?? "0");

      // 1. Buy Crypto flow — purchases/{depositId} doc created by the app
      const purchaseRef = db.collection("purchases").doc(depositId);
      const purchaseSnap = await purchaseRef.get();

      if (purchaseSnap.exists && purchaseSnap.data()?.status === "pending") {
        const purchase = purchaseSnap.data()!;
        const walletAddress: string = purchase.walletAddress ?? "";
        const token: string = purchase.token ?? "";
        const cryptoAmount: number = purchase.cryptoAmount ?? 0;

        if (!walletAddress || !token || cryptoAmount <= 0) {
          console.error("Purchase doc missing required fields", { depositId });
          await purchaseRef.update({ status: "failed", error: "Missing fields" });
          res.status(200).json({ received: true });
          return;
        }

        try {
          const txHash = await sendCrypto({ toAddress: walletAddress, tokenSymbol: token, amount: cryptoAmount });

          await purchaseRef.update({
            status: "completed",
            txHash,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          console.log(`Crypto sent: ${cryptoAmount} ${token} → ${walletAddress} (tx: ${txHash})`);
        } catch (err) {
          console.error("sendCrypto failed:", err);
          await purchaseRef.update({ status: "failed", error: String(err) });
        }

        res.status(200).json({ received: true });
        return;
      }

      // 2. Fiat Escrow funding flow — find escrow with matching depositId
      const escrowsSnap = await db
        .collection("escrows")
        .where("depositId", "==", depositId)
        .where("paymentType", "==", "fiat")
        .limit(1)
        .get();

      if (!escrowsSnap.empty) {
        const escrowDoc = escrowsSnap.docs[0];
        if (escrowDoc.data().status === "created") {
          await escrowDoc.ref.update({
            status: "funded",
            fundedAt: admin.firestore.FieldValue.serverTimestamp(),
            // Store the actual fiat amount paid so the seller payout uses it
            fiatAmountPaid: fiatAmount,
            fiatCurrencyPaid: event.currency ?? escrowDoc.data().fiatCurrency,
          });
          console.log(`Fiat escrow funded: ${escrowDoc.id} (${fiatAmount} ${event.currency})`);
        }
      }
    }

    // ── Handle payout callback ─────────────────────────────────────────────
    if (event.payoutId && (status === "COMPLETED" || status === "FAILED" || status === "REJECTED")) {
      const payoutId = event.payoutId;

      const escrowsSnap = await db
        .collection("escrows")
        .where("payoutId", "==", payoutId)
        .limit(1)
        .get();

      if (!escrowsSnap.empty) {
        await escrowsSnap.docs[0].ref.update({
          payoutStatus: status,
          payoutUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        console.log(`Escrow ${escrowsSnap.docs[0].id} payout status → ${status}`);
      }
    }

    res.status(200).json({ received: true });
  }
);

// ---------------------------------------------------------------------------
// Firestore Trigger: fiat escrow reaches "completed" → pay seller via MoMo
// Fires whenever any escrow document is written.
// ---------------------------------------------------------------------------
export const onFiatEscrowCompleted = onDocumentWritten(
  { document: "escrows/{escrowId}", region: "europe-west1" },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Only react when status transitions INTO "completed" for a fiat escrow
    if (before.status === "completed" || after.status !== "completed") return;
    if (after.paymentType !== "fiat") return;

    const escrowId = event.params.escrowId;

    const sellerPhone: string = after.sellerPhone ?? "";
    const sellerProvider: string = after.sellerProvider ?? "";
    // Prefer the actual fiat amount that was collected; fall back to stored amount
    const fiatAmount: number = after.fiatAmountPaid ?? after.amount ?? 0;
    const currency: string =
      after.fiatCurrencyPaid ?? after.fiatCurrency ?? "RWF";

    if (!sellerPhone || !sellerProvider || fiatAmount <= 0) {
      console.error(`Escrow ${escrowId}: missing seller payout fields`, {
        sellerPhone,
        sellerProvider,
        fiatAmount,
        currency,
      });
      return;
    }

    if (!PAWAPAY_API_KEY) {
      console.error("PAWAPAY_API_KEY not configured — cannot initiate payout");
      return;
    }

    try {
      const payoutId = await initPawaPayPayout({
        phoneNumber: sellerPhone,
        provider: sellerProvider,
        amount: fiatAmount,
        currency,
        clientReference: escrowId,
      });

      await db.collection("escrows").doc(escrowId).update({
        payoutId,
        payoutInitiatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Escrow ${escrowId}: payout ${payoutId} initiated to ${sellerPhone} (${fiatAmount} ${currency})`);
    } catch (err) {
      console.error(`Escrow ${escrowId}: payout initiation failed:`, err);
      await db.collection("escrows").doc(escrowId).update({
        payoutError: String(err),
        payoutAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
);
