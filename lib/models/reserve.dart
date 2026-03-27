/// Mirrors `public.reserves` from Axon schema.
class Reserve {
  final String id;
  final String userId;
  final String productSku;
  final String productName;
  final int quantity;
  final int depositAmountCents;
  final String currency;
  final String? stripeSessionId;
  final String? stripePaymentIntent;
  final String? stripeCheckoutUrl;
  final ReserveStatus status;
  final String? notes;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime? cancelledAt;

  const Reserve({
    required this.id,
    required this.userId,
    required this.productSku,
    required this.productName,
    required this.quantity,
    required this.depositAmountCents,
    required this.currency,
    this.stripeSessionId,
    this.stripePaymentIntent,
    this.stripeCheckoutUrl,
    required this.status,
    this.notes,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.paidAt,
    this.cancelledAt,
  });

  double get depositAmountDollars => depositAmountCents / 100.0;

  factory Reserve.fromJson(Map<String, dynamic> json) => Reserve(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        productSku: json['product_sku'] as String,
        productName: json['product_name'] as String,
        quantity: json['quantity'] as int,
        depositAmountCents: json['deposit_amount_cents'] as int,
        currency: json['currency'] as String,
        stripeSessionId: json['stripe_session_id'] as String?,
        stripePaymentIntent: json['stripe_payment_intent'] as String?,
        stripeCheckoutUrl: json['stripe_checkout_url'] as String?,
        status: ReserveStatus.fromString(json['status'] as String),
        notes: json['notes'] as String?,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'] as String)
            : null,
        cancelledAt: json['cancelled_at'] != null
            ? DateTime.parse(json['cancelled_at'] as String)
            : null,
      );
}

enum ReserveStatus {
  pending('pending'),
  awaitingPayment('awaiting_payment'),
  paid('paid'),
  cancelled('cancelled'),
  refunded('refunded'),
  fulfilled('fulfilled');

  const ReserveStatus(this.value);
  final String value;

  static ReserveStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => ReserveStatus.pending);
}
