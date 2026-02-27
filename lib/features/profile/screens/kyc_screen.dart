/// KYC Verification Screen
/// Multi-step identity verification for increased escrow limits
/// Supports Rwanda National ID, Passport, and Driver's License
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/constants/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/storage_service.dart';
import '../../../services/wallet_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final WalletService _walletService = WalletService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Step tracking
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Personal information
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dateOfBirth;
  String _selectedGender = 'male';
  Map<String, String> _selectedCountry = {'code': 'RW', 'name': 'Rwanda', 'dial': '+250', 'flag': '🇷🇼'};
  Map<String, String> _selectedDialCode = {'code': 'RW', 'name': 'Rwanda', 'dial': '+250', 'flag': '🇷🇼'};

  // Step 2: Document
  String _selectedDocType = 'national_id';
  final _docNumberController = TextEditingController();
  String? _frontImageName;
  String? _backImageName;
  XFile? _frontImage;
  XFile? _backImage;

  // Step 3: Selfie
  String? _selfieImageName;
  XFile? _selfieImage;

  // Country-specific document types
  List<Map<String, dynamic>> get _docTypes {
    final code = _selectedCountry['code'];
    final base = <Map<String, dynamic>>[
      {'value': 'passport', 'label': 'Passport', 'icon': Icons.menu_book},
      {'value': 'driving_license', 'label': "Driver's License", 'icon': Icons.drive_eta},
    ];
    switch (code) {
      case 'RW':
        return [{'value': 'national_id', 'label': 'National ID (Indangamuntu)', 'icon': Icons.badge}, ...base];
      case 'KE':
        return [{'value': 'national_id', 'label': 'National ID (Kitambulisho)', 'icon': Icons.badge}, {'value': 'huduma', 'label': 'Huduma Namba', 'icon': Icons.credit_card}, ...base];
      case 'UG':
        return [{'value': 'national_id', 'label': 'National ID (Ndaga Muntu)', 'icon': Icons.badge}, ...base];
      case 'TZ':
        return [{'value': 'national_id', 'label': 'National ID (NIDA)', 'icon': Icons.badge}, ...base];
      case 'NG':
        return [{'value': 'nin', 'label': 'NIN (National Identification Number)', 'icon': Icons.badge}, {'value': 'voters_card', 'label': "Voter's Card", 'icon': Icons.how_to_vote}, ...base];
      case 'GH':
        return [{'value': 'ghana_card', 'label': 'Ghana Card', 'icon': Icons.badge}, {'value': 'voters_card', 'label': "Voter's ID", 'icon': Icons.how_to_vote}, ...base];
      case 'ZA':
        return [{'value': 'national_id', 'label': 'Smart ID Card', 'icon': Icons.badge}, {'value': 'green_book', 'label': 'Green ID Book', 'icon': Icons.menu_book}, ...base];
      case 'IN':
        return [{'value': 'aadhaar', 'label': 'Aadhaar Card', 'icon': Icons.badge}, {'value': 'pan', 'label': 'PAN Card', 'icon': Icons.credit_card}, {'value': 'voters_card', 'label': "Voter ID (EPIC)", 'icon': Icons.how_to_vote}, ...base];
      case 'US':
        return [{'value': 'state_id', 'label': 'State ID', 'icon': Icons.badge}, ...base];
      case 'GB':
        return [{'value': 'national_id', 'label': 'Biometric Residence Permit', 'icon': Icons.badge}, ...base];
      case 'AE':
        return [{'value': 'emirates_id', 'label': 'Emirates ID', 'icon': Icons.badge}, ...base];
      case 'SA':
        return [{'value': 'national_id', 'label': 'National ID (Iqama)', 'icon': Icons.badge}, ...base];
      case 'EG':
        return [{'value': 'national_id', 'label': 'National ID Card', 'icon': Icons.badge}, ...base];
      case 'PK':
        return [{'value': 'cnic', 'label': 'CNIC', 'icon': Icons.badge}, {'value': 'nicop', 'label': 'NICOP', 'icon': Icons.credit_card}, ...base];
      case 'BD':
        return [{'value': 'nid', 'label': 'National ID (NID)', 'icon': Icons.badge}, ...base];
      case 'BR':
        return [{'value': 'cpf', 'label': 'CPF', 'icon': Icons.badge}, {'value': 'rg', 'label': 'RG (Identity Card)', 'icon': Icons.credit_card}, ...base];
      case 'TR':
        return [{'value': 'national_id', 'label': 'Turkish ID Card', 'icon': Icons.badge}, ...base];
      default:
        return [{'value': 'national_id', 'label': 'National ID Card', 'icon': Icons.badge}, ...base];
    }
  }

  // Document number hint based on country and doc type
  String get _docNumberHint {
    final code = _selectedCountry['code'];
    switch (_selectedDocType) {
      case 'national_id':
        if (code == 'RW') return '1 1990 8 0012345 0 12';
        if (code == 'ZA') return '9001015009087';
        return 'Enter your ID number';
      case 'nin':
        return '00000000000';
      case 'aadhaar':
        return '0000 0000 0000';
      case 'pan':
        return 'ABCDE1234F';
      case 'cnic':
        return '00000-0000000-0';
      case 'cpf':
        return '000.000.000-00';
      case 'emirates_id':
        return '784-0000-0000000-0';
      case 'ghana_card':
        return 'GHA-000000000-0';
      case 'passport':
        return 'Enter passport number';
      case 'driving_license':
        return 'Enter license number';
      default:
        return 'Enter document number';
    }
  }

  static final List<Map<String, String>> _countries = [
    {'code': 'RW', 'name': 'Rwanda', 'dial': '+250', 'flag': '🇷🇼'},
    {'code': 'KE', 'name': 'Kenya', 'dial': '+254', 'flag': '🇰🇪'},
    {'code': 'UG', 'name': 'Uganda', 'dial': '+256', 'flag': '🇺🇬'},
    {'code': 'TZ', 'name': 'Tanzania', 'dial': '+255', 'flag': '🇹🇿'},
    {'code': 'BI', 'name': 'Burundi', 'dial': '+257', 'flag': '🇧🇮'},
    {'code': 'CD', 'name': 'DR Congo', 'dial': '+243', 'flag': '🇨🇩'},
    {'code': 'ET', 'name': 'Ethiopia', 'dial': '+251', 'flag': '🇪🇹'},
    {'code': 'NG', 'name': 'Nigeria', 'dial': '+234', 'flag': '🇳🇬'},
    {'code': 'GH', 'name': 'Ghana', 'dial': '+233', 'flag': '🇬🇭'},
    {'code': 'ZA', 'name': 'South Africa', 'dial': '+27', 'flag': '🇿🇦'},
    {'code': 'EG', 'name': 'Egypt', 'dial': '+20', 'flag': '🇪🇬'},
    {'code': 'MA', 'name': 'Morocco', 'dial': '+212', 'flag': '🇲🇦'},
    {'code': 'CM', 'name': 'Cameroon', 'dial': '+237', 'flag': '🇨🇲'},
    {'code': 'SN', 'name': 'Senegal', 'dial': '+221', 'flag': '🇸🇳'},
    {'code': 'CI', 'name': "Côte d'Ivoire", 'dial': '+225', 'flag': '🇨🇮'},
    {'code': 'DZ', 'name': 'Algeria', 'dial': '+213', 'flag': '🇩🇿'},
    {'code': 'AO', 'name': 'Angola', 'dial': '+244', 'flag': '🇦🇴'},
    {'code': 'BJ', 'name': 'Benin', 'dial': '+229', 'flag': '🇧🇯'},
    {'code': 'BW', 'name': 'Botswana', 'dial': '+267', 'flag': '🇧🇼'},
    {'code': 'BF', 'name': 'Burkina Faso', 'dial': '+226', 'flag': '🇧🇫'},
    {'code': 'CV', 'name': 'Cape Verde', 'dial': '+238', 'flag': '🇨🇻'},
    {'code': 'CF', 'name': 'Central African Republic', 'dial': '+236', 'flag': '🇨🇫'},
    {'code': 'TD', 'name': 'Chad', 'dial': '+235', 'flag': '🇹🇩'},
    {'code': 'KM', 'name': 'Comoros', 'dial': '+269', 'flag': '🇰🇲'},
    {'code': 'CG', 'name': 'Congo', 'dial': '+242', 'flag': '🇨🇬'},
    {'code': 'DJ', 'name': 'Djibouti', 'dial': '+253', 'flag': '🇩🇯'},
    {'code': 'GQ', 'name': 'Equatorial Guinea', 'dial': '+240', 'flag': '🇬🇶'},
    {'code': 'ER', 'name': 'Eritrea', 'dial': '+291', 'flag': '🇪🇷'},
    {'code': 'SZ', 'name': 'Eswatini', 'dial': '+268', 'flag': '🇸🇿'},
    {'code': 'GA', 'name': 'Gabon', 'dial': '+241', 'flag': '🇬🇦'},
    {'code': 'GM', 'name': 'Gambia', 'dial': '+220', 'flag': '🇬🇲'},
    {'code': 'GN', 'name': 'Guinea', 'dial': '+224', 'flag': '🇬🇳'},
    {'code': 'GW', 'name': 'Guinea-Bissau', 'dial': '+245', 'flag': '🇬🇼'},
    {'code': 'LS', 'name': 'Lesotho', 'dial': '+266', 'flag': '🇱🇸'},
    {'code': 'LR', 'name': 'Liberia', 'dial': '+231', 'flag': '🇱🇷'},
    {'code': 'LY', 'name': 'Libya', 'dial': '+218', 'flag': '🇱🇾'},
    {'code': 'MG', 'name': 'Madagascar', 'dial': '+261', 'flag': '🇲🇬'},
    {'code': 'MW', 'name': 'Malawi', 'dial': '+265', 'flag': '🇲🇼'},
    {'code': 'ML', 'name': 'Mali', 'dial': '+223', 'flag': '🇲🇱'},
    {'code': 'MR', 'name': 'Mauritania', 'dial': '+222', 'flag': '🇲🇷'},
    {'code': 'MU', 'name': 'Mauritius', 'dial': '+230', 'flag': '🇲🇺'},
    {'code': 'MZ', 'name': 'Mozambique', 'dial': '+258', 'flag': '🇲🇿'},
    {'code': 'NA', 'name': 'Namibia', 'dial': '+264', 'flag': '🇳🇦'},
    {'code': 'NE', 'name': 'Niger', 'dial': '+227', 'flag': '🇳🇪'},
    {'code': 'ST', 'name': 'São Tomé and Príncipe', 'dial': '+239', 'flag': '🇸🇹'},
    {'code': 'SC', 'name': 'Seychelles', 'dial': '+248', 'flag': '🇸🇨'},
    {'code': 'SL', 'name': 'Sierra Leone', 'dial': '+232', 'flag': '🇸🇱'},
    {'code': 'SO', 'name': 'Somalia', 'dial': '+252', 'flag': '🇸🇴'},
    {'code': 'SS', 'name': 'South Sudan', 'dial': '+211', 'flag': '🇸🇸'},
    {'code': 'SD', 'name': 'Sudan', 'dial': '+249', 'flag': '🇸🇩'},
    {'code': 'TG', 'name': 'Togo', 'dial': '+228', 'flag': '🇹🇬'},
    {'code': 'TN', 'name': 'Tunisia', 'dial': '+216', 'flag': '🇹🇳'},
    {'code': 'ZM', 'name': 'Zambia', 'dial': '+260', 'flag': '🇿🇲'},
    {'code': 'ZW', 'name': 'Zimbabwe', 'dial': '+263', 'flag': '🇿🇼'},
    {'code': 'US', 'name': 'United States', 'dial': '+1', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'United Kingdom', 'dial': '+44', 'flag': '🇬🇧'},
    {'code': 'FR', 'name': 'France', 'dial': '+33', 'flag': '🇫🇷'},
    {'code': 'DE', 'name': 'Germany', 'dial': '+49', 'flag': '🇩🇪'},
    {'code': 'CA', 'name': 'Canada', 'dial': '+1', 'flag': '🇨🇦'},
    {'code': 'AE', 'name': 'UAE', 'dial': '+971', 'flag': '🇦🇪'},
    {'code': 'IN', 'name': 'India', 'dial': '+91', 'flag': '🇮🇳'},
    {'code': 'CN', 'name': 'China', 'dial': '+86', 'flag': '🇨🇳'},
    {'code': 'BR', 'name': 'Brazil', 'dial': '+55', 'flag': '🇧🇷'},
    {'code': 'AU', 'name': 'Australia', 'dial': '+61', 'flag': '🇦🇺'},
    {'code': 'JP', 'name': 'Japan', 'dial': '+81', 'flag': '🇯🇵'},
    {'code': 'TR', 'name': 'Turkey', 'dial': '+90', 'flag': '🇹🇷'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'dial': '+966', 'flag': '🇸🇦'},
    {'code': 'PK', 'name': 'Pakistan', 'dial': '+92', 'flag': '🇵🇰'},
    {'code': 'BD', 'name': 'Bangladesh', 'dial': '+880', 'flag': '🇧🇩'},
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Identity Verification'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildStep1PersonalInfo()
                    : _currentStep == 1
                        ? _buildStep2Documents()
                        : _currentStep == 2
                            ? _buildStep3Selfie()
                            : _buildStep4Review(),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  // ====================== Progress Bar ======================
  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildProgressStep(0, 'Personal'),
          _buildProgressLine(0),
          _buildProgressStep(1, 'Document'),
          _buildProgressLine(1),
          _buildProgressStep(2, 'Selfie'),
          _buildProgressLine(2),
          _buildProgressStep(3, 'Review'),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isCurrent
                ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: isActive && _currentStep > step
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${step + 1}', style: TextStyle(color: isActive ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal, color: isActive ? AppTheme.primaryColor : Colors.grey[500])),
      ],
    );
  }

  Widget _buildProgressLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4), color: isActive ? AppTheme.primaryColor : Colors.grey[300]),
    );
  }

  // ====================== Step 1: Personal Info ======================
  Widget _buildStep1PersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Personal Information',
          'Provide your legal name as it appears on your ID.',
          Icons.person_outline,
        ),
        const SizedBox(height: 24),

        _buildFieldLabel('Full Name *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _inputDecoration('Enter your full legal name', Icons.person),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required';
            if (v.trim().split(' ').length < 2) return 'Please enter first and last name';
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Country / Nationality *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showCountryPicker((country) {
            setState(() {
              _selectedCountry = country;
              _selectedDialCode = country;
              // Reset doc type since options change per country
              _selectedDocType = _docTypes.first['value'] as String;
            });
          }),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Text(_selectedCountry['flag']!, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedCountry['name']!,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Phone Number *'),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code picker
            GestureDetector(
              onTap: () => _showCountryPicker((country) {
                setState(() => _selectedDialCode = country);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedDialCode['flag']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDialCode['dial']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey[500]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone number', Icons.phone),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 6) return 'Too short';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Email (Optional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDecoration('your@email.com', Icons.email),
          validator: (v) {
            if (v != null && v.trim().isNotEmpty && !AppConstants.isValidEmail(v.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Date of Birth *'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[500], size: 20),
                const SizedBox(width: 12),
                Text(
                  _dateOfBirth != null
                      ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                      : 'Select date of birth',
                  style: TextStyle(
                    fontSize: 15,
                    color: _dateOfBirth != null ? const Color(0xFF1A1A2E) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        _buildFieldLabel('Gender *'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildGenderChip('male', 'Male', Icons.male),
            const SizedBox(width: 12),
            _buildGenderChip('female', 'Female', Icons.female),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.grey[500], size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 18), // Must be 18+
      helpText: 'You must be at least 18 years old',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  void _showCountryPicker(ValueChanged<Map<String, String>> onSelected) {
    final searchController = TextEditingController();
    List<Map<String, String>> filtered = List.from(_countries);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Select Country', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search country...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (query) {
                  setModalState(() {
                    filtered = _countries
                        .where((c) =>
                            c['name']!.toLowerCase().contains(query.toLowerCase()) ||
                            c['dial']!.contains(query) ||
                            c['code']!.toLowerCase().contains(query.toLowerCase()))
                        .toList();
                  });
                },
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final country = filtered[i];
                    return ListTile(
                      leading: Text(country['flag']!, style: const TextStyle(fontSize: 24)),
                      title: Text(country['name']!),
                      trailing: Text(country['dial']!, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        searchController.dispose();
                        Navigator.pop(ctx);
                        onSelected(country);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================== Step 2: Document Upload ======================
  Widget _buildStep2Documents() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Identity Document',
          'Upload a clear photo of your ${_selectedCountry['name']} government-issued ID.',
          Icons.badge,
        ),
        const SizedBox(height: 24),

        _buildFieldLabel('Document Type *'),
        const SizedBox(height: 12),
        ..._docTypes.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildDocTypeOption(doc),
        )),
        const SizedBox(height: 16),

        _buildFieldLabel('Document Number *'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _docNumberController,
          decoration: _inputDecoration(
            _docNumberHint,
            Icons.numbers,
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Document number is required';
            if (v.trim().length < 5) return 'Enter a valid document number';
            return null;
          },
        ),
        const SizedBox(height: 24),

        _buildFieldLabel('Front of Document *'),
        const SizedBox(height: 8),
        _buildImageUploadCard(
          imageName: _frontImageName,
          label: 'Upload front side',
          icon: Icons.credit_card,
          onTap: () => _pickImage('front'),
        ),
        const SizedBox(height: 16),

        _buildFieldLabel(_selectedDocType == 'passport' ? 'Info Page (Optional)' : 'Back of Document *'),
        const SizedBox(height: 8),
        _buildImageUploadCard(
          imageName: _backImageName,
          label: _selectedDocType == 'passport' ? 'Upload info page' : 'Upload back side',
          icon: Icons.credit_card,
          onTap: () => _pickImage('back'),
        ),
        const SizedBox(height: 16),

        // Tips
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.infoColor),
                  const SizedBox(width: 8),
                  Text('Photo Tips', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.infoColor)),
                ],
              ),
              const SizedBox(height: 8),
              _buildTip('Place document on a flat, well-lit surface'),
              _buildTip('Ensure all text and photo are clearly visible'),
              _buildTip('Avoid glare, shadows, or blurriness'),
              _buildTip('Max file size: ${AppConstants.maxKycFileSize ~/ (1024 * 1024)}MB'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocTypeOption(Map<String, dynamic> doc) {
    final isSelected = _selectedDocType == doc['value'];
    return GestureDetector(
      onTap: () => setState(() => _selectedDocType = doc['value'] as String),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              doc['icon'] as IconData,
              color: isSelected ? AppTheme.primaryColor : Colors.grey[500],
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                doc['label'] as String,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadCard({
    required String? imageName,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final hasImage = imageName != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: hasImage ? AppTheme.successColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? AppTheme.successColor : Colors.grey[300]!,
            width: hasImage ? 2 : 1,
            style: hasImage ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasImage
                    ? AppTheme.successColor.withOpacity(0.1)
                    : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasImage ? Icons.check_circle : icon,
                color: hasImage ? AppTheme.successColor : Colors.grey[400],
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasImage ? imageName : label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: hasImage ? FontWeight.w600 : FontWeight.normal,
                color: hasImage ? AppTheme.successColor : Colors.grey[600],
              ),
            ),
            if (!hasImage) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to take a photo or choose from gallery',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
            if (hasImage) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to replace',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String type) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            const Text('Choose Photo Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSourceOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _captureImage(type, ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPhotoSourceOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: AppTheme.accentColor,
                    onTap: () {
                      Navigator.pop(ctx);
                      _captureImage(type, ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(String type, ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
        maxHeight: AppConstants.maxImageHeight.toDouble(),
        imageQuality: AppConstants.imageUploadQuality,
      );
      if (image == null) return;

      setState(() {
        switch (type) {
          case 'front':
            _frontImage = image;
            _frontImageName = image.name;
            break;
          case 'back':
            _backImage = image;
            _backImageName = image.name;
            break;
          case 'selfie':
            _selfieImage = image;
            _selfieImageName = image.name;
            break;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  // ====================== Step 3: Selfie ======================
  Widget _buildStep3Selfie() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Selfie Verification',
          'Take a clear selfie to confirm your identity matches your document.',
          Icons.face,
        ),
        const SizedBox(height: 24),

        _buildImageUploadCard(
          imageName: _selfieImageName,
          label: 'Take a selfie',
          icon: Icons.face,
          onTap: () => _pickImage('selfie'),
        ),
        const SizedBox(height: 24),

        // Selfie requirements
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Requirements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              _buildRequirement(Icons.face, 'Face must be clearly visible', true),
              _buildRequirement(Icons.wb_sunny, 'Good lighting, no shadows', true),
              _buildRequirement(Icons.block, 'No sunglasses or hats', true),
              _buildRequirement(Icons.crop_portrait, 'Plain background preferred', false),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.infoColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.infoColor.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock, size: 16, color: AppTheme.infoColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your data is encrypted and only used for identity verification. We follow GDPR and international data protection standards.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirement(IconData icon, String text, bool required) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
          if (required)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Required', style: TextStyle(fontSize: 10, color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ====================== Step 4: Review ======================
  Widget _buildStep4Review() {
    final docLabel = _docTypes.firstWhere((d) => d['value'] == _selectedDocType)['label'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepHeader(
          'Review & Submit',
          'Please verify all information before submitting.',
          Icons.fact_check,
        ),
        const SizedBox(height: 24),

        // Personal info card
        _buildReviewCard('Personal Information', [
          _buildReviewRow('Full Name', _fullNameController.text),
          _buildReviewRow('Country', '${_selectedCountry['flag']} ${_selectedCountry['name']}'),
          _buildReviewRow('Phone', '${_selectedDialCode['dial']} ${_phoneController.text}'),
          if (_emailController.text.isNotEmpty) _buildReviewRow('Email', _emailController.text),
          _buildReviewRow('Date of Birth', _dateOfBirth != null ? DateFormat('dd MMM yyyy').format(_dateOfBirth!) : 'Not set'),
          _buildReviewRow('Gender', _selectedGender == 'male' ? 'Male' : 'Female'),
        ]),
        const SizedBox(height: 16),

        // Document card
        _buildReviewCard('Identity Document', [
          _buildReviewRow('Type', docLabel),
          _buildReviewRow('Number', _docNumberController.text),
          _buildReviewRow('Front Photo', _frontImageName ?? 'Not uploaded'),
          _buildReviewRow('Back Photo', _backImageName ?? 'Not uploaded'),
        ]),
        const SizedBox(height: 16),

        // Selfie card
        _buildReviewCard('Selfie', [
          _buildReviewRow('Photo', _selfieImageName ?? 'Not uploaded'),
        ]),
        const SizedBox(height: 16),

        // What happens next
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text('What happens next?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                ],
              ),
              const SizedBox(height: 10),
              _buildNextStep('1', 'We verify your documents (24-48 hours)'),
              _buildNextStep('2', 'You receive a notification once verified'),
              _buildNextStep('3', 'Escrow limit increases to \$${AppConstants.maxEscrowAmountWithKYC.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Terms
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.warningColor.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.gavel, size: 16, color: AppTheme.warningColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By submitting, you confirm that all information is accurate and you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        ],
      ),
    );
  }

  // ====================== Shared Widgets ======================
  Widget _buildStepHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 14, color: AppTheme.infoColor),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ====================== Bottom Buttons ======================
  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onNextOrSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _currentStep == 3 ? AppTheme.successColor : AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22, width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Text(
                      _currentStep == 3 ? 'Submit for Verification' : 'Continue',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _onNextOrSubmit() {
    if (_currentStep == 0) {
      if (_fullNameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty || _dateOfBirth == null) {
        _formKey.currentState!.validate();
        if (_dateOfBirth == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your date of birth')),
          );
        }
        return;
      }
      if (!_formKey.currentState!.validate()) return;
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      if (_docNumberController.text.trim().isEmpty) {
        _formKey.currentState!.validate();
        return;
      }
      if (_frontImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload the front of your document')),
        );
        return;
      }
      if (_selectedDocType != 'passport' && _backImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload the back of your document')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      if (_selfieImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a selfie for verification')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    } else {
      _submitKYC();
    }
  }

  Future<void> _submitKYC() async {
    setState(() => _isSubmitting = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.uid;

      if (AppConstants.useFirebase && uid != null) {
        final storageService = StorageService();

        // Upload images to Cloud Storage
        String? frontUrl;
        String? backUrl;
        String? selfieUrl;

        if (_frontImage != null) {
          final bytes = await _frontImage!.readAsBytes();
          frontUrl = await storageService.uploadKycDocument(
            uid: uid,
            docName: 'front',
            bytes: bytes,
          );
        }

        if (_backImage != null) {
          final bytes = await _backImage!.readAsBytes();
          backUrl = await storageService.uploadKycDocument(
            uid: uid,
            docName: 'back',
            bytes: bytes,
          );
        }

        if (_selfieImage != null) {
          final bytes = await _selfieImage!.readAsBytes();
          selfieUrl = await storageService.uploadKycDocument(
            uid: uid,
            docName: 'selfie',
            bytes: bytes,
          );
        }

        // Write KYC data to Firestore user document
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({
          'kycStatus': AppConstants.kycStatusPending,
          'kycData': {
            'fullName': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'email': _emailController.text.trim(),
            'dateOfBirth': _dateOfBirth?.toIso8601String(),
            'gender': _selectedGender,
            'docType': _selectedDocType,
            'docNumber': _docNumberController.text.trim(),
            'frontImageUrl': frontUrl,
            'backImageUrl': backUrl,
            'selfieImageUrl': selfieUrl,
            'submittedAt': FieldValue.serverTimestamp(),
          },
        });

        // Refresh auth profile
        await authProvider.refreshProfile();
      } else {
        // Local dev mode: simulate submission
        await Future.delayed(const Duration(seconds: 2));
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppTheme.successColor, size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              'KYC Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents have been submitted for verification. We\'ll notify you within 24-48 hours.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: Pending Review',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.go(AppRoutes.home);
              },
              child: const Text('Go to Home'),
            ),
          ),
        ],
      ),
    );
  }
}
