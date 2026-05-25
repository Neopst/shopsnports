import 'package:flutter/material.dart';
import 'package:shopsnports/utils/countries.dart';

/// A reusable country/phone number input field with searchable dropdown
/// Shows country flag + name + code and phone number input
class CountryPhoneField extends StatefulWidget {
  final TextEditingController phoneController;
  final CountryData? initialCountry;
  final ValueChanged<CountryData> onCountryChanged;
  final String? Function(String?)? validator;
  final String label;
  final String hintText;
  final bool readOnly;

  const CountryPhoneField({
    super.key,
    required this.phoneController,
    this.initialCountry,
    required this.onCountryChanged,
    this.validator,
    this.label = 'Phone Number',
    this.hintText = 'Enter phone number',
    this.readOnly = false,
  });

  @override
  State<CountryPhoneField> createState() => _CountryPhoneFieldState();
}

class _CountryPhoneFieldState extends State<CountryPhoneField> {
  late CountryData selectedCountry;

  @override
  void initState() {
    super.initState();
    selectedCountry = widget.initialCountry ?? getDefaultCountry();
  }

  void _showCountryPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CountryPickerDialog(
          selectedCountry: selectedCountry,
          onCountrySelected: (country) {
            setState(() {
              selectedCountry = country;
              widget.onCountryChanged(country);
            });
            Navigator.pop(context);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Country selector button
            Expanded(
              flex: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.readOnly ? null : _showCountryPicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedCountry.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCountry.code,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                selectedCountry.isoCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.readOnly)
                          Icon(
                            Icons.expand_more,
                            color: Colors.grey[600],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Phone number input
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: widget.phoneController,
                readOnly: widget.readOnly,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
                validator: widget.validator,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dialog for country selection with search functionality
class _CountryPickerDialog extends StatefulWidget {
  final CountryData selectedCountry;
  final ValueChanged<CountryData> onCountrySelected;

  const _CountryPickerDialog({
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  late TextEditingController searchController;
  late List<CountryData> filteredCountries;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    filteredCountries = allCountries;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      filteredCountries = searchCountries(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Country',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: searchController,
                  onChanged: _filterCountries,
                  decoration: InputDecoration(
                    hintText: 'Search country... (e.g., "nig", "uga")',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _filterCountries('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Countries list
          Expanded(
            child: filteredCountries.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.language,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No countries found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try searching with different keywords',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected =
                          country.isoCode == widget.selectedCountry.isoCode;

                      return Material(
                        child: InkWell(
                          onTap: () => widget.onCountrySelected(country),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : null,
                            ),
                            child: ListTile(
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 28),
                              ),
                              title: Text(country.name),
                              subtitle: Text(country.code),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
