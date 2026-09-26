/// Canonical stock movement action types
class StockMovementTypes {
  StockMovementTypes._();

  /// Stock increase from wholesale purchase invoice
  static const String purchase = 'PURCHASE';

  /// Stock decrease from wholesale or retail sales invoice
  static const String sale = 'SALE';

  /// Stock manual increase (inventory audit surplus)
  static const String adjustmentIn = 'ADJUSTMENT_IN';

  /// Stock manual deduction (damaged, lost, audit deficit)
  static const String adjustmentOut = 'ADJUSTMENT_OUT';

  /// Stock returned by customer back into inventory
  static const String returnIn = 'RETURN_IN';

  /// Stock returned to supplier out of inventory
  static const String returnOut = 'RETURN_OUT';

  /// All valid types for verification
  static const List<String> all = [
    purchase,
    sale,
    adjustmentIn,
    adjustmentOut,
    returnIn,
    returnOut,
  ];
}
