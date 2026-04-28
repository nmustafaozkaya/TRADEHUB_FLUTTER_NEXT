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
  UserAddress({required this.id, required this.title, required this.addressText});

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

class UserOrderItem {
  UserOrderItem({
    required this.id,
    required this.totalPrice,
    required this.statusText,
    required this.dateLabel,
  });

  final int id;
  final double totalPrice;
  final String statusText;
  final String dateLabel;
}
