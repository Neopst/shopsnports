class CompanyDetails {
  final String companyName;
  final String companyAddress;
  final String city;
  final String state;
  final String country;
  final String zipCode;
  final String phoneNumber;
  final String email;
  final String website;
  final String taxId;
  final String registrationNumber;
  final String logoUrl;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String stripePublicKey;
  final String stripeSecretKey;
  final String paystackPublicKey;
  final String paystackSecretKey;
  final String flutterwavePublicKey;
  final String flutterwaveSecretKey;

  CompanyDetails({
    this.companyName = 'ShopsNSports',
    this.companyAddress = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.zipCode = '',
    this.phoneNumber = '',
    this.email = '',
    this.website = '',
    this.taxId = '',
    this.registrationNumber = '',
    this.logoUrl = '',
    this.bankName = '',
    this.accountNumber = '',
    this.accountName = '',
    this.stripePublicKey = '',
    this.stripeSecretKey = '',
    this.paystackPublicKey = '',
    this.paystackSecretKey = '',
    this.flutterwavePublicKey = '',
    this.flutterwaveSecretKey = '',
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      companyName: json['companyName'] ?? 'ShopsNSports',
      companyAddress: json['companyAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      zipCode: json['zipCode'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      taxId: json['taxId'] ?? '',
      registrationNumber: json['registrationNumber'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      accountName: json['accountName'] ?? '',
      stripePublicKey: json['stripePublicKey'] ?? '',
      stripeSecretKey: json['stripeSecretKey'] ?? '',
      paystackPublicKey: json['paystackPublicKey'] ?? '',
      paystackSecretKey: json['paystackSecretKey'] ?? '',
      flutterwavePublicKey: json['flutterwavePublicKey'] ?? '',
      flutterwaveSecretKey: json['flutterwaveSecretKey'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'companyAddress': companyAddress,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'phoneNumber': phoneNumber,
      'email': email,
      'website': website,
      'taxId': taxId,
      'registrationNumber': registrationNumber,
      'logoUrl': logoUrl,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'stripePublicKey': stripePublicKey,
      'stripeSecretKey': stripeSecretKey,
      'paystackPublicKey': paystackPublicKey,
      'paystackSecretKey': paystackSecretKey,
      'flutterwavePublicKey': flutterwavePublicKey,
      'flutterwaveSecretKey': flutterwaveSecretKey,
    };
  }

  CompanyDetails copyWith({
    String? companyName,
    String? companyAddress,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? phoneNumber,
    String? email,
    String? website,
    String? taxId,
    String? registrationNumber,
    String? logoUrl,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? stripePublicKey,
    String? stripeSecretKey,
    String? paystackPublicKey,
    String? paystackSecretKey,
    String? flutterwavePublicKey,
    String? flutterwaveSecretKey,
  }) {
    return CompanyDetails(
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      website: website ?? this.website,
      taxId: taxId ?? this.taxId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      logoUrl: logoUrl ?? this.logoUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountName: accountName ?? this.accountName,
      stripePublicKey: stripePublicKey ?? this.stripePublicKey,
      stripeSecretKey: stripeSecretKey ?? this.stripeSecretKey,
      paystackPublicKey: paystackPublicKey ?? this.paystackPublicKey,
      paystackSecretKey: paystackSecretKey ?? this.paystackSecretKey,
      flutterwavePublicKey: flutterwavePublicKey ?? this.flutterwavePublicKey,
      flutterwaveSecretKey: flutterwaveSecretKey ?? this.flutterwaveSecretKey,
    );
  }
}
