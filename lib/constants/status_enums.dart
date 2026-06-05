enum SaleStatus {
  pendingApproval('pending_approval'),
  approved('approved');

  const SaleStatus(this.value);
  final String value;

  static SaleStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in SaleStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum StockStatus {
  completed('completed'),
  inTransit('in_transit');

  const StockStatus(this.value);
  final String value;

  static StockStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in StockStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum DeliveryStatus {
  pending('pending'),
  pickedUp('picked_up'),
  delivered('delivered'),
  cashReceived('cash_received');

  const DeliveryStatus(this.value);
  final String value;

  static DeliveryStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in DeliveryStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum MovementStatus {
  pending('pending'),
  sent('sent'),
  received('received'),
  cancelled('cancelled');

  const MovementStatus(this.value);
  final String value;

  static MovementStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in MovementStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

/// Note: Firestore stores 'in-progress' with a hyphen (not underscore).
enum ShipmentStatus {
  inProgress('in-progress'),
  completed('completed'),
  cancelled('cancelled');

  const ShipmentStatus(this.value);
  final String value;

  static ShipmentStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in ShipmentStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum ExpenseStatus {
  pendingApproval('pending_approval'),
  approved('approved'),
  rejected('rejected');

  const ExpenseStatus(this.value);
  final String value;

  static ExpenseStatus? fromString(String? s) {
    if (s == null) return null;
    for (final e in ExpenseStatus.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum ExpenseType {
  operativo('operativo'),
  noOperativo('no_operativo');

  const ExpenseType(this.value);
  final String value;

  static ExpenseType? fromString(String? s) {
    if (s == null) return null;
    for (final e in ExpenseType.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

enum UserRole {
  admin('admin'),
  kiosko('kiosko'),
  warehouse('warehouse'),
  mensajero('mensajero'),
  custom('custom');

  const UserRole(this.value);
  final String value;

  static UserRole? fromString(String? s) {
    if (s == null) return null;
    for (final e in UserRole.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}
