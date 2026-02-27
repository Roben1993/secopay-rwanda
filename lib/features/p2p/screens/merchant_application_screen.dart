/// Merchant Application Screen
/// KYC-style form for users to apply to become verified P2P merchants
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/theme.dart';
import '../../../services/wallet_service.dart';
import '../models/merchant_application_model.dart';
import '../services/p2p_service.dart';

class MerchantApplicationScreen extends StatefulWidget {
  const MerchantApplicationScreen({super.key});

  @override
  State<MerchantApplicationScreen> createState() =>
      _MerchantApplicationScreenState();
}

class _MerchantApplicationScreenState
    extends State<MerchantApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final P2PService _p2pService = P2PService();
  final WalletService _walletService = WalletService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _businessNameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedIdType = 'national_id';
  String? _idFrontPath;
  String? _idBackPath;
  String? _selfiePath;

  String? _walletAddress;
  MerchantApplicationModel? _existingApplication;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _idNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final address = await _walletService.getWalletAddress();
      MerchantApplicationModel? existing;
      if (address != null) {
        existing = await _p2pService.getMerchantApplication(address);
      }
      setState(() {
        _walletAddress = address;
        _existingApplication = existing;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading merchant data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Become a Merchant'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _existingApplication != null
              ? _buildExistingStatus()
              : _buildApplicationForm(),
    );
  }

  // ============================================================================
  // EXISTING APPLICATION STATUS
  // ============================================================================

  Widget _buildExistingStatus() {
    final app = _existingApplication!;
    final statusColor = app.status == MerchantStatus.approved
        ? Colors.green
        : app.status == MerchantStatus.rejected
            ? Colors.red
            : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  app.status == MerchantStatus.approved
                      ? Icons.verified
                      : app.status == MerchantStatus.rejected
                          ? Icons.cancel
                          : Icons.hourglass_top,
                  size: 64,
                  color: statusColor,
                ),
                const SizedBox(height: 16),
                Text(
                  app.statusLabel,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  app.status == MerchantStatus.pending
                      ? 'Your application is being reviewed. This usually takes 1-3 business days.'
                      : app.status == MerchantStatus.approved
                          ? 'You are now a verified merchant! You can post sell ads on the P2P marketplace.'
                          : 'Your application was rejected. ${app.rejectionReason ?? ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Application Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E))),
                const Divider(height: 20),
                _buildDetailRow('Application ID', app.id),
                _buildDetailRow('Business Name', app.businessName),
                _buildDetailRow('Full Name', app.fullName),
                _buildDetailRow('Phone', app.phoneNumber),
                _buildDetailRow('Email', app.email),
                _buildDetailRow('ID Type', app.idTypeLabel),
                _buildDetailRow('Submitted',
                    '${app.createdAt.day}/${app.createdAt.month}/${app.createdAt.year}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (app.status == MerchantStatus.approved)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Go to P2P Market'),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // APPLICATION FORM
  // ============================================================================

  Widget _buildApplicationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Step indicator
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _currentStep == 0
                  ? _buildPersonalInfoStep()
                  : _currentStep == 1
                      ? _buildIdVerificationStep()
                      : _buildReviewStep(),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildStepDot(0, 'Personal Info'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 1
                  ? AppTheme.primaryColor
                  : Colors.grey[300],
            ),
          ),
          _buildStepDot(1, 'ID Verification'),
          Expanded(
            child: Container(
              height: 2,
              color: _currentStep >= 2
                  ? AppTheme.primaryColor
                  : Colors.grey[300],
            ),
          ),
          _buildStepDot(2, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppTheme.primaryColor : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Step 1: Personal & Business Info
  Widget _buildPersonalInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Information',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Business Name',
          controller: _businessNameController,
          hint: 'Your business or trade name',
          icon: Icons.store,
          validator: (v) =>
              v == null || v.isEmpty ? 'Business name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Full Legal Name',
          controller: _fullNameController,
          hint: 'As shown on your ID',
          icon: Icons.person,
          validator: (v) =>
              v == null || v.isEmpty ? 'Full name is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Phone Number',
          controller: _phoneController,
          hint: '+250 7XX XXX XXX',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (v) =>
              v == null || v.isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Email Address',
          controller: _emailController,
          hint: 'your@email.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!AppConstants.isValidEmail(v)) return 'Invalid email';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Business Address',
          controller: _addressController,
          hint: 'City, District, Sector',
          icon: Icons.location_on,
          validator: (v) =>
              v == null || v.isEmpty ? 'Address is required' : null,
        ),
      ],
    );
  }

  // Step 2: ID Verification
  Widget _buildIdVerificationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ID Verification',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(
          'Upload clear photos of your government-issued ID',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // ID Type selection
        const Text('ID Type',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedIdType,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 'national_id', child: Text('National ID')),
                DropdownMenuItem(
                    value: 'passport', child: Text('Passport')),
                DropdownMenuItem(
                    value: 'driving_license',
                    child: Text('Driving License')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedIdType = v);
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // ID Number
        _buildTextField(
          label: 'ID Number',
          controller: _idNumberController,
          hint: 'Enter your ID number',
          icon: Icons.badge,
          validator: (v) =>
              v == null || v.isEmpty ? 'ID number is required' : null,
        ),
        const SizedBox(height: 20),

        // ID Front
        _buildImageUpload(
          label: 'ID Front Side',
          path: _idFrontPath,
          onTap: () async {
            final path = await _pickImage();
            if (path != null) setState(() => _idFrontPath = path);
          },
        ),
        const SizedBox(height: 16),

        // ID Back
        _buildImageUpload(
          label: 'ID Back Side',
          path: _idBackPath,
          onTap: () async {
            final path = await _pickImage();
            if (path != null) setState(() => _idBackPath = path);
          },
        ),
        const SizedBox(height: 16),

        // Selfie
        _buildImageUpload(
          label: 'Selfie with ID',
          subtitle: 'Hold your ID next to your face',
          path: _selfiePath,
          onTap: () async {
            final path = await _pickImage();
            if (path != null) setState(() => _selfiePath = path);
          },
        ),
      ],
    );
  }

  // Step 3: Review
  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Application',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(
          'Please review your information before submitting',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),

        // Personal info summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('Personal Information',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
              const Divider(height: 20),
              _buildDetailRow(
                  'Business Name', _businessNameController.text),
              _buildDetailRow('Full Name', _fullNameController.text),
              _buildDetailRow('Phone', _phoneController.text),
              _buildDetailRow('Email', _emailController.text),
              _buildDetailRow('Address', _addressController.text),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ID summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.badge,
                      size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Text('ID Verification',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                ],
              ),
              const Divider(height: 20),
              _buildDetailRow('ID Type', _idTypeLabel(_selectedIdType)),
              _buildDetailRow('ID Number', _idNumberController.text),
              _buildDetailRow(
                  'ID Front', _idFrontPath != null ? 'Uploaded' : 'Missing'),
              _buildDetailRow(
                  'ID Back', _idBackPath != null ? 'Uploaded' : 'Missing'),
              _buildDetailRow(
                  'Selfie', _selfiePath != null ? 'Uploaded' : 'Missing'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms notice
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline,
                  color: Colors.blue[700], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By submitting this application, you agree to our merchant terms and conditions. Your information will be verified within 1-3 business days.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.blue[700]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================================
  // BOTTOM BUTTONS
  // ============================================================================

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () =>
                    setState(() => _currentStep = _currentStep - 1),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 2
                    ? Colors.green
                    : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _currentStep == 0
                          ? 'Next'
                          : _currentStep == 1
                              ? 'Review'
                              : 'Submit Application',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_idNumberController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your ID number')),
        );
        return;
      }
      if (_idFrontPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please upload the front of your ID')),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else {
      // Submit
      setState(() => _isSubmitting = true);
      try {
        final app = await _p2pService.submitMerchantApplication(
          walletAddress: _walletAddress!,
          businessName: _businessNameController.text,
          fullName: _fullNameController.text,
          phoneNumber: _phoneController.text,
          email: _emailController.text,
          idType: _selectedIdType,
          idNumber: _idNumberController.text,
          idFrontImagePath: _idFrontPath,
          idBackImagePath: _idBackPath,
          selfieImagePath: _selfiePath,
          businessAddress: _addressController.text,
        );

        setState(() {
          _existingApplication = app;
          _isSubmitting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildImageUpload({
    required String label,
    String? subtitle,
    required String? path,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: path != null
                ? Colors.green.withValues(alpha: 0.5)
                : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (path != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              )
            else
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_a_photo,
                    color: Colors.grey[400], size: 28),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500])),
                  Text(
                    path != null ? 'Tap to change' : 'Tap to upload',
                    style: TextStyle(
                      fontSize: 12,
                      color: path != null
                          ? Colors.green
                          : AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              path != null ? Icons.check_circle : Icons.upload,
              color: path != null ? Colors.green : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: Colors.green),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: AppConstants.imageUploadQuality,
        maxWidth: AppConstants.maxImageWidth.toDouble(),
      );
      return picked?.path;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
      return null;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Flexible(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  String _idTypeLabel(String type) {
    switch (type) {
      case 'national_id':
        return 'National ID';
      case 'passport':
        return 'Passport';
      case 'driving_license':
        return 'Driving License';
      default:
        return type;
    }
  }
}
