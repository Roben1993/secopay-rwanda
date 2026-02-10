# Smart Contract Deployment Guide

## Overview

This guide will help you deploy the EscrowContract to Polygon Mumbai Testnet (and later to Polygon Mainnet).

## Prerequisites

1. **MetaMask Wallet** - Install from metamask.io
2. **Mumbai MATIC** - Get free testnet tokens from faucet
3. **Remix IDE** or **Hardhat** - For contract deployment
4. **Node.js** (for Hardhat method)

---

## Method 1: Deploy Using Remix IDE (Easiest for Beginners)

### Step 1: Get Mumbai Test MATIC

1. Visit: https://faucet.polygon.technology/
2. Select "Mumbai" network
3. Enter your MetaMask wallet address
4. Click "Submit" - you'll receive 0.5 test MATIC
5. Alternatively, use: https://mumbaifaucet.com/

### Step 2: Configure MetaMask for Mumbai

1. Open MetaMask
2. Click network dropdown → "Add Network"
3. Enter Mumbai network details:
   - **Network Name:** Polygon Mumbai Testnet
   - **RPC URL:** https://rpc-mumbai.maticvigil.com
   - **Chain ID:** 80001
   - **Currency Symbol:** MATIC
   - **Block Explorer:** https://mumbai.polygonscan.com

4. Switch to Mumbai network

### Step 3: Open Remix IDE

1. Visit: https://remix.ethereum.org/
2. Create new file: `EscrowContract.sol`
3. Copy the entire contract code from `EscrowContract.sol`
4. Paste into Remix

### Step 4: Install OpenZeppelin Contracts

The contract uses OpenZeppelin libraries. Remix will auto-import them, but you can manually add:

1. In Remix, go to "File Explorer"
2. Create folder: `.deps/npm/@openzeppelin/contracts`
3. Or simply let Remix auto-import when you compile

### Step 5: Compile Contract

1. Go to "Solidity Compiler" tab (left sidebar)
2. Select compiler version: `0.8.20` or higher
3. Click "Compile EscrowContract.sol"
4. Verify compilation succeeds (green checkmark)

### Step 6: Deploy Contract

1. Go to "Deploy & Run Transactions" tab
2. Select Environment: **"Injected Provider - MetaMask"**
3. MetaMask will pop up - connect your wallet
4. Ensure you're on Mumbai network in MetaMask
5. In Remix, under "Deploy" section:
   - Contract: `EscrowContract`
   - Constructor parameter: Enter your wallet address for fee recipient
   - Example: `0xYourWalletAddress`
6. Click "Deploy"
7. MetaMask will pop up - confirm transaction
8. Wait for deployment (~10-30 seconds)
9. **SAVE THE CONTRACT ADDRESS!** You'll need it in your app

### Step 7: Verify Contract on PolygonScan (Optional but Recommended)

1. Go to: https://mumbai.polygonscan.com/
2. Search for your contract address
3. Click "Contract" tab → "Verify and Publish"
4. Fill in details:
   - Compiler version: 0.8.20
   - License: MIT
   - Optimization: No (or Yes if enabled in Remix)
5. Paste the flattened contract source code
6. Submit verification
7. Once verified, users can interact directly on PolygonScan

---

## Method 2: Deploy Using Hardhat (Recommended for Production)

### Step 1: Install Hardhat

```bash
cd C:\Users\user\Documents\escrow_app\contracts
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox
npm install @openzeppelin/contracts
```

### Step 2: Initialize Hardhat Project

```bash
npx hardhat init
```

Select: "Create a TypeScript project" (or JavaScript)

### Step 3: Configure Hardhat

Edit `hardhat.config.ts`:

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: ["YOUR_PRIVATE_KEY_HERE"], // ⚠️ NEVER commit this!
      chainId: 80001,
    },
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: ["YOUR_PRIVATE_KEY_HERE"], // For mainnet deployment
      chainId: 137,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: "YOUR_POLYGONSCAN_API_KEY", // Get from polygonscan.com
      polygon: "YOUR_POLYGONSCAN_API_KEY",
    },
  },
};

export default config;
```

**⚠️ SECURITY WARNING:**
- Never commit private keys to Git
- Use environment variables instead:

Create `.env` file:
```
PRIVATE_KEY=your_private_key_here
POLYGONSCAN_API_KEY=your_api_key_here
```

Update config to use:
```typescript
require('dotenv').config();
// ...
accounts: [process.env.PRIVATE_KEY!]
```

### Step 4: Create Deployment Script

Create `scripts/deploy.ts`:

```typescript
import { ethers } from "hardhat";

async function main() {
  // Get deployer account
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  // Fee recipient address (change this to your wallet)
  const feeRecipient = deployer.address; // Or use a different address

  // Deploy contract
  const EscrowContract = await ethers.getContractFactory("EscrowContract");
  const escrow = await EscrowContract.deploy(feeRecipient);

  await escrow.waitForDeployment();

  const address = await escrow.getAddress();

  console.log("EscrowContract deployed to:", address);
  console.log("Fee recipient:", feeRecipient);
  console.log("\n⚠️  SAVE THIS CONTRACT ADDRESS! Add it to web3_config.dart");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### Step 5: Deploy to Mumbai

```bash
npx hardhat run scripts/deploy.ts --network mumbai
```

Output will show:
```
Deploying contracts with account: 0x...
EscrowContract deployed to: 0x...
```

**⚠️ SAVE THE CONTRACT ADDRESS!**

### Step 6: Verify Contract

```bash
npx hardhat verify --network mumbai DEPLOYED_CONTRACT_ADDRESS "FEE_RECIPIENT_ADDRESS"
```

Example:
```bash
npx hardhat verify --network mumbai 0x1234... 0xYourWallet...
```

---

## After Deployment

### Update Flutter App Configuration

1. Open `lib/core/constants/web3_config.dart`
2. Update the contract address:

```dart
// ESCROW SMART CONTRACT ADDRESSES
static const String escrowContractMumbai = '0xYOUR_DEPLOYED_ADDRESS_HERE';
```

For mainnet (later):
```dart
static const String escrowContractMainnet = '0xYOUR_MAINNET_ADDRESS_HERE';
```

### Create Contract ABI File

After deployment, you need the ABI (Application Binary Interface):

#### If using Remix:
1. In Remix, go to "Solidity Compiler" tab
2. Click "ABI" button (bottom of page)
3. Copy the JSON
4. Create file: `lib/core/constants/escrow_contract_abi.dart`
5. Paste as:

```dart
const String escrowContractABI = '''
[
  // Paste ABI JSON here
]
''';
```

#### If using Hardhat:
The ABI is automatically generated in:
`artifacts/contracts/EscrowContract.sol/EscrowContract.json`

---

## Testing the Contract

### Test on Mumbai Testnet

1. **Get Test Tokens:**
   - USDT Mumbai: https://faucet.paradigm.xyz/
   - Or use test faucets for ERC-20 tokens

2. **Test Flow:**
   ```solidity
   // 1. Create escrow
   createEscrow(sellerAddress, usdtAddress, 1000000, "Test escrow")

   // 2. Approve tokens
   USDT.approve(escrowContractAddress, 1020000) // amount + 2% fee

   // 3. Fund escrow
   fundEscrow(escrowId)

   // 4. Mark as shipped (from seller)
   markAsShipped(escrowId)

   // 5. Confirm delivery (from buyer)
   confirmDelivery(escrowId)

   // 6. Release funds
   releaseFunds(escrowId)
   ```

### Using PolygonScan

1. Go to your contract on Mumbai PolygonScan
2. Click "Contract" → "Write Contract"
3. Connect MetaMask
4. Test each function manually

---

## Deploy to Mainnet (Production)

⚠️ **ONLY after extensive testing on Mumbai!**

### Checklist Before Mainnet:

- [ ] Fully tested on Mumbai testnet
- [ ] Security audit completed (recommended for production)
- [ ] All functions work as expected
- [ ] Have real MATIC for gas fees (~$5-10 recommended)
- [ ] Fee recipient address is correct
- [ ] Platform fee percentage is set correctly (default 2%)

### Deployment Steps:

1. Get MATIC on Polygon mainnet (buy from exchange)
2. Change network in MetaMask to "Polygon Mainnet"
3. In Hardhat: `npx hardhat run scripts/deploy.ts --network polygon`
4. Verify: `npx hardhat verify --network polygon ADDRESS FEE_RECIPIENT`
5. Update `web3_config.dart` with mainnet address
6. Set `isProduction = true` in web3_config.dart

---

## Costs Estimate

### Mumbai Testnet (Free):
- Gas: Free (test MATIC from faucet)
- Tokens: Free (test tokens from faucets)

### Polygon Mainnet:
- Deployment: ~0.1-0.5 MATIC (~$0.05-0.25)
- Each transaction: ~0.001-0.01 MATIC (~$0.0005-0.005)
- **Much cheaper than Ethereum!** 🎉

---

## Troubleshooting

### Error: "Insufficient funds"
- Get more test MATIC from faucet
- Ensure you're on the correct network

### Error: "Contract creation code storage out of gas"
- Increase gas limit in deployment
- Check for code optimization

### Error: "nonce too low"
- Reset MetaMask account:
  - Settings → Advanced → Reset Account

### Contract not verified
- Ensure compiler version matches
- Check optimization settings
- Use exact contract source code

---

## Security Considerations

1. **Private Keys:** Never share or commit to Git
2. **Fee Recipient:** Use a secure hardware wallet for mainnet
3. **Platform Fee:** Set reasonable fee (2% is standard)
4. **Emergency Withdraw:** Only use in true emergencies
5. **Dispute Resolution:** Implement proper governance

---

## Next Steps

After deploying:

1. ✅ Update contract address in Flutter app
2. ✅ Test with real test tokens on Mumbai
3. ✅ Implement Flutter integration
4. ✅ Build UI for escrow creation/funding
5. ✅ Add contract interaction in web3_service.dart
6. ✅ Test end-to-end flow
7. ✅ Deploy to mainnet when ready

---

## Useful Links

- **Polygon Mumbai Faucet:** https://faucet.polygon.technology/
- **PolygonScan Mumbai:** https://mumbai.polygonscan.com/
- **Remix IDE:** https://remix.ethereum.org/
- **Hardhat Docs:** https://hardhat.org/getting-started/
- **OpenZeppelin:** https://docs.openzeppelin.com/

---

**Good luck with your deployment! 🚀**

*Building something great for Rwanda and the world! 🇷🇼*
