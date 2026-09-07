// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'ユニバーサルROM変換スイート';

  @override
  String get convertButton => '変換';

  @override
  String convertButtonWithCount(int count) {
    return '変換 ($count個のファイル)';
  }

  @override
  String get dropZoneHint => 'ここにROMファイルをドラッグ＆ドロップ';

  @override
  String get dropZoneSubHint => 'またはクリックして参照';

  @override
  String get settingsTitle => '変換設定';

  @override
  String get outputFormat => '出力形式';

  @override
  String get compressionLevel => '圧縮レベル';

  @override
  String get compressionNormal => '標準';

  @override
  String get compressionHigh => '高圧縮';

  @override
  String get compressionMax => '最大';

  @override
  String get postProcessing => '後処理';

  @override
  String get verifyAfterConversion => '変換後に検証する';

  @override
  String get outputDestination => '出力先';

  @override
  String get browse => '参照';

  @override
  String get statusWaiting => '待機中...';

  @override
  String get statusConverting => '変換中...';

  @override
  String get statusDone => '完了';

  @override
  String get statusFailed => '失敗';

  @override
  String get aboutTitle => 'OpenROM について';

  @override
  String get settingsScreen => '設定';

  @override
  String get aboutScreen => '情報';

  @override
  String get themeScreen => 'テーマ';

  @override
  String get errorCoreNotFound =>
      'openrom-core が見つかりません。完全なZIPファイルを再ダウンロードしてください。';

  @override
  String get errorUnsupportedFormat => 'このファイル形式はサポートされていません。';

  @override
  String get errorDiskSpace => '変換に必要なディスク容量が不足しています。';

  @override
  String get errorConversionFailed => '変換に失敗しました。ROMファイルが破損している可能性があります。';

  @override
  String get retryButton => '再試行';

  @override
  String get closeButton => '閉じる';

  @override
  String get reportBugButton => 'バグを報告';

  @override
  String get clearQueue => 'キューをクリア';

  @override
  String get removeFile => '削除';

  @override
  String get openOutputFolder => '出力フォルダを開く';
}
