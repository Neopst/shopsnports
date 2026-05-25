import 'package:shopsnports/models/address.dart';
import 'package:shopsnports/repositories/addresses_repository.dart';

/// Mock implementation of AddressesRepository for development/testing
class MockAddressesRepository implements AddressesRepository {
  final List<Address> _addresses = [];
  Address? _lastDeleted;

  @override
  Stream<List<Address>> addressesStream() {
    return Stream.value(List.unmodifiable(_addresses));
  }

  @override
  Future<Address> saveAddress(Address address) async {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index >= 0) {
      _addresses[index] = address;
    } else {
      _addresses.add(address);
    }
    return address;
  }

  @override
  Future<void> deleteAddress(String id) async {
    final index = _addresses.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _lastDeleted = _addresses[index];
      _addresses.removeAt(index);
    }
  }

  /// Restore the last deleted address (for undo functionality)
  Future<Address?> restoreLastDeleted() async {
    if (_lastDeleted != null) {
      _addresses.add(_lastDeleted!);
      final restored = _lastDeleted;
      _lastDeleted = null;
      return restored;
    }
    return null;
  }
}
