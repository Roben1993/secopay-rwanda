/// Web3 Service
/// Handles all blockchain interactions with Polygon network
/// Manages USDT/USDC token operations and escrow contract interactions

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';
import '../core/constants/web3_config.dart';

class Web3Service {
  late Web3Client _client;
  late String _rpcUrl;

  // Singleton pattern
  static final Web3Service _instance = Web3Service._internal();
  factory Web3Service() => _instance;

  Web3Service._internal() {
    _initialize();
  }

  /// Initialize Web3 client with RPC URL
  void _initialize() {
    _rpcUrl = Web3Config.getRpcUrlWithKey();
    _client = Web3Client(_rpcUrl, http.Client());
  }

  /// Get Web3 client instance
  Web3Client get client => _client;

  // ============================================================================
  // NETWORK OPERATIONS
  // ============================================================================

  /// Get current network chain ID
  Future<int> getChainId() async {
    try {
      return await _client.getNetworkId();
    } catch (e) {
      throw Web3Exception('Failed to get chain ID: $e');
    }
  }

  /// Check if connected to correct network
  Future<bool> isCorrectNetwork() async {
    try {
      final chainId = await getChainId();
      final expectedChainId = int.parse(Web3Config.chainId);
      return chainId == expectedChainId;
    } catch (e) {
      return false;
    }
  }

  /// Get current gas price
  Future<EtherAmount> getGasPrice() async {
    try {
      return await _client.getGasPrice();
    } catch (e) {
      throw Web3Exception('Failed to get gas price: $e');
    }
  }

  /// Get latest block number
  Future<int> getBlockNumber() async {
    try {
      final block = await _client.getBlockNumber();
      return block;
    } catch (e) {
      throw Web3Exception('Failed to get block number: $e');
    }
  }

  // ============================================================================
  // WALLET OPERATIONS
  // ============================================================================

  /// Get MATIC balance for an address
  Future<EtherAmount> getMaticBalance(String address) async {
    try {
      final ethAddress = EthereumAddress.fromHex(address);
      return await _client.getBalance(ethAddress);
    } catch (e) {
      throw Web3Exception('Failed to get MATIC balance: $e');
    }
  }

  /// Get MATIC balance in human-readable format
  Future<double> getMaticBalanceInEther(String address) async {
    try {
      final balance = await getMaticBalance(address);
      return balance.getValueInUnit(EtherUnit.ether);
    } catch (e) {
      throw Web3Exception('Failed to get MATIC balance: $e');
    }
  }

  /// Get ERC-20 token balance (USDT, USDC)
  Future<BigInt> getTokenBalance(String walletAddress, String tokenAddress) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(ERC20ABI.balanceOfABI, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      final balanceFunction = contract.function('balanceOf');
      final result = await _client.call(
        contract: contract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(walletAddress)],
      );

      return result.first as BigInt;
    } catch (e) {
      throw Web3Exception('Failed to get token balance: $e');
    }
  }

  /// Get USDT balance
  Future<BigInt> getUSDTBalance(String walletAddress) async {
    return await getTokenBalance(walletAddress, Web3Config.usdtAddress);
  }

  /// Get USDC balance
  Future<BigInt> getUSDCBalance(String walletAddress) async {
    return await getTokenBalance(walletAddress, Web3Config.usdcAddress);
  }

  /// Get USDT balance in human-readable format (with 6 decimals)
  Future<double> getUSDTBalanceInUnits(String walletAddress) async {
    try {
      final balance = await getUSDTBalance(walletAddress);
      final metadata = Web3Config.supportedTokens['USDT']!;
      return metadata.fromSmallestUnit(balance);
    } catch (e) {
      throw Web3Exception('Failed to get USDT balance: $e');
    }
  }

  /// Get USDC balance in human-readable format (with 6 decimals)
  Future<double> getUSDCBalanceInUnits(String walletAddress) async {
    try {
      final balance = await getUSDCBalance(walletAddress);
      final metadata = Web3Config.supportedTokens['USDC']!;
      return metadata.fromSmallestUnit(balance);
    } catch (e) {
      throw Web3Exception('Failed to get USDC balance: $e');
    }
  }

  /// Get all balances for a wallet
  Future<WalletBalances> getAllBalances(String walletAddress) async {
    try {
      final maticBalance = await getMaticBalanceInEther(walletAddress);
      final usdtBalance = await getUSDTBalanceInUnits(walletAddress);
      final usdcBalance = await getUSDCBalanceInUnits(walletAddress);

      return WalletBalances(
        matic: maticBalance,
        usdt: usdtBalance,
        usdc: usdcBalance,
      );
    } catch (e) {
      throw Web3Exception('Failed to get wallet balances: $e');
    }
  }

  // ============================================================================
  // TOKEN TRANSFER OPERATIONS
  // ============================================================================

  /// Transfer ERC-20 tokens
  Future<String> transferToken({
    required String tokenAddress,
    required String fromPrivateKey,
    required String toAddress,
    required BigInt amount,
  }) async {
    try {
      // Create credentials from private key
      final credentials = EthPrivateKey.fromHex(fromPrivateKey);

      // Create contract instance
      final contract = DeployedContract(
        ContractAbi.fromJson(ERC20ABI.transferABI, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      // Get transfer function
      final transferFunction = contract.function('transfer');

      // Send transaction
      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: transferFunction,
          parameters: [EthereumAddress.fromHex(toAddress), amount],
          maxGas: Web3Config.transferGasLimit,
        ),
        chainId: int.parse(Web3Config.chainId),
      );

      return txHash;
    } catch (e) {
      throw Web3Exception('Failed to transfer token: $e');
    }
  }

  /// Transfer USDT
  Future<String> transferUSDT({
    required String fromPrivateKey,
    required String toAddress,
    required double amount,
  }) async {
    try {
      final metadata = Web3Config.supportedTokens['USDT']!;
      final amountInSmallestUnit = metadata.toSmallestUnit(amount);

      return await transferToken(
        tokenAddress: Web3Config.usdtAddress,
        fromPrivateKey: fromPrivateKey,
        toAddress: toAddress,
        amount: amountInSmallestUnit,
      );
    } catch (e) {
      throw Web3Exception('Failed to transfer USDT: $e');
    }
  }

  /// Transfer USDC
  Future<String> transferUSDC({
    required String fromPrivateKey,
    required String toAddress,
    required double amount,
  }) async {
    try {
      final metadata = Web3Config.supportedTokens['USDC']!;
      final amountInSmallestUnit = metadata.toSmallestUnit(amount);

      return await transferToken(
        tokenAddress: Web3Config.usdcAddress,
        fromPrivateKey: fromPrivateKey,
        toAddress: toAddress,
        amount: amountInSmallestUnit,
      );
    } catch (e) {
      throw Web3Exception('Failed to transfer USDC: $e');
    }
  }

  /// Transfer MATIC
  Future<String> transferMatic({
    required String fromPrivateKey,
    required String toAddress,
    required double amountInEther,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(fromPrivateKey);
      final amount = EtherAmount.fromUnitAndValue(EtherUnit.ether, amountInEther);

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction(
          to: EthereumAddress.fromHex(toAddress),
          value: amount,
          maxGas: Web3Config.transferGasLimit,
        ),
        chainId: int.parse(Web3Config.chainId),
      );

      return txHash;
    } catch (e) {
      throw Web3Exception('Failed to transfer MATIC: $e');
    }
  }

  // ============================================================================
  // TOKEN APPROVAL OPERATIONS (Required before escrow funding)
  // ============================================================================

  /// Approve token spending for escrow contract
  Future<String> approveToken({
    required String tokenAddress,
    required String ownerPrivateKey,
    required String spenderAddress,
    required BigInt amount,
  }) async {
    try {
      final credentials = EthPrivateKey.fromHex(ownerPrivateKey);

      final contract = DeployedContract(
        ContractAbi.fromJson(ERC20ABI.approveABI, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      final approveFunction = contract.function('approve');

      final txHash = await _client.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: approveFunction,
          parameters: [EthereumAddress.fromHex(spenderAddress), amount],
          maxGas: Web3Config.approveGasLimit,
        ),
        chainId: int.parse(Web3Config.chainId),
      );

      return txHash;
    } catch (e) {
      throw Web3Exception('Failed to approve token: $e');
    }
  }

  /// Check token allowance
  Future<BigInt> checkAllowance({
    required String tokenAddress,
    required String ownerAddress,
    required String spenderAddress,
  }) async {
    try {
      final contract = DeployedContract(
        ContractAbi.fromJson(ERC20ABI.allowanceABI, 'ERC20'),
        EthereumAddress.fromHex(tokenAddress),
      );

      final allowanceFunction = contract.function('allowance');
      final result = await _client.call(
        contract: contract,
        function: allowanceFunction,
        params: [
          EthereumAddress.fromHex(ownerAddress),
          EthereumAddress.fromHex(spenderAddress),
        ],
      );

      return result.first as BigInt;
    } catch (e) {
      throw Web3Exception('Failed to check allowance: $e');
    }
  }

  // ============================================================================
  // TRANSACTION OPERATIONS
  // ============================================================================

  /// Get transaction receipt
  Future<TransactionReceipt?> getTransactionReceipt(String txHash) async {
    try {
      return await _client.getTransactionReceipt(txHash);
    } catch (e) {
      throw Web3Exception('Failed to get transaction receipt: $e');
    }
  }

  /// Wait for transaction confirmation
  Future<TransactionReceipt> waitForTransactionConfirmation(
    String txHash, {
    int requiredConfirmations = 3,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      final startTime = DateTime.now();

      while (true) {
        // Check timeout
        if (DateTime.now().difference(startTime) > timeout) {
          throw Web3Exception('Transaction confirmation timeout');
        }

        // Get receipt
        final receipt = await getTransactionReceipt(txHash);

        if (receipt != null) {
          // Check if transaction was successful
          if (receipt.status == false) {
            throw Web3Exception('Transaction failed');
          }

          // Check confirmations
          final currentBlock = await getBlockNumber();
          final confirmations = currentBlock - receipt.blockNumber.blockNum.toInt();

          if (confirmations >= requiredConfirmations) {
            return receipt;
          }
        }

        // Wait before next check
        await Future.delayed(Duration(milliseconds: Web3Config.pollingInterval));
      }
    } catch (e) {
      throw Web3Exception('Failed to wait for transaction confirmation: $e');
    }
  }

  /// Estimate gas for transaction
  Future<BigInt> estimateGas({
    required EthereumAddress sender,
    required EthereumAddress? to,
    EtherAmount? value,
    Uint8List? data,
  }) async {
    try {
      return await _client.estimateGas(
        sender: sender,
        to: to,
        value: value,
        data: data,
      );
    } catch (e) {
      throw Web3Exception('Failed to estimate gas: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Validate Ethereum address
  bool isValidAddress(String address) {
    return Web3Config.isValidAddress(address);
  }

  /// Get address from private key
  EthereumAddress getAddressFromPrivateKey(String privateKey) {
    try {
      final credentials = EthPrivateKey.fromHex(privateKey);
      return credentials.address;
    } catch (e) {
      throw Web3Exception('Invalid private key: $e');
    }
  }

  /// Convert Wei to Ether
  double weiToEther(BigInt wei) {
    return wei / BigInt.from(10).pow(18);
  }

  /// Convert Ether to Wei
  BigInt etherToWei(double ether) {
    return BigInt.from(ether * BigInt.from(10).pow(18).toDouble());
  }

  /// Dispose Web3 client
  void dispose() {
    _client.dispose();
  }
}

// ============================================================================
// WALLET BALANCES MODEL
// ============================================================================

class WalletBalances {
  final double matic;
  final double usdt;
  final double usdc;

  WalletBalances({
    required this.matic,
    required this.usdt,
    required this.usdc,
  });

  /// Get total value in USD (assuming USDT/USDC = $1)
  double get totalUSD => usdt + usdc;

  /// Check if has enough MATIC for gas
  bool get hasEnoughGas => matic > 0.01; // Minimum 0.01 MATIC for gas

  @override
  String toString() {
    return 'WalletBalances(MATIC: $matic, USDT: $usdt, USDC: $usdc)';
  }

  Map<String, dynamic> toJson() => {
    'matic': matic,
    'usdt': usdt,
    'usdc': usdc,
  };
}

// ============================================================================
// WEB3 EXCEPTION
// ============================================================================

class Web3Exception implements Exception {
  final String message;

  Web3Exception(this.message);

  @override
  String toString() => 'Web3Exception: $message';
}
