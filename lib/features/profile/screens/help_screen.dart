/// Help, FAQ, Terms and Privacy screens
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';

// ============================================================================
// HELP SCREEN
// ============================================================================

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Contact card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.support_agent_rounded, color: Colors.white, size: 32),
                const SizedBox(height: 12),
                const Text('Need Help?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Our support team is available 24/7', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _ContactChip(icon: Icons.email_outlined, label: AppConstants.supportEmail),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Quick Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _LinkCard(
            icon: Icons.quiz_rounded,
            color: AppTheme.primaryColor,
            title: 'FAQ',
            subtitle: 'Answers to common questions',
            onTap: () => context.push('/help/faq'),
          ),
          const SizedBox(height: 10),
          _LinkCard(
            icon: Icons.description_rounded,
            color: Colors.grey[700]!,
            title: 'Terms of Service',
            subtitle: 'Our rules and agreements',
            onTap: () => context.push('/help/terms'),
          ),
          const SizedBox(height: 10),
          _LinkCard(
            icon: Icons.privacy_tip_rounded,
            color: Colors.grey[700]!,
            title: 'Privacy Policy',
            subtitle: 'How we handle your data',
            onTap: () => context.push('/help/privacy'),
          ),
          const SizedBox(height: 24),

          const Text('Common Topics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          ..._topics.map((t) => _TopicTile(topic: t)),
        ],
      ),
    );
  }

  static const _topics = [
    _Topic('How does escrow work?', 'Funds are locked when the buyer funds the escrow. They are only released to the seller when the buyer confirms delivery. If there is a dispute, our admin team reviews and resolves it.'),
    _Topic('How do I recover my wallet?', 'Go to Settings → Security → Restore Wallet and enter your 12-word recovery phrase. Never share your recovery phrase with anyone.'),
    _Topic('Why is my KYC pending?', 'KYC verification usually takes 1–3 business days. Make sure your ID photo is clear and your selfie matches your ID.'),
    _Topic('How long does a P2P order take?', 'P2P orders typically complete in 15–30 minutes once the seller confirms payment. If the seller is unresponsive, you can open a dispute.'),
    _Topic('What fees does ESCOPAY charge?', 'ESCOPAY charges a ${AppConstants.platformFeePercent}% platform fee on completed escrow transactions. Blockchain gas fees are paid separately.'),
  ];
}

class _Topic {
  final String question;
  final String answer;
  const _Topic(this.question, this.answer);
}

class _TopicTile extends StatefulWidget {
  final _Topic topic;
  const _TopicTile({required this.topic});

  @override
  State<_TopicTile> createState() => _TopicTileState();
}

class _TopicTileState extends State<_TopicTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.topic.question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Icon(_expanded ? Icons.remove_circle_outline : Icons.add_circle_outline, color: AppTheme.primaryColor, size: 20),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.topic.answer, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkCard({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FAQ SCREEN
// ============================================================================

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ContentScreen(
      title: 'FAQ',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._faqs.map((f) => _FaqTile(faq: f)),
        ],
      ),
    );
  }

  static const _faqs = [
    _Faq('What is ESCOPAY?', 'ESCOPAY is a secure P2P crypto escrow platform for East Africa. It lets you trade safely using USDT and USDC on the Polygon blockchain.'),
    _Faq('How do I create an escrow?', 'Tap the + button on the home screen, fill in the trade details (amount, counterparty, description), and send the invite link. The other party confirms, then fund the escrow to start.'),
    _Faq('What happens if there is a dispute?', 'Either party can raise a dispute. Our admin team reviews the evidence and resolves it within 48 hours by either releasing funds to the seller or refunding the buyer.'),
    _Faq('How do I fund an escrow?', 'Open the escrow detail screen and tap "Fund Escrow". Your crypto wallet balance will be checked and the amount deducted via blockchain transaction.'),
    _Faq('Is my wallet secure?', 'Yes. Your private key is encrypted with AES-256 and stored only on your device. ESCOPAY never has access to your private keys.'),
    _Faq('What is KYC?', 'KYC (Know Your Customer) is an identity verification process. Complete it to unlock higher transaction limits and become an eligible merchant.'),
    _Faq('How do I become a P2P merchant?', 'Go to P2P → Apply as Merchant. Submit your ID and business details. Approval takes 1-3 business days.'),
    _Faq('What currencies are supported?', 'We support USDT and USDC on the Polygon network. MATIC is used for gas fees. Rwanda Franc (RWF) is used for P2P fiat payments.'),
    _Faq('How do I recover my wallet?', 'Go to Security → Restore Wallet and enter your 12-word recovery phrase. Keep this phrase safe — it cannot be reset.'),
    _Faq('What are the fees?', 'ESCOPAY charges ${AppConstants.platformFeePercent}% on completed escrow transactions. P2P trades have no platform fee. Polygon gas fees are typically under \$0.01.'),
  ];
}

class _Faq {
  final String q;
  final String a;
  const _Faq(this.q, this.a);
}

class _FaqTile extends StatefulWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(widget.faq.q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          trailing: Icon(_expanded ? Icons.remove : Icons.add, color: AppTheme.primaryColor, size: 18),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.faq.a, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// TERMS OF SERVICE SCREEN
// ============================================================================

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ContentScreen(
      title: 'Terms of Service',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDate('Last updated: January 2025'),
            _buildSection('1. Acceptance of Terms', 'By using ESCOPAY, you agree to these Terms of Service. If you do not agree, do not use the platform. We reserve the right to update these terms at any time.'),
            _buildSection('2. Eligibility', 'You must be at least 18 years old and legally allowed to enter contracts in your country to use ESCOPAY. By using the platform, you represent that you meet these requirements.'),
            _buildSection('3. Escrow Services', 'ESCOPAY acts as a neutral third party in escrow transactions. Funds are held until both parties fulfill their obligations. ESCOPAY does not guarantee that counterparties will fulfill their obligations.'),
            _buildSection('4. KYC Verification', 'Certain features require identity verification. You agree to provide accurate information. False information may result in account suspension.'),
            _buildSection('5. Prohibited Activities', 'You may not use ESCOPAY for illegal activities, money laundering, fraud, or any activity that violates applicable laws. Violations will result in immediate account termination.'),
            _buildSection('6. Fees', 'ESCOPAY charges a ${AppConstants.platformFeePercent}% fee on completed escrow transactions. Fees are non-refundable once a transaction is completed.'),
            _buildSection('7. Disputes', 'Disputes must be raised within 7 days of the transaction. ESCOPAY\'s admin decision on disputes is final.'),
            _buildSection('8. Cryptocurrency Risk', 'Cryptocurrency values are volatile. ESCOPAY is not responsible for losses due to market fluctuations. You use the platform at your own risk.'),
            _buildSection('9. Limitation of Liability', 'ESCOPAY is not liable for indirect, incidental, or consequential damages. Our total liability is limited to the transaction fees paid in the last 30 days.'),
            _buildSection('10. Contact', 'For questions about these terms, contact us at ${AppConstants.supportEmail}.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDate(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
  );

  Widget _buildSection(String title, String content) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6)),
      ],
    ),
  );
}

// ============================================================================
// PRIVACY POLICY SCREEN
// ============================================================================

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ContentScreen(
      title: 'Privacy Policy',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDate('Last updated: January 2025'),
            _buildSection('1. Information We Collect', 'We collect: your email address, display name, phone number, wallet address, KYC documents (ID and selfie), transaction data, and device information.'),
            _buildSection('2. How We Use Your Information', 'We use your data to: verify your identity, process transactions, resolve disputes, send notifications, comply with legal requirements, and improve our services.'),
            _buildSection('3. Data Storage', 'Your data is stored on Firebase servers in the EU (europe-west1). Your private keys are stored only on your device and are never transmitted to our servers.'),
            _buildSection('4. KYC Documents', 'KYC documents are stored securely in Firebase Storage. They are accessible only to you and authorized ESCOPAY administrators. We do not sell your data.'),
            _buildSection('5. Data Sharing', 'We do not sell your personal data. We may share data with law enforcement if required by applicable law. Transaction data visible to your counterparty includes only your wallet address.'),
            _buildSection('6. Your Rights', 'You have the right to: access your data, correct inaccurate data, request deletion (subject to legal requirements), and opt out of marketing communications.'),
            _buildSection('7. Cookies and Analytics', 'We use Firebase Analytics to improve the app. No third-party advertising trackers are used.'),
            _buildSection('8. Security', 'We use industry-standard security including AES-256 encryption, HTTPS, and Firebase security rules. However, no system is 100% secure.'),
            _buildSection('9. Children', 'ESCOPAY is not intended for users under 18. We do not knowingly collect data from minors.'),
            _buildSection('10. Contact', 'For privacy questions, contact us at ${AppConstants.supportEmail}.'),
          ],
        ),
      ),
    );
  }

  Widget _buildDate(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Text(text, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
  );

  Widget _buildSection(String title, String content) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(content, style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.6)),
      ],
    ),
  );
}

// ============================================================================
// SHARED CONTENT SCREEN WRAPPER
// ============================================================================

class _ContentScreen extends StatelessWidget {
  final String title;
  final Widget child;
  const _ContentScreen({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: child,
    );
  }
}
