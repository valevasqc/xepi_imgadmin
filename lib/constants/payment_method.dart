enum PaymentMethod {
  efectivo('efectivo'),
  transferencia('transferencia'),
  tarjeta('tarjeta');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod? fromString(String? s) {
    if (s == null) return null;
    for (final e in PaymentMethod.values) {
      if (e.value == s) return e;
    }
    return null;
  }

  bool get requiresApproval =>
      this == PaymentMethod.transferencia || this == PaymentMethod.tarjeta;

  bool get isCash => this == PaymentMethod.efectivo;
}
