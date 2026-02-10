/// Web3 Configuration for Polygon Network
/// Contains RPC URLs, Contract Addresses, and Network Configuration

class Web3Config {
  Web3Config._(); // Private constructor to prevent instantiation

  // ============================================================================
  // POLYGON MAINNET CONFIGURATION (Production)
  // ============================================================================

  static const String polygonMainnetRpcUrl = 'https://polygon-rpc.com';
  static const String polygonMainnetChainId = '137';
  static const String polygonMainnetName = 'Polygon Mainnet';
  static const String polygonMainnetCurrency = 'MATIC';
  static const String polygonMainnetExplorer = 'https://polygonscan.com';

  // Backup RPC URLs for redundancy
  static const List<String> polygonMainnetRpcBackups = [
    'https://rpc-mainnet.matic.network',
    'https://rpc-mainnet.maticvigil.com',
    'https://polygon-mainnet.infura.io/v3/YOUR_INFURA_KEY', // Replace with your key
    'https://polygon-mainnet.g.alchemy.com/v2/YOUR_ALCHEMY_KEY', // Replace with your key
  ];

  // ============================================================================
  // POLYGON MUMBAI TESTNET CONFIGURATION (Development & Testing)
  // ============================================================================

  static const String polygonMumbaiRpcUrl = 'https://rpc-mumbai.maticvigil.com';
  static const String polygonMumbaiChainId = '80001';
  static const String polygonMumbaiName = 'Polygon Mumbai Testnet';
  static const String polygonMumbaiCurrency = 'MATIC';
  static const String polygonMumbaiExplorer = 'https://mumbai.polygonscan.com';

  // Mumbai testnet RPC backups
  static const List<String> polygonMumbaiRpcBackups = [
    'https://matic-mumbai.chainstacklabs.com',
    'https://polygon-mumbai.infura.io/v3/YOUR_INFURA_KEY',
    'https://polygon-mumbai.g.alchemy.com/v2/YOUR_ALCHEMY_KEY',
  ];

  // ============================================================================
  // TOKEN CONTRACT ADDRESSES - POLYGON MAINNET
  // ============================================================================

  // USDT (Tether) on Polygon Mainnet
  static const String usdtMainnetAddress = '0xc2132D05D31c914a87C6611C10748AEb04B58e8F';

  // USDC (USD Coin) on Polygon Mainnet
  static const String usdcMainnetAddress = '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174';

  // Native MATIC (Wrapped MATIC for swaps)
  static const String wmaticMainnetAddress = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';

  // ============================================================================
  // TOKEN CONTRACT ADDRESSES - POLYGON MUMBAI TESTNET
  // ============================================================================

  // USDT on Mumbai (Test tokens - get from faucet)
  static const String usdtMumbaiAddress = '0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832';

  // USDC on Mumbai (Test tokens)
  static const String usdcMumbaiAddress = '0x0FA8781a83E46826621b3BC094Ea2A0212e71B23';

  // Wrapped MATIC on Mumbai
  static const String wmaticMumbaiAddress = '0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889';

  // ============================================================================
  // ESCROW SMART CONTRACT ADDRESSES
  // ============================================================================

  // TODO: Deploy your escrow contract and update these addresses
  static const String escrowContractMainnet = '0x0000000000000000000000000000000000000000'; // Replace after deployment
  static const String escrowContractMumbai = '0x0000000000000000000000000000000000000000'; // Replace after deployment

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  // Toggle this to switch between mainnet and testnet
  static const bool isProduction = false; // Set to true for production release

  // Get current network configuration based on environment
  static String get rpcUrl => isProduction ? polygonMainnetRpcUrl : polygonMumbaiRpcUrl;
  static String get chainId => isProduction ? polygonMainnetChainId : polygonMumbaiChainId;
  static String get networkName => isProduction ? polygonMainnetName : polygonMumbaiName;
  static String get nativeCurrency => isProduction ? polygonMainnetCurrency : polygonMumbaiCurrency;
  static String get explorerUrl => isProduction ? polygonMainnetExplorer : polygonMumbaiExplorer;

  // Get token addresses based on environment
  static String get usdtAddress => isProduction ? usdtMainnetAddress : usdtMumbaiAddress;
  static String get usdcAddress => isProduction ? usdcMainnetAddress : usdcMumbaiAddress;
  static String get wmaticAddress => isProduction ? wmaticMainnetAddress : wmaticMumbaiAddress;
  static String get escrowContractAddress => isProduction ? escrowContractMainnet : escrowContractMumbai;

  // ============================================================================
  // TOKEN METADATA
  // ============================================================================

  static const Map<String, TokenMetadata> supportedTokens = {
    'USDT': TokenMetadata(
      symbol: 'USDT',
      name: 'Tether USD',
      decimals: 6,
      icon: '💵',
    ),
    'USDC': TokenMetadata(
      symbol: 'USDC',
      name: 'USD Coin',
      decimals: 6,
      icon: '💲',
    ),
    'MATIC': TokenMetadata(
      symbol: 'MATIC',
      name: 'Polygon',
      decimals: 18,
      icon: '⬡',
    ),
  };

  // ============================================================================
  // GAS CONFIGURATION
  // ============================================================================

  // Gas limits for different operations
  static const int transferGasLimit = 100000;
  static const int approveGasLimit = 60000;
  static const int escrowCreateGasLimit = 300000;
  static const int escrowReleaseGasLimit = 150000;

  // Gas price configuration (in Gwei)
  static const int defaultGasPrice = 50; // 50 Gwei (adjust based on network)
  static const int maxGasPrice = 500; // Maximum acceptable gas price

  // ============================================================================
  // TRANSACTION SETTINGS
  // ============================================================================

  // Number of confirmations to wait before considering transaction final
  static const int requiredConfirmations = 3;

  // Transaction timeout (in seconds)
  static const int transactionTimeout = 300; // 5 minutes

  // Polling interval for transaction status (in milliseconds)
  static const int pollingInterval = 2000; // 2 seconds

  // ============================================================================
  // FAUCET URLS (For getting test tokens on Mumbai)
  // ============================================================================

  static const String maticFaucetUrl = 'https://faucet.polygon.technology/';
  static const String mumbaiFaucetUrl = 'https://mumbaifaucet.com/';

  // ============================================================================
  // API KEYS (Store in environment variables in production!)
  // ============================================================================

  // TODO: Move these to environment variables or Firebase Remote Config
  static const String infuraApiKey = 'YOUR_INFURA_API_KEY'; // Get from infura.io
  static const String alchemyApiKey = 'YOUR_ALCHEMY_API_KEY'; // Get from alchemy.com
  static const String polygonscanApiKey = 'YOUR_POLYGONSCAN_API_KEY'; // Get from polygonscan.com

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get RPC URL with API key if available
  static String getRpcUrlWithKey() {
    if (infuraApiKey != 'YOUR_INFURA_API_KEY' && infuraApiKey.isNotEmpty) {
      return isProduction
          ? 'https://polygon-mainnet.infura.io/v3/$infuraApiKey'
          : 'https://polygon-mumbai.infura.io/v3/$infuraApiKey';
    }
    return rpcUrl;
  }

  /// Get block explorer URL for transaction
  static String getTransactionUrl(String txHash) {
    return '$explorerUrl/tx/$txHash';
  }

  /// Get block explorer URL for address
  static String getAddressUrl(String address) {
    return '$explorerUrl/address/$address';
  }

  /// Get block explorer URL for token
  static String getTokenUrl(String tokenAddress) {
    return '$explorerUrl/token/$tokenAddress';
  }

  /// Validate if address is a valid Ethereum address
  static bool isValidAddress(String address) {
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }
}

// ============================================================================
// TOKEN METADATA CLASS
// ============================================================================

class TokenMetadata {
  final String symbol;
  final String name;
  final int decimals;
  final String icon;

  const TokenMetadata({
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.icon,
  });

  /// Convert token amount from smallest unit to human-readable format
  /// Example: 1000000 USDT (6 decimals) → 1.0 USDT
  double fromSmallestUnit(BigInt amount) {
    return amount / BigInt.from(10).pow(decimals);
  }

  /// Convert human-readable amount to smallest unit
  /// Example: 1.5 USDT → 1500000 (6 decimals)
  BigInt toSmallestUnit(double amount) {
    return BigInt.from(amount * BigInt.from(10).pow(decimals).toDouble());
  }
}

// ============================================================================
// ERC-20 TOKEN ABI (Application Binary Interface)
// ============================================================================

/// Standard ERC-20 functions we'll need for USDT/USDC interaction
class ERC20ABI {
  static const String balanceOfABI = '''
  [
    {
      "constant": true,
      "inputs": [{"name": "owner", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"name": "", "type": "uint256"}],
      "type": "function"
    }
  ]
  ''';

  static const String transferABI = '''
  [
    {
      "constant": false,
      "inputs": [
        {"name": "to", "type": "address"},
        {"name": "value", "type": "uint256"}
      ],
      "name": "transfer",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    }
  ]
  ''';

  static const String approveABI = '''
  [
    {
      "constant": false,
      "inputs": [
        {"name": "spender", "type": "address"},
        {"name": "value", "type": "uint256"}
      ],
      "name": "approve",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    }
  ]
  ''';

  static const String allowanceABI = '''
  [
    {
      "constant": true,
      "inputs": [
        {"name": "owner", "type": "address"},
        {"name": "spender", "type": "address"}
      ],
      "name": "allowance",
      "outputs": [{"name": "", "type": "uint256"}],
      "type": "function"
    }
  ]
  ''';

  // Complete ERC-20 ABI with all standard functions
  static const String completeERC20ABI = '''
  [
    {
      "constant": true,
      "inputs": [],
      "name": "name",
      "outputs": [{"name": "", "type": "string"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "symbol",
      "outputs": [{"name": "", "type": "string"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "decimals",
      "outputs": [{"name": "", "type": "uint8"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [],
      "name": "totalSupply",
      "outputs": [{"name": "", "type": "uint256"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [{"name": "owner", "type": "address"}],
      "name": "balanceOf",
      "outputs": [{"name": "", "type": "uint256"}],
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {"name": "to", "type": "address"},
        {"name": "value", "type": "uint256"}
      ],
      "name": "transfer",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {"name": "spender", "type": "address"},
        {"name": "value", "type": "uint256"}
      ],
      "name": "approve",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    },
    {
      "constant": true,
      "inputs": [
        {"name": "owner", "type": "address"},
        {"name": "spender", "type": "address"}
      ],
      "name": "allowance",
      "outputs": [{"name": "", "type": "uint256"}],
      "type": "function"
    },
    {
      "constant": false,
      "inputs": [
        {"name": "from", "type": "address"},
        {"name": "to", "type": "address"},
        {"name": "value", "type": "uint256"}
      ],
      "name": "transferFrom",
      "outputs": [{"name": "", "type": "bool"}],
      "type": "function"
    }
  ]
  ''';
}
