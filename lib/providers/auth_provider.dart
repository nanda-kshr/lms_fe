import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'api_provider.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;
  final Map<String, dynamic>? user;
  final bool isInitialized;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
    this.user,
    this.isInitialized = false,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
    Map<String, dynamic>? user,
    bool? isInitialized,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
      user: user ?? this.user,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  ApiService get _apiService => ref.read(apiServiceProvider);
  static const String _tokenKey = 'auth_token';

  @override
  AuthState build() {
    return AuthState();
  }

  Future<void> checkAuth() async {
    try {
      await _apiService.init();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        // In a real app, you'd validate the token or fetch user profile here
        // For now, assume token means logged in
        final user = {'email': 'user@example.com'}; // Placeholder

        state = state.copyWith(
          isAuthenticated: true,
          isInitialized: true,
          user: user,
        );
      } else {
        state = state.copyWith(isInitialized: true, isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(isInitialized: true, error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(email, password);
      final accessToken = response['accessToken'];

      _apiService.setToken(accessToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, accessToken);

      // In a real app, you'd decode the token or fetch user profile here
      final user = {'email': email};

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.signup(name, email, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    state = AuthState(isInitialized: true); // Keep initialized true
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
