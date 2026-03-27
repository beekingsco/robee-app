/// Mirrors the `public.profiles` Supabase table defined in Axon's schema.
class Profile {
  final String id;
  final String? fullName;
  final String? displayName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DepositStatus depositStatus;
  final String? stripeCustomerId;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    this.fullName,
    this.displayName,
    required this.email,
    this.phone,
    this.avatarUrl,
    required this.depositStatus,
    this.stripeCustomerId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        displayName: json['display_name'] as String?,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        depositStatus: DepositStatus.fromString(json['deposit_status'] as String),
        stripeCustomerId: json['stripe_customer_id'] as String?,
        role: UserRole.fromString(json['role'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'deposit_status': depositStatus.value,
        'stripe_customer_id': stripeCustomerId,
        'role': role.value,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    String? fullName,
    String? displayName,
    String? phone,
    String? avatarUrl,
    DepositStatus? depositStatus,
    String? stripeCustomerId,
    UserRole? role,
  }) =>
      Profile(
        id: id,
        fullName: fullName ?? this.fullName,
        displayName: displayName ?? this.displayName,
        email: email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        depositStatus: depositStatus ?? this.depositStatus,
        stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
        role: role ?? this.role,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

enum DepositStatus {
  none('none'),
  pending('pending'),
  paid('paid'),
  refunded('refunded'),
  failed('failed');

  const DepositStatus(this.value);
  final String value;

  static DepositStatus fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => DepositStatus.none);
}

enum UserRole {
  user('user'),
  operator('operator'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String s) =>
      values.firstWhere((e) => e.value == s, orElse: () => UserRole.user);
}
