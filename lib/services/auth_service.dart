import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final Dio dio = Dio();
  static String? _accessToken;
  static bool _interceptorAttached = false;
  static const String _accessTokenKey = 'access_token';

  static Future<void> init() async {
    if (!_interceptorAttached) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (_accessToken != null) {
              options.headers['Authorization'] = 'Bearer $_accessToken';
            }
            return handler.next(options);
          },
        ),
      );
      _interceptorAttached = true;
    }

    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
  }

  static Future<void> _saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  static Future<void> _removeAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }

  //LOGIN
  static Future<Response> login(String username, String password) async {
    final response = await dio.post(
      'https://dummyjson.com/auth/login',
      data: {'username': username, 'password': password, 'expiresInMins': 30},
      options: Options(contentType: Headers.jsonContentType),
    );

    if (response.statusCode == 200 && response.data['accessToken'] != null) {
      _accessToken = response.data['accessToken'];
      await _saveAccessToken(_accessToken!);
    }

    return response;
  }

  //GET AUTH USER
  static Future<Response> getUser() async {
    return await dio.get('https://dummyjson.com/auth/me');
  }

  //GET AUTH USER (/user/me)
  static Future<Response> getAuthUserMe() async {
    return await dio.get('https://dummyjson.com/user/me');
  }

  //GET POSTS (PAGINATION)
  static Future<Response> getPosts({
    required int limit,
    required int skip,
    String? select,
  }) async {
    return await dio.get(
      'https://dummyjson.com/posts',
      queryParameters: {
        'limit': limit,
        'skip': skip,
        if (select != null && select.isNotEmpty) 'select': select,
      },
    );
  }

  // ================= SEARCH POSTS =================
  static Future<Response> searchPosts({
    required String query,
    required int limit,
    required int skip,
    String? select,
  }) async {
    return await dio.get(
      'https://dummyjson.com/posts/search',
      queryParameters: {
        'q': query,
        'limit': limit,
        'skip': skip,
        if (select != null && select.isNotEmpty) 'select': select,
      },
    );
  }

  // ================= GET SINGLE POST =================
  static Future<Response> getPost(int postId) async {
    return await dio.get('https://dummyjson.com/posts/$postId');
  }

  // ================= GET POSTS BY USER ID =================
  static Future<Response> getPostsByUserId({
    required int userId,
    required int limit,
    required int skip,
    String? select,
  }) async {
    return await dio.get(
      'https://dummyjson.com/users/$userId/posts',
      queryParameters: {
        'limit': limit,
        'skip': skip,
        if (select != null && select.isNotEmpty) 'select': select,
      },
    );
  }

  // ================= GET POST COMMENTS =================
  static Future<Response> getPostComments(int postId) async {
    return await dio.get('https://dummyjson.com/posts/$postId/comments');
  }

  // ================= REFRESH =================
  static Future<Response> refresh() async {
    final response = await dio.post(
      'https://dummyjson.com/auth/refresh',
      data: {'expiresInMins': 30},
    );

    if (response.statusCode == 200 && response.data['accessToken'] != null) {
      _accessToken = response.data['accessToken'];
      await _saveAccessToken(_accessToken!);
    }

    return response;
  }

  static Future<void> logout() async {
    _accessToken = null;
    await _removeAccessToken();
  }

  // ================= DELETE POST =================
  static Future<Response> deletePost(int postId) async {
    return await dio.delete('https://dummyjson.com/posts/$postId');
  }
}
