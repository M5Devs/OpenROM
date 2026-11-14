import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
    Locale('zh', 'TW')
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
  /// **'openrom-core is missing from the app folder.'**
  String get errorCoreNotFound;

  /// No description provided for @errorUnsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This file format cannot be converted with the selected output.'**
  String get errorUnsupportedFormat;

  /// No description provided for @errorDiskSpace.
  ///
  /// In en, this message translates to:
  /// **'Not enough free space to complete this conversion.'**
  String get errorDiskSpace;

  /// No description provided for @errorToolFailed.
  ///
  /// In en, this message translates to:
  /// **'The conversion tool (chdman/maxcso) exited unexpectedly.'**
  String get errorToolFailed;

  /// No description provided for @errorConversionFailed.
  ///
  /// In en, this message translates to:
  /// **'Conversion stopped before completing.'**
  String get errorConversionFailed;

  /// No description provided for @errorFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'The input file was moved or deleted.'**
  String get errorFileNotFound;

  /// No description provided for @errorOutputDirNotFound.
  ///
  /// In en, this message translates to:
  /// **'The selected output folder no longer exists.'**
  String get errorOutputDirNotFound;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'OpenROM can\'t write to the output folder.'**
  String get errorPermissionDenied;

  /// No description provided for @errorCorruptedFile.
  ///
  /// In en, this message translates to:
  /// **'The file appears to be corrupted or is 0 bytes.'**
  String get errorCorruptedFile;

  /// No description provided for @errorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. This might be a bug.'**
  String get errorUnknown;

  /// No description provided for @errorDetailsLabel.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get errorDetailsLabel;

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

  /// No description provided for @patcherTitle.
  ///
  /// In en, this message translates to:
  /// **'ROM Patcher'**
  String get patcherTitle;

  /// No description provided for @patcherRomFile.
  ///
  /// In en, this message translates to:
  /// **'ROM File'**
  String get patcherRomFile;

  /// No description provided for @patcherPatchFile.
  ///
  /// In en, this message translates to:
  /// **'Patch File'**
  String get patcherPatchFile;

  /// No description provided for @patcherOutputFile.
  ///
  /// In en, this message translates to:
  /// **'Output File'**
  String get patcherOutputFile;

  /// No description provided for @patcherSameFolder.
  ///
  /// In en, this message translates to:
  /// **'Same folder as ROM'**
  String get patcherSameFolder;

  /// No description provided for @patcherIgnoreChecksum.
  ///
  /// In en, this message translates to:
  /// **'Ignore checksum errors'**
  String get patcherIgnoreChecksum;

  /// No description provided for @patcherApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Patch'**
  String get patcherApplyButton;

  /// No description provided for @patcherSuccess.
  ///
  /// In en, this message translates to:
  /// **'Patched successfully!'**
  String get patcherSuccess;

  /// No description provided for @patcherFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get patcherFormat;

  /// No description provided for @patcherChecksumPassed.
  ///
  /// In en, this message translates to:
  /// **'passed'**
  String get patcherChecksumPassed;

  /// No description provided for @patcherChecksumSkipped.
  ///
  /// In en, this message translates to:
  /// **'skipped'**
  String get patcherChecksumSkipped;

  /// No description provided for @patcherDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop ROM + Patch files here'**
  String get patcherDropHint;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get toolsTitle;

  /// No description provided for @compressorTitle.
  ///
  /// In en, this message translates to:
  /// **'ROM Compressor'**
  String get compressorTitle;

  /// No description provided for @compressorAddFiles.
  ///
  /// In en, this message translates to:
  /// **'Add Files'**
  String get compressorAddFiles;

  /// No description provided for @compressorAddFolder.
  ///
  /// In en, this message translates to:
  /// **'Add Folder'**
  String get compressorAddFolder;

  /// No description provided for @compressorOutputFormat.
  ///
  /// In en, this message translates to:
  /// **'Output Format'**
  String get compressorOutputFormat;

  /// No description provided for @compressorLevel.
  ///
  /// In en, this message translates to:
  /// **'Compression Level'**
  String get compressorLevel;

  /// No description provided for @compressorLevelFast.
  ///
  /// In en, this message translates to:
  /// **'Fast'**
  String get compressorLevelFast;

  /// No description provided for @compressorLevelNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get compressorLevelNormal;

  /// No description provided for @compressorLevelUltra.
  ///
  /// In en, this message translates to:
  /// **'Ultra'**
  String get compressorLevelUltra;

  /// No description provided for @compressorDeleteSource.
  ///
  /// In en, this message translates to:
  /// **'Delete source after done'**
  String get compressorDeleteSource;

  /// No description provided for @compressorSameFolder.
  ///
  /// In en, this message translates to:
  /// **'Same folder as source'**
  String get compressorSameFolder;

  /// No description provided for @compressorButton.
  ///
  /// In en, this message translates to:
  /// **'Compress ({count} Files)'**
  String compressorButton(int count);

  /// No description provided for @compressorSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped (already compressed)'**
  String get compressorSkipped;

  /// No description provided for @m3uTitle.
  ///
  /// In en, this message translates to:
  /// **'M3U Generator'**
  String get m3uTitle;

  /// No description provided for @m3uDropHint.
  ///
  /// In en, this message translates to:
  /// **'Drop disc files here'**
  String get m3uDropHint;

  /// No description provided for @m3uOutputLabel.
  ///
  /// In en, this message translates to:
  /// **'Output folder'**
  String get m3uOutputLabel;

  /// No description provided for @m3uButton.
  ///
  /// In en, this message translates to:
  /// **'Generate M3U'**
  String get m3uButton;

  /// No description provided for @m3uSuccess.
  ///
  /// In en, this message translates to:
  /// **'Created: {filename}'**
  String m3uSuccess(String filename);

  /// No description provided for @cueGeneratorTitle.
  ///
  /// In en, this message translates to:
  /// **'CUE Generator'**
  String get cueGeneratorTitle;

  /// No description provided for @cueGeneratorBinFile.
  ///
  /// In en, this message translates to:
  /// **'BIN File'**
  String get cueGeneratorBinFile;

  /// No description provided for @cueGeneratorDetectedMode.
  ///
  /// In en, this message translates to:
  /// **'Detected mode'**
  String get cueGeneratorDetectedMode;

  /// No description provided for @cueGeneratorButton.
  ///
  /// In en, this message translates to:
  /// **'Generate CUE'**
  String get cueGeneratorButton;

  /// No description provided for @cueGeneratorSuccess.
  ///
  /// In en, this message translates to:
  /// **'Created: {filename}'**
  String cueGeneratorSuccess(String filename);

  /// No description provided for @binMergerTitle.
  ///
  /// In en, this message translates to:
  /// **'BIN Merger'**
  String get binMergerTitle;

  /// No description provided for @binMergerCueFile.
  ///
  /// In en, this message translates to:
  /// **'CUE File (multi-track)'**
  String get binMergerCueFile;

  /// No description provided for @binMergerDetected.
  ///
  /// In en, this message translates to:
  /// **'Detected: {count} BIN files'**
  String binMergerDetected(int count);

  /// No description provided for @binMergerButton.
  ///
  /// In en, this message translates to:
  /// **'Merge BINs'**
  String get binMergerButton;

  /// No description provided for @binMergerSuccess.
  ///
  /// In en, this message translates to:
  /// **'Merged: {filename}'**
  String binMergerSuccess(String filename);

  /// No description provided for @headerRemoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Header Remover'**
  String get headerRemoverTitle;

  /// No description provided for @headerRemoverSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get headerRemoverSystem;

  /// No description provided for @headerRemoverFound.
  ///
  /// In en, this message translates to:
  /// **'Header Found'**
  String get headerRemoverFound;

  /// No description provided for @headerRemoverNotFound.
  ///
  /// In en, this message translates to:
  /// **'No Header Found'**
  String get headerRemoverNotFound;

  /// No description provided for @headerRemoverConfidence.
  ///
  /// In en, this message translates to:
  /// **'Confidence'**
  String get headerRemoverConfidence;

  /// No description provided for @headerRemoverBackup.
  ///
  /// In en, this message translates to:
  /// **'Keep backup (.bak)'**
  String get headerRemoverBackup;

  /// No description provided for @headerRemoverButton.
  ///
  /// In en, this message translates to:
  /// **'Remove Header'**
  String get headerRemoverButton;

  /// No description provided for @headerRemoverSuccess.
  ///
  /// In en, this message translates to:
  /// **'Clean ROM: {filename}'**
  String headerRemoverSuccess(String filename);

  /// No description provided for @headerRemoverNoHeader.
  ///
  /// In en, this message translates to:
  /// **'No copier header detected.'**
  String get headerRemoverNoHeader;

  /// No description provided for @dreamcastTitle.
  ///
  /// In en, this message translates to:
  /// **'Dreamcast'**
  String get dreamcastTitle;

  /// No description provided for @dreamcastDcpTab.
  ///
  /// In en, this message translates to:
  /// **'Apply DCP'**
  String get dreamcastDcpTab;

  /// No description provided for @dreamcastIpbinTab.
  ///
  /// In en, this message translates to:
  /// **'IP.BIN Editor'**
  String get dreamcastIpbinTab;

  /// No description provided for @dreamcastGdiTab.
  ///
  /// In en, this message translates to:
  /// **'GDI Info'**
  String get dreamcastGdiTab;

  /// No description provided for @dreamcastDiscDir.
  ///
  /// In en, this message translates to:
  /// **'Disc Directory'**
  String get dreamcastDiscDir;

  /// No description provided for @dreamcastDcpFile.
  ///
  /// In en, this message translates to:
  /// **'DCP Patch File'**
  String get dreamcastDcpFile;

  /// No description provided for @dreamcastOutputDir.
  ///
  /// In en, this message translates to:
  /// **'Output Directory'**
  String get dreamcastOutputDir;

  /// No description provided for @dreamcastApplyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply DCP Patch'**
  String get dreamcastApplyButton;

  /// No description provided for @dreamcastApplySuccess.
  ///
  /// In en, this message translates to:
  /// **'DCP patch applied successfully!'**
  String get dreamcastApplySuccess;

  /// No description provided for @dreamcastIpbinFile.
  ///
  /// In en, this message translates to:
  /// **'IP.BIN or GDI File'**
  String get dreamcastIpbinFile;

  /// No description provided for @dreamcastIpbinLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get dreamcastIpbinLoad;

  /// No description provided for @dreamcastIpbinSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get dreamcastIpbinSave;

  /// No description provided for @dreamcastIpbinTitle.
  ///
  /// In en, this message translates to:
  /// **'Game Title'**
  String get dreamcastIpbinTitle;

  /// No description provided for @dreamcastIpbinProductNumber.
  ///
  /// In en, this message translates to:
  /// **'Product Number'**
  String get dreamcastIpbinProductNumber;

  /// No description provided for @dreamcastIpbinVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get dreamcastIpbinVersion;

  /// No description provided for @dreamcastIpbinDate.
  ///
  /// In en, this message translates to:
  /// **'Release Date'**
  String get dreamcastIpbinDate;

  /// No description provided for @dreamcastIpbinRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get dreamcastIpbinRegion;

  /// No description provided for @dreamcastIpbinRegionJapan.
  ///
  /// In en, this message translates to:
  /// **'Japan'**
  String get dreamcastIpbinRegionJapan;

  /// No description provided for @dreamcastIpbinRegionUSA.
  ///
  /// In en, this message translates to:
  /// **'USA'**
  String get dreamcastIpbinRegionUSA;

  /// No description provided for @dreamcastIpbinRegionEurope.
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get dreamcastIpbinRegionEurope;

  /// No description provided for @dreamcastIpbinRegionFree.
  ///
  /// In en, this message translates to:
  /// **'Region Free'**
  String get dreamcastIpbinRegionFree;

  /// No description provided for @dreamcastIpbinVga.
  ///
  /// In en, this message translates to:
  /// **'Enable VGA'**
  String get dreamcastIpbinVga;

  /// No description provided for @dreamcastIpbinSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'IP.BIN saved successfully!'**
  String get dreamcastIpbinSaveSuccess;

  /// No description provided for @dreamcastGdiFile.
  ///
  /// In en, this message translates to:
  /// **'GDI File'**
  String get dreamcastGdiFile;

  /// No description provided for @dreamcastGdiLoad.
  ///
  /// In en, this message translates to:
  /// **'Load GDI'**
  String get dreamcastGdiLoad;

  /// No description provided for @dreamcastGdiTracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get dreamcastGdiTracks;

  /// No description provided for @dreamcastGdiTrackNum.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get dreamcastGdiTrackNum;

  /// No description provided for @dreamcastGdiTrackLba.
  ///
  /// In en, this message translates to:
  /// **'LBA'**
  String get dreamcastGdiTrackLba;

  /// No description provided for @dreamcastGdiTrackType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get dreamcastGdiTrackType;

  /// No description provided for @dreamcastGdiTrackSize.
  ///
  /// In en, this message translates to:
  /// **'Sector Size'**
  String get dreamcastGdiTrackSize;

  /// No description provided for @dreamcastGdiTrackFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get dreamcastGdiTrackFile;

  /// No description provided for @dreamcastGdiAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get dreamcastGdiAudio;

  /// No description provided for @dreamcastGdiData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get dreamcastGdiData;

  /// No description provided for @dreamcastSameFolder.
  ///
  /// In en, this message translates to:
  /// **'Same folder as source'**
  String get dreamcastSameFolder;

  /// No description provided for @dreamcastBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get dreamcastBrowse;

  /// No description provided for @onlineFeaturesSection.
  ///
  /// In en, this message translates to:
  /// **'Online Features'**
  String get onlineFeaturesSection;

  /// No description provided for @onlineFeaturesSub.
  ///
  /// In en, this message translates to:
  /// **'All features are opt-in. No data is collected without your consent.'**
  String get onlineFeaturesSub;

  /// No description provided for @autoUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates automatically'**
  String get autoUpdateTitle;

  /// No description provided for @autoUpdateSub.
  ///
  /// In en, this message translates to:
  /// **'Checks GitHub on startup for a newer version'**
  String get autoUpdateSub;

  /// No description provided for @autoUpdateCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get autoUpdateCheckNow;

  /// No description provided for @autoUpdateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date ({version})'**
  String autoUpdateUpToDate(String version);

  /// No description provided for @autoUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available: v{version}'**
  String autoUpdateAvailable(String version);

  /// No description provided for @autoUpdateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get autoUpdateDownload;

  /// No description provided for @raSection.
  ///
  /// In en, this message translates to:
  /// **'RetroAchievements'**
  String get raSection;

  /// No description provided for @raEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Enable RetroAchievements hash check'**
  String get raEnabledTitle;

  /// No description provided for @raEnabledSub.
  ///
  /// In en, this message translates to:
  /// **'Checks if your ROM is supported before loading'**
  String get raEnabledSub;

  /// No description provided for @raUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get raUsername;

  /// No description provided for @raApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get raApiKey;

  /// No description provided for @raApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Get your key at retroachievements.org/settings'**
  String get raApiKeyHint;

  /// No description provided for @raHashChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking hash...'**
  String get raHashChecking;

  /// No description provided for @raHashFound.
  ///
  /// In en, this message translates to:
  /// **'✅ Supported — {title} ({count} achievements)'**
  String raHashFound(String title, int count);

  /// No description provided for @raHashNotFound.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Not found on RetroAchievements'**
  String get raHashNotFound;

  /// No description provided for @raHashError.
  ///
  /// In en, this message translates to:
  /// **'Error: {msg}'**
  String raHashError(String msg);

  /// No description provided for @raViewGame.
  ///
  /// In en, this message translates to:
  /// **'View on RA'**
  String get raViewGame;

  /// No description provided for @raSaveCredentials.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get raSaveCredentials;

  /// No description provided for @navPatch.
  ///
  /// In en, this message translates to:
  /// **'Patch'**
  String get navPatch;

  /// No description provided for @navTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get navTools;

  /// No description provided for @navPlugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get navPlugins;

  /// No description provided for @mediaTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized Media Type'**
  String get mediaTypeTitle;

  /// No description provided for @mediaTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Unrecognized Media Type: Is this game a CD or DVD?\n\nFile: {file}'**
  String mediaTypeBody(String file);

  /// No description provided for @mediaCd.
  ///
  /// In en, this message translates to:
  /// **'CD'**
  String get mediaCd;

  /// No description provided for @mediaDvd.
  ///
  /// In en, this message translates to:
  /// **'DVD'**
  String get mediaDvd;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get commonApply;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get commonInstall;

  /// No description provided for @pluginsTabInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed Plugins 📦'**
  String get pluginsTabInstalled;

  /// No description provided for @pluginsTabStore.
  ///
  /// In en, this message translates to:
  /// **'Plugin Store 🌐🛒'**
  String get pluginsTabStore;

  /// No description provided for @pluginsTabStudio.
  ///
  /// In en, this message translates to:
  /// **'Create / Studio 🛠️'**
  String get pluginsTabStudio;

  /// No description provided for @pluginsDropTitle.
  ///
  /// In en, this message translates to:
  /// **'Drag & Drop .orplug Archive Here'**
  String get pluginsDropTitle;

  /// No description provided for @pluginsDropSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Install custom ROM tools, extensions, and formats'**
  String get pluginsDropSubtitle;

  /// No description provided for @pluginsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse .orplug File'**
  String get pluginsBrowse;

  /// No description provided for @pluginsInstalledHeading.
  ///
  /// In en, this message translates to:
  /// **'Installed Plugins ({count})'**
  String pluginsInstalledHeading(int count);

  /// No description provided for @pluginsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Plugins Installed Yet'**
  String get pluginsEmptyTitle;

  /// No description provided for @pluginsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Drop an .orplug package above or explore community plugins in the Plugin Store.'**
  String get pluginsEmptyBody;

  /// No description provided for @pluginsUninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get pluginsUninstall;

  /// No description provided for @pluginsUninstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall Plugin'**
  String get pluginsUninstallTitle;

  /// No description provided for @pluginsUninstallBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to uninstall \"{name}\" ({id})?'**
  String pluginsUninstallBody(String name, String id);

  /// No description provided for @pluginsInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get pluginsInstallFailed;

  /// No description provided for @pluginsAlreadyInstalled.
  ///
  /// In en, this message translates to:
  /// **'{name} is already installed'**
  String pluginsAlreadyInstalled(String name);

  /// No description provided for @pluginsInstalledToast.
  ///
  /// In en, this message translates to:
  /// **'{name} installed'**
  String pluginsInstalledToast(String name);

  /// No description provided for @storeTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin Marketplace'**
  String get storeTitle;

  /// No description provided for @storeRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalogue'**
  String get storeRefresh;

  /// No description provided for @storeSubtitleLive.
  ///
  /// In en, this message translates to:
  /// **'Official and community plugins, served live from the store.'**
  String get storeSubtitleLive;

  /// No description provided for @storeSubtitleCached.
  ///
  /// In en, this message translates to:
  /// **'Showing the last cached catalogue. Reconnect to refresh.'**
  String get storeSubtitleCached;

  /// No description provided for @storeBadgeLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get storeBadgeLive;

  /// No description provided for @storeBadgeOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get storeBadgeOffline;

  /// No description provided for @storeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search plugins, publishers, routes…'**
  String get storeSearchHint;

  /// No description provided for @storeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get storeAll;

  /// No description provided for @storeOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'ROMéo is offline'**
  String get storeOfflineTitle;

  /// No description provided for @storeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No plugins published yet'**
  String get storeEmptyTitle;

  /// No description provided for @storeNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No plugins match your filters'**
  String get storeNoMatchTitle;

  /// No description provided for @storeOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'The store could not be reached and no cached copy exists. Check your connection and refresh.'**
  String get storeOfflineBody;

  /// No description provided for @storeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — new plugins land often.'**
  String get storeEmptyBody;

  /// No description provided for @storeNoMatchBody.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or category.'**
  String get storeNoMatchBody;

  /// No description provided for @storeVerifiedPublisher.
  ///
  /// In en, this message translates to:
  /// **'Verified publisher'**
  String get storeVerifiedPublisher;

  /// No description provided for @storeInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get storeInstalled;

  /// No description provided for @storeByPublisher.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String storeByPublisher(String name);

  /// No description provided for @storeCoreMin.
  ///
  /// In en, this message translates to:
  /// **'core ≥ {version}'**
  String storeCoreMin(String version);

  /// No description provided for @deepLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Install plugin from link?'**
  String get deepLinkTitle;

  /// No description provided for @deepLinkBody.
  ///
  /// In en, this message translates to:
  /// **'An openrom:// link wants to install a plugin. Review it before continuing.'**
  String get deepLinkBody;

  /// No description provided for @deepLinkPlugin.
  ///
  /// In en, this message translates to:
  /// **'Plugin'**
  String get deepLinkPlugin;

  /// No description provided for @deepLinkId.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get deepLinkId;

  /// No description provided for @deepLinkVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get deepLinkVersion;

  /// No description provided for @deepLinkPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get deepLinkPublisher;

  /// No description provided for @deepLinkCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get deepLinkCategory;

  /// No description provided for @deepLinkRequiresCore.
  ///
  /// In en, this message translates to:
  /// **'Requires core'**
  String get deepLinkRequiresCore;

  /// No description provided for @deepLinkVerified.
  ///
  /// In en, this message translates to:
  /// **'The download is verified against the published SHA-256 before installation.'**
  String get deepLinkVerified;

  /// No description provided for @deepLinkNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Plugin not found'**
  String get deepLinkNotFoundTitle;

  /// No description provided for @deepLinkNotFoundBody.
  ///
  /// In en, this message translates to:
  /// **'No plugin with the id \"{id}\" was found in the store catalogue.'**
  String deepLinkNotFoundBody(String id);

  /// No description provided for @studioTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual .orplug Builder Studio'**
  String get studioTitle;

  /// No description provided for @studioIntro.
  ///
  /// In en, this message translates to:
  /// **'Start a new plugin or open an existing project folder.'**
  String get studioIntro;

  /// No description provided for @studioNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get studioNew;

  /// No description provided for @studioOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get studioOpen;

  /// No description provided for @studioRescan.
  ///
  /// In en, this message translates to:
  /// **'Rescan project'**
  String get studioRescan;

  /// No description provided for @studioIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get studioIdentity;

  /// No description provided for @studioPluginId.
  ///
  /// In en, this message translates to:
  /// **'Plugin ID'**
  String get studioPluginId;

  /// No description provided for @studioDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get studioDisplayName;

  /// No description provided for @studioVersion.
  ///
  /// In en, this message translates to:
  /// **'Version (SemVer)'**
  String get studioVersion;

  /// No description provided for @studioMinCore.
  ///
  /// In en, this message translates to:
  /// **'Min Core Version'**
  String get studioMinCore;

  /// No description provided for @studioCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get studioCategory;

  /// No description provided for @studioPublisher.
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get studioPublisher;

  /// No description provided for @studioPublisherId.
  ///
  /// In en, this message translates to:
  /// **'Publisher ID'**
  String get studioPublisherId;

  /// No description provided for @studioPublisherName.
  ///
  /// In en, this message translates to:
  /// **'Publisher Name'**
  String get studioPublisherName;

  /// No description provided for @studioVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get studioVerified;

  /// No description provided for @studioVerifiedTip.
  ///
  /// In en, this message translates to:
  /// **'Verified publishers get the blue check in the store'**
  String get studioVerifiedTip;

  /// No description provided for @studioDescriptionRoutes.
  ///
  /// In en, this message translates to:
  /// **'Description & Routes'**
  String get studioDescriptionRoutes;

  /// No description provided for @studioDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get studioDescription;

  /// No description provided for @studioRouteHint.
  ///
  /// In en, this message translates to:
  /// **'Add route (e.g. ISO -> WUA)'**
  String get studioRouteHint;

  /// No description provided for @studioNoRoutes.
  ///
  /// In en, this message translates to:
  /// **'No routes yet.'**
  String get studioNoRoutes;

  /// No description provided for @studioBinaries.
  ///
  /// In en, this message translates to:
  /// **'Binaries'**
  String get studioBinaries;

  /// No description provided for @studioBinariesHelp.
  ///
  /// In en, this message translates to:
  /// **'Attach one executable per platform. SHA-256 hashes are computed automatically when you save or build.'**
  String get studioBinariesHelp;

  /// No description provided for @studioNotSet.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get studioNotSet;

  /// No description provided for @studioReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get studioReplace;

  /// No description provided for @studioExecutionArgs.
  ///
  /// In en, this message translates to:
  /// **'Execution Arguments'**
  String get studioExecutionArgs;

  /// No description provided for @studioPlaceholders.
  ///
  /// In en, this message translates to:
  /// **'Placeholders: bin (executable) · in (input) · out (output) · outdir (output dir) · cue (cue sheet)'**
  String get studioPlaceholders;

  /// No description provided for @studioArgsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Argument template'**
  String get studioArgsTemplate;

  /// No description provided for @studioBuild.
  ///
  /// In en, this message translates to:
  /// **'Build'**
  String get studioBuild;

  /// No description provided for @studioSaveManifest.
  ///
  /// In en, this message translates to:
  /// **'Save Manifest'**
  String get studioSaveManifest;

  /// No description provided for @studioValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get studioValidate;

  /// No description provided for @studioBuildPackage.
  ///
  /// In en, this message translates to:
  /// **'Build .orplug'**
  String get studioBuildPackage;

  /// No description provided for @studioLastBuild.
  ///
  /// In en, this message translates to:
  /// **'Last build: {path} · sha256 {sha}'**
  String studioLastBuild(String path, String sha);

  /// No description provided for @studioCopyMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Copy marketplace JSON'**
  String get studioCopyMarketplace;

  /// No description provided for @studioMarketplaceCopied.
  ///
  /// In en, this message translates to:
  /// **'Marketplace JSON copied'**
  String get studioMarketplaceCopied;

  /// No description provided for @studioManifestValid.
  ///
  /// In en, this message translates to:
  /// **'Manifest is valid'**
  String get studioManifestValid;

  /// No description provided for @studioValidationIssues.
  ///
  /// In en, this message translates to:
  /// **'Validation issues'**
  String get studioValidationIssues;

  /// No description provided for @studioBuiltTitle.
  ///
  /// In en, this message translates to:
  /// **'Built .orplug'**
  String get studioBuiltTitle;

  /// No description provided for @studioArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get studioArchive;

  /// No description provided for @studioSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get studioSize;

  /// No description provided for @studioSizeBytes.
  ///
  /// In en, this message translates to:
  /// **'{bytes} bytes'**
  String studioSizeBytes(int bytes);

  /// No description provided for @studioMarketplaceEntry.
  ///
  /// In en, this message translates to:
  /// **'Marketplace entry (paste into the store catalogue):'**
  String get studioMarketplaceEntry;

  /// No description provided for @studioCopyJson.
  ///
  /// In en, this message translates to:
  /// **'Copy JSON'**
  String get studioCopyJson;

  /// No description provided for @studioNewProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select where to create the plugin'**
  String get studioNewProjectTitle;

  /// No description provided for @studioOpenProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a plugin project folder'**
  String get studioOpenProjectTitle;

  /// No description provided for @studioDefaultName.
  ///
  /// In en, this message translates to:
  /// **'My Tool'**
  String get studioDefaultName;

  /// No description provided for @themeEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme Editor'**
  String get themeEditorTitle;

  /// No description provided for @themeCustomSkin.
  ///
  /// In en, this message translates to:
  /// **'Custom Skin'**
  String get themeCustomSkin;

  /// No description provided for @themeCustomTheme.
  ///
  /// In en, this message translates to:
  /// **'Custom Theme'**
  String get themeCustomTheme;

  /// No description provided for @themeThemeName.
  ///
  /// In en, this message translates to:
  /// **'Theme Name'**
  String get themeThemeName;

  /// No description provided for @themePickWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Choose a wallpaper (GIF, PNG, JPG or WebP)'**
  String get themePickWallpaper;

  /// No description provided for @themePickDropzone.
  ///
  /// In en, this message translates to:
  /// **'Choose a dropzone illustration (GIF or PNG)'**
  String get themePickDropzone;

  /// No description provided for @themePickFont.
  ///
  /// In en, this message translates to:
  /// **'Choose a UI font (TTF or OTF)'**
  String get themePickFont;

  /// No description provided for @themeImportSkinBundle.
  ///
  /// In en, this message translates to:
  /// **'Import an .orskin bundle'**
  String get themeImportSkinBundle;

  /// No description provided for @themeExportSkinBundle.
  ///
  /// In en, this message translates to:
  /// **'Export .orskin bundle'**
  String get themeExportSkinBundle;

  /// No description provided for @themeImportShort.
  ///
  /// In en, this message translates to:
  /// **'Import .orskin'**
  String get themeImportShort;

  /// No description provided for @themeExportShort.
  ///
  /// In en, this message translates to:
  /// **'Export .orskin'**
  String get themeExportShort;

  /// No description provided for @themeImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String themeImportFailed(String error);

  /// No description provided for @themeExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String themeExportFailed(String error);

  /// No description provided for @themeImported.
  ///
  /// In en, this message translates to:
  /// **'Imported skin \"{name}\"'**
  String themeImported(String name);

  /// No description provided for @themeExported.
  ///
  /// In en, this message translates to:
  /// **'Exported {path}'**
  String themeExported(String path);

  /// No description provided for @themePickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick Color'**
  String get themePickColor;

  /// No description provided for @themeHue.
  ///
  /// In en, this message translates to:
  /// **'Hue'**
  String get themeHue;

  /// No description provided for @themeSaturation.
  ///
  /// In en, this message translates to:
  /// **'Saturation'**
  String get themeSaturation;

  /// No description provided for @themeValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get themeValue;

  /// No description provided for @themeColors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get themeColors;

  /// No description provided for @themeBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get themeBackground;

  /// No description provided for @themeSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get themeSurface;

  /// No description provided for @themeAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get themeAccent;

  /// No description provided for @themeTextPrimary.
  ///
  /// In en, this message translates to:
  /// **'Text Primary'**
  String get themeTextPrimary;

  /// No description provided for @themeTextSecondary.
  ///
  /// In en, this message translates to:
  /// **'Text Secondary'**
  String get themeTextSecondary;

  /// No description provided for @themeSidebarBg.
  ///
  /// In en, this message translates to:
  /// **'Sidebar Background'**
  String get themeSidebarBg;

  /// No description provided for @themeCardBg.
  ///
  /// In en, this message translates to:
  /// **'Card Background'**
  String get themeCardBg;

  /// No description provided for @themeTerminalBg.
  ///
  /// In en, this message translates to:
  /// **'Terminal Background'**
  String get themeTerminalBg;

  /// No description provided for @themeTerminalText.
  ///
  /// In en, this message translates to:
  /// **'Terminal Text'**
  String get themeTerminalText;

  /// No description provided for @themeGeometry.
  ///
  /// In en, this message translates to:
  /// **'Skin Geometry & Wallpaper'**
  String get themeGeometry;

  /// No description provided for @themeCornerRadius.
  ///
  /// In en, this message translates to:
  /// **'Corner Radius'**
  String get themeCornerRadius;

  /// No description provided for @themeWallpaperOpacity.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Opacity'**
  String get themeWallpaperOpacity;

  /// No description provided for @themeWallpaperBlur.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper Blur'**
  String get themeWallpaperBlur;

  /// No description provided for @themeChooseWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Choose Wallpaper'**
  String get themeChooseWallpaper;

  /// No description provided for @themeChooseDropzone.
  ///
  /// In en, this message translates to:
  /// **'Choose Dropzone'**
  String get themeChooseDropzone;

  /// No description provided for @themeChooseFont.
  ///
  /// In en, this message translates to:
  /// **'Choose Font'**
  String get themeChooseFont;

  /// No description provided for @themeSidebarTabs.
  ///
  /// In en, this message translates to:
  /// **'Sidebar Tabs'**
  String get themeSidebarTabs;

  /// No description provided for @themeSidebarTabsHelp.
  ///
  /// In en, this message translates to:
  /// **'Uncheck a tab to hide it from the sidebar and navigation.'**
  String get themeSidebarTabsHelp;

  /// No description provided for @themeSaveTheme.
  ///
  /// In en, this message translates to:
  /// **'Save Theme'**
  String get themeSaveTheme;

  /// No description provided for @themeLivePreview.
  ///
  /// In en, this message translates to:
  /// **'Live Preview'**
  String get themeLivePreview;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAudioCodec.
  ///
  /// In en, this message translates to:
  /// **'CD Audio Codec (CHD)'**
  String get settingsAudioCodec;

  /// No description provided for @settingsCodecFlac.
  ///
  /// In en, this message translates to:
  /// **'Lossless (FLAC) - Recommended'**
  String get settingsCodecFlac;

  /// No description provided for @settingsCodecVorbis.
  ///
  /// In en, this message translates to:
  /// **'Max Compression (Vorbis)'**
  String get settingsCodecVorbis;

  /// No description provided for @settingsVerifySub.
  ///
  /// In en, this message translates to:
  /// **'Runs chdman verify on newly created CHD files'**
  String get settingsVerifySub;

  /// No description provided for @settingsSameFolder.
  ///
  /// In en, this message translates to:
  /// **'Same folder as source file'**
  String get settingsSameFolder;

  /// No description provided for @settingsSelectDir.
  ///
  /// In en, this message translates to:
  /// **'Select directory...'**
  String get settingsSelectDir;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error checking for updates'**
  String get settingsUpdateError;

  /// No description provided for @settingsRaSaved.
  ///
  /// In en, this message translates to:
  /// **'RetroAchievements credentials saved'**
  String get settingsRaSaved;

  /// No description provided for @settingsHasheous.
  ///
  /// In en, this message translates to:
  /// **'Hasheous'**
  String get settingsHasheous;

  /// No description provided for @settingsHasheousEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Hasheous hash lookup'**
  String get settingsHasheousEnable;

  /// No description provided for @settingsHasheousSub.
  ///
  /// In en, this message translates to:
  /// **'Identifies games by transmitting the ROM SHA-1 to hasheous.org. Off by default; only your file hash is sent.'**
  String get settingsHasheousSub;

  /// No description provided for @batchTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Complete! 🎉'**
  String get batchTitle;

  /// No description provided for @batchSaved.
  ///
  /// In en, this message translates to:
  /// **'You just saved {amount}'**
  String batchSaved(String amount);

  /// No description provided for @batchSavedDetail.
  ///
  /// In en, this message translates to:
  /// **'({percent} reduction) across {count} {count, plural, =1{game} other{games}}!'**
  String batchSavedDetail(String percent, int count);

  /// No description provided for @batchAllProcessed.
  ///
  /// In en, this message translates to:
  /// **'All {count} {count, plural, =1{file} other{files}} processed successfully!'**
  String batchAllProcessed(int count);

  /// No description provided for @batchAwesome.
  ///
  /// In en, this message translates to:
  /// **'Awesome!'**
  String get batchAwesome;

  /// No description provided for @hasheousUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown title'**
  String get hasheousUnknown;

  /// No description provided for @hasheousMore.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String hasheousMore(int count);

  /// No description provided for @hasheousVerifiedIn.
  ///
  /// In en, this message translates to:
  /// **'Verified in {source}'**
  String hasheousVerifiedIn(String source);

  /// No description provided for @hasheousNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match found in preservation databases.'**
  String get hasheousNoMatch;

  /// No description provided for @toolsTabCue.
  ///
  /// In en, this message translates to:
  /// **'CUE Editor'**
  String get toolsTabCue;

  /// No description provided for @toolsTabRenamer.
  ///
  /// In en, this message translates to:
  /// **'ROM Renamer'**
  String get toolsTabRenamer;

  /// No description provided for @toolsTab1g1r.
  ///
  /// In en, this message translates to:
  /// **'1G1R Cleaner'**
  String get toolsTab1g1r;

  /// No description provided for @toolsTabHasher.
  ///
  /// In en, this message translates to:
  /// **'ROM Hasher'**
  String get toolsTabHasher;

  /// No description provided for @toolsWatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch Folder'**
  String get toolsWatchTitle;

  /// No description provided for @toolsArcadeTitle.
  ///
  /// In en, this message translates to:
  /// **'Arcade / MAME'**
  String get toolsArcadeTitle;

  /// No description provided for @toolsHasherIntro.
  ///
  /// In en, this message translates to:
  /// **'Compute CRC32, MD5, SHA-1 and SHA-256 in a single streaming pass.'**
  String get toolsHasherIntro;

  /// No description provided for @toolsHasherDrop.
  ///
  /// In en, this message translates to:
  /// **'Drag & drop a ROM here, or click to browse'**
  String get toolsHasherDrop;

  /// No description provided for @toolsChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get toolsChooseFile;

  /// No description provided for @toolsComputeHashes.
  ///
  /// In en, this message translates to:
  /// **'Compute Hashes'**
  String get toolsComputeHashes;

  /// No description provided for @toolsResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get toolsResults;

  /// No description provided for @toolsCopyAll.
  ///
  /// In en, this message translates to:
  /// **'Copy All'**
  String get toolsCopyAll;

  /// No description provided for @toolsFileSize.
  ///
  /// In en, this message translates to:
  /// **'File Size'**
  String get toolsFileSize;

  /// No description provided for @toolsIdentifying.
  ///
  /// In en, this message translates to:
  /// **'Identifying…'**
  String get toolsIdentifying;

  /// No description provided for @toolsIdentifyGame.
  ///
  /// In en, this message translates to:
  /// **'Identify Game (Hasheous)'**
  String get toolsIdentifyGame;

  /// No description provided for @toolsHasheousHint.
  ///
  /// In en, this message translates to:
  /// **'Sends the file SHA-1 to hasheous.org. Enable in Settings → Online Features.'**
  String get toolsHasheousHint;

  /// No description provided for @toolsWatchStopped.
  ///
  /// In en, this message translates to:
  /// **'Watch stopped.'**
  String get toolsWatchStopped;

  /// No description provided for @toolsWatchNeedFolders.
  ///
  /// In en, this message translates to:
  /// **'Select both an input and an output folder first.'**
  String get toolsWatchNeedFolders;

  /// No description provided for @toolsChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose folder…'**
  String get toolsChooseFolder;

  /// No description provided for @toolsWatchIntro.
  ///
  /// In en, this message translates to:
  /// **'Automatically convert ROMs as they land in a folder.'**
  String get toolsWatchIntro;

  /// No description provided for @toolsInputFolder.
  ///
  /// In en, this message translates to:
  /// **'Input Folder'**
  String get toolsInputFolder;

  /// No description provided for @toolsOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Output Folder'**
  String get toolsOutputFolder;

  /// No description provided for @toolsTargetFormat.
  ///
  /// In en, this message translates to:
  /// **'Target Format'**
  String get toolsTargetFormat;

  /// No description provided for @toolsDeleteSource.
  ///
  /// In en, this message translates to:
  /// **'Delete source after conversion'**
  String get toolsDeleteSource;

  /// No description provided for @toolsStopWatching.
  ///
  /// In en, this message translates to:
  /// **'Stop Watching'**
  String get toolsStopWatching;

  /// No description provided for @toolsStartWatching.
  ///
  /// In en, this message translates to:
  /// **'Start Watching'**
  String get toolsStartWatching;

  /// No description provided for @toolsActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get toolsActive;

  /// No description provided for @toolsLiveLog.
  ///
  /// In en, this message translates to:
  /// **'Live Log'**
  String get toolsLiveLog;

  /// No description provided for @toolsNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get toolsNoActivity;

  /// No description provided for @themeSaved.
  ///
  /// In en, this message translates to:
  /// **'Theme \"{name}\" saved!'**
  String themeSaved(String name);
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
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
