import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// NetworkService — HTTP client (Dio) + WebSocket helpers + connectivity monitoring.
class NetworkService {
  static final _log = Logger(printer: SimplePrinter());

  late final Dio _dio;
  ConnectivityResult _connectivity = ConnectivityResult.none;

  // ── Connectivity stream ───────────────────────────────────────────────────────
  final _connectivityController = StreamController<ConnectivityResult>.broadcast();
  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;
  ConnectivityResult get connectivity => _connectivity;
  bool get isOnline => _connectivity != ConnectivityResult.none;

  NetworkService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      _LoggingInterceptor(),
      _RetryInterceptor(dio: _dio),
    ]);

    _watchConnectivity();
  }

  void _watchConnectivity() {
    Connectivity().checkConnectivity().then((r) {
      _connectivity = r;
      _connectivityController.add(r);
    });
    Connectivity().onConnectivityChanged.listen((r) {
      _connectivity = r;
      _connectivityController.add(r);
    });
  }

  // ── Auth header injection ─────────────────────────────────────────────────────
  void setAuthToken(String? token) {
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // ── HTTP helpers ──────────────────────────────────────────────────────────────
  Future<T?> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.get(path, queryParameters: queryParams);
      return fromJson != null ? fromJson(resp.data) : resp.data as T?;
    } on DioException catch (e) {
      _log.e('GET $path failed: ${e.message}');
      rethrow;
    }
  }

  Future<T?> post<T>(
    String path, {
    required Map<String, dynamic> body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.post(path, data: body);
      return fromJson != null ? fromJson(resp.data) : resp.data as T?;
    } on DioException catch (e) {
      _log.e('POST $path failed: ${e.message}');
      rethrow;
    }
  }

  Future<T?> patch<T>(
    String path, {
    required Map<String, dynamic> body,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final resp = await _dio.patch(path, data: body);
      return fromJson != null ? fromJson(resp.data) : resp.data as T?;
    } on DioException catch (e) {
      _log.e('PATCH $path failed: ${e.message}');
      rethrow;
    }
  }

  // ── WebSocket factory ─────────────────────────────────────────────────────────
  WebSocketChannel openWebSocket(
    String url, {
    Map<String, dynamic>? headers,
    List<String>? protocols,
  }) {
    _log.i('Opening WS: $url');
    return WebSocketChannel.connect(
      Uri.parse(url),
      protocols: protocols,
    );
  }

  // ── Supabase realtime helper ─────────────────────────────────────────────────
  /// Convenience: stream rows from a Supabase realtime channel.
  /// Actual Supabase realtime is handled by the supabase_flutter package;
  /// this is a raw WS fallback for non-Supabase endpoints.

  // ── Cleanup ──────────────────────────────────────────────────────────────────
  void dispose() {
    _connectivityController.close();
    _dio.close();
  }
}

// ── Logging interceptor ─────────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  static final _log = Logger(printer: SimplePrinter());

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.d('← ${response.statusCode} ${response.realUri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e('✗ ${err.requestOptions.method} ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}

// ── Basic retry interceptor (3 retries on 5xx) ──────────────────────────────────
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  static final _log = Logger(printer: SimplePrinter());
  static const _maxRetries = 3;

  _RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = (extra['_retryCount'] as int?) ?? 0;

    final isServerError = err.response?.statusCode != null &&
        err.response!.statusCode! >= 500;
    final isTimeout = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if ((isServerError || isTimeout) && retryCount < _maxRetries) {
      _log.w('Retry ${retryCount + 1}/$_maxRetries for ${err.requestOptions.uri}');
      await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
      err.requestOptions.extra['_retryCount'] = retryCount + 1;
      try {
        final response = await dio.fetch(err.requestOptions);
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }
}
