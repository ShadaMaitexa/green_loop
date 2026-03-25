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
        return 'http://10.0.2.2:8000'; // Android emulator → localhost
      case Environment.staging:
        return 'https://staging-api.greenloop.app';
      case Environment.production:
        return 'https://api.greenloop.app';
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
