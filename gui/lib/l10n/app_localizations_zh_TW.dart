// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizations {
  AppLocalizationsZhTw([String locale = 'zh_TW']) : super(locale);

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
  String get compressionLevel => '壓縮層級';

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
  String get outputDestination => '輸出目標';

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
  String get errorCoreNotFound =>
      '應用程式資料夾中缺少 openrom-core。';

  @override
  String get errorUnsupportedFormat =>
      '此檔案格式無法使用選擇的輸出格式進行轉換。';

  @override
  String get errorDiskSpace =>
      '可用空間不足以完成此次轉換。';

  @override
  String get errorToolFailed =>
      '轉換工具（chdman/maxcso）未預期結束。';

  @override
  String get errorConversionFailed => '轉換在完成前停止。';

  @override
  String get errorFileNotFound => '輸入檔案已被移動或刪除。';

  @override
  String get errorOutputDirNotFound =>
      '選擇的輸出資料夾已不存在。';

  @override
  String get errorPermissionDenied =>
      'OpenROM 無法寫入輸出資料夾。';

  @override
  String get errorCorruptedFile =>
      '檔案似乎已損毀或為 0 bytes。';

  @override
  String get errorUnknown => '發生錯誤。這可能是程式缺陷。';

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
  String get compressorLevel => '壓縮層級';

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
  String get onlineFeaturesSub =>
      '所有功能均為選擇性啟用。未經您同意，不會收集任何資料。';

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
