// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'حزمة تحويل ROM الشاملة';

  @override
  String get convertButton => 'تحويل';

  @override
  String convertButtonWithCount(int count) {
    return 'تحويل ($count ملفات)';
  }

  @override
  String get dropZoneHint => 'اسحب وافلت ملفات ROM هنا';

  @override
  String get dropZoneSubHint => 'أو اضغط للتصفح';

  @override
  String get settingsTitle => 'إعدادات التحويل';

  @override
  String get outputFormat => 'صيغة الإخراج';

  @override
  String get compressionLevel => 'مستوى الضغط';

  @override
  String get compressionNormal => 'عادي';

  @override
  String get compressionHigh => 'عالي';

  @override
  String get compressionMax => 'أقصى ضغط';

  @override
  String get postProcessing => 'معالجة بعد التحويل';

  @override
  String get verifyAfterConversion => 'التحقق بعد التحويل';

  @override
  String get outputDestination => 'وجهة الإخراج';

  @override
  String get browse => 'تصفح';

  @override
  String get statusWaiting => 'في الانتظار...';

  @override
  String get statusConverting => 'جاري التحويل...';

  @override
  String get statusDone => 'تم';

  @override
  String get statusFailed => 'فشل';

  @override
  String get aboutTitle => 'عن OpenROM';

  @override
  String get settingsScreen => 'الإعدادات';

  @override
  String get aboutScreen => 'عن التطبيق';

  @override
  String get themeScreen => 'المظاهر';

  @override
  String get errorCoreNotFound =>
      'لم يتم العثور على openrom-core. يرجى إعادة تنزيل الملف المضغوط الكامل.';

  @override
  String get errorUnsupportedFormat => 'صيغة الملف هذه غير مدعومة.';

  @override
  String get errorDiskSpace => 'لا توجد مساحة كافية على القرص لهذا التحويل.';

  @override
  String get errorToolFailed =>
      'تعطلت أداة التحويل (chdman/maxcso) بشكل غير متوقع.';

  @override
  String get errorConversionFailed => 'فشل التحويل. قد يكون ملف ROM تالفًا.';

  @override
  String get errorFileNotFound => 'الملف المدخل تم نقله أو حذفه.';

  @override
  String get errorOutputDirNotFound => 'مجلد الإخراج المحدد لم يعد موجوداً.';

  @override
  String get errorPermissionDenied =>
      'لا يملك OpenROM أذونات الكتابة في مجلد الإخراج.';

  @override
  String get errorCorruptedFile => 'يبدو أن الملف تالف أو بحجم 0 بايت.';

  @override
  String get errorUnknown => 'حدث خطأ غير متوقع.';

  @override
  String get errorDetailsLabel => 'التفاصيل';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get reportBugButton => 'الإبلاغ عن خطأ';

  @override
  String get clearQueue => 'مسح قائمة الانتظار';

  @override
  String get removeFile => 'إزالة';

  @override
  String get openOutputFolder => 'فتح مجلد الإخراج';

  @override
  String get patcherTitle => 'مطبق التصحيحات';

  @override
  String get patcherRomFile => 'ملف الـ ROM';

  @override
  String get patcherPatchFile => 'ملف التصحيح';

  @override
  String get patcherOutputFile => 'ملف الإخراج';

  @override
  String get patcherSameFolder => 'نفس مجلد الـ ROM';

  @override
  String get patcherIgnoreChecksum => 'تجاهل أخطاء المجموع الخانتين (Checksum)';

  @override
  String get patcherApplyButton => 'تطبيق التصحيح';

  @override
  String get patcherSuccess => 'تم تطبيق التصحيح بنجاح!';

  @override
  String get patcherFormat => 'الصيغة';

  @override
  String get patcherChecksumPassed => 'تم الاجتياز';

  @override
  String get patcherChecksumSkipped => 'تم التخطي';

  @override
  String get patcherDropHint => 'اسحب وأسقط ملفات الـ ROM والتصحيح هنا';

  @override
  String get toolsTitle => 'الأدوات';

  @override
  String get compressorTitle => 'ضاغط ROM';

  @override
  String get compressorAddFiles => 'إضافة ملفات';

  @override
  String get compressorAddFolder => 'إضافة مجلد';

  @override
  String get compressorOutputFormat => 'تنسيق الإخراج';

  @override
  String get compressorLevel => 'مستوى الضغط';

  @override
  String get compressorLevelFast => 'سريع';

  @override
  String get compressorLevelNormal => 'عادي';

  @override
  String get compressorLevelUltra => 'فائق';

  @override
  String get compressorDeleteSource => 'حذف المصدر بعد الانتهاء';

  @override
  String get compressorSameFolder => 'نفس مجلد المصدر';

  @override
  String compressorButton(int count) {
    return 'ضغط ($count ملفات)';
  }

  @override
  String get compressorSkipped => 'تم التخطي (مضغوط بالفعل)';

  @override
  String get m3uTitle => 'مولد قائمة M3U';

  @override
  String get m3uDropHint => 'أفلت ملفات الأقراص هنا';

  @override
  String get m3uOutputLabel => 'مجلد الإخراج';

  @override
  String get m3uButton => 'إنشاء M3U';

  @override
  String m3uSuccess(String filename) {
    return 'تم الإنشاء: $filename';
  }

  @override
  String get cueGeneratorTitle => 'مولد CUE';

  @override
  String get cueGeneratorBinFile => 'ملف BIN';

  @override
  String get cueGeneratorDetectedMode => 'النمط المكتشف';

  @override
  String get cueGeneratorButton => 'إنشاء CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'تم الإنشاء: $filename';
  }

  @override
  String get binMergerTitle => 'دمج BIN';

  @override
  String get binMergerCueFile => 'ملف CUE (متعدد المسارات)';

  @override
  String binMergerDetected(int count) {
    return 'تم اكتشاف: $count ملفات BIN';
  }

  @override
  String get binMergerButton => 'دمج ملفات BIN';

  @override
  String binMergerSuccess(String filename) {
    return 'تم الدمج: $filename';
  }

  @override
  String get headerRemoverTitle => 'مزيل الترويسة';

  @override
  String get headerRemoverSystem => 'النظام';

  @override
  String get headerRemoverFound => 'تم العثور على ترويسة';

  @override
  String get headerRemoverNotFound => 'لم يتم العثور على ترويسة';

  @override
  String get headerRemoverConfidence => 'مستوى الثقة';

  @override
  String get headerRemoverBackup => 'الاحتفاظ بنسخة احتياطية (.bak)';

  @override
  String get headerRemoverButton => 'إزالة الترويسة';

  @override
  String headerRemoverSuccess(String filename) {
    return 'ROM نظيف: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'لم يتم اكتشاف ترويسة ناسخة.';

  @override
  String get dreamcastTitle => 'دريم كاست';

  @override
  String get dreamcastDcpTab => 'تطبيق DCP';

  @override
  String get dreamcastIpbinTab => 'محرر IP.BIN';

  @override
  String get dreamcastGdiTab => 'معلومات GDI';

  @override
  String get dreamcastDiscDir => 'مجلد القرص';

  @override
  String get dreamcastDcpFile => 'ملف رقعة DCP';

  @override
  String get dreamcastOutputDir => 'مجلد الإخراج';

  @override
  String get dreamcastApplyButton => 'تطبيق رقعة DCP';

  @override
  String get dreamcastApplySuccess => 'تم تطبيق الرقعة بنجاح!';

  @override
  String get dreamcastIpbinFile => 'ملف IP.BIN أو GDI';

  @override
  String get dreamcastIpbinLoad => 'تحميل';

  @override
  String get dreamcastIpbinSave => 'حفظ التغييرات';

  @override
  String get dreamcastIpbinTitle => 'اسم اللعبة';

  @override
  String get dreamcastIpbinProductNumber => 'رقم المنتج';

  @override
  String get dreamcastIpbinVersion => 'الإصدار';

  @override
  String get dreamcastIpbinDate => 'تاريخ الإصدار';

  @override
  String get dreamcastIpbinRegion => 'المنطقة';

  @override
  String get dreamcastIpbinRegionJapan => 'اليابان';

  @override
  String get dreamcastIpbinRegionUSA => 'الولايات المتحدة';

  @override
  String get dreamcastIpbinRegionEurope => 'أوروبا';

  @override
  String get dreamcastIpbinRegionFree => 'كل المناطق';

  @override
  String get dreamcastIpbinVga => 'تفعيل VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'تم حفظ IP.BIN بنجاح!';

  @override
  String get dreamcastGdiFile => 'ملف GDI';

  @override
  String get dreamcastGdiLoad => 'تحميل GDI';

  @override
  String get dreamcastGdiTracks => 'المسارات';

  @override
  String get dreamcastGdiTrackNum => 'مسار';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'النوع';

  @override
  String get dreamcastGdiTrackSize => 'حجم القطاع';

  @override
  String get dreamcastGdiTrackFile => 'المِلَفّ';

  @override
  String get dreamcastGdiAudio => 'صوت';

  @override
  String get dreamcastGdiData => 'بيانات';

  @override
  String get dreamcastSameFolder => 'نفس مجلد المصدر';

  @override
  String get dreamcastBrowse => 'استعراض';

  @override
  String get onlineFeaturesSection => 'الميزات الإلكترونية';

  @override
  String get onlineFeaturesSub =>
      'جميع الميزات اختيارية. لا يتم جمع أي بيانات بدون موافقتك.';

  @override
  String get autoUpdateTitle => 'التحقق من التحديثات تلقائياً';

  @override
  String get autoUpdateSub =>
      'يتحقق من GitHub عند بدء التشغيل للكشف عن إصدار أحدث';

  @override
  String get autoUpdateCheckNow => 'تحقق الآن';

  @override
  String autoUpdateUpToDate(String version) {
    return 'أنت تستخدم أحدث إصدار ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return 'تحديث متاح: v$version';
  }

  @override
  String get autoUpdateDownload => 'تنزيل';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle => 'تفعيل فحص hash لـ RetroAchievements';

  @override
  String get raEnabledSub => 'يتحقق من دعم ROM قبل تحميله';

  @override
  String get raUsername => 'اسم المستخدم';

  @override
  String get raApiKey => 'مفتاح API';

  @override
  String get raApiKeyHint =>
      'احصل على مفتاحك من retroachievements.org/settings';

  @override
  String get raHashChecking => 'جارٍ فحص الـ hash...';

  @override
  String raHashFound(String title, int count) {
    return '✅ مدعوم — $title ($count إنجاز)';
  }

  @override
  String get raHashNotFound => '⚠️ غير موجود على RetroAchievements';

  @override
  String raHashError(String msg) {
    return 'خطأ: $msg';
  }

  @override
  String get raViewGame => 'عرض على RA';

  @override
  String get raSaveCredentials => 'حفظ';

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
