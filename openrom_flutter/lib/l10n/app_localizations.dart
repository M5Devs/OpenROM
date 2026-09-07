import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenROM'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Universal ROM Conversion Suite'**
  String get appSubtitle;

  /// No description provided for @convertButton.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convertButton;

  /// No description provided for @convertButtonWithCount.
  ///
  /// In en, this message translates to:
  /// **'Convert ({count} Files)'**
  String convertButtonWithCount(int count);

  /// No description provided for @dropZoneHint.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop ROM files here'**
  String get dropZoneHint;

  /// No description provided for @dropZoneSubHint.
  ///
  /// In en, this message translates to:
  /// **'or Click to browse'**
  String get dropZoneSubHint;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversion Settings'**
  String get settingsTitle;

  /// No description provided for @outputFormat.
  ///
  /// In en, this message translates to:
  /// **'Output Format'**
  String get outputFormat;

  /// No description provided for @compressionLevel.
  ///
  /// In en, this message translates to:
  /// **'Compression Level'**
  String get compressionLevel;

  /// No description provided for @compressionNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get compressionNormal;

  /// No description provided for @compressionHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get compressionHigh;

  /// No description provided for @compressionMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get compressionMax;

  /// No description provided for @postProcessing.
  ///
  /// In en, this message translates to:
  /// **'Post-Processing'**
  String get postProcessing;

  /// No description provided for @verifyAfterConversion.
  ///
  /// In en, this message translates to:
  /// **'Verify after conversion'**
  String get verifyAfterConversion;

  /// No description provided for @outputDestination.
  ///
  /// In en, this message translates to:
  /// **'Output Destination'**
  String get outputDestination;

  /// No description provided for @browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browse;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting...'**
  String get statusWaiting;

  /// No description provided for @statusConverting.
  ///
  /// In en, this message translates to:
  /// **'Converting...'**
  String get statusConverting;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get statusFailed;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About OpenROM'**
  String get aboutTitle;

  /// No description provided for @settingsScreen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsScreen;

  /// No description provided for @aboutScreen.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutScreen;

  /// No description provided for @themeScreen.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get themeScreen;

  /// No description provided for @errorCoreNotFound.
  ///
  /// In en, this message translates to:
  /// **'openrom-core not found. Please re-download the full ZIP.'**
  String get errorCoreNotFound;

  /// No description provided for @errorUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This file format is not supported.'**
  String get errorUnsupportedFormat;

  /// No description provided for @errorDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough disk space for this conversion.'**
  String get errorDiskSpace;

  /// No description provided for @errorConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion failed. The ROM file might be corrupted.'**
  String get errorConversionFailed;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @reportBugButton.
  ///
  /// In en, this message translates to:
  /// **'Report Bug'**
  String get reportBugButton;

  /// No description provided for @clearQueue.
  ///
  /// In en, this message translates to:
  /// **'Clear Queue'**
  String get clearQueue;

  /// No description provided for @removeFile.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFile;

  /// No description provided for @openOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Output Folder'**
  String get openOutputFolder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'en',
        'es',
        'fr',
        'ja',
        'pt'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
