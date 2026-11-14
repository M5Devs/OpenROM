// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

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

  @override
  String get cueGeneratorTitle => 'CUE Generator';

  @override
  String get cueGeneratorBinFile => 'BIN File';

  @override
  String get cueGeneratorDetectedMode => 'Detected mode';

  @override
  String get cueGeneratorButton => 'Generate CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'Created: $filename';
  }

  @override
  String get binMergerTitle => 'BIN Merger';

  @override
  String get binMergerCueFile => 'CUE File (multi-track)';

  @override
  String binMergerDetected(int count) {
    return 'Detected: $count BIN files';
  }

  @override
  String get binMergerButton => 'Merge BINs';

  @override
  String binMergerSuccess(String filename) {
    return 'Merged: $filename';
  }

  @override
  String get headerRemoverTitle => 'Header Remover';

  @override
  String get headerRemoverSystem => 'System';

  @override
  String get headerRemoverFound => 'Header Found';

  @override
  String get headerRemoverNotFound => 'No Header Found';

  @override
  String get headerRemoverConfidence => 'Confidence';

  @override
  String get headerRemoverBackup => 'Keep backup (.bak)';

  @override
  String get headerRemoverButton => 'Remove Header';

  @override
  String headerRemoverSuccess(String filename) {
    return 'Clean ROM: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'No copier header detected.';

  @override
  String get dreamcastTitle => 'Dreamcast';

  @override
  String get dreamcastDcpTab => 'Apply DCP';

  @override
  String get dreamcastIpbinTab => 'IP.BIN Editor';

  @override
  String get dreamcastGdiTab => 'GDI Info';

  @override
  String get dreamcastDiscDir => 'Disc Directory';

  @override
  String get dreamcastDcpFile => 'DCP Patch File';

  @override
  String get dreamcastOutputDir => 'Output Directory';

  @override
  String get dreamcastApplyButton => 'Apply DCP Patch';

  @override
  String get dreamcastApplySuccess => 'DCP patch applied successfully!';

  @override
  String get dreamcastIpbinFile => 'IP.BIN or GDI File';

  @override
  String get dreamcastIpbinLoad => 'Load';

  @override
  String get dreamcastIpbinSave => 'Save Changes';

  @override
  String get dreamcastIpbinTitle => 'Game Title';

  @override
  String get dreamcastIpbinProductNumber => 'Product Number';

  @override
  String get dreamcastIpbinVersion => 'Version';

  @override
  String get dreamcastIpbinDate => 'Release Date';

  @override
  String get dreamcastIpbinRegion => 'Region';

  @override
  String get dreamcastIpbinRegionJapan => 'Japan';

  @override
  String get dreamcastIpbinRegionUSA => 'USA';

  @override
  String get dreamcastIpbinRegionEurope => 'Europe';

  @override
  String get dreamcastIpbinRegionFree => 'Region Free';

  @override
  String get dreamcastIpbinVga => 'Enable VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BIN saved successfully!';

  @override
  String get dreamcastGdiFile => 'GDI File';

  @override
  String get dreamcastGdiLoad => 'Load GDI';

  @override
  String get dreamcastGdiTracks => 'Tracks';

  @override
  String get dreamcastGdiTrackNum => 'Track';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'Type';

  @override
  String get dreamcastGdiTrackSize => 'Sector Size';

  @override
  String get dreamcastGdiTrackFile => 'File';

  @override
  String get dreamcastGdiAudio => 'Audio';

  @override
  String get dreamcastGdiData => 'Data';

  @override
  String get dreamcastSameFolder => 'Same folder as source';

  @override
  String get dreamcastBrowse => 'Browse';

  @override
  String get onlineFeaturesSection => 'Online Features';

  @override
  String get onlineFeaturesSub =>
      'All features are opt-in. No data is collected without your consent.';

  @override
  String get autoUpdateTitle => 'Check for updates automatically';

  @override
  String get autoUpdateSub => 'Checks GitHub on startup for a newer version';

  @override
  String get autoUpdateCheckNow => 'Check now';

  @override
  String autoUpdateUpToDate(String version) {
    return 'You\'re up to date ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return 'Update available: v$version';
  }

  @override
  String get autoUpdateDownload => 'Download';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle => 'Enable RetroAchievements hash check';

  @override
  String get raEnabledSub => 'Checks if your ROM is supported before loading';

  @override
  String get raUsername => 'Username';

  @override
  String get raApiKey => 'API Key';

  @override
  String get raApiKeyHint => 'Get your key at retroachievements.org/settings';

  @override
  String get raHashChecking => 'Checking hash...';

  @override
  String raHashFound(String title, int count) {
    return '✅ Supported — $title ($count achievements)';
  }

  @override
  String get raHashNotFound => '⚠️ Not found on RetroAchievements';

  @override
  String raHashError(String msg) {
    return 'Error: $msg';
  }

  @override
  String get raViewGame => 'View on RA';

  @override
  String get raSaveCredentials => 'Save';

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
