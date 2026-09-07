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
}
