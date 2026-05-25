import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Customer model - represents a customer in Firestore
class Customer {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String status; // 'active', 'suspended', 'banned'
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;

  // Extended fields
  final String? businessName;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? zipCode;
  final String? gender;
  final String? dateOfBirth;
  final bool emailVerified;
  final bool phoneVerified;
  final String? notes;

  // Statistics
  final int totalOrders;
  final double totalSpent;
  final int pendingOrders;
  final double pendingAmount;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl = '',
    this.status = 'active',
    required this.createdAt,
    this.lastLogin,
    this.updatedAt,
    this.businessName,
    this.address,
    this.city,
    this.state,
    this.country,
    this.zipCode,
    this.gender,
    this.dateOfBirth,
    this.emailVerified = false,
    this.phoneVerified = false,
    this.notes,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.pendingOrders = 0,
    this.pendingAmount = 0.0,
  });

  /// Get status color
  Color get statusColor {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'suspended':
        return Colors.orange;
      case 'banned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get display status
  String get displayStatus {
    if (status.isEmpty) return 'Unknown';
    return status[0].toUpperCase() + status.substring(1);
  }

  /// Check if customer is active
  bool get isActive => status == 'active';

  /// Check if customer is suspended
  bool get isSuspended => status == 'suspended';

  /// Check if customer is banned
  bool get isBanned => status == 'banned';

  /// Get full address
  String? get fullAddress {
    final parts = [
      if (address != null && address!.isNotEmpty) address,
      if (city != null && city!.isNotEmpty) city,
      if (state != null && state!.isNotEmpty) state,
      if (zipCode != null && zipCode!.isNotEmpty) zipCode,
      if (country != null && country!.isNotEmpty) country,
    ];
    return parts.isNotEmpty ? parts.join(', ') : null;
  }

  /// Factory constructor from Firestore
  factory Customer.fromFirestore(Map<String, dynamic> data, String id) {
    return Customer(
      id: id,
      name: data['name'] as String? ?? 'Unknown',
      email: data['email'] as String? ?? 'noemail@example.com',
      phone: data['phone'] as String?,
      avatarUrl: data['avatarUrl'] as String? ?? '',
      status: (data['status'] as String?) ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      lastLogin: _parseTimestamp(data['lastLogin']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      businessName: data['businessName'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      country: data['country'] as String?,
      zipCode: data['zipCode'] as String?,
      gender: data['gender'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      emailVerified: data['emailVerified'] as bool? ?? false,
      phoneVerified: data['phoneVerified'] as bool? ?? false,
      notes: data['notes'] as String?,
      totalOrders: (data['totalOrders'] as int?) ?? 0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      pendingOrders: (data['pendingOrders'] as int?) ?? 0,
      pendingAmount: (data['pendingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'status': status,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'updatedAt': DateTime.now(),
      'businessName': businessName,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'zipCode': zipCode,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'notes': notes,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'pendingOrders': pendingOrders,
      'pendingAmount': pendingAmount,
    };
  }

  /// Parse timestamp safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    return DateTime.now();
  }

  /// Create a copy with updated fields
  Customer copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? status,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
    String? businessName,
    String? address,
    String? city,
    String? state,
    String? country,
    String? zipCode,
    String? gender,
    String? dateOfBirth,
    bool? emailVerified,
    bool? phoneVerified,
    String? notes,
    int? totalOrders,
    double? totalSpent,
    int? pendingOrders,
    double? pendingAmount,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      notes: notes ?? this.notes,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      pendingAmount: pendingAmount ?? this.pendingAmount,
    );
  }
}

/// Customer status enum for type safety
enum CustomerStatus {
  active('Active', Colors.green),
  suspended('Suspended', Colors.orange),
  banned('Banned', Colors.red);

  final String displayName;
  final Color color;
  const CustomerStatus(this.displayName, this.color);

  static CustomerStatus fromString(String status) {
    return values.firstWhere(
      (e) => e.name == status,
      orElse: () => active,
    );
  }
}