// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => '通用 ROM 转换套件';

  @override
  String get convertButton => '转换';

  @override
  String convertButtonWithCount(int count) {
    return '转换（$count 个文件）';
  }

  @override
  String get dropZoneHint => '将 ROM 文件拖放到此处';

  @override
  String get dropZoneSubHint => '或点击浏览';

  @override
  String get settingsTitle => '转换设置';

  @override
  String get outputFormat => '输出格式';

  @override
  String get compressionLevel => '压缩等级';

  @override
  String get compressionNormal => '标准';

  @override
  String get compressionHigh => '高';

  @override
  String get compressionMax => '最大';

  @override
  String get postProcessing => '后处理';

  @override
  String get verifyAfterConversion => '转换后验证';

  @override
  String get outputDestination => '输出位置';

  @override
  String get browse => '浏览';

  @override
  String get statusWaiting => '等待中...';

  @override
  String get statusConverting => '转换中...';

  @override
  String get statusDone => '完成';

  @override
  String get statusFailed => '失败';

  @override
  String get aboutTitle => '关于 OpenROM';

  @override
  String get settingsScreen => '设置';

  @override
  String get aboutScreen => '关于';

  @override
  String get themeScreen => '主题';

  @override
  String get errorCoreNotFound => '应用程序文件夹中缺少 openrom-core。';

  @override
  String get errorUnsupportedFormat => '此文件格式无法使用所选输出进行转换。';

  @override
  String get errorDiskSpace => '可用空间不足以完成此转换。';

  @override
  String get errorToolFailed => '转换工具（chdman/maxcso）意外退出。';

  @override
  String get errorConversionFailed => '转换在完成前停止。';

  @override
  String get errorFileNotFound => '输入文件已被移动或删除。';

  @override
  String get errorOutputDirNotFound => '所选输出文件夹已不存在。';

  @override
  String get errorPermissionDenied => 'OpenROM 无法写入输出文件夹。';

  @override
  String get errorCorruptedFile => '文件似乎已损坏或为 0 字节。';

  @override
  String get errorUnknown => '发生错误。这可能是 Bug。';

  @override
  String get errorDetailsLabel => '详细信息';

  @override
  String get retryButton => '重试';

  @override
  String get closeButton => '关闭';

  @override
  String get reportBugButton => '报告问题';

  @override
  String get clearQueue => '清除队列';

  @override
  String get removeFile => '移除';

  @override
  String get openOutputFolder => '打开输出文件夹';

  @override
  String get patcherTitle => 'ROM 修补器';

  @override
  String get patcherRomFile => 'ROM 文件';

  @override
  String get patcherPatchFile => '补丁文件';

  @override
  String get patcherOutputFile => '输出文件';

  @override
  String get patcherSameFolder => '与 ROM 相同文件夹';

  @override
  String get patcherIgnoreChecksum => '忽略校验和错误';

  @override
  String get patcherApplyButton => '应用补丁';

  @override
  String get patcherSuccess => '修补成功！';

  @override
  String get patcherFormat => '格式';

  @override
  String get patcherChecksumPassed => '通过';

  @override
  String get patcherChecksumSkipped => '已跳过';

  @override
  String get patcherDropHint => '将 ROM 和补丁文件拖放到此处';

  @override
  String get toolsTitle => '工具';

  @override
  String get compressorTitle => 'ROM 压缩器';

  @override
  String get compressorAddFiles => '添加文件';

  @override
  String get compressorAddFolder => '添加文件夹';

  @override
  String get compressorOutputFormat => '输出格式';

  @override
  String get compressorLevel => '压缩等级';

  @override
  String get compressorLevelFast => '快速';

  @override
  String get compressorLevelNormal => '标准';

  @override
  String get compressorLevelUltra => '极致';

  @override
  String get compressorDeleteSource => '完成后删除源文件';

  @override
  String get compressorSameFolder => '与源文件相同文件夹';

  @override
  String compressorButton(int count) {
    return '压缩（$count 个文件）';
  }

  @override
  String get compressorSkipped => '已跳过（已压缩）';

  @override
  String get m3uTitle => 'M3U 生成器';

  @override
  String get m3uDropHint => '将光盘文件拖放到此处';

  @override
  String get m3uOutputLabel => '输出文件夹';

  @override
  String get m3uButton => '生成 M3U';

  @override
  String m3uSuccess(String filename) {
    return '已创建：$filename';
  }

  @override
  String get cueGeneratorTitle => 'CUE 生成器';

  @override
  String get cueGeneratorBinFile => 'BIN 文件';

  @override
  String get cueGeneratorDetectedMode => '检测模式';

  @override
  String get cueGeneratorButton => '生成 CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return '已创建：$filename';
  }

  @override
  String get binMergerTitle => 'BIN 合并器';

  @override
  String get binMergerCueFile => 'CUE 文件（多轨道）';

  @override
  String binMergerDetected(int count) {
    return '检测到：$count 个 BIN 文件';
  }

  @override
  String get binMergerButton => '合并 BIN';

  @override
  String binMergerSuccess(String filename) {
    return '已合并：$filename';
  }

  @override
  String get headerRemoverTitle => '文件头移除器';

  @override
  String get headerRemoverSystem => '系统';

  @override
  String get headerRemoverFound => '找到文件头';

  @override
  String get headerRemoverNotFound => '未找到文件头';

  @override
  String get headerRemoverConfidence => '置信度';

  @override
  String get headerRemoverBackup => '保留备份（.bak）';

  @override
  String get headerRemoverButton => '移除文件头';

  @override
  String headerRemoverSuccess(String filename) {
    return '干净的 ROM：$filename';
  }

  @override
  String get headerRemoverNoHeader => '未检测到文件头。';

  @override
  String get dreamcastTitle => 'Dreamcast';

  @override
  String get dreamcastDcpTab => '应用 DCP';

  @override
  String get dreamcastIpbinTab => 'IP.BIN 编辑器';

  @override
  String get dreamcastGdiTab => 'GDI 信息';

  @override
  String get dreamcastDiscDir => '光盘目录';

  @override
  String get dreamcastDcpFile => 'DCP 补丁文件';

  @override
  String get dreamcastOutputDir => '输出目录';

  @override
  String get dreamcastApplyButton => '应用 DCP 补丁';

  @override
  String get dreamcastApplySuccess => 'DCP 补丁应用成功！';

  @override
  String get dreamcastIpbinFile => 'IP.BIN 或 GDI 文件';

  @override
  String get dreamcastIpbinLoad => '加载';

  @override
  String get dreamcastIpbinSave => '保存更改';

  @override
  String get dreamcastIpbinTitle => '游戏名称';

  @override
  String get dreamcastIpbinProductNumber => '产品编号';

  @override
  String get dreamcastIpbinVersion => '版本';

  @override
  String get dreamcastIpbinDate => '发行日期';

  @override
  String get dreamcastIpbinRegion => '区域';

  @override
  String get dreamcastIpbinRegionJapan => '日本';

  @override
  String get dreamcastIpbinRegionUSA => '美国';

  @override
  String get dreamcastIpbinRegionEurope => '欧洲';

  @override
  String get dreamcastIpbinRegionFree => '全区';

  @override
  String get dreamcastIpbinVga => '启用 VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BIN 保存成功！';

  @override
  String get dreamcastGdiFile => 'GDI 文件';

  @override
  String get dreamcastGdiLoad => '加载 GDI';

  @override
  String get dreamcastGdiTracks => '轨道列表';

  @override
  String get dreamcastGdiTrackNum => '轨道';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => '类型';

  @override
  String get dreamcastGdiTrackSize => '扇区大小';

  @override
  String get dreamcastGdiTrackFile => '文件';

  @override
  String get dreamcastGdiAudio => '音频';

  @override
  String get dreamcastGdiData => '数据';

  @override
  String get dreamcastSameFolder => '与源文件相同文件夹';

  @override
  String get dreamcastBrowse => '浏览';

  @override
  String get onlineFeaturesSection => '在线功能';

  @override
  String get onlineFeaturesSub => '所有功能均为可选启用。未经您的同意，不会收集任何数据。';

  @override
  String get autoUpdateTitle => '自动检查更新';

  @override
  String get autoUpdateSub => '启动时在 GitHub 上检查新版本';

  @override
  String get autoUpdateCheckNow => '立即检查';

  @override
  String autoUpdateUpToDate(String version) {
    return '已是最新版本（$version）';
  }

  @override
  String autoUpdateAvailable(String version) {
    return '有可用更新：v$version';
  }

  @override
  String get autoUpdateDownload => '下载';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle => '启用 RetroAchievements 哈希检查';

  @override
  String get raEnabledSub => '加载前检查您的 ROM 是否受支持';

  @override
  String get raUsername => '用户名';

  @override
  String get raApiKey => 'API 密钥';

  @override
  String get raApiKeyHint => '在 retroachievements.org/settings 获取您的密钥';

  @override
  String get raHashChecking => '正在检查哈希值...';

  @override
  String raHashFound(String title, int count) {
    return '✅ 已支持 — $title（$count 个成就）';
  }

  @override
  String get raHashNotFound => '⚠️ 在 RetroAchievements 上未找到';

  @override
  String raHashError(String msg) {
    return '错误：$msg';
  }

  @override
  String get raViewGame => '在 RA 上查看';

  @override
  String get raSaveCredentials => '保存';

  @override
  String get navPatch => '应用补丁';

  @override
  String get navTools => '工具';

  @override
  String get navPlugins => '插件';

  @override
  String get mediaTypeTitle => '无法识别媒体类型';

  @override
  String mediaTypeBody(String file) {
    return '无法识别媒体类型：这个游戏是 CD 还是 DVD？\n\n文件：$file';
  }

  @override
  String get mediaCd => 'CD';

  @override
  String get mediaDvd => 'DVD';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '确定';

  @override
  String get commonAdd => '添加';

  @override
  String get commonDone => '完成';

  @override
  String get commonApply => '应用';

  @override
  String get commonRemove => '移除';

  @override
  String get commonInstall => '安装';

  @override
  String get pluginsTabInstalled => '已安装插件 📦';

  @override
  String get pluginsTabStore => '插件商店 🌐🛒';

  @override
  String get pluginsTabStudio => '创建 / 工作室 🛠️';

  @override
  String get pluginsDropTitle => '将 .orplug 压缩包拖放到这里';

  @override
  String get pluginsDropSubtitle => '安装自定义 ROM 工具、扩展和格式';

  @override
  String get pluginsBrowse => '浏览 .orplug 文件';

  @override
  String pluginsInstalledHeading(int count) {
    return '已安装插件（$count）';
  }

  @override
  String get pluginsEmptyTitle => '尚未安装任何插件';

  @override
  String get pluginsEmptyBody => '将 .orplug 包拖放到上方，或到插件商店浏览社区插件。';

  @override
  String get pluginsUninstall => '卸载';

  @override
  String get pluginsUninstallTitle => '卸载插件';

  @override
  String pluginsUninstallBody(String name, String id) {
    return '确定要卸载“$name”（$id）吗？';
  }

  @override
  String get pluginsInstallFailed => '安装失败';

  @override
  String pluginsAlreadyInstalled(String name) {
    return '$name 已经安装过了';
  }

  @override
  String pluginsInstalledToast(String name) {
    return '已安装 $name';
  }

  @override
  String get storeTitle => '插件市集';

  @override
  String get storeRefresh => '刷新目录';

  @override
  String get storeSubtitleLive => '由商店实时提供的官方与社区插件。';

  @override
  String get storeSubtitleCached => '当前显示上次缓存的目录，重新连接后可更新。';

  @override
  String get storeBadgeLive => '在线';

  @override
  String get storeBadgeOffline => '离线';

  @override
  String get storeSearchHint => '搜索插件、发布者、转换路径…';

  @override
  String get storeAll => '全部';

  @override
  String get storeOfflineTitle => 'ROMéo 离线了';

  @override
  String get storeEmptyTitle => '还没有任何插件上架';

  @override
  String get storeNoMatchTitle => '没有符合筛选条件的插件';

  @override
  String get storeOfflineBody => '无法连接到商店，且本地没有缓存。请检查网络连接后刷新。';

  @override
  String get storeEmptyBody => '敬请期待，新插件会陆续上架。';

  @override
  String get storeNoMatchBody => '换个关键词或分类试试。';

  @override
  String get storeVerifiedPublisher => '已验证发布者';

  @override
  String get storeInstalled => '已安装';

  @override
  String storeByPublisher(String name) {
    return '作者：$name';
  }

  @override
  String storeCoreMin(String version) {
    return '核心 ≥ $version';
  }

  @override
  String get deepLinkTitle => '要从链接安装插件吗？';

  @override
  String get deepLinkBody => '有 openrom:// 链接请求安装插件，请先确认内容再继续。';

  @override
  String get deepLinkPlugin => '插件';

  @override
  String get deepLinkId => '标识符';

  @override
  String get deepLinkVersion => '版本';

  @override
  String get deepLinkPublisher => '发布者';

  @override
  String get deepLinkCategory => '分类';

  @override
  String get deepLinkRequiresCore => '需要核心版本';

  @override
  String get deepLinkVerified => '安装前会使用商店公布的 SHA-256 校验下载文件。';

  @override
  String get deepLinkNotFoundTitle => '找不到插件';

  @override
  String deepLinkNotFoundBody(String id) {
    return '商店目录中找不到标识符为“$id”的插件。';
  }

  @override
  String get studioTitle => '可视化 .orplug 制作工作室';

  @override
  String get studioIntro => '创建新插件，或打开现有的项目文件夹。';

  @override
  String get studioNew => '新建';

  @override
  String get studioOpen => '打开';

  @override
  String get studioRescan => '重新扫描项目';

  @override
  String get studioIdentity => '基本信息';

  @override
  String get studioPluginId => '插件标识符';

  @override
  String get studioDisplayName => '显示名称';

  @override
  String get studioVersion => '版本（SemVer）';

  @override
  String get studioMinCore => '最低核心版本';

  @override
  String get studioCategory => '分类';

  @override
  String get studioPublisher => '发布者';

  @override
  String get studioPublisherId => '发布者标识符';

  @override
  String get studioPublisherName => '发布者名称';

  @override
  String get studioVerified => '已验证';

  @override
  String get studioVerifiedTip => '已验证的发布者会在商店显示蓝色勾选标记。';

  @override
  String get studioDescriptionRoutes => '说明与转换路径';

  @override
  String get studioDescription => '说明';

  @override
  String get studioRouteHint => '添加转换路径（例如 ISO -> WUA）';

  @override
  String get studioNoRoutes => '尚未添加任何转换路径。';

  @override
  String get studioBinaries => '可执行文件';

  @override
  String get studioBinariesHelp => '每个平台附加一个可执行文件。保存或构建时会自动计算 SHA-256。';

  @override
  String get studioNotSet => '未设置';

  @override
  String get studioReplace => '替换';

  @override
  String get studioExecutionArgs => '执行参数';

  @override
  String get studioPlaceholders =>
      '预留字段：bin（可执行文件）、in（输入）、out（输出）、outdir（输出目录）、cue（cue 文件）';

  @override
  String get studioArgsTemplate => '参数模板';

  @override
  String get studioBuild => '构建';

  @override
  String get studioSaveManifest => '保存清单';

  @override
  String get studioValidate => '校验';

  @override
  String get studioBuildPackage => '构建 .orplug';

  @override
  String studioLastBuild(String path, String sha) {
    return '上次构建：$path · sha256 $sha';
  }

  @override
  String get studioCopyMarketplace => '复制市集 JSON';

  @override
  String get studioMarketplaceCopied => '已复制市集 JSON';

  @override
  String get studioManifestValid => '清单有效';

  @override
  String get studioValidationIssues => '校验问题';

  @override
  String get studioBuiltTitle => '已构建 .orplug';

  @override
  String get studioArchive => '压缩包';

  @override
  String get studioSize => '大小';

  @override
  String studioSizeBytes(int bytes) {
    return '$bytes 字节';
  }

  @override
  String get studioMarketplaceEntry => '商店条目（粘贴到商店目录）：';

  @override
  String get studioCopyJson => '复制 JSON';

  @override
  String get studioNewProjectTitle => '选择插件的创建位置';

  @override
  String get studioOpenProjectTitle => '选择插件项目文件夹';

  @override
  String get studioDefaultName => '我的工具';

  @override
  String get themeEditorTitle => '主题编辑器';

  @override
  String get themeCustomSkin => '自定义外观';

  @override
  String get themeCustomTheme => '自定义主题';

  @override
  String get themeThemeName => '主题名称';

  @override
  String get themePickWallpaper => '选择壁纸（GIF、PNG、JPG 或 WebP）';

  @override
  String get themePickDropzone => '选择拖放区插图（GIF 或 PNG）';

  @override
  String get themePickFont => '选择界面字体（TTF 或 OTF）';

  @override
  String get themeImportSkinBundle => '导入 .orskin 外观包';

  @override
  String get themeExportSkinBundle => '导出 .orskin 外观包';

  @override
  String get themeImportShort => '导入 .orskin';

  @override
  String get themeExportShort => '导出 .orskin';

  @override
  String themeImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String themeExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String themeImported(String name) {
    return '已导入外观“$name”';
  }

  @override
  String themeExported(String path) {
    return '已导出 $path';
  }

  @override
  String get themePickColor => '选择颜色';

  @override
  String get themeHue => '色相';

  @override
  String get themeSaturation => '饱和度';

  @override
  String get themeValue => '明度';

  @override
  String get themeColors => '颜色';

  @override
  String get themeBackground => '背景';

  @override
  String get themeSurface => '表面色';

  @override
  String get themeAccent => '强调色';

  @override
  String get themeTextPrimary => '主要文字';

  @override
  String get themeTextSecondary => '次要文字';

  @override
  String get themeSidebarBg => '侧边栏背景';

  @override
  String get themeCardBg => '卡片背景';

  @override
  String get themeTerminalBg => '终端背景';

  @override
  String get themeTerminalText => '终端文字';

  @override
  String get themeGeometry => '外观几何与壁纸';

  @override
  String get themeCornerRadius => '圆角半径';

  @override
  String get themeWallpaperOpacity => '壁纸不透明度';

  @override
  String get themeWallpaperBlur => '壁纸模糊';

  @override
  String get themeChooseWallpaper => '选择壁纸';

  @override
  String get themeChooseDropzone => '选择拖放区';

  @override
  String get themeChooseFont => '选择字体';

  @override
  String get themeSidebarTabs => '侧边栏标签页';

  @override
  String get themeSidebarTabsHelp => '取消勾选即可从侧边栏和导航中隐藏。';

  @override
  String get themeSaveTheme => '保存主题';

  @override
  String get themeLivePreview => '实时预览';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsAudioCodec => 'CD 音频编码（CHD）';

  @override
  String get settingsCodecFlac => '无损（FLAC）－推荐';

  @override
  String get settingsCodecVorbis => '最大压缩（Vorbis）';

  @override
  String get settingsVerifySub => '对新建的 CHD 文件运行 chdman verify';

  @override
  String get settingsSameFolder => '与源文件相同的文件夹';

  @override
  String get settingsSelectDir => '选择文件夹…';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsUpdateError => '检查更新时出错';

  @override
  String get settingsRaSaved => '已保存 RetroAchievements 凭据';

  @override
  String get settingsHasheous => 'Hasheous';

  @override
  String get settingsHasheousEnable => '启用 Hasheous 哈希查询';

  @override
  String get settingsHasheousSub =>
      '将 ROM 的 SHA-1 发送至 hasheous.org 来识别游戏。默认关闭，仅发送文件哈希。';

  @override
  String get batchTitle => '批量处理完成！🎉';

  @override
  String batchSaved(String amount) {
    return '你刚刚节省了 $amount';
  }

  @override
  String batchSavedDetail(String percent, int count) {
    return '（缩减 $percent）共 $count 个游戏！';
  }

  @override
  String batchAllProcessed(int count) {
    return '全部 $count 个文件处理完成！';
  }

  @override
  String get batchAwesome => '太棒了！';

  @override
  String get hasheousUnknown => '未知标题';

  @override
  String hasheousMore(int count) {
    return '另有 $count 个来源';
  }

  @override
  String hasheousVerifiedIn(String source) {
    return '已在 $source 验证';
  }

  @override
  String get hasheousNoMatch => '在保存数据库中找不到匹配项。';

  @override
  String get toolsTabCue => 'CUE 编辑器';

  @override
  String get toolsTabRenamer => 'ROM 重命名';

  @override
  String get toolsTab1g1r => '1G1R 清理器';

  @override
  String get toolsTabHasher => 'ROM 哈希计算';

  @override
  String get toolsWatchTitle => '监视文件夹';

  @override
  String get toolsArcadeTitle => '街机 / MAME';

  @override
  String get toolsHasherIntro => '单次流式计算 CRC32、MD5、SHA-1 和 SHA-256。';

  @override
  String get toolsHasherDrop => '将 ROM 拖放到这里，或点击浏览';

  @override
  String get toolsChooseFile => '选择文件';

  @override
  String get toolsComputeHashes => '计算哈希';

  @override
  String get toolsResults => '结果';

  @override
  String get toolsCopyAll => '全部复制';

  @override
  String get toolsFileSize => '文件大小';

  @override
  String get toolsIdentifying => '识别中…';

  @override
  String get toolsIdentifyGame => '识别游戏（Hasheous）';

  @override
  String get toolsHasheousHint =>
      '会将文件的 SHA-1 发送至 hasheous.org。请在“设置 → 在线功能”中启用。';

  @override
  String get toolsWatchStopped => '已停止监视。';

  @override
  String get toolsWatchNeedFolders => '请先选择输入和输出文件夹。';

  @override
  String get toolsChooseFolder => '选择文件夹…';

  @override
  String get toolsWatchIntro => '自动转换进入文件夹的 ROM。';

  @override
  String get toolsInputFolder => '输入文件夹';

  @override
  String get toolsOutputFolder => '输出文件夹';

  @override
  String get toolsTargetFormat => '目标格式';

  @override
  String get toolsDeleteSource => '转换后删除源文件';

  @override
  String get toolsStopWatching => '停止监视';

  @override
  String get toolsStartWatching => '开始监视';

  @override
  String get toolsActive => '运行中';

  @override
  String get toolsLiveLog => '实时日志';

  @override
  String get toolsNoActivity => '尚无活动。';

  @override
  String themeSaved(String name) {
    return '已保存主题“$name”！';
  }
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => '萬用 ROM 轉換工具';

  @override
  String get convertButton => '轉換';

  @override
  String convertButtonWithCount(int count) {
    return '轉換（$count 個檔案）';
  }

  @override
  String get dropZoneHint => '將 ROM 檔案拖曳至此';

  @override
  String get dropZoneSubHint => '或點擊瀏覽';

  @override
  String get settingsTitle => '轉換設定';

  @override
  String get outputFormat => '輸出格式';

  @override
  String get compressionLevel => '壓縮等級';

  @override
  String get compressionNormal => '標準';

  @override
  String get compressionHigh => '高';

  @override
  String get compressionMax => '最高';

  @override
  String get postProcessing => '後續處理';

  @override
  String get verifyAfterConversion => '轉換後驗證';

  @override
  String get outputDestination => '輸出位置';

  @override
  String get browse => '瀏覽';

  @override
  String get statusWaiting => '等待中...';

  @override
  String get statusConverting => '轉換中...';

  @override
  String get statusDone => '完成';

  @override
  String get statusFailed => '失敗';

  @override
  String get aboutTitle => '關於 OpenROM';

  @override
  String get settingsScreen => '設定';

  @override
  String get aboutScreen => '關於';

  @override
  String get themeScreen => '主題';

  @override
  String get errorCoreNotFound => '應用程式資料夾中缺少 openrom-core。';

  @override
  String get errorUnsupportedFormat => '此檔案格式無法使用選擇的輸出格式進行轉換。';

  @override
  String get errorDiskSpace => '可用空間不足以完成此次轉換。';

  @override
  String get errorToolFailed => '轉換工具（chdman/maxcso）未預期結束。';

  @override
  String get errorConversionFailed => '轉換在完成前停止。';

  @override
  String get errorFileNotFound => '輸入檔案已被移動或刪除。';

  @override
  String get errorOutputDirNotFound => '選擇的輸出資料夾已不存在。';

  @override
  String get errorPermissionDenied => 'OpenROM 無法寫入輸出資料夾。';

  @override
  String get errorCorruptedFile => '檔案似乎已損毀或為 0 bytes。';

  @override
  String get errorUnknown => '發生錯誤。這可能是 Bug。';

  @override
  String get errorDetailsLabel => '詳細資料';

  @override
  String get retryButton => '重試';

  @override
  String get closeButton => '關閉';

  @override
  String get reportBugButton => '回報問題';

  @override
  String get clearQueue => '清除佇列';

  @override
  String get removeFile => '移除';

  @override
  String get openOutputFolder => '開啟輸出資料夾';

  @override
  String get patcherTitle => 'ROM 修補器';

  @override
  String get patcherRomFile => 'ROM 檔案';

  @override
  String get patcherPatchFile => '修補檔案';

  @override
  String get patcherOutputFile => '輸出檔案';

  @override
  String get patcherSameFolder => '與 ROM 相同資料夾';

  @override
  String get patcherIgnoreChecksum => '忽略總和檢查錯誤';

  @override
  String get patcherApplyButton => '套用修補';

  @override
  String get patcherSuccess => '修補成功！';

  @override
  String get patcherFormat => '格式';

  @override
  String get patcherChecksumPassed => '通過';

  @override
  String get patcherChecksumSkipped => '略過';

  @override
  String get patcherDropHint => '將 ROM 與修補檔案拖曳至此';

  @override
  String get toolsTitle => '工具';

  @override
  String get compressorTitle => 'ROM 壓縮器';

  @override
  String get compressorAddFiles => '新增檔案';

  @override
  String get compressorAddFolder => '新增資料夾';

  @override
  String get compressorOutputFormat => '輸出格式';

  @override
  String get compressorLevel => '壓縮等級';

  @override
  String get compressorLevelFast => '快速';

  @override
  String get compressorLevelNormal => '標準';

  @override
  String get compressorLevelUltra => '極致';

  @override
  String get compressorDeleteSource => '完成後刪除來源';

  @override
  String get compressorSameFolder => '與來源相同資料夾';

  @override
  String compressorButton(int count) {
    return '壓縮（$count 個檔案）';
  }

  @override
  String get compressorSkipped => '略過（已壓縮）';

  @override
  String get m3uTitle => 'M3U 產生器';

  @override
  String get m3uDropHint => '將光碟檔案拖曳至此';

  @override
  String get m3uOutputLabel => '輸出資料夾';

  @override
  String get m3uButton => '產生 M3U';

  @override
  String m3uSuccess(String filename) {
    return '已建立：$filename';
  }

  @override
  String get cueGeneratorTitle => 'CUE 產生器';

  @override
  String get cueGeneratorBinFile => 'BIN 檔案';

  @override
  String get cueGeneratorDetectedMode => '偵測模式';

  @override
  String get cueGeneratorButton => '產生 CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return '已建立：$filename';
  }

  @override
  String get binMergerTitle => 'BIN 合併器';

  @override
  String get binMergerCueFile => 'CUE 檔案（多音軌）';

  @override
  String binMergerDetected(int count) {
    return '偵測到：$count 個 BIN 檔案';
  }

  @override
  String get binMergerButton => '合併 BIN';

  @override
  String binMergerSuccess(String filename) {
    return '已合併：$filename';
  }

  @override
  String get headerRemoverTitle => '檔頭移除器';

  @override
  String get headerRemoverSystem => '系統';

  @override
  String get headerRemoverFound => '找到檔頭';

  @override
  String get headerRemoverNotFound => '找不到檔頭';

  @override
  String get headerRemoverConfidence => '信心度';

  @override
  String get headerRemoverBackup => '保留備份（.bak）';

  @override
  String get headerRemoverButton => '移除檔頭';

  @override
  String headerRemoverSuccess(String filename) {
    return '乾淨的 ROM：$filename';
  }

  @override
  String get headerRemoverNoHeader => '未偵測到檔頭。';

  @override
  String get dreamcastTitle => 'Dreamcast';

  @override
  String get dreamcastDcpTab => '套用 DCP';

  @override
  String get dreamcastIpbinTab => 'IP.BIN 編輯器';

  @override
  String get dreamcastGdiTab => 'GDI 資訊';

  @override
  String get dreamcastDiscDir => '光碟目錄';

  @override
  String get dreamcastDcpFile => 'DCP 修補檔案';

  @override
  String get dreamcastOutputDir => '輸出目錄';

  @override
  String get dreamcastApplyButton => '套用 DCP 修補';

  @override
  String get dreamcastApplySuccess => 'DCP 修補成功套用！';

  @override
  String get dreamcastIpbinFile => 'IP.BIN 或 GDI 檔案';

  @override
  String get dreamcastIpbinLoad => '載入';

  @override
  String get dreamcastIpbinSave => '儲存變更';

  @override
  String get dreamcastIpbinTitle => '遊戲名稱';

  @override
  String get dreamcastIpbinProductNumber => '產品編號';

  @override
  String get dreamcastIpbinVersion => '版本';

  @override
  String get dreamcastIpbinDate => '發售日期';

  @override
  String get dreamcastIpbinRegion => '區域';

  @override
  String get dreamcastIpbinRegionJapan => '日本';

  @override
  String get dreamcastIpbinRegionUSA => '美國';

  @override
  String get dreamcastIpbinRegionEurope => '歐洲';

  @override
  String get dreamcastIpbinRegionFree => '全區';

  @override
  String get dreamcastIpbinVga => '啟用 VGA';

  @override
  String get dreamcastIpbinSaveSuccess => 'IP.BIN 已成功儲存！';

  @override
  String get dreamcastGdiFile => 'GDI 檔案';

  @override
  String get dreamcastGdiLoad => '載入 GDI';

  @override
  String get dreamcastGdiTracks => '軌道列表';

  @override
  String get dreamcastGdiTrackNum => '軌道';

  @override
  String get dreamcastGdiTrackLba => 'LBA';

  @override
  String get dreamcastGdiTrackType => '類型';

  @override
  String get dreamcastGdiTrackSize => '磁區大小';

  @override
  String get dreamcastGdiTrackFile => '檔案';

  @override
  String get dreamcastGdiAudio => '音訊';

  @override
  String get dreamcastGdiData => '資料';

  @override
  String get dreamcastSameFolder => '與來源相同資料夾';

  @override
  String get dreamcastBrowse => '瀏覽';

  @override
  String get onlineFeaturesSection => '線上功能';

  @override
  String get onlineFeaturesSub => '所有功能均為選擇性啟用。未經您同意，不會收集任何資料。';

  @override
  String get autoUpdateTitle => '自動檢查更新';

  @override
  String get autoUpdateSub => '啟動時在 GitHub 上檢查新版本';

  @override
  String get autoUpdateCheckNow => '立即檢查';

  @override
  String autoUpdateUpToDate(String version) {
    return '已是最新版本（$version）';
  }

  @override
  String autoUpdateAvailable(String version) {
    return '有可用更新：v$version';
  }

  @override
  String get autoUpdateDownload => '下載';

  @override
  String get raSection => 'RetroAchievements';

  @override
  String get raEnabledTitle => '啟用 RetroAchievements 雜湊檢查';

  @override
  String get raEnabledSub => '載入前檢查您的 ROM 是否受支援';

  @override
  String get raUsername => '使用者名稱';

  @override
  String get raApiKey => 'API 金鑰';

  @override
  String get raApiKeyHint => '於 retroachievements.org/settings 取得您的金鑰';

  @override
  String get raHashChecking => '檢查雜湊中...';

  @override
  String raHashFound(String title, int count) {
    return '✅ 已支援 — $title（$count 個成就）';
  }

  @override
  String get raHashNotFound => '⚠️ 在 RetroAchievements 上找不到';

  @override
  String raHashError(String msg) {
    return '錯誤：$msg';
  }

  @override
  String get raViewGame => '在 RA 上檢視';

  @override
  String get raSaveCredentials => '儲存';

  @override
  String get navPatch => '套用修補';

  @override
  String get navTools => '工具';

  @override
  String get navPlugins => '外掛';

  @override
  String get mediaTypeTitle => '無法辨識媒體類型';

  @override
  String mediaTypeBody(String file) {
    return '無法辨識媒體類型：這個遊戲是 CD 還是 DVD？\n\n檔案：$file';
  }

  @override
  String get mediaCd => 'CD';

  @override
  String get mediaDvd => 'DVD';

  @override
  String get commonCancel => '取消';

  @override
  String get commonOk => '確定';

  @override
  String get commonAdd => '新增';

  @override
  String get commonDone => '完成';

  @override
  String get commonApply => '套用';

  @override
  String get commonRemove => '移除';

  @override
  String get commonInstall => '安裝';

  @override
  String get pluginsTabInstalled => '已安裝外掛 📦';

  @override
  String get pluginsTabStore => '外掛商店 🌐🛒';

  @override
  String get pluginsTabStudio => '建立 / 工作室 🛠️';

  @override
  String get pluginsDropTitle => '將 .orplug 壓縮包拖放到這裡';

  @override
  String get pluginsDropSubtitle => '安裝自訂 ROM 工具、擴充功能與格式';

  @override
  String get pluginsBrowse => '瀏覽 .orplug 檔案';

  @override
  String pluginsInstalledHeading(int count) {
    return '已安裝外掛（$count）';
  }

  @override
  String get pluginsEmptyTitle => '尚未安裝任何外掛';

  @override
  String get pluginsEmptyBody => '將 .orplug 套件拖放到上方，或到外掛商店探索社群外掛。';

  @override
  String get pluginsUninstall => '解除安裝';

  @override
  String get pluginsUninstallTitle => '解除安裝外掛';

  @override
  String pluginsUninstallBody(String name, String id) {
    return '確定要解除安裝「$name」（$id）嗎？';
  }

  @override
  String get pluginsInstallFailed => '安裝失敗';

  @override
  String pluginsAlreadyInstalled(String name) {
    return '$name 已經安裝過了';
  }

  @override
  String pluginsInstalledToast(String name) {
    return '已安裝 $name';
  }

  @override
  String get storeTitle => '外掛市集';

  @override
  String get storeRefresh => '重新整理目錄';

  @override
  String get storeSubtitleLive => '由商店即時提供的官方與社群外掛。';

  @override
  String get storeSubtitleCached => '目前顯示上次快取的目錄，重新連線後可更新。';

  @override
  String get storeBadgeLive => '線上';

  @override
  String get storeBadgeOffline => '離線';

  @override
  String get storeSearchHint => '搜尋外掛、發佈者、轉換路徑…';

  @override
  String get storeAll => '全部';

  @override
  String get storeOfflineTitle => 'ROMéo 離線了';

  @override
  String get storeEmptyTitle => '還沒有任何外掛上架';

  @override
  String get storeNoMatchTitle => '沒有符合條件的外掛';

  @override
  String get storeOfflineBody => '無法連線到商店，而且本機沒有快取。請檢查網路連線後重新整理。';

  @override
  String get storeEmptyBody => '敬請期待，新外掛會陸續上架。';

  @override
  String get storeNoMatchBody => '換個關鍵字或分類試試看。';

  @override
  String get storeVerifiedPublisher => '已驗證發佈者';

  @override
  String get storeInstalled => '已安裝';

  @override
  String storeByPublisher(String name) {
    return '作者：$name';
  }

  @override
  String storeCoreMin(String version) {
    return '核心 ≥ $version';
  }

  @override
  String get deepLinkTitle => '要從連結安裝外掛嗎？';

  @override
  String get deepLinkBody => '有 openrom:// 連結要求安裝外掛，請先確認內容再繼續。';

  @override
  String get deepLinkPlugin => '外掛';

  @override
  String get deepLinkId => '識別碼';

  @override
  String get deepLinkVersion => '版本';

  @override
  String get deepLinkPublisher => '發佈者';

  @override
  String get deepLinkCategory => '分類';

  @override
  String get deepLinkRequiresCore => '需要核心版本';

  @override
  String get deepLinkVerified => '安裝前會以商店公佈的 SHA-256 驗證下載檔案。';

  @override
  String get deepLinkNotFoundTitle => '找不到外掛';

  @override
  String deepLinkNotFoundBody(String id) {
    return '商店目錄中找不到識別碼為「$id」的外掛。';
  }

  @override
  String get studioTitle => '視覺化 .orplug 製作工作室';

  @override
  String get studioIntro => '建立新外掛，或開啟現有的專案資料夾。';

  @override
  String get studioNew => '新增';

  @override
  String get studioOpen => '開啟';

  @override
  String get studioRescan => '重新掃描專案';

  @override
  String get studioIdentity => '基本資料';

  @override
  String get studioPluginId => '外掛識別碼';

  @override
  String get studioDisplayName => '顯示名稱';

  @override
  String get studioVersion => '版本（SemVer）';

  @override
  String get studioMinCore => '最低核心版本';

  @override
  String get studioCategory => '分類';

  @override
  String get studioPublisher => '發佈者';

  @override
  String get studioPublisherId => '發佈者識別碼';

  @override
  String get studioPublisherName => '發佈者名稱';

  @override
  String get studioVerified => '已驗證';

  @override
  String get studioVerifiedTip => '已驗證的發佈者會在商店顯示藍色勾選標記。';

  @override
  String get studioDescriptionRoutes => '說明與轉換路徑';

  @override
  String get studioDescription => '說明';

  @override
  String get studioRouteHint => '新增轉換路徑（例如 ISO -> WUA）';

  @override
  String get studioNoRoutes => '尚未新增任何轉換路徑。';

  @override
  String get studioBinaries => '執行檔';

  @override
  String get studioBinariesHelp => '每個平台附加一個執行檔。儲存或建置時會自動計算 SHA-256。';

  @override
  String get studioNotSet => '未設定';

  @override
  String get studioReplace => '替換';

  @override
  String get studioExecutionArgs => '執行參數';

  @override
  String get studioPlaceholders =>
      '預留欄位：bin（執行檔）、in（輸入）、out（輸出）、outdir（輸出目錄）、cue（cue 檔）';

  @override
  String get studioArgsTemplate => '參數範本';

  @override
  String get studioBuild => '建置';

  @override
  String get studioSaveManifest => '儲存資訊清單';

  @override
  String get studioValidate => '驗證';

  @override
  String get studioBuildPackage => '建置 .orplug';

  @override
  String studioLastBuild(String path, String sha) {
    return '上次建置：$path · sha256 $sha';
  }

  @override
  String get studioCopyMarketplace => '複製市集 JSON';

  @override
  String get studioMarketplaceCopied => '已複製市集 JSON';

  @override
  String get studioManifestValid => '資訊清單有效';

  @override
  String get studioValidationIssues => '驗證問題';

  @override
  String get studioBuiltTitle => '已建置 .orplug';

  @override
  String get studioArchive => '壓縮包';

  @override
  String get studioSize => '大小';

  @override
  String studioSizeBytes(int bytes) {
    return '$bytes 位元組';
  }

  @override
  String get studioMarketplaceEntry => '市集項目（貼到商店目錄）：';

  @override
  String get studioCopyJson => '複製 JSON';

  @override
  String get studioNewProjectTitle => '選擇外掛的建立位置';

  @override
  String get studioOpenProjectTitle => '選擇外掛專案資料夾';

  @override
  String get studioDefaultName => '我的工具';

  @override
  String get themeEditorTitle => '主題編輯器';

  @override
  String get themeCustomSkin => '自訂外觀';

  @override
  String get themeCustomTheme => '自訂主題';

  @override
  String get themeThemeName => '主題名稱';

  @override
  String get themePickWallpaper => '選擇桌布（GIF、PNG、JPG 或 WebP）';

  @override
  String get themePickDropzone => '選擇拖放區插圖（GIF 或 PNG）';

  @override
  String get themePickFont => '選擇介面字型（TTF 或 OTF）';

  @override
  String get themeImportSkinBundle => '匯入 .orskin 外觀包';

  @override
  String get themeExportSkinBundle => '匯出 .orskin 外觀包';

  @override
  String get themeImportShort => '匯入 .orskin';

  @override
  String get themeExportShort => '匯出 .orskin';

  @override
  String themeImportFailed(String error) {
    return '匯入失敗：$error';
  }

  @override
  String themeExportFailed(String error) {
    return '匯出失敗：$error';
  }

  @override
  String themeImported(String name) {
    return '已匯入外觀「$name」';
  }

  @override
  String themeExported(String path) {
    return '已匯出 $path';
  }

  @override
  String get themePickColor => '選擇顏色';

  @override
  String get themeHue => '色相';

  @override
  String get themeSaturation => '飽和度';

  @override
  String get themeValue => '明度';

  @override
  String get themeColors => '顏色';

  @override
  String get themeBackground => '背景';

  @override
  String get themeSurface => '表面色';

  @override
  String get themeAccent => '強調色';

  @override
  String get themeTextPrimary => '主要文字';

  @override
  String get themeTextSecondary => '次要文字';

  @override
  String get themeSidebarBg => '側邊欄背景';

  @override
  String get themeCardBg => '卡片背景';

  @override
  String get themeTerminalBg => '終端機背景';

  @override
  String get themeTerminalText => '終端機文字';

  @override
  String get themeGeometry => '外觀幾何與桌布';

  @override
  String get themeCornerRadius => '圓角半徑';

  @override
  String get themeWallpaperOpacity => '桌布不透明度';

  @override
  String get themeWallpaperBlur => '桌布模糊';

  @override
  String get themeChooseWallpaper => '選擇桌布';

  @override
  String get themeChooseDropzone => '選擇拖放區';

  @override
  String get themeChooseFont => '選擇字型';

  @override
  String get themeSidebarTabs => '側邊欄分頁';

  @override
  String get themeSidebarTabsHelp => '取消勾選即可從側邊欄與導覽中隱藏。';

  @override
  String get themeSaveTheme => '儲存主題';

  @override
  String get themeLivePreview => '即時預覽';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsAudioCodec => 'CD 音訊編碼（CHD）';

  @override
  String get settingsCodecFlac => '無損（FLAC）－建議使用';

  @override
  String get settingsCodecVorbis => '最大壓縮（Vorbis）';

  @override
  String get settingsVerifySub => '對新建立的 CHD 檔案執行 chdman verify';

  @override
  String get settingsSameFolder => '與來源檔案相同的資料夾';

  @override
  String get settingsSelectDir => '選擇資料夾…';

  @override
  String get settingsThemeSystem => '跟隨系統';

  @override
  String get settingsThemeLight => '淺色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsUpdateError => '檢查更新時發生錯誤';

  @override
  String get settingsRaSaved => '已儲存 RetroAchievements 認證';

  @override
  String get settingsHasheous => 'Hasheous';

  @override
  String get settingsHasheousEnable => '啟用 Hasheous 雜湊查詢';

  @override
  String get settingsHasheousSub =>
      '將 ROM 的 SHA-1 傳送至 hasheous.org 來辨識遊戲。預設關閉，只會傳送檔案雜湊。';

  @override
  String get batchTitle => '批次處理完成！🎉';

  @override
  String batchSaved(String amount) {
    return '你剛剛節省了 $amount';
  }

  @override
  String batchSavedDetail(String percent, int count) {
    return '（縮減 $percent）共 $count 個遊戲！';
  }

  @override
  String batchAllProcessed(int count) {
    return '全部 $count 個檔案處理完成！';
  }

  @override
  String get batchAwesome => '太棒了！';

  @override
  String get hasheousUnknown => '未知標題';

  @override
  String hasheousMore(int count) {
    return '另有 $count 個來源';
  }

  @override
  String hasheousVerifiedIn(String source) {
    return '已在 $source 驗證';
  }

  @override
  String get hasheousNoMatch => '在保存資料庫中找不到相符項目。';

  @override
  String get toolsTabCue => 'CUE 編輯器';

  @override
  String get toolsTabRenamer => 'ROM 重新命名';

  @override
  String get toolsTab1g1r => '1G1R 整理器';

  @override
  String get toolsTabHasher => 'ROM 雜湊計算';

  @override
  String get toolsWatchTitle => '監看資料夾';

  @override
  String get toolsArcadeTitle => '街機 / MAME';

  @override
  String get toolsHasherIntro => '以單次串流計算 CRC32、MD5、SHA-1 與 SHA-256。';

  @override
  String get toolsHasherDrop => '將 ROM 拖放到這裡，或點擊瀏覽';

  @override
  String get toolsChooseFile => '選擇檔案';

  @override
  String get toolsComputeHashes => '計算雜湊';

  @override
  String get toolsResults => '結果';

  @override
  String get toolsCopyAll => '全部複製';

  @override
  String get toolsFileSize => '檔案大小';

  @override
  String get toolsIdentifying => '辨識中…';

  @override
  String get toolsIdentifyGame => '辨識遊戲（Hasheous）';

  @override
  String get toolsHasheousHint =>
      '會將檔案的 SHA-1 傳送至 hasheous.org。請在「設定 → 線上功能」中啟用。';

  @override
  String get toolsWatchStopped => '已停止監看。';

  @override
  String get toolsWatchNeedFolders => '請先選擇輸入與輸出資料夾。';

  @override
  String get toolsChooseFolder => '選擇資料夾…';

  @override
  String get toolsWatchIntro => '自動轉換進入資料夾的 ROM。';

  @override
  String get toolsInputFolder => '輸入資料夾';

  @override
  String get toolsOutputFolder => '輸出資料夾';

  @override
  String get toolsTargetFormat => '目標格式';

  @override
  String get toolsDeleteSource => '轉換後刪除來源檔';

  @override
  String get toolsStopWatching => '停止監看';

  @override
  String get toolsStartWatching => '開始監看';

  @override
  String get toolsActive => '運作中';

  @override
  String get toolsLiveLog => '即時記錄';

  @override
  String get toolsNoActivity => '尚無活動。';

  @override
  String themeSaved(String name) {
    return '已儲存主題「$name」！';
  }
}
