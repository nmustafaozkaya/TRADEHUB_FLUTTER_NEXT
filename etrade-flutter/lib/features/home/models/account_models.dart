/// Lightweight account models for profile, orders, addresses and saved cards.
class UserProfile {
  UserProfile({
    required this.fullName,
    required this.email,
    required this.gender,
    required this.birthdate,
    required this.phone,
  });

  final String fullName;
  final String email;
  final String gender;
  final String birthdate;
  final String phone;

  factory UserProfile.empty() {
    return UserProfile(
      fullName: '',
      email: '',
      gender: '',
      birthdate: '',
      phone: '',
    );
  }

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? gender,
    String? birthdate,
    String? phone,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      phone: phone ?? this.phone,
    );
  }
}

class UserAddress {
  UserAddress({
    required this.id,
    required this.title,
    required this.addressText,
  });

  final int id;
  final String title;
  final String addressText;
}

class SavedCardItem {
  SavedCardItem({
    required this.id,
    required this.brand,
    required this.last4,
    required this.cardHolder,
    required this.expMonth,
    required this.expYear,
  });

  final int id;
  final String brand;
  final String last4;
  final String cardHolder;
  final int expMonth;
  final int expYear;
}

class OrderLineItem {
  OrderLineItem({
    required this.itemId,
    required this.itemName,
    required this.brand,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.imageUrl,
  });

  final int itemId;
  final String itemName;
  final String brand;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  final String? imageUrl;

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    return OrderLineItem(
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      itemName: (json['itemName'] ?? 'Item').toString(),
      brand: (json['brand'] ?? '').toString(),
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}

class UserOrderDetail {
  UserOrderDetail({
    required this.id,
    required this.totalPrice,
    required this.status,
    required this.statusText,
    required this.dateLabel,
    required this.items,
    required this.subtotal,
    required this.shippingFee,
    this.cargoCompany,
    this.trackingNo,
    this.addressText,
    this.city,
    this.town,
  });

  final int id;
  final double totalPrice;
  final int status;
  final String statusText;
  final String dateLabel;
  final List<OrderLineItem> items;
  final double subtotal;
  final double shippingFee;
  final String? cargoCompany;
  final String? trackingNo;
  final String? addressText;
  final String? city;
  final String? town;

  double get total => subtotal + shippingFee;

  factory UserOrderDetail.fromJson(
    Map<String, dynamic> json,
    List<dynamic> linesJson,
  ) {
    final items = linesJson.map((raw) {
      final map = raw as Map<String, dynamic>;
      return OrderLineItem.fromJson(map);
    }).toList();
    final double subtotal =
        (json['subtotal'] as num?)?.toDouble() ??
        items.fold<double>(0.0, (double sum, item) => sum + item.lineTotal);
    final double shippingFee =
        (json['shippingFee'] as num?)?.toDouble() ??
        (subtotal >= 300 ? 0.0 : 100.0);

    return UserOrderDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusText: (json['statusLabel'] ?? json['statusText'] ?? 'Unknown')
          .toString(),
      dateLabel: _formatDate(json['date']?.toString()),
      items: items,
      subtotal: subtotal,
      shippingFee: shippingFee,
      cargoCompany: json['cargoCompany']?.toString(),
      trackingNo: json['trackingNo']?.toString(),
      addressText: json['addressText']?.toString(),
      city: json['city']?.toString(),
      town: json['town']?.toString(),
    );
  }

  static String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      const monthNames = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour12 = date.hour == 0
          ? 12
          : (date.hour > 12 ? date.hour - 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '${monthNames[date.month - 1]} ${date.day}, ${date.year}, $hour12:$minute $ampm';
    } catch (_) {
      return raw;
    }
  }
}

class UserOrderItem {
  UserOrderItem({
    required this.id,
    required this.totalPrice,
    required this.statusText,
    required this.dateLabel,
    this.status,
    this.cargoCompany,
    this.trackingNo,
    this.addressText,
  });

  final int id;
  final double totalPrice;
  final String statusText;
  final String dateLabel;
  final int? status;
  final String? cargoCompany;
  final String? trackingNo;
  final String? addressText;
}
