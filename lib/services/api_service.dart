import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';

class ApiService {
  final String baseUrl = 'http://10.217.109.103:3000';
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<List<Question>> fetchQuestions({String? status}) async {
    final queryParams = status != null ? '?vetting_status=$status' : '';
    final response = await http.get(
      Uri.parse('$baseUrl/questions/vetting$queryParams'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  Future<void> vetQuestion(
    String id,
    VettingAction action, {
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/questions/$id/vet'),
      headers: _headers,
      body: json.encode({'action': action.name, 'reason': reason}),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to vet question');
    }
  }
}
