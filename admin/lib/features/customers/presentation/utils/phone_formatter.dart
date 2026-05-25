/// Helper to extract country code from phone number
/// Format: +1234567890 -> +1 or +234567890 -> +234
String extractCountryCode(String? phone) {
  if (phone == null || phone.isEmpty || !phone.startsWith('+')) return '';

  // Try to match country codes (1-3 digits)
  final match = RegExp(r'^\+(\d{1,3})').firstMatch(phone);
  if (match != null && match.group(1) != null) {
    return '+${match.group(1)!}';
  }
  return '';
}

/// Map country code to country name and flag
Map<String, String> countryCodeMap = {
  '+1': '🇺🇸 US',
  '+44': '🇬🇧 UK',
  '+91': '🇮🇳 IN',
  '+234': '🇳🇬 NG',
  '+255': '🇹🇿 TZ',
  '+256': '🇺🇬 UG',
  '+254': '🇰🇪 KE',
  '+27': '🇿🇦 ZA',
  '+233': '🇬🇭 GH',
  '+212': '🇲🇦 MA',
  '+20': '🇪🇬 EG',
  '+1': '🇺🇸 US',
  '+33': '🇫🇷 FR',
  '+49': '🇩🇪 DE',
  '+39': '🇮🇹 IT',
  '+34': '🇪🇸 ES',
  '+358': '🇫🇮 FI',
  '+46': '🇸🇪 SE',
  '+45': '🇩🇰 DK',
  '+47': '🇳🇴 NO',
  '+31': '🇳🇱 NL',
  '+43': '🇦🇹 AT',
  '+41': '🇨🇭 CH',
  '+48': '🇵🇱 PL',
  '+30': '🇬🇷 GR',
  '+355': '🇦🇱 AL',
  '+381': '🇷🇸 RS',
  '+385': '🇭🇷 HR',
  '+386': '🇸🇮 SI',
  '+387': '🇧🇦 BA',
  '+61': '🇦🇺 AU',
  '+64': '🇳🇿 NZ',
  '+65': '🇸🇬 SG',
  '+60': '🇲🇾 MY',
  '+66': '🇹🇭 TH',
  '+84': '🇻🇳 VN',
  '+81': '🇯🇵 JP',
  '+82': '🇰🇷 KR',
  '+86': '🇨🇳 CN',
  '+55': '🇧🇷 BR',
  '+56': '🇨🇱 CL',
  '+57': '🇨🇴 CO',
  '+51': '🇵🇪 PE',
  '+52': '🇲🇽 MX',
};

/// Display phone number with country flag
String formatPhoneWithFlag(String? phone) {
  if (phone == null || phone.isEmpty) return 'N/A';

  final code = extractCountryCode(phone);
  final flag = countryCodeMap[code] ?? '';

  if (flag.isNotEmpty) {
    return '$flag $phone';
  }

  return phone;
}
