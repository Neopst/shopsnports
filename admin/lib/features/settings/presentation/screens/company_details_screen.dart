import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../../data/models/company_details.dart';
import '../providers/company_details_provider.dart';

class CompanyDetailsScreen extends ConsumerStatefulWidget {
  const CompanyDetailsScreen({super.key});

  @override
  ConsumerState<CompanyDetailsScreen> createState() =>
      _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends ConsumerState<CompanyDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _companyNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _countryController;
  late TextEditingController _zipCodeController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _taxIdController;
  late TextEditingController _registrationController;
  late TextEditingController _logoUrlController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _accountNameController;
  late TextEditingController _stripePublicKeyController;
  late TextEditingController _stripeSecretKeyController;
  late TextEditingController _paystackPublicKeyController;
  late TextEditingController _paystackSecretKeyController;
  late TextEditingController _flutterwavePublicKeyController;
  late TextEditingController _flutterwaveSecretKeyController;

  bool _isLoading = false;
  Uint8List? _logoBytes;
  String? _logoFileName;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _countryController = TextEditingController();
    _zipCodeController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _taxIdController = TextEditingController();
    _registrationController = TextEditingController();
    _logoUrlController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _accountNameController = TextEditingController();
    _stripePublicKeyController = TextEditingController();
    _stripeSecretKeyController = TextEditingController();
    _paystackPublicKeyController = TextEditingController();
    _paystackSecretKeyController = TextEditingController();
    _flutterwavePublicKeyController = TextEditingController();
    _flutterwaveSecretKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _taxIdController.dispose();
    _registrationController.dispose();
    _logoUrlController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _stripePublicKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _paystackPublicKeyController.dispose();
    _paystackSecretKeyController.dispose();
    _flutterwavePublicKeyController.dispose();
    _flutterwaveSecretKeyController.dispose();
    super.dispose();
  }

  void _loadCompanyDetails(CompanyDetails details) {
    _companyNameController.text = details.companyName;
    _addressController.text = details.companyAddress;
    _cityController.text = details.city;
    _stateController.text = details.state;
    _countryController.text = details.country;
    _zipCodeController.text = details.zipCode;
    _phoneController.text = details.phoneNumber;
    _emailController.text = details.email;
    _websiteController.text = details.website;
    _taxIdController.text = details.taxId;
    _registrationController.text = details.registrationNumber;
    _logoUrlController.text = details.logoUrl;
    _bankNameController.text = details.bankName;
    _accountNumberController.text = details.accountNumber;
    _accountNameController.text = details.accountName;
    _stripePublicKeyController.text = details.stripePublicKey;
    _stripeSecretKeyController.text = details.stripeSecretKey;
    _paystackPublicKeyController.text = details.paystackPublicKey;
    _paystackSecretKeyController.text = details.paystackSecretKey;
    _flutterwavePublicKeyController.text = details.flutterwavePublicKey;
    _flutterwaveSecretKeyController.text = details.flutterwaveSecretKey;
  }

  Future<void> _saveCompanyDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final details = CompanyDetails(
        companyName: _companyNameController.text.trim(),
        companyAddress: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        zipCode: _zipCodeController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        taxId: _taxIdController.text.trim(),
        registrationNumber: _registrationController.text.trim(),
        logoUrl: _logoUrlController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        accountName: _accountNameController.text.trim(),
        stripePublicKey: _stripePublicKeyController.text.trim(),
        stripeSecretKey: _stripeSecretKeyController.text.trim(),
        paystackPublicKey: _paystackPublicKeyController.text.trim(),
        paystackSecretKey: _paystackSecretKeyController.text.trim(),
        flutterwavePublicKey: _flutterwavePublicKeyController.text.trim(),
        flutterwaveSecretKey: _flutterwaveSecretKeyController.text.trim(),
      );

      await ref
          .read(companyDetailsProvider.notifier)
          .updateCompanyDetails(details);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company details saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving company details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyDetailsAsync = ref.watch(companyDetailsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: companyDetailsAsync.when(
        data: (details) {
          // Load data only once
          if (_companyNameController.text.isEmpty) {
            _loadCompanyDetails(details);
          }
          return _buildFormWithHeader();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(companyDetailsProvider.notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormWithHeader() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.business, size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Company Details',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Changes'),
                  onPressed: _saveCompanyDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A2A66),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Company Information'),
          _buildCompanyInfoSection(),
          const SizedBox(height: 32),
          _buildSectionHeader('Contact Information'),
          _buildContactSection(),
          const SizedBox(height: 32),
          _buildSectionHeader('Logo & Branding'),
          _buildBrandingSection(),
          const SizedBox(height: 32),
          _buildSectionHeader('Legal Information'),
          _buildLegalSection(),
          const SizedBox(height: 32),
          _buildSectionHeader('Banking Information'),
          _buildBankingSection(),
          const SizedBox(height: 32),
          _buildSectionHeader(
            'Payment Providers (Stripe, Paystack, Flutterwave)',
          ),
          _buildPaymentProvidersSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCompanyInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Company Name *',
                hintText: 'e.g., ShopsNSports',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Company name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g., 123 Main Street',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: const InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'e.g., Nigeria',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Zip/Postal Code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+234 XXX XXX XXXX',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'info@shopsnports.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                hintText: 'https://www.shopsnports.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _logoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Logo URL (Optional)',
                      hintText: 'https://example.com/logo.png',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Logo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_logoBytes != null || _logoUrlController.text.isNotEmpty)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Logo Preview',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_logoBytes != null ||
                              _logoUrlController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: _clearLogo,
                              tooltip: 'Remove logo',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _logoBytes != null
                            ? Column(
                                children: [
                                  Image.memory(
                                    _logoBytes!,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 8),
                                  Chip(
                                    avatar: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 18,
                                    ),
                                    label: Text(_logoFileName ?? 'Uploaded'),
                                    backgroundColor: Colors.green[50],
                                  ),
                                ],
                              )
                            : _logoUrlController.text.startsWith('http')
                            ? Image.network(
                                _logoUrlController.text,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(Icons.broken_image, size: 100),
                              )
                            : Image.asset(
                                _logoUrlController.text,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stack) =>
                                    const Icon(Icons.broken_image, size: 100),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upload a logo from your computer or provide a URL. This logo will appear on invoices and official documents.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _logoBytes = file.bytes;
          _logoFileName = file.name;
          // Clear URL when uploading file
          _logoUrlController.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logo "${file.name}" uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
      _logoUrlController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logo removed'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildLegalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'Tax ID / TIN',
                hintText: 'Tax Identification Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _registrationController,
              decoration: const InputDecoration(
                labelText: 'Business Registration Number',
                hintText: 'e.g., RC Number',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banking information for payment instructions on invoices',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name',
                hintText: 'e.g., First Bank of Nigeria',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProvidersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configure payment gateway API keys for Stripe, Paystack, and Flutterwave',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            // Stripe Section
            Text(
              'Stripe',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stripePublicKeyController,
              decoration: const InputDecoration(
                labelText: 'Stripe Public Key',
                hintText: 'pk_live_...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stripeSecretKeyController,
              decoration: const InputDecoration(
                labelText: 'Stripe Secret Key',
                hintText: 'sk_live_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Paystack Section
            Text(
              'Paystack',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paystackPublicKeyController,
              decoration: const InputDecoration(
                labelText: 'Paystack Public Key',
                hintText: 'pk_live_...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _paystackSecretKeyController,
              decoration: const InputDecoration(
                labelText: 'Paystack Secret Key',
                hintText: 'sk_live_...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            // Flutterwave Section
            Text(
              'Flutterwave',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _flutterwavePublicKeyController,
              decoration: const InputDecoration(
                labelText: 'Flutterwave Public Key',
                hintText: 'FLWPUBK-...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _flutterwaveSecretKeyController,
              decoration: const InputDecoration(
                labelText: 'Flutterwave Secret Key',
                hintText: 'FLWSECK-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _saveCompanyDetails,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: Text(_isLoading ? 'Saving...' : 'Save Company Details'),
        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
      ),
    );
  }
}
