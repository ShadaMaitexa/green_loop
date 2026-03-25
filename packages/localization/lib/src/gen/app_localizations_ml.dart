// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malayalam (`ml`).
class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl([String locale = 'ml']) : super(locale);

  @override
  String get appTitle => 'ഗ്രീൻലൂപ്പ്';

  @override
  String get welcomeMessage => 'ഗ്രീൻലൂപ്പിലേക്ക് സ്വാഗതം';

  @override
  String get loginButton => 'ലോഗിൻ ചെയ്യുക';

  @override
  String get emailLabel => 'ഇമെയിൽ';

  @override
  String get passwordLabel => 'പാസ്സ്‌വേർഡ്';

  @override
  String get pickupStatusPending => 'തീരുമാനമാകാത്ത';

  @override
  String get pickupStatusCompleted => 'പൂർത്തിയായി';

  @override
  String get pickupStatusCancelled => 'റദ്ദാക്കി';

  @override
  String get pickupStatusAssigned => 'ചുമതലപ്പെടുത്തി';

  @override
  String get pickupStatusInProgress => 'പുരോഗമിക്കുന്നു';
}
