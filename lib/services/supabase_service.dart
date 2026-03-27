import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/profile.dart';
import '../models/reserve.dart';
import '../config/app_config.dart';

/// SupabaseService — thin wrapper around the Supabase client.
/// Mirrors the schema defined by Axon (schema.sql).
class SupabaseService {
  static final _log = Logger(printer: SimplePrinter());

  SupabaseClient get _client => Supabase.instance.client;
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isSignedIn => currentUser != null;

  // ── Initialise (call once at app start) ────────────────────────────────────
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: false,
    );
    _log.i('Supabase initialised: ${AppConfig.supabaseUrl}');
  }

  // ── Auth ───────────────────────────────────────────────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final resp = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    _log.i('SignUp: ${resp.user?.email}');
    return resp;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final resp = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    _log.i('SignIn: ${resp.user?.email}');
    return resp;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _log.i('Signed out');
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  Future<Profile?> getProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  Future<Profile?> updateProfile({
    String? fullName,
    String? displayName,
    String? phone,
    String? avatarUrl,
  }) async {
    final uid = currentUser?.id;
    if (uid == null) return null;

    final updates = <String, dynamic>{
      if (fullName != null) 'full_name': fullName,
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    if (updates.isEmpty) return getProfile();

    final data = await _client
        .from('profiles')
        .update(updates)
        .eq('id', uid)
        .select()
        .single();

    return Profile.fromJson(data);
  }

  // ── Reserves ───────────────────────────────────────────────────────────────
  Future<List<Reserve>> getMyReserves() async {
    final uid = currentUser?.id;
    if (uid == null) return [];

    final data = await _client
        .from('reserves')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return (data as List).map((r) => Reserve.fromJson(r)).toList();
  }

  Future<Reserve?> createReserve({
    required String productSku,
    required String productName,
    int quantity = 1,
    int? depositAmountCents,
    String currency = 'usd',
  }) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final data = await _client
        .from('reserves')
        .insert({
          'user_id': uid,
          'product_sku': productSku,
          'product_name': productName,
          'quantity': quantity,
          'deposit_amount_cents': depositAmountCents ?? AppConfig.depositAmountCents,
          'currency': currency,
          'status': 'pending',
        })
        .select()
        .single();

    return Reserve.fromJson(data);
  }

  /// Update reserve with Stripe session after checkout initiation
  Future<Reserve?> attachStripeSession({
    required String reserveId,
    required String sessionId,
    required String checkoutUrl,
    DateTime? expiresAt,
  }) async {
    final data = await _client
        .from('reserves')
        .update({
          'stripe_session_id': sessionId,
          'stripe_checkout_url': checkoutUrl,
          'status': 'awaiting_payment',
          if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        })
        .eq('id', reserveId)
        .select()
        .single();

    return Reserve.fromJson(data);
  }

  // ── Realtime subscriptions ─────────────────────────────────────────────────
  RealtimeChannel subscribeToReserves(
    String userId,
    void Function(Reserve) onUpdate,
  ) {
    return _client
        .channel('reserves:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'reserves',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              try {
                onUpdate(Reserve.fromJson(payload.newRecord));
              } catch (e) {
                _log.w('Reserve parse error: $e');
              }
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to device telemetry (admin/operator only)
  RealtimeChannel subscribeTelemetry(
    String deviceId,
    void Function(Map<String, dynamic>) onRow,
  ) {
    return _client
        .channel('telemetry:$deviceId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'device_telemetry',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'device_id',
            value: deviceId,
          ),
          callback: (payload) => onRow(payload.newRecord),
        )
        .subscribe();
  }
}
