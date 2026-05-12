/// Canonical order workflow codes — must match `etrade-next/src/lib/orderStatus.ts`.
abstract final class OrderStatus {
  static const int placed = 0;
  static const int preparing = 1;
  static const int shipped = 2;
  static const int delivered = 3;
  static const int rejected = 4;
  static const int completed = 5;

  static String label(int status) {
    switch (status) {
      case placed:
        return 'Order placed';
      case preparing:
        return 'Preparing';
      case shipped:
        return 'Shipped';
      case delivered:
        return 'Delivered';
      case rejected:
        return 'Rejected';
      case completed:
        return 'Completed';
      default:
        return 'Processing';
    }
  }

  /// Prefer numeric [status] when present so labels never disagree with the server.
  static String displayLabel({required int? status, String? statusText}) {
    final s = status;
    if (s != null && s >= placed && s <= completed) {
      return label(s);
    }
    final t = statusText?.trim();
    if (t != null && t.isNotEmpty) return t;
    return 'Unknown';
  }
}
