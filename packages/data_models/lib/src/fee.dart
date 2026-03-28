/// Payment method as returned by the API.
/// API uses `payment_method: "CASH"` or `"UPI"`.
enum PaymentMode {
  cash,
  upi;

  static PaymentMode fromJson(String? json) {
    if (json?.toUpperCase() == 'UPI') return PaymentMode.upi;
    return PaymentMode.cash;
  }

  String toJson() => this == PaymentMode.upi ? 'UPI' : 'CASH';
}

/// Aligns with GET /api/v1/payments/{id}/ response:
/// { id, amount, payment_method, receipt_number, payment_date,
///   created_at, updated_at, resident, ward, collected_by }
class FeeCollection {
  final int id;
  final double amount;
  final PaymentMode paymentMode;
  final String receiptNumber;
  final DateTime paymentDate;
  final String? residentId;   // UUID of resident
  final int? wardId;
  final String? collectedById; // UUID of worker who collected

  // Legacy field kept for existing screens
  String get pickupId => residentId ?? '';
  DateTime get collectedAt => paymentDate;

  FeeCollection({
    required this.id,
    required this.amount,
    required this.paymentMode,
    required this.receiptNumber,
    required this.paymentDate,
    this.residentId,
    this.wardId,
    this.collectedById,
  });

  factory FeeCollection.fromJson(Map<String, dynamic> json) {
    return FeeCollection(
      id: json['id'] as int? ?? 0,
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMode: PaymentMode.fromJson(json['payment_method']?.toString()),
      receiptNumber: json['receipt_number']?.toString() ?? '',
      paymentDate: DateTime.tryParse(json['payment_date']?.toString() ?? '') ??
          DateTime.tryParse(json['collected_at']?.toString() ?? '') ??
          DateTime.now(),
      residentId: json['resident']?.toString(),
      wardId: json['ward'] is int ? json['ward'] as int : null,
      collectedById: json['collected_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount.toString(),
      'payment_method': paymentMode.toJson(),
      'receipt_number': receiptNumber,
      'payment_date': paymentDate.toIso8601String(),
      if (residentId != null) 'resident': residentId,
      if (wardId != null) 'ward': wardId,
      if (collectedById != null) 'collected_by': collectedById,
    };
  }
}

/// Request body for POST /api/v1/payments/
class FeeCollectionRequest {
  final double amount;
  final PaymentMode paymentMethod;
  final String residentId;
  final int wardId;

  const FeeCollectionRequest({
    required this.amount,
    required this.paymentMethod,
    required this.residentId,
    required this.wardId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toString(),
      'payment_method': paymentMethod.toJson(),
      'resident': residentId,
      'ward': wardId,
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
