// Global configuration for the app
import 'config_local.dart' as local;
import 'config_prod.dart' as prod;

const bool isRelease = bool.fromEnvironment('RELEASE');
const String backendUrl = isRelease ? prod.backendUrl : local.backendUrl;
