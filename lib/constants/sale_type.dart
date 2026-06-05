enum SaleType {
  kiosko('kiosko'),
  delivery('delivery');

  const SaleType(this.value);
  final String value;

  static SaleType? fromString(String? s) {
    if (s == null) return null;
    for (final e in SaleType.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}
