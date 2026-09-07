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
      'openrom-core is missing from the app folder.';

  @override
  String get errorUnsupportedFormat =>
      'This file format cannot be converted with the selected output.';

  @override
  String get errorDiskSpace =>
      'Not enough free space to complete this conversion.';

  @override
  String get errorToolFailed =>
      'The conversion tool (chdman/maxcso) exited unexpectedly.';

  @override
  String get errorConversionFailed => 'Conversion stopped before completing.';

  @override
  String get errorFileNotFound => 'The input file was moved or deleted.';

  @override
  String get errorOutputDirNotFound =>
      'The selected output folder no longer exists.';

  @override
  String get errorPermissionDenied =>
      'OpenROM can\'t write to the output folder.';

  @override
  String get errorCorruptedFile =>
      'The file appears to be corrupted or is 0 bytes.';

  @override
  String get errorUnknown => 'Something went wrong. This might be a bug.';

  @override
  String get errorDetailsLabel => 'Details';

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

  @override
  String get patcherTitle => 'ROM Patcher';

  @override
  String get patcherRomFile => 'ROM File';

  @override
  String get patcherPatchFile => 'Patch File';

  @override
  String get patcherOutputFile => 'Output File';

  @override
  String get patcherSameFolder => 'Same folder as ROM';

  @override
  String get patcherIgnoreChecksum => 'Ignore checksum errors';

  @override
  String get patcherApplyButton => 'Apply Patch';

  @override
  String get patcherSuccess => 'Patched successfully!';

  @override
  String get patcherFormat => 'Format';

  @override
  String get patcherChecksumPassed => 'passed';

  @override
  String get patcherChecksumSkipped => 'skipped';

  @override
  String get patcherDropHint => 'Drop ROM + Patch files here';

  @override
  String get toolsTitle => 'Tools';

  @override
  String get compressorTitle => 'ROM Compressor';

  @override
  String get compressorAddFiles => 'Add Files';

  @override
  String get compressorAddFolder => 'Add Folder';

  @override
  String get compressorOutputFormat => 'Output Format';

  @override
  String get compressorLevel => 'Compression Level';

  @override
  String get compressorLevelFast => 'Fast';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Delete source after done';

  @override
  String get compressorSameFolder => 'Same folder as source';

  @override
  String compressorButton(int count) {
    return 'Compress ($count Files)';
  }

  @override
  String get compressorSkipped => 'Skipped (already compressed)';

  @override
  String get m3uTitle => 'M3U Generator';

  @override
  String get m3uDropHint => 'Drop disc files here';

  @override
  String get m3uOutputLabel => 'Output folder';

  @override
  String get m3uButton => 'Generate M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Created: $filename';
  }
}
