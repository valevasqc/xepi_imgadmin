/// Physical location for stock tracking.
enum StockLocation {
  store('store'),
  warehouse('warehouse');

  const StockLocation(this.value);
  final String value;

  String get stockField =>
      this == StockLocation.store ? 'stockStore' : 'stockWarehouse';

  static StockLocation? fromString(String? s) {
    if (s == null) return null;
    for (final e in StockLocation.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}

/// Cash pools tracked per source. Includes delivery partners.
enum CashSource {
  store('store'),
  mensajero('mensajero'),
  forza('forza');

  const CashSource(this.value);
  final String value;

  static CashSource? fromString(String? s) {
    if (s == null) return null;
    for (final e in CashSource.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}
