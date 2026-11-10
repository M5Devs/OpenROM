// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suite Universal de Conversión de ROMs';

  @override
  String get convertButton => 'Convertir';

  @override
  String convertButtonWithCount(int count) {
    return 'Convertir ($count Archivos)';
  }

  @override
  String get dropZoneHint => 'Arrastra y suelta archivos ROM aquí';

  @override
  String get dropZoneSubHint => 'o haz clic para explorar';

  @override
  String get settingsTitle => 'Configuración de Conversión';

  @override
  String get outputFormat => 'Formato de Salida';

  @override
  String get compressionLevel => 'Nivel de Compresión';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Alta';

  @override
  String get compressionMax => 'Máxima';

  @override
  String get postProcessing => 'Post-Procesamiento';

  @override
  String get verifyAfterConversion => 'Verificar después de convertir';

  @override
  String get outputDestination => 'Destino de Salida';

  @override
  String get browse => 'Examinar';

  @override
  String get statusWaiting => 'Esperando...';

  @override
  String get statusConverting => 'Convirtiendo...';

  @override
  String get statusDone => 'Hecho';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get aboutTitle => 'Acerca de OpenROM';

  @override
  String get settingsScreen => 'Ajustes';

  @override
  String get aboutScreen => 'Acerca de';

  @override
  String get themeScreen => 'Temas';

  @override
  String get errorCoreNotFound =>
      'No se encontró openrom-core. Por favor, vuelve a descargar el ZIP completo.';

  @override
  String get errorUnsupportedFormat =>
      'Este formato de archivo no es compatible.';

  @override
  String get errorDiskSpace =>
      'No hay suficiente espacio en disco para esta conversión.';

  @override
  String get errorToolFailed =>
      'La herramienta de conversión (chdman/maxcso) falló inesperadamente.';

  @override
  String get errorConversionFailed =>
      'La conversión falló. El archivo ROM podría estar dañado.';

  @override
  String get errorFileNotFound =>
      'El archivo de entrada fue movido o eliminado.';

  @override
  String get errorOutputDirNotFound =>
      'La carpeta de salida seleccionada ya no existe.';

  @override
  String get errorPermissionDenied =>
      'OpenROM no puede escribir en la carpeta de salida.';

  @override
  String get errorCorruptedFile =>
      'El archivo parece estar dañado o tiene 0 bytes.';

  @override
  String get errorUnknown => 'Ocurrió un error inesperado.';

  @override
  String get errorDetailsLabel => 'Detalles';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get reportBugButton => 'Reportar Error';

  @override
  String get clearQueue => 'Limpiar Cola';

  @override
  String get removeFile => 'Eliminar';

  @override
  String get openOutputFolder => 'Abrir Carpeta de Salida';

  @override
  String get patcherTitle => 'Parcheador de ROM';

  @override
  String get patcherRomFile => 'Archivo ROM';

  @override
  String get patcherPatchFile => 'Archivo de Parche';

  @override
  String get patcherOutputFile => 'Archivo de Salida';

  @override
  String get patcherSameFolder => 'Misma carpeta que el ROM';

  @override
  String get patcherIgnoreChecksum => 'Ignorar errores de suma de comprobación';

  @override
  String get patcherApplyButton => 'Aplicar Parche';

  @override
  String get patcherSuccess => '¡Parcheado con éxito!';

  @override
  String get patcherFormat => 'Formato';

  @override
  String get patcherChecksumPassed => 'aprobado';

  @override
  String get patcherChecksumSkipped => 'omitido';

  @override
  String get patcherDropHint =>
      'Arrastra y suelta los archivos ROM y parche aquí';

  @override
  String get toolsTitle => 'Herramientas';

  @override
  String get compressorTitle => 'Compresor de ROM';

  @override
  String get compressorAddFiles => 'Añadir archivos';

  @override
  String get compressorAddFolder => 'Añadir carpeta';

  @override
  String get compressorOutputFormat => 'Formato de salida';

  @override
  String get compressorLevel => 'Nivel de compresión';

  @override
  String get compressorLevelFast => 'Rápido';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Eliminar origen al finalizar';

  @override
  String get compressorSameFolder => 'Misma carpeta que el origen';

  @override
  String compressorButton(int count) {
    return 'Comprimir ($count archivos)';
  }

  @override
  String get compressorSkipped => 'Omitido (ya comprimido)';

  @override
  String get m3uTitle => 'Generador de M3U';

  @override
  String get m3uDropHint => 'Arrastre archivos de disco aquí';

  @override
  String get m3uOutputLabel => 'Carpeta de salida';

  @override
  String get m3uButton => 'Generar M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Creado: $filename';
  }

  @override
  String get cueGeneratorTitle => 'Generador de CUE';

  @override
  String get cueGeneratorBinFile => 'Archivo BIN';

  @override
  String get cueGeneratorDetectedMode => 'Modo detectado';

  @override
  String get cueGeneratorButton => 'Generar CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'Creado: $filename';
  }

  @override
  String get binMergerTitle => 'Unificador de BIN';

  @override
  String get binMergerCueFile => 'Archivo CUE (multipista)';

  @override
  String binMergerDetected(int count) {
    return 'Detectados: $count archivos BIN';
  }

  @override
  String get binMergerButton => 'Unir BINs';

  @override
  String binMergerSuccess(String filename) {
    return 'Unido: $filename';
  }

  @override
  String get headerRemoverTitle => 'Eliminador de Cabecera';

  @override
  String get headerRemoverSystem => 'Sistema';

  @override
  String get headerRemoverFound => 'Cabecera encontrada';

  @override
  String get headerRemoverNotFound => 'Sin cabecera';

  @override
  String get headerRemoverConfidence => 'Confianza';

  @override
  String get headerRemoverBackup => 'Guardar copia de seguridad (.bak)';

  @override
  String get headerRemoverButton => 'Eliminar Cabecera';

  @override
  String headerRemoverSuccess(String filename) {
    return 'ROM limpio: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'No se detectó cabecera de copiador.';

  @override
  String get dreamcastTitle => 'Dreamcast';

  @override
  String get dreamcastDcpTab => 'Aplicar DCP';

  @override
  String get dreamcastIpbinTab => 'Editor IP.BIN';

  @override
  String get dreamcastGdiTab => 'Información GDI';

  @override
  String get dreamcastDiscDir => 'Directorio del disco';

  @override
  String get dreamcastDcpFile => 'Archivo de parche DCP';

  @override
  String get dreamcastOutputDir => 'Directorio de salida';

  @override
  String get dreamcastApplyButton => 'Aplicar parche DCP';

  @override
  String get dreamcastApplySuccess => '¡Parche DCP aplicado con éxito!';

  @override
  String get dreamcastIpbinFile => 'Archivo IP.BIN o GDI';

  @override
  String get dreamcastIpbinLoad => 'Cargar';

  @override
  String get dreamcastIpbinSave => 'Guardar cambios';

  @override
  String get dreamcastIpbinTitle => 'Título del juego';

  @override
  String get dreamcastIpbinProductNumber => 'Número de producto';

  @override
  String get dreamcastIpbinVersion => 'Versión';

  @override
  String get dreamcastIpbinDate => 'Fecha de lanzamiento';

  @override
  String get dreamcastIpbinRegion => 'Región';

  @override
  String get dreamcastIpbinRegionJapan => 'Japón';

  @override
  String get dreamcastIpbinRegionUSA => 'EE. UU.';

  @override
  String get dreamcastIpbinRegionEurope => 'Europa';

  @override
  String get dreamcastIpbinRegionFree => 'Región libre';

  @override
  String get dreamcastIpbinVga => 'Habilitar VGA';

  @override
  String get dreamcastIpbinSaveSuccess => '¡IP.BIN guardado con éxito!';

  @override
  String get dreamcastGdiFile => 'Archivo GDI';

  @override
  String get dreamcastGdiLoad => 'Cargar GDI';

  @override
  String get dreamcastGdiTracks => 'Pistas';

  @override
  String get dreamcastGdiTrackNum => 'Pista';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'Tipo';

  @override
  String get dreamcastGdiTrackSize => 'Tamaño de sector';

  @override
  String get dreamcastGdiTrackFile => 'Archivo';

  @override
  String get dreamcastGdiAudio => 'Audio';

  @override
  String get dreamcastGdiData => 'Datos';

  @override
  String get dreamcastSameFolder => 'Misma carpeta que el origen';

  @override
  String get dreamcastBrowse => 'Examinar';

  @override
  String get onlineFeaturesSection => 'Funciones en línea';

  @override
  String get onlineFeaturesSub =>
      'Todas las funciones son optativas. No se recopilan datos sin su consentimiento.';

  @override
  String get autoUpdateTitle => 'Buscar actualizaciones automáticamente';

  @override
  String get autoUpdateSub =>
      'Comprueba GitHub al iniciar si hay una versión más reciente';

  @override
  String get autoUpdateCheckNow => 'Buscar ahora';

  @override
  String autoUpdateUpToDate(String version) {
    return 'Está actualizado ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return 'Actualización disponible: v$version';
  }

  @override
  String get autoUpdateDownload => 'Descargar';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle =>
      'Habilitar comprobación de hash de RetroAchievements';

  @override
  String get raEnabledSub =>
      'Comprueba si su ROM es compatible antes de cargar';

  @override
  String get raUsername => 'Nombre de usuario';

  @override
  String get raApiKey => 'Clave API';

  @override
  String get raApiKeyHint =>
      'Obtenga su clave en retroachievements.org/settings';

  @override
  String get raHashChecking => 'Comprobando hash...';

  @override
  String raHashFound(String title, int count) {
    return '✅ Compatible — $title ($count logros)';
  }

  @override
  String get raHashNotFound => '⚠️ No encontrado en RetroAchievements';

  @override
  String raHashError(String msg) {
    return 'Error: $msg';
  }

  @override
  String get raViewGame => 'Ver en RA';

  @override
  String get raSaveCredentials => 'Guardar';

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
