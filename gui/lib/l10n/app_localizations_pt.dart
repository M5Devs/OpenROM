// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suíte Universal de Conversão de ROMs';

  @override
  String get convertButton => 'Converter';

  @override
  String convertButtonWithCount(int count) {
    return 'Converter ($count Arquivos)';
  }

  @override
  String get dropZoneHint => 'Arraste e solte arquivos ROM aqui';

  @override
  String get dropZoneSubHint => 'ou Clique para navegar';

  @override
  String get settingsTitle => 'Configurações de Conversão';

  @override
  String get outputFormat => 'Formato de Saída';

  @override
  String get compressionLevel => 'Nível de Compressão';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Alta';

  @override
  String get compressionMax => 'Máxima';

  @override
  String get postProcessing => 'Pós-Processamento';

  @override
  String get verifyAfterConversion => 'Verificar após a conversão';

  @override
  String get outputDestination => 'Destino de Saída';

  @override
  String get browse => 'Navegar';

  @override
  String get statusWaiting => 'Aguardando...';

  @override
  String get statusConverting => 'Convertendo...';

  @override
  String get statusDone => 'Concluído';

  @override
  String get statusFailed => 'Falhou';

  @override
  String get aboutTitle => 'Sobre o OpenROM';

  @override
  String get settingsScreen => 'Configurações';

  @override
  String get aboutScreen => 'Sobre';

  @override
  String get themeScreen => 'Temas';

  @override
  String get errorCoreNotFound =>
      'openrom-core não encontrado. Por favor, baixe o ZIP completo novamente.';

  @override
  String get errorUnsupportedFormat =>
      'Este formato de arquivo não é suportado.';

  @override
  String get errorDiskSpace =>
      'Espaço em disco insuficiente para esta conversão.';

  @override
  String get errorToolFailed =>
      'A ferramenta de conversão (chdman/maxcso) fechou inesperadamente.';

  @override
  String get errorConversionFailed =>
      'A conversão falhou. O arquivo ROM pode estar corrompido.';

  @override
  String get errorFileNotFound =>
      'O arquivo de entrada foi movido ou removido.';

  @override
  String get errorOutputDirNotFound =>
      'A pasta de saída selecionada não existe mais.';

  @override
  String get errorPermissionDenied =>
      'O OpenROM não tem permissão para escrever na pasta de saída.';

  @override
  String get errorCorruptedFile =>
      'O arquivo parece estar corrompido ou tem 0 bytes.';

  @override
  String get errorUnknown => 'Ocorreu um erro inesperado.';

  @override
  String get errorDetailsLabel => 'Detalhes';

  @override
  String get retryButton => 'Tentar novamente';

  @override
  String get closeButton => 'Fechar';

  @override
  String get reportBugButton => 'Reportar Erro';

  @override
  String get clearQueue => 'Limpar Fila';

  @override
  String get removeFile => 'Remover';

  @override
  String get openOutputFolder => 'Abrir Pasta de Saída';

  @override
  String get patcherTitle => 'Aplicador de correções';

  @override
  String get patcherRomFile => 'Arquivo ROM';

  @override
  String get patcherPatchFile => 'Arquivo de correção';

  @override
  String get patcherOutputFile => 'Arquivo de Saída';

  @override
  String get patcherSameFolder => 'Mesma pasta do ROM';

  @override
  String get patcherIgnoreChecksum => 'Ignorar erros de verificação';

  @override
  String get patcherApplyButton => 'Aplicar correção';

  @override
  String get patcherSuccess => 'Correção aplicada com sucesso!';

  @override
  String get patcherFormat => 'Formato';

  @override
  String get patcherChecksumPassed => 'passou';

  @override
  String get patcherChecksumSkipped => 'ignorado';

  @override
  String get patcherDropHint => 'Arraste e solte os arquivos ROM e Patch aqui';

  @override
  String get toolsTitle => 'Ferramentas';

  @override
  String get compressorTitle => 'Compressor de ROM';

  @override
  String get compressorAddFiles => 'Adicionar arquivos';

  @override
  String get compressorAddFolder => 'Adicionar pasta';

  @override
  String get compressorOutputFormat => 'Formato de saída';

  @override
  String get compressorLevel => 'Nível de compressão';

  @override
  String get compressorLevelFast => 'Rápido';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Excluir origem ao concluir';

  @override
  String get compressorSameFolder => 'Mesma pasta de origem';

  @override
  String compressorButton(int count) {
    return 'Comprimir ($count arquivos)';
  }

  @override
  String get compressorSkipped => 'Ignorado (já comprimido)';

  @override
  String get m3uTitle => 'Gerador M3U';

  @override
  String get m3uDropHint => 'Solte os arquivos de disco aqui';

  @override
  String get m3uOutputLabel => 'Pasta de saída';

  @override
  String get m3uButton => 'Gerar M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Criado: $filename';
  }

  @override
  String get cueGeneratorTitle => 'Gerador de CUE';

  @override
  String get cueGeneratorBinFile => 'Arquivo BIN';

  @override
  String get cueGeneratorDetectedMode => 'Modo detectado';

  @override
  String get cueGeneratorButton => 'Gerar CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'Criado: $filename';
  }

  @override
  String get binMergerTitle => 'Unificador de BIN';

  @override
  String get binMergerCueFile => 'Arquivo CUE (multifaixa)';

  @override
  String binMergerDetected(int count) {
    return 'Detectado: $count arquivos BIN';
  }

  @override
  String get binMergerButton => 'Unir BINs';

  @override
  String binMergerSuccess(String filename) {
    return 'Unido: $filename';
  }

  @override
  String get headerRemoverTitle => 'Removedor de Cabeçalho';

  @override
  String get headerRemoverSystem => 'Sistema';

  @override
  String get headerRemoverFound => 'Cabeçalho encontrado';

  @override
  String get headerRemoverNotFound => 'Nenhum cabeçalho encontrado';

  @override
  String get headerRemoverConfidence => 'Confiança';

  @override
  String get headerRemoverBackup => 'Manter cópia de segurança (.bak)';

  @override
  String get headerRemoverButton => 'Remover Cabeçalho';

  @override
  String headerRemoverSuccess(String filename) {
    return 'ROM limpa: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'Nenhum cabeçalho de copiador detectado.';

  @override
  String get dreamcastTitle => 'Dreamstime';

  @override
  String get dreamcastDcpTab => 'Aplicar DCP';

  @override
  String get dreamcastIpbinTab => 'Editor IP.BIN';

  @override
  String get dreamcastGdiTab => 'Informações GDI';

  @override
  String get dreamcastDiscDir => 'Diretório do disco';

  @override
  String get dreamcastDcpFile => 'Arquivo de patch DCP';

  @override
  String get dreamcastOutputDir => 'Diretório de saída';

  @override
  String get dreamcastApplyButton => 'Aplicar patch DCP';

  @override
  String get dreamcastApplySuccess => 'Patch DCP aplicado com sucesso!';

  @override
  String get dreamcastIpbinFile => 'Arquivo IP.BIN ou GDI';

  @override
  String get dreamcastIpbinLoad => 'Carregar';

  @override
  String get dreamcastIpbinSave => 'Salvar alterações';

  @override
  String get dreamcastIpbinTitle => 'Título do jogo';

  @override
  String get dreamcastIpbinProductNumber => 'Número do produto';

  @override
  String get dreamcastIpbinVersion => 'Versão';

  @override
  String get dreamcastIpbinDate => 'Data de lançamento';

  @override
  String get dreamcastIpbinRegion => 'Região';

  @override
  String get dreamcastIpbinRegionJapan => 'Japão';

  @override
  String get dreamcastIpbinRegionUSA => 'EUA';

  @override
  String get dreamcastIpbinRegionEurope => 'Europa';

  @override
  String get dreamcastIpbinRegionFree => 'Região livre';

  @override
  String get dreamcastIpbinVga => 'Ativar VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BIN salvo com sucesso!';

  @override
  String get dreamcastGdiFile => 'Arquivo GDI';

  @override
  String get dreamcastGdiLoad => 'Carregar GDI';

  @override
  String get dreamcastGdiTracks => 'Faixas';

  @override
  String get dreamcastGdiTrackNum => 'Faixa';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => 'Tipo';

  @override
  String get dreamcastGdiTrackSize => 'Tamanho do setor';

  @override
  String get dreamcastGdiTrackFile => 'Arquivo';

  @override
  String get dreamcastGdiAudio => 'Áudio';

  @override
  String get dreamcastGdiData => 'Dados';

  @override
  String get dreamcastSameFolder => 'Mesma pasta da origem';

  @override
  String get dreamcastBrowse => 'Navegar';

  @override
  String get onlineFeaturesSection => 'Recursos online';

  @override
  String get onlineFeaturesSub =>
      'Todos os recursos são opcionais. Nenhum dado é coletado sem o seu consentimento.';

  @override
  String get autoUpdateTitle => 'Verificar atualizações automaticamente';

  @override
  String get autoUpdateSub =>
      'Verifica o GitHub na inicialização para uma versão mais recente';

  @override
  String get autoUpdateCheckNow => 'Verificar agora';

  @override
  String autoUpdateUpToDate(String version) {
    return 'Você está atualizado ($version)';
  }

  @override
  String autoUpdateAvailable(String version) {
    return 'Atualização disponível: v$version';
  }

  @override
  String get autoUpdateDownload => 'Baixar';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle =>
      'Ativar verificação de hash do RetroAchievements';

  @override
  String get raEnabledSub =>
      'Verifica se a sua ROM é suportada antes de carregar';

  @override
  String get raUsername => 'Nome de usuário';

  @override
  String get raApiKey => 'Chave de API';

  @override
  String get raApiKeyHint =>
      'Obtenha sua chave em retroachievements.org/settings';

  @override
  String get raHashChecking => 'Verificando hash...';

  @override
  String raHashFound(String title, int count) {
    return '✅ Suportado — $title ($count conquistas)';
  }

  @override
  String get raHashNotFound => '⚠️ Não encontrado no RetroAchievements';

  @override
  String raHashError(String msg) {
    return 'Erro: $msg';
  }

  @override
  String get raViewGame => 'Ver no RA';

  @override
  String get raSaveCredentials => 'Salvar';

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
