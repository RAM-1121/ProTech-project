class TariffPlan {
  final String id;
  final String name;
  final double amount;
  final int rewardPoints;
  final String? serviceType;

  TariffPlan({
    required this.id,
    required this.name,
    required this.amount,
    required this.rewardPoints,
    this.serviceType,
  });

  factory TariffPlan.fromJson(Map<String, dynamic> json) {
    return TariffPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      rewardPoints: json['rewardPoints'] ?? 0,
      serviceType: json['serviceType'],
    );
  }
}

class Coupon {
  final String code;
  final double discountPercentage;

  Coupon({
    required this.code,
    required this.discountPercentage,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      code: json['code'] ?? '',
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaymentConfig {
  final List<TariffPlan> tariffs;
  final double gstPercentage;
  final String? gstNumber;
  final String? upiId;
  final String? merchantName;
  final List<Coupon> coupons;

  PaymentConfig({
    required this.tariffs,
    required this.gstPercentage,
    this.gstNumber,
    this.upiId,
    this.merchantName,
    required this.coupons,
  });

  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    var tariffsList = json['tariffs'] as List? ?? [];
    var couponsList = json['coupons'] as List? ?? [];
    var configData = json['paymentConfig'] ?? {};

    return PaymentConfig(
      tariffs: tariffsList.map((t) => TariffPlan.fromJson(t)).toList(),
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 18.0,
      gstNumber: json['gstNumber'],
      upiId: configData['upiId'],
      merchantName: configData['merchantName'],
      coupons: couponsList.map((c) => Coupon.fromJson(c)).toList(),
    );
  }
}
