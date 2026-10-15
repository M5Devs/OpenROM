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
}
