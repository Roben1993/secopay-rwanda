/// P2P Marketplace Screen
/// Main screen for browsing sell ads and viewing my trades
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../models/p2p_ad_model.dart';
import '../models/p2p_order_model.dart';
import '../services/p2p_service.dart';

class P2PMarketScreen extends StatefulWidget {
  const P2PMarketScreen({super.key});

  @override
  State<P2PMarketScreen> createState() => _P2PMarketScreenState();
}

class _P2PMarketScreenState extends State<P2PMarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();

  String? _walletAddress;
  List<P2PAdModel> _ads = [];
  List<P2POrderModel> _myOrders = [];
  List<P2PAdModel> _myAds = [];
  bool _isLoading = true;
  String _tokenFilter = 'All';
  String? _countryFilter; // null = not yet loaded, 'ALL' = show all countries
  bool _countryLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserCountryThenData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCountryThenData() async {
    // Load saved country preference first, then load data
    final savedCountry = await _p2pService.getUserCountry();
    _countryFilter = savedCountry ?? 'ALL';
    _countryLoaded = true;
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final address = await _walletService.getWalletAddress();
      final tokenFilter = _tokenFilter == 'All' ? null : _tokenFilter;
      final countryFilter = _countryFilter == 'ALL' ? null : _countryFilter;
      final ads = await _p2pService.getActiveAds(
        tokenFilter: tokenFilter,
        countryFilter: countryFilter,
      );
      List<P2POrderModel> orders = [];
      List<P2PAdModel> myAds = [];
      if (address != null) {
        orders = await _p2pService.getMyOrders(address);
        myAds = await _p2pService.getMyAds(address);
      }
      setState(() {
        _walletAddress = address;
        _ads = ads;
        _myOrders = orders;
        _myAds = myAds;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading P2P data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('P2P Trading'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.merchantApplication),
            icon: const Icon(Icons.verified_user, size: 18),
            label: const Text('Merchant'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Buy'),
            Tab(text: 'My Orders'),
            Tab(text: 'My Ads'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuyTab(),
          _buildMyOrdersTab(),
          _buildMyAdsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.p2pCreateAd);
          _loadData();
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Sell Ad', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ============================================================================
  // BUY TAB - Browse active sell ads
  // ============================================================================

  Widget _buildBuyTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildCountryFilter(),
          _buildTokenFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _ads.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.storefront_outlined,
                        title: 'No ads available',
                        subtitle: 'Be the first to post a sell ad!',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: _ads.length,
                        itemBuilder: (context, index) =>
                            _buildAdCard(_ads[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryFilter() {
    if (!_countryLoaded) return const SizedBox.shrink();

    final selectedCountry = _countryFilter == 'ALL'
        ? null
        : AppConstants.getP2PCountry(_countryFilter ?? 'ALL');

    return GestureDetector(
      onTap: _showCountryFilterPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                selectedCountry != null
                    ? '${selectedCountry.flag} ${selectedCountry.name} (${selectedCountry.currency})'
                    : 'All Countries',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryFilterPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filter by Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // "All Countries" option
                      ListTile(
                        leading: const Icon(Icons.public, size: 28),
                        title: Text(
                          'All Countries',
                          style: TextStyle(
                            fontWeight: _countryFilter == 'ALL'
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: _countryFilter == 'ALL'
                                ? AppTheme.primaryColor
                                : const Color(0xFF1A1A2E),
                          ),
                        ),
                        subtitle: Text(
                          'Show ads from all countries',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        trailing: _countryFilter == 'ALL'
                            ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                            : null,
                        onTap: () {
                          setState(() => _countryFilter = 'ALL');
                          _loadData();
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      // Country list
                      ...AppConstants.p2pCountries.map((country) {
                        final isSelected = _countryFilter == country.code;
                        return ListTile(
                          leading: Text(country.flag,
                              style: const TextStyle(fontSize: 28)),
                          title: Text(
                            country.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                          subtitle: Text(
                            country.currency,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
                              : Text(
                                  country.currencySymbol,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                          onTap: () {
                            setState(() => _countryFilter = country.code);
                            _p2pService.setUserCountry(country.code);
                            _loadData();
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTokenFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: ['All', 'USDT', 'USDC'].map((token) {
          final isSelected = _tokenFilter == token;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(token),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _tokenFilter = token);
                _loadData();
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdCard(P2PAdModel ad) {
    final fiatPrice = ad.pricePerUnit.toStringAsFixed(2);
    final currency = ad.fiatCurrency;
    return GestureDetector(
      onTap: () async {
        // Don't allow buying own ads
        if (_walletAddress != null &&
            ad.sellerAddress.toLowerCase() == _walletAddress!.toLowerCase()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You cannot buy from your own ad')),
          );
          return;
        }
        await context.push(AppRoutes.getP2PBuyRoute(ad.id));
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: seller + token
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: Text(
                    ad.sellerAddress.substring(2, 4).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ad.shortSeller,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${ad.completedOrders} orders',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ad.tokenSymbol == 'USDT'
                        ? const Color(0xFF26A17B).withValues(alpha: 0.1)
                        : const Color(0xFF2775CA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ad.tokenSymbol,
                    style: TextStyle(
                      color: ad.tokenSymbol == 'USDT'
                          ? const Color(0xFF26A17B)
                          : const Color(0xFF2775CA),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Price
            Row(
              children: [
                if (ad.countryFlag.isNotEmpty) ...[
                  Text(ad.countryFlag, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                Text(
                  '$fiatPrice $currency',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  ' / ${ad.tokenSymbol}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Available + limits
            Row(
              children: [
                _buildAdInfoChip(
                    'Available', ad.availableAmount.toStringAsFixed(2)),
                const SizedBox(width: 8),
                _buildAdInfoChip('Limit',
                    '${ad.minOrderAmount.toStringAsFixed(0)}-${ad.maxOrderAmount.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 10),

            // Payment methods
            Wrap(
              spacing: 6,
              children: ad.paymentMethods.map((method) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppConstants.getPaymentMethodLabel(method),
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E)),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MY ORDERS TAB
  // ============================================================================

  Widget _buildMyOrdersTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myOrders.isEmpty
              ? _buildEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders yet',
                  subtitle: 'Browse ads and start trading!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _myOrders.length,
                  itemBuilder: (context, index) =>
                      _buildOrderCard(_myOrders[index]),
                ),
    );
  }

  Widget _buildOrderCard(P2POrderModel order) {
    final role = _walletAddress != null ? order.roleFor(_walletAddress!) : '';
    final statusColor = _getOrderStatusColor(order.status);

    return GestureDetector(
      onTap: () async {
        await context.push(AppRoutes.getP2POrderRoute(order.id));
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.id,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '${order.cryptoAmount.toStringAsFixed(2)} ${order.tokenSymbol}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.fiatAmount.toStringAsFixed(2)} ${order.fiatCurrency}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'You are the $role',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const Spacer(),
                Text(
                  order.paymentMethodLabel,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MY ADS TAB
  // ============================================================================

  Widget _buildMyAdsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _myAds.isEmpty
              ? _buildEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No ads posted',
                  subtitle: 'Post a sell ad to start trading!',
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: _myAds.length,
                  itemBuilder: (context, index) =>
                      _buildMyAdCard(_myAds[index]),
                ),
    );
  }

  Widget _buildMyAdCard(P2PAdModel ad) {
    final statusColor = _getAdStatusColor(ad.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(ad.id,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ad.tokenSymbol == 'USDT'
                      ? const Color(0xFF26A17B).withValues(alpha: 0.1)
                      : const Color(0xFF2775CA).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ad.tokenSymbol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: ad.tokenSymbol == 'USDT'
                        ? const Color(0xFF26A17B)
                        : const Color(0xFF2775CA),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ad.status.name.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '${ad.pricePerUnit.toStringAsFixed(2)} ${ad.fiatCurrency} / ${ad.tokenSymbol}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar for available amount
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ad.totalAmount > 0
                  ? ad.availableAmount / ad.totalAmount
                  : 0,
              backgroundColor: Colors.grey[200],
              color: AppTheme.primaryColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Available: ${ad.availableAmount.toStringAsFixed(2)} / ${ad.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const Spacer(),
              Text(
                '${ad.completedOrders} completed',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          if (ad.status == P2PAdStatus.active ||
              ad.status == P2PAdStatus.paused)
            Row(
              children: [
                if (ad.status == P2PAdStatus.active)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _p2pService.pauseAd(ad.id);
                        _loadData();
                      },
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('Pause'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                      ),
                    ),
                  ),
                if (ad.status == P2PAdStatus.paused)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _p2pService.resumeAd(ad.id);
                        _loadData();
                      },
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Resume'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Cancel Ad'),
                          content: const Text(
                              'Are you sure you want to cancel this ad?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await _p2pService.cancelAd(ad.id);
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: Colors.grey[400]),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getOrderStatusColor(P2POrderStatus status) {
    switch (status) {
      case P2POrderStatus.pendingPayment:
        return Colors.orange;
      case P2POrderStatus.proofUploaded:
        return Colors.blue;
      case P2POrderStatus.completed:
        return Colors.green;
      case P2POrderStatus.cancelled:
        return Colors.red;
      case P2POrderStatus.disputed:
        return Colors.deepOrange;
      case P2POrderStatus.expired:
        return Colors.grey;
    }
  }

  Color _getAdStatusColor(P2PAdStatus status) {
    switch (status) {
      case P2PAdStatus.active:
        return Colors.green;
      case P2PAdStatus.paused:
        return Colors.orange;
      case P2PAdStatus.completed:
        return Colors.blue;
      case P2PAdStatus.cancelled:
        return Colors.red;
    }
  }
}
