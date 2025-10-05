class ApiConfig {
  ApiConfig._();

  // Prefer explicit override first, then ENV, then defaults
  static const String _baseUrlOverride = String.fromEnvironment('BASE_URL');
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const String _useMock = String.fromEnvironment(
    'USE_MOCK_FALLBACK',
    defaultValue: 'false',
  );

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (_env == 'prod') {
      return 'https://marineguard-api.onrender.com';
    }
    return 'http://localhost:5000';
  }

  static bool get useMockFallback => _useMock.toLowerCase() == 'true';
}
