import 'package:flutter/foundation.dart';

@immutable
class Address {
  final String id;
  final String type; // Home/Office/Delivery
  final String name;
  final String street;
  final String apt;
  final String city;
  final String state;
  final String zip;
  final String landmark;
  final String country;
  final String? phone;
  final bool isDefault;

  const Address({
    required this.id,
    required this.type,
    required this.name,
    required this.street,
    this.apt = '',
    required this.city,
    required this.state,
    required this.zip,
    this.landmark = '',
    required this.country,
    this.phone,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? type,
    String? name,
    String? street,
    String? apt,
    String? city,
    String? state,
    String? zip,
    String? landmark,
    String? country,
    String? phone,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      street: street ?? this.street,
      apt: apt ?? this.apt,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      landmark: landmark ?? this.landmark,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'name': name,
        'street': street,
        'apt': apt,
        'city': city,
        'state': state,
        'zip': zip,
        'landmark': landmark,
        'country': country,
        'phone': phone,
        'isDefault': isDefault,
      };

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        id: m['id'] as String,
        type: m['type'] as String? ?? 'Home',
        name: m['name'] as String? ?? '',
        street: m['street'] as String? ?? '',
        apt: m['apt'] as String? ?? '',
        city: m['city'] as String? ?? '',
        state: m['state'] as String? ?? '',
        zip: m['zip'] as String? ?? '',
        landmark: m['landmark'] as String? ?? '',
        country: m['country'] as String? ?? '',
        phone: m['phone'] as String?,
        isDefault: m['isDefault'] as bool? ?? false,
      );
}
