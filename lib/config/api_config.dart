class ApiConfig {
  // Base URL (તમારા બેકએન્ડની લિંક)
  // જો મોબાઈલમાં રન કરતા હોવ તો:
  // static const String baseUrl = "http://10.0.2.2:3000/api";
  
  // જો Chrome (Web) માં રન કરતા હોવ તો:
  static const String baseUrl = "http://localhost:3000/api";

  // Endpoints (રસ્તાઓ)
  static const String loginEndpoint = "/auth/login";
  static const String registerEndpoint = "/auth/register";

  // Keys (ડેટા સાચવવા માટેની ચાવીઓ)
  static const String tokenKey = "auth_token";

  // Timeout (કેટલી વાર સુધી રાહ જોવી)
  static const Duration requestTimeout = Duration(seconds: 10);
}