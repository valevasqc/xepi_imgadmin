enum DeliveryMethod {
  mensajero('mensajero'),
  forza('forza');

  const DeliveryMethod(this.value);
  final String value;

  static DeliveryMethod? fromString(String? s) {
    if (s == null) return null;
    for (final e in DeliveryMethod.values) {
      if (e.value == s) return e;
    }
    return null;
  }
}
