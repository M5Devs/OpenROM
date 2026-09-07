// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Universal ROM Conversion Suite';

  @override
  String get convertButton => 'Convert';

  @override
  String convertButtonWithCount(int count) {
    return 'Convert ($count Files)';
  }

  @override
  String get dropZoneHint => 'Drag & Drop ROM files here';

  @override
  String get dropZoneSubHint => 'or Click to browse';

  @override
  String get settingsTitle => 'Conversion Settings';

  @override
  String get outputFormat => 'Output Format';

  @override
  String get compressionLevel => 'Compression Level';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'High';

  @override
  String get compressionMax => 'Max';

  @override
  String get postProcessing => 'Post-Processing';

  @override
  String get verifyAfterConversion => 'Verify after conversion';

  @override
  String get outputDestination => 'Output Destination';

  @override
  String get browse => 'Browse';

  @override
  String get statusWaiting => 'Waiting...';

  @override
  String get statusConverting => 'Converting...';

  @override
  String get statusDone => 'Done';

  @override
  String get statusFailed => 'Failed';

  @override
  String get aboutTitle => 'About OpenROM';

  @override
  String get settingsScreen => 'Settings';

  @override
  String get aboutScreen => 'About';

  @override
  String get themeScreen => 'Themes';

  @override
  String get errorCoreNotFound =>
      'openrom-core not found. Please re-download the full ZIP.';

  @override
  String get errorUnsupportedFormat => 'This file format is not supported.';

  @override
  String get errorDiskSpace => 'Not enough disk space for this conversion.';

  @override
  String get errorConversionFailed =>
      'Conversion failed. The ROM file might be corrupted.';

  @override
  String get retryButton => 'Retry';

  @override
  String get closeButton => 'Close';

  @override
  String get reportBugButton => 'Report Bug';

  @override
  String get clearQueue => 'Clear Queue';

  @override
  String get removeFile => 'Remove';

  @override
  String get openOutputFolder => 'Open Output Folder';
}
