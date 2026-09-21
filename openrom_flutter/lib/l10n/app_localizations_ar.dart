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
  String get dreamcastGdiTrackFile => 'الملف';

  @override
  String get dreamcastGdiAudio => 'صوت';

  @override
  String get dreamcastGdiData => 'بيانات';

  @override
  String get dreamcastSameFolder => 'نفس مجلد المصدر';

  @override
  String get dreamcastBrowse => 'استعراض';
}
