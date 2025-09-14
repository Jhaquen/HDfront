// Global configuration for the app
const bool isRelease = bool.fromEnvironment('RELEASE');
const String backendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:8080');
