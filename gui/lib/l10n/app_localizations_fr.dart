// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suite Universelle de Conversion de ROMs';

  @override
  String get convertButton => 'Convertir';

  @override
  String convertButtonWithCount(int count) {
    return 'Convertir ($count Fichiers)';
  }

  @override
  String get dropZoneHint => 'Glissez & déposez des fichiers ROM ici';

  @override
  String get dropZoneSubHint => 'ou Cliquez pour parcourir';

  @override
  String get settingsTitle => 'Paramètres de Conversion';

  @override
  String get outputFormat => 'Format de Sortie';

  @override
  String get compressionLevel => 'Niveau de Compression';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Élevé';

  @override
  String get compressionMax => 'Maximum';

  @override
  String get postProcessing => 'Post-Traitement';

  @override
  String get verifyAfterConversion => 'Vérifier après la conversion';

  @override
  String get outputDestination => 'Destination de Sortie';

  @override
  String get browse => 'Parcourir';

  @override
  String get statusWaiting => 'En attente...';

  @override
  String get statusConverting => 'Conversion en cours...';

  @override
  String get statusDone => 'Terminé';

  @override
  String get statusFailed => 'Échec';

  @override
  String get aboutTitle => 'À propos d\'OpenROM';

  @override
  String get settingsScreen => 'Paramètres';

  @override
  String get aboutScreen => 'À propos';

  @override
  String get themeScreen => 'Thèmes';

  @override
  String get errorCoreNotFound =>
      'openrom-core introuvable. Veuillez télécharger à nouveau le ZIP complet.';

  @override
  String get errorUnsupportedFormat =>
      'Ce format de fichier n\'est pas pris en charge.';

  @override
  String get errorDiskSpace =>
      'Espace disque insuffisant pour cette conversion.';

  @override
  String get errorToolFailed =>
      'L\'outil de conversion (chdman/maxcso) a quitté de manière inattendue.';

  @override
  String get errorConversionFailed =>
      'La conversion a échoué. Le fichier ROM est peut-être corrompu.';

  @override
  String get errorFileNotFound =>
      'Le fichier d\'entrée a été déplacé ou supprimé.';

  @override
  String get errorOutputDirNotFound =>
      'Le dossier de sortie sélectionné n\'existe plus.';

  @override
  String get errorPermissionDenied =>
      'OpenROM ne peut pas écrire dans le dossier de sortie.';

  @override
  String get errorCorruptedFile =>
      'Le fichier semble être corrompu ou fait 0 octet.';

  @override
  String get errorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String get errorDetailsLabel => 'Détails';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get closeButton => 'Fermer';

  @override
  String get reportBugButton => 'Signaler un bug';

  @override
  String get clearQueue => 'Vider la file d\'attente';

  @override
  String get removeFile => 'Supprimer';

  @override
  String get openOutputFolder => 'Ouvrir le dossier de sortie';

  @override
  String get patcherTitle => 'Patcheur de ROM';

  @override
  String get patcherRomFile => 'Fichier ROM';

  @override
  String get patcherPatchFile => 'Fichier de Patch';

  @override
  String get patcherOutputFile => 'Fichier de Sortie';

  @override
  String get patcherSameFolder => 'Même dossier que le ROM';

  @override
  String get patcherIgnoreChecksum =>
      'Ignorer les erreurs de somme de contrôle';

  @override
  String get patcherApplyButton => 'Appliquer le Patch';

  @override
  String get patcherSuccess => 'Patché avec succès !';

  @override
  String get patcherFormat => 'Format';

  @override
  String get patcherChecksumPassed => 'réussi';

  @override
  String get patcherChecksumSkipped => 'ignoré';

  @override
  String get patcherDropHint => 'Déposez les fichiers ROM et Patch ici';

  @override
  String get toolsTitle => 'Outils';

  @override
  String get compressorTitle => 'Compresseur de ROM';

  @override
  String get compressorAddFiles => 'Ajouter des fichiers';

  @override
  String get compressorAddFolder => 'Ajouter un dossier';

  @override
  String get compressorOutputFormat => 'Format de sortie';

  @override
  String get compressorLevel => 'Niveau de compression';

  @override
  String get compressorLevelFast => 'Rapide';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Supprimer la source après fin';

  @override
  String get compressorSameFolder => 'Même dossier que la source';

  @override
  String compressorButton(int count) {
    return 'Compresser ($count fichiers)';
  }

  @override
  String get compressorSkipped => 'Ignoré (déjà compressé)';

  @override
  String get m3uTitle => 'Générateur M3U';

  @override
  String get m3uDropHint => 'Déposez les fichiers de disque ici';

  @override
  String get m3uOutputLabel => 'Dossier de sortie';

  @override
  String get m3uButton => 'Générer M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Créé : $filename';
  }

  @override
  String get cueGeneratorTitle => 'Générateur CUE';

  @override
  String get cueGeneratorBinFile => 'Fichier BIN';

  @override
  String get cueGeneratorDetectedMode => 'Mode détecté';

  @override
  String get cueGeneratorButton => 'Générer CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'Créé : $filename';
  }

  @override
  String get binMergerTitle => 'Fusionneur de BIN';

  @override
  String get binMergerCueFile => 'Fichier CUE (multi-pistes)';

  @override
  String binMergerDetected(int count) {
    return 'Détectés : $count fichiers BIN';
  }

  @override
  String get binMergerButton => 'Fusionner les BIN';

  @override
  String binMergerSuccess(String filename) {
    return 'Fusionné : $filename';
  }

  @override
  String get headerRemoverTitle => 'Suppresseur d\'En-tête';

  @override
  String get headerRemoverSystem => 'Système';

  @override
  String get headerRemoverFound => 'En-tête trouvé';

  @override
  String get headerRemoverNotFound => 'Aucun en-tête trouvé';

  @override
  String get headerRemoverConfidence => 'Confiance';

  @override
  String get headerRemoverBackup => 'Conserver la sauvegarde (.bak)';

  @override
  String get headerRemoverButton => 'Supprimer l\'En-tête';

  @override
  String headerRemoverSuccess(String filename) {
    return 'ROM propre : $filename';
  }

  @override
  String get headerRemoverNoHeader => 'Aucun en-tête de copieur détecté.';

  @override
  String get dreamcastTitle => 'Dreamcast';

  @override
  String get dreamcastDcpTab => 'Appliquer DCP';

  @override
  String get dreamcastIpbinTab => 'Éditeur IP.BIN';

  @override
  String get dreamcastGdiTab => 'Infos GDI';

  @override
  String get dreamcastDiscDir => 'Dossier du disque';

  @override
  String get dreamcastDcpFile => 'Fichier de patch DCP';

  @override
  String get dreamcastOutputDir => 'Dossier de sortie';

  @override
  String get dreamcastApplyButton => 'Appliquer le patch DCP';

  @override
  String get dreamcastApplySuccess => 'Patch DCP appliqué avec succès !';

  @override
  String get dreamcastIpbinFile => 'Fichier IP.BIN ou GDI';

  @override
  String get dreamcastIpbinLoad => 'Charger';

  @override
  String get dreamcastIpbinSave => 'Enregistrer les modifications';

  @override
  String get dreamcastIpbinTitle => 'Titre du jeu';

  @override
  String get dreamcastIpbinProductNumber => 'Numéro de produit';

  @override
  String get dreamcastIpbinVersion => 'Version';

  @override
  String get dreamcastIpbinDate => 'Date de sortie';

  @override
  String get dreamcastIpbinRegion => 'Région';

  @override
  String get dreamcastIpbinRegionJapan => 'Japon';

  @override
  String get dreamcastIpbinRegionUSA => 'États-Unis';

  @override
  String get dreamcastIpbinRegionEurope => 'Europe';

  @override
  String get dreamcastIpbinRegionFree => 'Toutes régions';

  @override
  String get dreamcastIpbinVga => 'Activer VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BIN enregistré avec succès !';

  @override
  String get dreamcastGdiFile => 'Fichier GDI';

  @override
  String get dreamcastGdiLoad => 'Charger GDI';

  @override
  String get dreamcastGdiTracks => 'Pistes';

  @override
  String get dreamcastGdiTrackNum => 'Piste';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'Type';

  @override
  String get dreamcastGdiTrackSize => 'Taille de secteur';

  @override
  String get dreamcastGdiTrackFile => 'Fichier';

  @override
  String get dreamcastGdiAudio => 'Audio';

  @override
  String get dreamcastGdiData => 'Données';

  @override
  String get dreamcastSameFolder => 'Même dossier que la source';

  @override
  String get dreamcastBrowse => 'Parcourir';

  @override
  String get onlineFeaturesSection => 'Fonctionnalités en ligne';

  @override
  String get onlineFeaturesSub =>
      'Toutes les fonctionnalités sont optionnelles. Aucune donnée n\'est collectée sans votre consentement.';

  @override
  String get autoUpdateTitle => 'Vérifier les mises à jour automatiquement';

  @override
  String get autoUpdateSub =>
      'Vérifie GitHub au démarrage pour une version plus récente';

  @override
  String get autoUpdateCheckNow => 'Vérifier maintenant';

  @override
  String autoUpdateUpToDate(String version) {
    return 'Vous êtes à jour ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return 'Mise à jour disponible : v$version';
  }

  @override
  String get autoUpdateDownload => 'Télécharger';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle =>
      'Activer la vérification du hash RetroAchievements';

  @override
  String get raEnabledSub =>
      'Vérifie si votre ROM est prise en charge avant le chargement';

  @override
  String get raUsername => 'Nom d\'utilisateur';

  @override
  String get raApiKey => 'Clé API';

  @override
  String get raApiKeyHint =>
      'Obtenez votre clé sur retroachievements.org/settings';

  @override
  String get raHashChecking => 'Vérification du hash...';

  @override
  String raHashFound(String title, int count) {
    return '✅ Pris en charge — $title ($count succès)';
  }

  @override
  String get raHashNotFound => '⚠️ Non trouvé sur RetroAchievements';

  @override
  String raHashError(String msg) {
    return 'Erreur : $msg';
  }

  @override
  String get raViewGame => 'Voir sur RA';

  @override
  String get raSaveCredentials => 'Enregistrer';

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
