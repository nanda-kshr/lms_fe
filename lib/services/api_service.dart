import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/question.dart';

class ApiService {
  late final Dio _dio;
  String? _token;
  late final PersistCookieJar _cookieJar;
  bool _isInitialized = false;

  ApiService() {
    String baseUrl = 'http://localhost:3000';
    if (Platform.isAndroid) {
      baseUrl = 'http://10.0.2.2:3000';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(minutes: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  Future<void> init() async {
    if (_isInitialized) return;

    final appDocDir = await getApplicationDocumentsDirectory();
    final cookiePath = '${appDocDir.path}/.cookies/';
    final dir = Directory(cookiePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _cookieJar = PersistCookieJar(storage: FileStorage(cookiePath));
    _dio.interceptors.add(CookieManager(_cookieJar));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          print(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}',
          );

          // Handle 401 Unauthorized for token refresh
          if (e.response?.statusCode == 401 &&
              _token != null &&
              !e.requestOptions.path.contains('/auth/signin') &&
              !e.requestOptions.path.contains('/auth/refresh')) {
            try {
              print('Token expired. Attempting refresh...');
              final newAccessToken = await _refreshToken();
              if (newAccessToken != null) {
                print('Token refreshed successfully.');
                _token = newAccessToken;

                // Retry original request with new token
                final opts = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                opts.headers?['Authorization'] = 'Bearer $newAccessToken';

                final clonedRequest = await _dio.request(
                  e.requestOptions.path,
                  options: opts,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(clonedRequest);
              }
            } catch (refreshError) {
              print('Refresh failed: $refreshError');
              // Proceed with original error (logout will happen in UI/Provider)
            }
          }

          return handler.next(e);
        },
      ),
    );
    _isInitialized = true;
  }

  Future<String?> _refreshToken() async {
    try {
      // Cookies are automatically sent by CookieManager
      final response = await _dio.post('/auth/refresh');
      if (response.statusCode == 200) {
        return response.data['accessToken'];
      }
    } catch (e) {
      print('Failed to refresh token: $e');
      throw e;
    }
    return null;
  }

  void setToken(String token) {
    _token = token;
  }

  Future<void> logout() async {
    if (_isInitialized) {
      await _cookieJar.deleteAll();
    }
    _token = null;
  }

  // --- Auth ---

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Clear cookies before login to ensure fresh session
      if (_isInitialized) {
        await _cookieJar.deleteAll();
      }

      final response = await _dio.post(
        '/auth/signin',
        data: {'email': email, 'password': password},
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to login: ${e.response?.data ?? e.message}');
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      await _dio.post(
        '/auth/signup',
        data: {'name': name, 'email': email, 'password': password},
      );
    } on DioException catch (e) {
      throw Exception('Failed to signup: ${e.response?.data ?? e.message}');
    }
  }

  // --- Metadata ---

  Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final response = await _dio.get('/courses');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch courses: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopics(String courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId/topics');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch topics: ${e.response?.data ?? e.message}',
      );
    }
  }

  // --- Questions ---

  Future<Map<String, dynamic>> uploadQuestions(
    File file, {
    String? courseCode,
    String? topic,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      final map = <String, dynamic>{
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      };
      if (courseCode != null) map['course_code'] = courseCode;
      if (topic != null) map['topic'] = topic;

      FormData formData = FormData.fromMap(map);

      final response = await _dio.post('/questions/upload', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to upload questions: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> uploadMaterial(
    File file, {
    required String courseCode,
    required String type, // SYLLABUS or CONTENT
  }) async {
    try {
      String fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'course_code': courseCode,
        'type': type,
      });

      final response = await _dio.post('/materials/upload', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to upload material: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserUploads() async {
    try {
      final response = await _dio.get('/questions/my-uploads');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to fetch uploads');
      }
    } catch (e) {
      throw Exception('Error fetching uploads: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUserMaterials() async {
    try {
      final response = await _dio.get('/materials/my-uploads');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Failed to fetch materials');
      }
    } catch (e) {
      throw Exception('Error fetching materials: $e');
    }
  }

  Future<void> deleteQuestionUpload(String uploadId) async {
    try {
      await _dio.delete('/questions/upload/$uploadId');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete questions: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> deleteMaterial(String id) async {
    try {
      await _dio.delete('/materials/$id');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete material: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchQuestions({String? status}) async {
    try {
      final queryParams = status != null ? {'vetting_status': status} : null;
      final response = await _dio.get(
        '/questions/vetting',
        queryParameters: queryParams,
      );

      final data = response.data as Map<String, dynamic>;
      final List<dynamic> questionsJson = data['questions'] ?? [];
      final questions = questionsJson
          .map((json) => Question.fromJson(json))
          .toList();

      return {
        'questions': questions,
        'vetted_today': data['vetted_today'] ?? 0,
        'remaining_votes': data['remaining_votes'] ?? 0,
        'daily_limit': data['daily_limit'] ?? 10,
      };
    } on DioException catch (e) {
      throw Exception(
        'Failed to load questions: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> vetQuestion(
    String id,
    VettingAction action, {
    String? reason,
  }) async {
    try {
      await _dio.post(
        '/questions/$id/vet',
        data: {'action': action.name, 'reason': reason},
      );
    } on DioException catch (e) {
      throw Exception(
        'Failed to vet question: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> generatePaper({
    required String courseCode,
    List<String>? topics,
    required int marks,
    required int total,
    required Map<String, int> coDistribution,
    required Map<String, int> loDistribution,
    required Map<String, int> difficultyDistribution,
    String? questionStyle,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        '/questions/generate',
        data: {
          'course_code': courseCode,
          if (topics != null && topics.isNotEmpty) 'topics': topics,
          'marks': marks,
          'total': total,
          'co_distribution': coDistribution,
          'lo_distribution': loDistribution,
          'difficulty_distribution': difficultyDistribution,
          if (questionStyle != null) 'question_style': questionStyle,
        },
        options: Options(receiveTimeout: const Duration(minutes: 60)),
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('Generation cancelled by user.');
      }
      throw Exception(
        'Failed to generate paper: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchSystemAnalytics() async {
    try {
      final response = await _dio.get('/analytics/system');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch analytics: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchTrends() async {
    try {
      final response = await _dio.get('/analytics/trends');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch trends: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchCourseAnalytics(String code) async {
    try {
      final response = await _dio.get('/analytics/course/$code');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch course analytics: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchFacultyDetails(String id) async {
    try {
      final response = await _dio.get('/analytics/faculty/$id');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch faculty details: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> fetchUserVettingStats() async {
    try {
      final response = await _dio.get('/analytics/user-vetting');
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch user vetting stats: ${e.response?.data ?? e.message}',
      );
    }
  }

  // --- Course CRUD ---

  Future<Map<String, dynamic>> createCourse(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/courses', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to create course: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> updateCourse(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/courses/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to update course: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> deleteCourse(String id) async {
    try {
      await _dio.delete('/courses/$id');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete course: ${e.response?.data ?? e.message}',
      );
    }
  }

  // --- Topic CRUD ---

  Future<Map<String, dynamic>> addTopic(
    String courseId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post('/courses/$courseId/topics', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception('Failed to add topic: ${e.response?.data ?? e.message}');
    }
  }

  Future<Map<String, dynamic>> updateTopic(
    String courseId,
    String topicId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put(
        '/courses/$courseId/topics/$topicId',
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to update topic: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> deleteTopic(String courseId, String topicId) async {
    try {
      await _dio.delete('/courses/$courseId/topics/$topicId');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete topic: ${e.response?.data ?? e.message}',
      );
    }
  }

  // ── Rubrics ────────────────────────────────────────────

  Future<Map<String, dynamic>> getRubrics({
    String? search,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/rubrics',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'page': page,
          'limit': limit,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch rubrics: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> createRubric(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/rubrics', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to create rubric: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<Map<String, dynamic>> updateRubric(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put('/rubrics/$id', data: data);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        'Failed to update rubric: ${e.response?.data ?? e.message}',
      );
    }
  }

  Future<void> deleteRubric(String id) async {
    try {
      await _dio.delete('/rubrics/$id');
    } on DioException catch (e) {
      throw Exception(
        'Failed to delete rubric: ${e.response?.data ?? e.message}',
      );
    }
  }
}
