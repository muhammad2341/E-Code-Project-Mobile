import 'package:dio/dio.dart';

class AuthService {
  static final Dio dio = Dio();
  static String? _accessToken;

  static void init() {
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
    }

    return response;
  }

  // ================= GET AUTH USER =================
  static Future<Response> getUser() async {
    return await dio.get('https://dummyjson.com/auth/me');
  }

  // ================= GET POSTS (PAGINATION) =================
  static Future<Response> getPosts({
    required int limit,
    required int skip,
  }) async {
    return await dio.get(
      'https://dummyjson.com/posts',
      queryParameters: {'limit': limit, 'skip': skip},
    );
  }

  // ================= GET SINGLE POST =================
  static Future<Response> getPost(int postId) async {
    return await dio.get('https://dummyjson.com/posts/$postId');
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
    }

    return response;
  }

  static void logout() {
    _accessToken = null;
  }

  // ================= DELETE POST =================
  static Future<Response> deletePost(int postId) async {
    return await dio.delete('https://dummyjson.com/posts/$postId');
  }
}
