

enum PaymentMode { cash, upi }

class FeeCollection {
  final String id;
  final String pickupId;
  final double amount;
  final PaymentMode paymentMode;
  final String receiptNumber;
  final DateTime collectedAt;

  FeeCollection({
    required this.id,
    required this.pickupId,
    required this.amount,
    required this.paymentMode,
    required this.receiptNumber,
    required this.collectedAt,
  });

  factory FeeCollection.fromJson(Map<String, dynamic> json) {
    return FeeCollection(
      id: json['id'] as String,
      pickupId: json['pickup_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] == 'upi' ? PaymentMode.upi : PaymentMode.cash,
      receiptNumber: json['receipt_number'] as String,
      collectedAt: DateTime.parse(json['collected_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pickup_id': pickupId,
      'amount': amount,
      'payment_mode': paymentMode == PaymentMode.upi ? 'upi' : 'cash',
      'receipt_number': receiptNumber,
      'collected_at': collectedAt.toIso8601String(),
    };
  }
}

class DailyFeeSummary {
  final double totalCollected;
  final int numberHouseholds;
  final double cashCollected;
  final double upiCollected;

  DailyFeeSummary({
    required this.totalCollected,
    required this.numberHouseholds,
    required this.cashCollected,
    required this.upiCollected,
  });

  factory DailyFeeSummary.fromJson(Map<String, dynamic> json) {
    return DailyFeeSummary(
      totalCollected: (json['total_collected'] as num?)?.toDouble() ?? 0.0,
      numberHouseholds: (json['number_households'] as int?) ?? 0,
      cashCollected: (json['cash_collected'] as num?)?.toDouble() ?? 0.0,
      upiCollected: (json['upi_collected'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
