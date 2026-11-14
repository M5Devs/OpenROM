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
  String get errorToolFailed => '変換ツール (chdman/maxcso) が予期せず終了しました。';

  @override
  String get errorConversionFailed => '変換に失敗しました。ROMファイルが破損している可能性があります。';

  @override
  String get errorFileNotFound => '入力ファイルが移動または削除されました。';

  @override
  String get errorOutputDirNotFound => '選択された出力フォルダが存在しません。';

  @override
  String get errorPermissionDenied => '出力フォルダへの書き込み権限がありません。';

  @override
  String get errorCorruptedFile => 'ファイルが破損しているか0バイトです。';

  @override
  String get errorUnknown => '予期しないエラーが発生しました。';

  @override
  String get errorDetailsLabel => '詳細';

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

  @override
  String get patcherTitle => 'ROMパッチャー';

  @override
  String get patcherRomFile => 'ROMファイル';

  @override
  String get patcherPatchFile => 'パッチファイル';

  @override
  String get patcherOutputFile => '出力ファイル';

  @override
  String get patcherSameFolder => 'ROMと同じフォルダ';

  @override
  String get patcherIgnoreChecksum => 'チェックサムエラーを無視';

  @override
  String get patcherApplyButton => 'パッチを適用';

  @override
  String get patcherSuccess => 'パッチの適用に成功しました！';

  @override
  String get patcherFormat => 'フォーマット';

  @override
  String get patcherChecksumPassed => '合格';

  @override
  String get patcherChecksumSkipped => 'スキップ';

  @override
  String get patcherDropHint => 'ここにROMとパッチファイルをドロップ';

  @override
  String get toolsTitle => 'ツール';

  @override
  String get compressorTitle => 'ROM 圧縮ツール';

  @override
  String get compressorAddFiles => 'ファイルを追加';

  @override
  String get compressorAddFolder => 'フォルダを追加';

  @override
  String get compressorOutputFormat => '出力フォーマット';

  @override
  String get compressorLevel => '圧縮レベル';

  @override
  String get compressorLevelFast => '高速';

  @override
  String get compressorLevelNormal => '標準';

  @override
  String get compressorLevelUltra => '最高';

  @override
  String get compressorDeleteSource => '完了後に元ファイルを削除';

  @override
  String get compressorSameFolder => '元ファイルと同じフォルダ';

  @override
  String compressorButton(int count) {
    return '圧縮 ($count 個のファイル)';
  }

  @override
  String get compressorSkipped => 'スキップ (圧縮済み)';

  @override
  String get m3uTitle => 'M3U プレイリスト生成';

  @override
  String get m3uDropHint => 'ディスクファイルをここにドロップ';

  @override
  String get m3uOutputLabel => '出力フォルダ';

  @override
  String get m3uButton => 'M3U を生成';

  @override
  String m3uSuccess(String filename) {
    return '作成完了: $filename';
  }

  @override
  String get cueGeneratorTitle => 'CUE 生成';

  @override
  String get cueGeneratorBinFile => 'BIN ファイル';

  @override
  String get cueGeneratorDetectedMode => '検出されたモード';

  @override
  String get cueGeneratorButton => 'CUE を生成';

  @override
  String cueGeneratorSuccess(String filename) {
    return '作成完了: $filename';
  }

  @override
  String get binMergerTitle => 'BIN 結合';

  @override
  String get binMergerCueFile => 'CUE ファイル (マルチトラック)';

  @override
  String binMergerDetected(int count) {
    return '検出: $count 個の BIN ファイル';
  }

  @override
  String get binMergerButton => 'BIN を結合';

  @override
  String binMergerSuccess(String filename) {
    return '結合完了: $filename';
  }

  @override
  String get headerRemoverTitle => 'ヘッダー削除';

  @override
  String get headerRemoverSystem => 'システム';

  @override
  String get headerRemoverFound => 'ヘッダー検出';

  @override
  String get headerRemoverNotFound => 'ヘッダーなし';

  @override
  String get headerRemoverConfidence => '信頼度';

  @override
  String get headerRemoverBackup => 'バックアップを保持 (.bak)';

  @override
  String get headerRemoverButton => 'ヘッダーを削除';

  @override
  String headerRemoverSuccess(String filename) {
    return 'クリーン ROM: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'コピアヘッダーは検出されませんでした。';

  @override
  String get dreamcastTitle => 'ドリームキャスト';

  @override
  String get dreamcastDcpTab => 'DCP適用';

  @override
  String get dreamcastIpbinTab => 'IP.BINエディター';

  @override
  String get dreamcastGdiTab => 'GDI情報';

  @override
  String get dreamcastDiscDir => 'ディスクディレクトリ';

  @override
  String get dreamcastDcpFile => 'DCPパッチファイル';

  @override
  String get dreamcastOutputDir => '出力ディレクトリ';

  @override
  String get dreamcastApplyButton => 'DCPパッチを適用';

  @override
  String get dreamcastApplySuccess => 'DCPパッチが正常に適用されました！';

  @override
  String get dreamcastIpbinFile => 'IP.BINまたはGDIファイル';

  @override
  String get dreamcastIpbinLoad => '読み込み';

  @override
  String get dreamcastIpbinSave => '変更を保存';

  @override
  String get dreamcastIpbinTitle => 'ゲームタイトル';

  @override
  String get dreamcastIpbinProductNumber => '製品番号';

  @override
  String get dreamcastIpbinVersion => 'バージョン';

  @override
  String get dreamcastIpbinDate => '発売日';

  @override
  String get dreamcastIpbinRegion => 'リージョン';

  @override
  String get dreamcastIpbinRegionJapan => '日本';

  @override
  String get dreamcastIpbinRegionUSA => '北米';

  @override
  String get dreamcastIpbinRegionEurope => '欧州';

  @override
  String get dreamcastIpbinRegionFree => 'リージョンフリー';

  @override
  String get dreamcastIpbinVga => 'VGAを有効化';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BINが正常に保存されました！';

  @override
  String get dreamcastGdiFile => 'GDIファイル';

  @override
  String get dreamcastGdiLoad => 'GDI読み込み';

  @override
  String get dreamcastGdiTracks => 'トラック';

  @override
  String get dreamcastGdiTrackNum => 'トラック';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'タイプ';

  @override
  String get dreamcastGdiTrackSize => 'セクターサイズ';

  @override
  String get dreamcastGdiTrackFile => 'ファイル';

  @override
  String get dreamcastGdiAudio => 'オーディオ';

  @override
  String get dreamcastGdiData => 'データ';

  @override
  String get dreamcastSameFolder => 'ソースと同じフォルダー';

  @override
  String get dreamcastBrowse => '参照';

  @override
  String get onlineFeaturesSection => 'オンライン機能';

  @override
  String get onlineFeaturesSub => 'すべての機能はオプトインです。同意なしにデータが収集されることはありません。';

  @override
  String get autoUpdateTitle => '自動的に更新を確認する';

  @override
  String get autoUpdateSub => '起動時にGitHubで新しいバージョンを確認します';

  @override
  String get autoUpdateCheckNow => '今すぐ確認';

  @override
  String autoUpdateUpToDate(String version) {
    return '最新バージョンです ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return '利用可能なアップデート: v$version';
  }

  @override
  String get autoUpdateDownload => 'ダウンロード';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle => 'RetroAchievements ハッシュチェックを有効化';

  @override
  String get raEnabledSub => '読み込む前にROMがサポートされているか確認します';

  @override
  String get raUsername => 'ユーザー名';

  @override
  String get raApiKey => 'APIキー';

  @override
  String get raApiKeyHint => 'retroachievements.org/settings でキーを取得';

  @override
  String get raHashChecking => 'ハッシュをチェック中...';

  @override
  String raHashFound(String title, int count) {
    return '✅ サポート済み — $title ($count 実績)';
  }

  @override
  String get raHashNotFound => '⚠️ RetroAchievements で見つかりません';

  @override
  String raHashError(String msg) {
    return 'エラー: $msg';
  }

  @override
  String get raViewGame => 'RAで表示';

  @override
  String get raSaveCredentials => '保存';

  @override
  String get navPatch => 'Patch';

  @override
  String get navTools => 'Tools';

  @override
  String get navPlugins => 'Plugins';

  @override
  String get mediaTypeTitle => 'Unrecognized Media Type';

  @override
  String mediaTypeBody(String file) {
    return 'Unrecognized Media Type: Is this game a CD or DVD?\n\nFile: $file';
  }

  @override
  String get mediaCd => 'CD';

  @override
  String get mediaDvd => 'DVD';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonDone => 'Done';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonInstall => 'Install';

  @override
  String get pluginsTabInstalled => 'Installed Plugins 📦';

  @override
  String get pluginsTabStore => 'Plugin Store 🌐🛒';

  @override
  String get pluginsTabStudio => 'Create / Studio 🛠️';

  @override
  String get pluginsDropTitle => 'Drag & Drop .orplug Archive Here';

  @override
  String get pluginsDropSubtitle =>
      'Install custom ROM tools, extensions, and formats';

  @override
  String get pluginsBrowse => 'Browse .orplug File';

  @override
  String pluginsInstalledHeading(int count) {
    return 'Installed Plugins ($count)';
  }

  @override
  String get pluginsEmptyTitle => 'No Plugins Installed Yet';

  @override
  String get pluginsEmptyBody =>
      'Drop an .orplug package above or explore community plugins in the Plugin Store.';

  @override
  String get pluginsUninstall => 'Uninstall';

  @override
  String get pluginsUninstallTitle => 'Uninstall Plugin';

  @override
  String pluginsUninstallBody(String name, String id) {
    return 'Are you sure you want to uninstall \"$name\" ($id)?';
  }

  @override
  String get pluginsInstallFailed => 'Install failed';

  @override
  String pluginsAlreadyInstalled(String name) {
    return '$name is already installed';
  }

  @override
  String pluginsInstalledToast(String name) {
    return '$name installed';
  }

  @override
  String get storeTitle => 'Plugin Marketplace';

  @override
  String get storeRefresh => 'Refresh catalogue';

  @override
  String get storeSubtitleLive =>
      'Official and community plugins, served live from the store.';

  @override
  String get storeSubtitleCached =>
      'Showing the last cached catalogue. Reconnect to refresh.';

  @override
  String get storeBadgeLive => 'Live';

  @override
  String get storeBadgeOffline => 'Offline';

  @override
  String get storeSearchHint => 'Search plugins, publishers, routes…';

  @override
  String get storeAll => 'All';

  @override
  String get storeOfflineTitle => 'ROMéo is offline';

  @override
  String get storeEmptyTitle => 'No plugins published yet';

  @override
  String get storeNoMatchTitle => 'No plugins match your filters';

  @override
  String get storeOfflineBody =>
      'The store could not be reached and no cached copy exists. Check your connection and refresh.';

  @override
  String get storeEmptyBody => 'Check back soon — new plugins land often.';

  @override
  String get storeNoMatchBody => 'Try a different search term or category.';

  @override
  String get storeVerifiedPublisher => 'Verified publisher';

  @override
  String get storeInstalled => 'Installed';

  @override
  String storeByPublisher(String name) {
    return 'by $name';
  }

  @override
  String storeCoreMin(String version) {
    return 'core ≥ $version';
  }

  @override
  String get deepLinkTitle => 'Install plugin from link?';

  @override
  String get deepLinkBody =>
      'An openrom:// link wants to install a plugin. Review it before continuing.';

  @override
  String get deepLinkPlugin => 'Plugin';

  @override
  String get deepLinkId => 'ID';

  @override
  String get deepLinkVersion => 'Version';

  @override
  String get deepLinkPublisher => 'Publisher';

  @override
  String get deepLinkCategory => 'Category';

  @override
  String get deepLinkRequiresCore => 'Requires core';

  @override
  String get deepLinkVerified =>
      'The download is verified against the published SHA-256 before installation.';

  @override
  String get deepLinkNotFoundTitle => 'Plugin not found';

  @override
  String deepLinkNotFoundBody(String id) {
    return 'No plugin with the id \"$id\" was found in the store catalogue.';
  }

  @override
  String get studioTitle => 'Visual .orplug Builder Studio';

  @override
  String get studioIntro =>
      'Start a new plugin or open an existing project folder.';

  @override
  String get studioNew => 'New';

  @override
  String get studioOpen => 'Open';

  @override
  String get studioRescan => 'Rescan project';

  @override
  String get studioIdentity => 'Identity';

  @override
  String get studioPluginId => 'Plugin ID';

  @override
  String get studioDisplayName => 'Display Name';

  @override
  String get studioVersion => 'Version (SemVer)';

  @override
  String get studioMinCore => 'Min Core Version';

  @override
  String get studioCategory => 'Category';

  @override
  String get studioPublisher => 'Publisher';

  @override
  String get studioPublisherId => 'Publisher ID';

  @override
  String get studioPublisherName => 'Publisher Name';

  @override
  String get studioVerified => 'Verified';

  @override
  String get studioVerifiedTip =>
      'Verified publishers get the blue check in the store';

  @override
  String get studioDescriptionRoutes => 'Description & Routes';

  @override
  String get studioDescription => 'Description';

  @override
  String get studioRouteHint => 'Add route (e.g. ISO -> WUA)';

  @override
  String get studioNoRoutes => 'No routes yet.';

  @override
  String get studioBinaries => 'Binaries';

  @override
  String get studioBinariesHelp =>
      'Attach one executable per platform. SHA-256 hashes are computed automatically when you save or build.';

  @override
  String get studioNotSet => 'not set';

  @override
  String get studioReplace => 'Replace';

  @override
  String get studioExecutionArgs => 'Execution Arguments';

  @override
  String get studioPlaceholders =>
      'Placeholders: bin (executable) · in (input) · out (output) · outdir (output dir) · cue (cue sheet)';

  @override
  String get studioArgsTemplate => 'Argument template';

  @override
  String get studioBuild => 'Build';

  @override
  String get studioSaveManifest => 'Save Manifest';

  @override
  String get studioValidate => 'Validate';

  @override
  String get studioBuildPackage => 'Build .orplug';

  @override
  String studioLastBuild(String path, String sha) {
    return 'Last build: $path · sha256 $sha';
  }

  @override
  String get studioCopyMarketplace => 'Copy marketplace JSON';

  @override
  String get studioMarketplaceCopied => 'Marketplace JSON copied';

  @override
  String get studioManifestValid => 'Manifest is valid';

  @override
  String get studioValidationIssues => 'Validation issues';

  @override
  String get studioBuiltTitle => 'Built .orplug';

  @override
  String get studioArchive => 'Archive';

  @override
  String get studioSize => 'Size';

  @override
  String studioSizeBytes(int bytes) {
    return '$bytes bytes';
  }

  @override
  String get studioMarketplaceEntry =>
      'Marketplace entry (paste into the store catalogue):';

  @override
  String get studioCopyJson => 'Copy JSON';

  @override
  String get studioNewProjectTitle => 'Select where to create the plugin';

  @override
  String get studioOpenProjectTitle => 'Select a plugin project folder';

  @override
  String get studioDefaultName => 'My Tool';

  @override
  String get themeEditorTitle => 'Theme Editor';

  @override
  String get themeCustomSkin => 'Custom Skin';

  @override
  String get themeCustomTheme => 'Custom Theme';

  @override
  String get themeThemeName => 'Theme Name';

  @override
  String get themePickWallpaper => 'Choose a wallpaper (GIF, PNG, JPG or WebP)';

  @override
  String get themePickDropzone => 'Choose a dropzone illustration (GIF or PNG)';

  @override
  String get themePickFont => 'Choose a UI font (TTF or OTF)';

  @override
  String get themeImportSkinBundle => 'Import an .orskin bundle';

  @override
  String get themeExportSkinBundle => 'Export .orskin bundle';

  @override
  String get themeImportShort => 'Import .orskin';

  @override
  String get themeExportShort => 'Export .orskin';

  @override
  String themeImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String themeExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String themeImported(String name) {
    return 'Imported skin \"$name\"';
  }

  @override
  String themeExported(String path) {
    return 'Exported $path';
  }

  @override
  String get themePickColor => 'Pick Color';

  @override
  String get themeHue => 'Hue';

  @override
  String get themeSaturation => 'Saturation';

  @override
  String get themeValue => 'Value';

  @override
  String get themeColors => 'Colors';

  @override
  String get themeBackground => 'Background';

  @override
  String get themeSurface => 'Surface';

  @override
  String get themeAccent => 'Accent';

  @override
  String get themeTextPrimary => 'Text Primary';

  @override
  String get themeTextSecondary => 'Text Secondary';

  @override
  String get themeSidebarBg => 'Sidebar Background';

  @override
  String get themeCardBg => 'Card Background';

  @override
  String get themeTerminalBg => 'Terminal Background';

  @override
  String get themeTerminalText => 'Terminal Text';

  @override
  String get themeGeometry => 'Skin Geometry & Wallpaper';

  @override
  String get themeCornerRadius => 'Corner Radius';

  @override
  String get themeWallpaperOpacity => 'Wallpaper Opacity';

  @override
  String get themeWallpaperBlur => 'Wallpaper Blur';

  @override
  String get themeChooseWallpaper => 'Choose Wallpaper';

  @override
  String get themeChooseDropzone => 'Choose Dropzone';

  @override
  String get themeChooseFont => 'Choose Font';

  @override
  String get themeSidebarTabs => 'Sidebar Tabs';

  @override
  String get themeSidebarTabsHelp =>
      'Uncheck a tab to hide it from the sidebar and navigation.';

  @override
  String get themeSaveTheme => 'Save Theme';

  @override
  String get themeLivePreview => 'Live Preview';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAudioCodec => 'CD Audio Codec (CHD)';

  @override
  String get settingsCodecFlac => 'Lossless (FLAC) - Recommended';

  @override
  String get settingsCodecVorbis => 'Max Compression (Vorbis)';

  @override
  String get settingsVerifySub =>
      'Runs chdman verify on newly created CHD files';

  @override
  String get settingsSameFolder => 'Same folder as source file';

  @override
  String get settingsSelectDir => 'Select directory...';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsUpdateError => 'Error checking for updates';

  @override
  String get settingsRaSaved => 'RetroAchievements credentials saved';

  @override
  String get settingsHasheous => 'Hasheous';

  @override
  String get settingsHasheousEnable => 'Enable Hasheous hash lookup';

  @override
  String get settingsHasheousSub =>
      'Identifies games by transmitting the ROM SHA-1 to hasheous.org. Off by default; only your file hash is sent.';

  @override
  String get batchTitle => 'Batch Complete! 🎉';

  @override
  String batchSaved(String amount) {
    return 'You just saved $amount';
  }

  @override
  String batchSavedDetail(String percent, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'games',
      one: 'game',
    );
    return '($percent reduction) across $count $_temp0!';
  }

  @override
  String batchAllProcessed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'files',
      one: 'file',
    );
    return 'All $count $_temp0 processed successfully!';
  }

  @override
  String get batchAwesome => 'Awesome!';

  @override
  String get hasheousUnknown => 'Unknown title';

  @override
  String hasheousMore(int count) {
    return '+ $count more';
  }

  @override
  String hasheousVerifiedIn(String source) {
    return 'Verified in $source';
  }

  @override
  String get hasheousNoMatch => 'No match found in preservation databases.';

  @override
  String get toolsTabCue => 'CUE Editor';

  @override
  String get toolsTabRenamer => 'ROM Renamer';

  @override
  String get toolsTab1g1r => '1G1R Cleaner';

  @override
  String get toolsTabHasher => 'ROM Hasher';

  @override
  String get toolsWatchTitle => 'Watch Folder';

  @override
  String get toolsArcadeTitle => 'Arcade / MAME';

  @override
  String get toolsHasherIntro =>
      'Compute CRC32, MD5, SHA-1 and SHA-256 in a single streaming pass.';

  @override
  String get toolsHasherDrop => 'Drag & drop a ROM here, or click to browse';

  @override
  String get toolsChooseFile => 'Choose File';

  @override
  String get toolsComputeHashes => 'Compute Hashes';

  @override
  String get toolsResults => 'Results';

  @override
  String get toolsCopyAll => 'Copy All';

  @override
  String get toolsFileSize => 'File Size';

  @override
  String get toolsIdentifying => 'Identifying…';

  @override
  String get toolsIdentifyGame => 'Identify Game (Hasheous)';

  @override
  String get toolsHasheousHint =>
      'Sends the file SHA-1 to hasheous.org. Enable in Settings → Online Features.';

  @override
  String get toolsWatchStopped => 'Watch stopped.';

  @override
  String get toolsWatchNeedFolders =>
      'Select both an input and an output folder first.';

  @override
  String get toolsChooseFolder => 'Choose folder…';

  @override
  String get toolsWatchIntro =>
      'Automatically convert ROMs as they land in a folder.';

  @override
  String get toolsInputFolder => 'Input Folder';

  @override
  String get toolsOutputFolder => 'Output Folder';

  @override
  String get toolsTargetFormat => 'Target Format';

  @override
  String get toolsDeleteSource => 'Delete source after conversion';

  @override
  String get toolsStopWatching => 'Stop Watching';

  @override
  String get toolsStartWatching => 'Start Watching';

  @override
  String get toolsActive => 'Active';

  @override
  String get toolsLiveLog => 'Live Log';

  @override
  String get toolsNoActivity => 'No activity yet.';

  @override
  String themeSaved(String name) {
    return 'Theme \"$name\" saved!';
  }
}
