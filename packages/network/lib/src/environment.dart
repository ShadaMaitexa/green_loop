/// Environment configuration for the GreenLoop API client.
///
/// Usage:
///   ApiClient(environment: Environment.dev)
///   ApiClient(environment: Environment.production)
enum Environment { dev, staging, production }

extension EnvironmentExtension on Environment {
  String get baseUrl {
    switch (this) {
      case Environment.dev:
        return 'https://greenloop-hdwc.onrender.com'; // Target remote backend again
      case Environment.staging:
        return 'https://greenloop-hdwc.onrender.com';
      case Environment.production:
        return 'https://greenloop-hdwc.onrender.com';
    }
  }

  String get name {
    switch (this) {
      case Environment.dev:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  bool get isDebug => this == Environment.dev;
}
