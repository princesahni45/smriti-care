import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('as'),
    Locale('en'),
    Locale('hi')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Smriti Care'**
  String get appName;

  /// Welcome greeting for the patient
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Button to log in as a patient
  ///
  /// In en, this message translates to:
  /// **'Patient Login'**
  String get patientLogin;

  /// Button to log in as a caregiver
  ///
  /// In en, this message translates to:
  /// **'Caregiver Login'**
  String get caregiverLogin;

  /// Main dashboard title and navigation
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Cognitive activities and games section
  ///
  /// In en, this message translates to:
  /// **'Brain Games'**
  String get games;

  /// Medication and routine reminders section
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// Spoken assistant feature
  ///
  /// In en, this message translates to:
  /// **'Voice Assistant'**
  String get voiceAssistant;

  /// Help and guidance button
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Application settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language selection option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Hindi language name
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// Assamese language name
  ///
  /// In en, this message translates to:
  /// **'Assamese'**
  String get assamese;

  /// Start an activity or game
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Continue action button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// Repeat instructions or audio
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Navigate back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Home destination button
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Indicates an activity or reminder has been completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Retry an action or puzzle
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Refers to the current day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Morning period of the day
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// Afternoon period of the day
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get afternoon;

  /// Evening period of the day
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// Prompt to take prescribed medications
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminder'**
  String get medicineReminder;

  /// Gentle hydration prompt for the patient
  ///
  /// In en, this message translates to:
  /// **'Drink Water'**
  String get drinkWater;

  /// Medical or doctor appointment reminder
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// One-touch urgent assistance request button
  ///
  /// In en, this message translates to:
  /// **'Help Me'**
  String get helpMe;

  /// Critical emergency SOS trigger
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergency;

  /// Caregiver role label
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiver;

  /// Log out action
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logout;

  /// Confirmation button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancellation button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Loading state indication
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Status banner when device is offline
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get offlineMode;

  /// Notification when network connection is absent
  ///
  /// In en, this message translates to:
  /// **'Internet is unavailable. Operating in safe offline mode.'**
  String get internetUnavailable;

  /// Gentle, calm error fallback message for elderly patients
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please tap Back or Home.'**
  String get somethingWentWrong;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['as', 'en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
