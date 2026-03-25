// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GreenLoop';

  @override
  String get welcomeMessage => 'Welcome to GreenLoop';

  @override
  String get loginButton => 'Login';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get pickupStatusPending => 'Pending';

  @override
  String get pickupStatusCompleted => 'Completed';

  @override
  String get pickupStatusCancelled => 'Cancelled';

  @override
  String get pickupStatusAssigned => 'Assigned';

  @override
  String get pickupStatusInProgress => 'In Progress';
}
