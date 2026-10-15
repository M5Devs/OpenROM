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
}
