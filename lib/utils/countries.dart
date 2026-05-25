/// Complete list of world countries with flags and country codes
/// Used for country/phone number selection across the app
class CountryData {
  final String name;
  final String flag; // Unicode flag emoji
  final String code; // International calling code (e.g., +234)
  final String isoCode; // 2-letter ISO code (e.g., NG)

  CountryData({
    required this.name,
    required this.flag,
    required this.code,
    required this.isoCode,
  });

  String get displayName => '$flag $name ($code)';

  @override
  String toString() => displayName;
}

/// All world countries sorted alphabetically
final List<CountryData> allCountries = [
  CountryData(name: 'Afghanistan', flag: '🇦🇫', code: '+93', isoCode: 'AF'),
  CountryData(name: 'Albania', flag: '🇦🇱', code: '+355', isoCode: 'AL'),
  CountryData(name: 'Algeria', flag: '🇩🇿', code: '+213', isoCode: 'DZ'),
  CountryData(name: 'Andorra', flag: '🇦🇩', code: '+376', isoCode: 'AD'),
  CountryData(name: 'Angola', flag: '🇦🇴', code: '+244', isoCode: 'AO'),
  CountryData(
      name: 'Antigua and Barbuda', flag: '🇦🇬', code: '+1-268', isoCode: 'AG'),
  CountryData(name: 'Argentina', flag: '🇦🇷', code: '+54', isoCode: 'AR'),
  CountryData(name: 'Armenia', flag: '🇦🇲', code: '+374', isoCode: 'AM'),
  CountryData(name: 'Australia', flag: '🇦🇺', code: '+61', isoCode: 'AU'),
  CountryData(name: 'Austria', flag: '🇦🇹', code: '+43', isoCode: 'AT'),
  CountryData(name: 'Azerbaijan', flag: '🇦🇿', code: '+994', isoCode: 'AZ'),
  CountryData(name: 'Bahamas', flag: '🇧🇸', code: '+1-242', isoCode: 'BS'),
  CountryData(name: 'Bahrain', flag: '🇧🇭', code: '+973', isoCode: 'BH'),
  CountryData(name: 'Bangladesh', flag: '🇧🇩', code: '+880', isoCode: 'BD'),
  CountryData(name: 'Barbados', flag: '🇧🇧', code: '+1-246', isoCode: 'BB'),
  CountryData(name: 'Belarus', flag: '🇧🇾', code: '+375', isoCode: 'BY'),
  CountryData(name: 'Belgium', flag: '🇧🇪', code: '+32', isoCode: 'BE'),
  CountryData(name: 'Belize', flag: '🇧🇿', code: '+501', isoCode: 'BZ'),
  CountryData(name: 'Benin', flag: '🇧🇯', code: '+229', isoCode: 'BJ'),
  CountryData(name: 'Bhutan', flag: '🇧🇹', code: '+975', isoCode: 'BT'),
  CountryData(name: 'Bolivia', flag: '🇧🇴', code: '+591', isoCode: 'BO'),
  CountryData(
      name: 'Bosnia and Herzegovina',
      flag: '🇧🇦',
      code: '+387',
      isoCode: 'BA'),
  CountryData(name: 'Botswana', flag: '🇧🇼', code: '+267', isoCode: 'BW'),
  CountryData(name: 'Brazil', flag: '🇧🇷', code: '+55', isoCode: 'BR'),
  CountryData(name: 'Brunei', flag: '🇧🇳', code: '+673', isoCode: 'BN'),
  CountryData(name: 'Bulgaria', flag: '🇧🇬', code: '+359', isoCode: 'BG'),
  CountryData(name: 'Burkina Faso', flag: '🇧🇫', code: '+226', isoCode: 'BF'),
  CountryData(name: 'Burundi', flag: '🇧🇮', code: '+257', isoCode: 'BI'),
  CountryData(name: 'Cambodia', flag: '🇰🇭', code: '+855', isoCode: 'KH'),
  CountryData(name: 'Cameroon', flag: '🇨🇲', code: '+237', isoCode: 'CM'),
  CountryData(name: 'Canada', flag: '🇨🇦', code: '+1', isoCode: 'CA'),
  CountryData(name: 'Cape Verde', flag: '🇨🇻', code: '+238', isoCode: 'CV'),
  CountryData(
      name: 'Central African Republic',
      flag: '🇨🇫',
      code: '+236',
      isoCode: 'CF'),
  CountryData(name: 'Chad', flag: '🇹🇩', code: '+235', isoCode: 'TD'),
  CountryData(name: 'Chile', flag: '🇨🇱', code: '+56', isoCode: 'CL'),
  CountryData(name: 'China', flag: '🇨🇳', code: '+86', isoCode: 'CN'),
  CountryData(name: 'Colombia', flag: '🇨🇴', code: '+57', isoCode: 'CO'),
  CountryData(name: 'Comoros', flag: '🇰🇲', code: '+269', isoCode: 'KM'),
  CountryData(name: 'Congo', flag: '🇨🇬', code: '+242', isoCode: 'CG'),
  CountryData(name: 'Costa Rica', flag: '🇨🇷', code: '+506', isoCode: 'CR'),
  CountryData(name: 'Croatia', flag: '🇭🇷', code: '+385', isoCode: 'HR'),
  CountryData(name: 'Cuba', flag: '🇨🇺', code: '+53', isoCode: 'CU'),
  CountryData(name: 'Cyprus', flag: '🇨🇾', code: '+357', isoCode: 'CY'),
  CountryData(
      name: 'Czech Republic', flag: '🇨🇿', code: '+420', isoCode: 'CZ'),
  CountryData(name: 'Denmark', flag: '🇩🇰', code: '+45', isoCode: 'DK'),
  CountryData(name: 'Djibouti', flag: '🇩🇯', code: '+253', isoCode: 'DJ'),
  CountryData(name: 'Dominica', flag: '🇩🇲', code: '+1-767', isoCode: 'DM'),
  CountryData(
      name: 'Dominican Republic', flag: '🇩🇴', code: '+1-809', isoCode: 'DO'),
  CountryData(name: 'Ecuador', flag: '🇪🇨', code: '+593', isoCode: 'EC'),
  CountryData(name: 'Egypt', flag: '🇪🇬', code: '+20', isoCode: 'EG'),
  CountryData(name: 'El Salvador', flag: '🇸🇻', code: '+503', isoCode: 'SV'),
  CountryData(
      name: 'Equatorial Guinea', flag: '🇬🇶', code: '+240', isoCode: 'GQ'),
  CountryData(name: 'Eritrea', flag: '🇪🇷', code: '+291', isoCode: 'ER'),
  CountryData(name: 'Estonia', flag: '🇪🇪', code: '+372', isoCode: 'EE'),
  CountryData(name: 'Ethiopia', flag: '🇪🇹', code: '+251', isoCode: 'ET'),
  CountryData(name: 'Fiji', flag: '🇫🇯', code: '+679', isoCode: 'FJ'),
  CountryData(name: 'Finland', flag: '🇫🇮', code: '+358', isoCode: 'FI'),
  CountryData(name: 'France', flag: '🇫🇷', code: '+33', isoCode: 'FR'),
  CountryData(name: 'Gabon', flag: '🇬🇦', code: '+241', isoCode: 'GA'),
  CountryData(name: 'Gambia', flag: '🇬🇲', code: '+220', isoCode: 'GM'),
  CountryData(name: 'Georgia', flag: '🇬🇪', code: '+995', isoCode: 'GE'),
  CountryData(name: 'Germany', flag: '🇩🇪', code: '+49', isoCode: 'DE'),
  CountryData(name: 'Ghana', flag: '🇬🇭', code: '+233', isoCode: 'GH'),
  CountryData(name: 'Greece', flag: '🇬🇷', code: '+30', isoCode: 'GR'),
  CountryData(name: 'Grenada', flag: '🇬🇩', code: '+1-473', isoCode: 'GD'),
  CountryData(name: 'Guatemala', flag: '🇬🇹', code: '+502', isoCode: 'GT'),
  CountryData(name: 'Guinea', flag: '🇬🇳', code: '+224', isoCode: 'GN'),
  CountryData(name: 'Guinea-Bissau', flag: '🇬🇼', code: '+245', isoCode: 'GW'),
  CountryData(name: 'Guyana', flag: '🇬🇾', code: '+592', isoCode: 'GY'),
  CountryData(name: 'Haiti', flag: '🇭🇹', code: '+509', isoCode: 'HT'),
  CountryData(name: 'Honduras', flag: '🇭🇳', code: '+504', isoCode: 'HN'),
  CountryData(name: 'Hong Kong', flag: '🇭🇰', code: '+852', isoCode: 'HK'),
  CountryData(name: 'Hungary', flag: '🇭🇺', code: '+36', isoCode: 'HU'),
  CountryData(name: 'Iceland', flag: '🇮🇸', code: '+354', isoCode: 'IS'),
  CountryData(name: 'India', flag: '🇮🇳', code: '+91', isoCode: 'IN'),
  CountryData(name: 'Indonesia', flag: '🇮🇩', code: '+62', isoCode: 'ID'),
  CountryData(name: 'Iran', flag: '🇮🇷', code: '+98', isoCode: 'IR'),
  CountryData(name: 'Iraq', flag: '🇮🇶', code: '+964', isoCode: 'IQ'),
  CountryData(name: 'Ireland', flag: '🇮🇪', code: '+353', isoCode: 'IE'),
  CountryData(name: 'Israel', flag: '🇮🇱', code: '+972', isoCode: 'IL'),
  CountryData(name: 'Italy', flag: '🇮🇹', code: '+39', isoCode: 'IT'),
  CountryData(name: 'Ivory Coast', flag: '🇨🇮', code: '+225', isoCode: 'CI'),
  CountryData(name: 'Jamaica', flag: '🇯🇲', code: '+1-876', isoCode: 'JM'),
  CountryData(name: 'Japan', flag: '🇯🇵', code: '+81', isoCode: 'JP'),
  CountryData(name: 'Jordan', flag: '🇯🇴', code: '+962', isoCode: 'JO'),
  CountryData(name: 'Kazakhstan', flag: '🇰🇿', code: '+7', isoCode: 'KZ'),
  CountryData(name: 'Kenya', flag: '🇰🇪', code: '+254', isoCode: 'KE'),
  CountryData(name: 'Kiribati', flag: '🇰🇮', code: '+686', isoCode: 'KI'),
  CountryData(name: 'Kuwait', flag: '🇰🇼', code: '+965', isoCode: 'KW'),
  CountryData(name: 'Kyrgyzstan', flag: '🇰🇬', code: '+996', isoCode: 'KG'),
  CountryData(name: 'Laos', flag: '🇱🇦', code: '+856', isoCode: 'LA'),
  CountryData(name: 'Latvia', flag: '🇱🇻', code: '+371', isoCode: 'LV'),
  CountryData(name: 'Lebanon', flag: '🇱🇧', code: '+961', isoCode: 'LB'),
  CountryData(name: 'Lesotho', flag: '🇱🇸', code: '+266', isoCode: 'LS'),
  CountryData(name: 'Liberia', flag: '🇱🇷', code: '+231', isoCode: 'LR'),
  CountryData(name: 'Libya', flag: '🇱🇾', code: '+218', isoCode: 'LY'),
  CountryData(name: 'Liechtenstein', flag: '🇱🇮', code: '+423', isoCode: 'LI'),
  CountryData(name: 'Lithuania', flag: '🇱🇹', code: '+370', isoCode: 'LT'),
  CountryData(name: 'Luxembourg', flag: '🇱🇺', code: '+352', isoCode: 'LU'),
  CountryData(name: 'Macao', flag: '🇲🇴', code: '+853', isoCode: 'MO'),
  CountryData(name: 'Madagascar', flag: '🇲🇬', code: '+261', isoCode: 'MG'),
  CountryData(name: 'Malawi', flag: '🇲🇼', code: '+265', isoCode: 'MW'),
  CountryData(name: 'Malaysia', flag: '🇲🇾', code: '+60', isoCode: 'MY'),
  CountryData(name: 'Maldives', flag: '🇲🇻', code: '+960', isoCode: 'MV'),
  CountryData(name: 'Mali', flag: '🇲🇱', code: '+223', isoCode: 'ML'),
  CountryData(name: 'Malta', flag: '🇲🇹', code: '+356', isoCode: 'MT'),
  CountryData(
      name: 'Marshall Islands', flag: '🇲🇭', code: '+692', isoCode: 'MH'),
  CountryData(name: 'Mauritania', flag: '🇲🇷', code: '+222', isoCode: 'MR'),
  CountryData(name: 'Mauritius', flag: '🇲🇺', code: '+230', isoCode: 'MU'),
  CountryData(name: 'Mexico', flag: '🇲🇽', code: '+52', isoCode: 'MX'),
  CountryData(name: 'Micronesia', flag: '🇫🇲', code: '+691', isoCode: 'FM'),
  CountryData(name: 'Moldova', flag: '🇲🇩', code: '+373', isoCode: 'MD'),
  CountryData(name: 'Monaco', flag: '🇲🇨', code: '+377', isoCode: 'MC'),
  CountryData(name: 'Mongolia', flag: '🇲🇳', code: '+976', isoCode: 'MN'),
  CountryData(name: 'Montenegro', flag: '🇲🇪', code: '+382', isoCode: 'ME'),
  CountryData(name: 'Morocco', flag: '🇲🇦', code: '+212', isoCode: 'MA'),
  CountryData(name: 'Mozambique', flag: '🇲🇿', code: '+258', isoCode: 'MZ'),
  CountryData(name: 'Myanmar', flag: '🇲🇲', code: '+95', isoCode: 'MM'),
  CountryData(name: 'Namibia', flag: '🇳🇦', code: '+264', isoCode: 'NA'),
  CountryData(name: 'Nauru', flag: '🇳🇷', code: '+674', isoCode: 'NR'),
  CountryData(name: 'Nepal', flag: '🇳🇵', code: '+977', isoCode: 'NP'),
  CountryData(name: 'Netherlands', flag: '🇳🇱', code: '+31', isoCode: 'NL'),
  CountryData(name: 'New Zealand', flag: '🇳🇿', code: '+64', isoCode: 'NZ'),
  CountryData(name: 'Nicaragua', flag: '🇳🇮', code: '+505', isoCode: 'NI'),
  CountryData(name: 'Niger', flag: '🇳🇪', code: '+227', isoCode: 'NE'),
  CountryData(name: 'Nigeria', flag: '🇳🇬', code: '+234', isoCode: 'NG'),
  CountryData(name: 'North Korea', flag: '🇰🇵', code: '+850', isoCode: 'KP'),
  CountryData(
      name: 'North Macedonia', flag: '🇲🇰', code: '+389', isoCode: 'MK'),
  CountryData(name: 'Norway', flag: '🇳🇴', code: '+47', isoCode: 'NO'),
  CountryData(name: 'Oman', flag: '🇴🇲', code: '+968', isoCode: 'OM'),
  CountryData(name: 'Pakistan', flag: '🇵🇰', code: '+92', isoCode: 'PK'),
  CountryData(name: 'Palau', flag: '🇵🇼', code: '+680', isoCode: 'PW'),
  CountryData(name: 'Palestine', flag: '🇵🇸', code: '+970', isoCode: 'PS'),
  CountryData(name: 'Panama', flag: '🇵🇦', code: '+507', isoCode: 'PA'),
  CountryData(
      name: 'Papua New Guinea', flag: '🇵🇬', code: '+675', isoCode: 'PG'),
  CountryData(name: 'Paraguay', flag: '🇵🇾', code: '+595', isoCode: 'PY'),
  CountryData(name: 'Peru', flag: '🇵🇪', code: '+51', isoCode: 'PE'),
  CountryData(name: 'Philippines', flag: '🇵🇭', code: '+63', isoCode: 'PH'),
  CountryData(name: 'Poland', flag: '🇵🇱', code: '+48', isoCode: 'PL'),
  CountryData(name: 'Portugal', flag: '🇵🇹', code: '+351', isoCode: 'PT'),
  CountryData(name: 'Qatar', flag: '🇶🇦', code: '+974', isoCode: 'QA'),
  CountryData(name: 'Romania', flag: '🇷🇴', code: '+40', isoCode: 'RO'),
  CountryData(name: 'Russia', flag: '🇷🇺', code: '+7', isoCode: 'RU'),
  CountryData(name: 'Rwanda', flag: '🇷🇼', code: '+250', isoCode: 'RW'),
  CountryData(
      name: 'Saint Kitts and Nevis',
      flag: '🇰🇳',
      code: '+1-869',
      isoCode: 'KN'),
  CountryData(name: 'Saint Lucia', flag: '🇱🇨', code: '+1-758', isoCode: 'LC'),
  CountryData(
      name: 'Saint Vincent and the Grenadines',
      flag: '🇻🇨',
      code: '+1-784',
      isoCode: 'VC'),
  CountryData(name: 'Samoa', flag: '🇼🇸', code: '+685', isoCode: 'WS'),
  CountryData(name: 'San Marino', flag: '🇸🇲', code: '+378', isoCode: 'SM'),
  CountryData(
      name: 'Sao Tome and Principe', flag: '🇸🇹', code: '+239', isoCode: 'ST'),
  CountryData(name: 'Saudi Arabia', flag: '🇸🇦', code: '+966', isoCode: 'SA'),
  CountryData(name: 'Senegal', flag: '🇸🇳', code: '+221', isoCode: 'SN'),
  CountryData(name: 'Serbia', flag: '🇷🇸', code: '+381', isoCode: 'RS'),
  CountryData(name: 'Seychelles', flag: '🇸🇨', code: '+248', isoCode: 'SC'),
  CountryData(name: 'Sierra Leone', flag: '🇸🇱', code: '+232', isoCode: 'SL'),
  CountryData(name: 'Singapore', flag: '🇸🇬', code: '+65', isoCode: 'SG'),
  CountryData(name: 'Slovakia', flag: '🇸🇰', code: '+421', isoCode: 'SK'),
  CountryData(name: 'Slovenia', flag: '🇸🇮', code: '+386', isoCode: 'SI'),
  CountryData(
      name: 'Solomon Islands', flag: '🇸🇧', code: '+677', isoCode: 'SB'),
  CountryData(name: 'Somalia', flag: '🇸🇴', code: '+252', isoCode: 'SO'),
  CountryData(name: 'South Africa', flag: '🇿🇦', code: '+27', isoCode: 'ZA'),
  CountryData(name: 'South Korea', flag: '🇰🇷', code: '+82', isoCode: 'KR'),
  CountryData(name: 'South Sudan', flag: '🇸🇸', code: '+211', isoCode: 'SS'),
  CountryData(name: 'Spain', flag: '🇪🇸', code: '+34', isoCode: 'ES'),
  CountryData(name: 'Sri Lanka', flag: '🇱🇰', code: '+94', isoCode: 'LK'),
  CountryData(name: 'Sudan', flag: '🇸🇩', code: '+249', isoCode: 'SD'),
  CountryData(name: 'Suriname', flag: '🇸🇷', code: '+597', isoCode: 'SR'),
  CountryData(name: 'Sweden', flag: '🇸🇪', code: '+46', isoCode: 'SE'),
  CountryData(name: 'Switzerland', flag: '🇨🇭', code: '+41', isoCode: 'CH'),
  CountryData(name: 'Syria', flag: '🇸🇾', code: '+963', isoCode: 'SY'),
  CountryData(name: 'Taiwan', flag: '🇹🇼', code: '+886', isoCode: 'TW'),
  CountryData(name: 'Tajikistan', flag: '🇹🇯', code: '+992', isoCode: 'TJ'),
  CountryData(name: 'Tanzania', flag: '🇹🇿', code: '+255', isoCode: 'TZ'),
  CountryData(name: 'Thailand', flag: '🇹🇭', code: '+66', isoCode: 'TH'),
  CountryData(name: 'Timor-Leste', flag: '🇹🇱', code: '+670', isoCode: 'TL'),
  CountryData(name: 'Togo', flag: '🇹🇬', code: '+228', isoCode: 'TG'),
  CountryData(name: 'Tonga', flag: '🇹🇴', code: '+676', isoCode: 'TO'),
  CountryData(
      name: 'Trinidad and Tobago', flag: '🇹🇹', code: '+1-868', isoCode: 'TT'),
  CountryData(name: 'Tunisia', flag: '🇹🇳', code: '+216', isoCode: 'TN'),
  CountryData(name: 'Turkey', flag: '🇹🇷', code: '+90', isoCode: 'TR'),
  CountryData(name: 'Turkmenistan', flag: '🇹🇲', code: '+993', isoCode: 'TM'),
  CountryData(name: 'Tuvalu', flag: '🇹🇻', code: '+688', isoCode: 'TV'),
  CountryData(name: 'Uganda', flag: '🇺🇬', code: '+256', isoCode: 'UG'),
  CountryData(name: 'Ukraine', flag: '🇺🇦', code: '+380', isoCode: 'UA'),
  CountryData(
      name: 'United Arab Emirates', flag: '🇦🇪', code: '+971', isoCode: 'AE'),
  CountryData(name: 'United Kingdom', flag: '🇬🇧', code: '+44', isoCode: 'GB'),
  CountryData(name: 'United States', flag: '🇺🇸', code: '+1', isoCode: 'US'),
  CountryData(name: 'Uruguay', flag: '🇺🇾', code: '+598', isoCode: 'UY'),
  CountryData(name: 'Uzbekistan', flag: '🇺🇿', code: '+998', isoCode: 'UZ'),
  CountryData(name: 'Vanuatu', flag: '🇻🇺', code: '+678', isoCode: 'VU'),
  CountryData(name: 'Vatican City', flag: '🇻🇦', code: '+39', isoCode: 'VA'),
  CountryData(name: 'Venezuela', flag: '🇻🇪', code: '+58', isoCode: 'VE'),
  CountryData(name: 'Vietnam', flag: '🇻🇳', code: '+84', isoCode: 'VN'),
  CountryData(name: 'Yemen', flag: '🇾🇪', code: '+967', isoCode: 'YE'),
  CountryData(name: 'Zambia', flag: '🇿🇲', code: '+260', isoCode: 'ZM'),
  CountryData(name: 'Zimbabwe', flag: '🇿🇼', code: '+263', isoCode: 'ZW'),
];

/// Get default country (Nigeria)
CountryData getDefaultCountry() {
  return allCountries.firstWhere(
    (c) => c.isoCode == 'NG',
    orElse: () => allCountries.first,
  );
}

/// Search countries by name or code
List<CountryData> searchCountries(String query) {
  if (query.isEmpty) return allCountries;

  final lowerQuery = query.toLowerCase();
  return allCountries.where((country) {
    return country.name.toLowerCase().contains(lowerQuery) ||
        country.code.contains(query) ||
        country.isoCode.toLowerCase().contains(lowerQuery);
  }).toList();
}
