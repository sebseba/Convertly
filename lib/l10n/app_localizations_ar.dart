// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كونفرتلي';

  @override
  String get tabConvert => 'تحويل';

  @override
  String get tabHistory => 'السجل';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get imageTab => 'صورة';

  @override
  String get documentTab => 'مستند';

  @override
  String get selectImage => 'اختر صورة';

  @override
  String get noImageSelected => 'لم يتم اختيار صورة';

  @override
  String get selectFromGallery => 'من المعرض';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get selectDocument => 'اختر مستندًا (PDF/Word)';

  @override
  String get targetFormat => 'الصيغة المستهدفة';

  @override
  String get convert => 'حوّل';

  @override
  String get converting => 'جاري التحويل...';

  @override
  String get convertedImage => 'الصورة المحولة';

  @override
  String get convertedDocument => 'المستند المحول';

  @override
  String get saveToDevice => 'حفظ على الجهاز';

  @override
  String get formatLabel => 'الصيغة';

  @override
  String get sizeLabel => 'الحجم';

  @override
  String get conversionHistory => 'سجل التحويلات';

  @override
  String get clearHistory => 'مسح السجل';

  @override
  String get about => 'حول';

  @override
  String get aboutSubtitle => 'إصدار التطبيق والمعلومات';

  @override
  String get language => 'اللغة';

  @override
  String get languageSubtitle => 'تغيير لغة التطبيق';

  @override
  String get permissionTitle => 'مطلوب إذن';

  @override
  String get permissionBody =>
      'نحتاج إذن التخزين لحفظ الملفات. يرجى تفعيله من الإعدادات.';

  @override
  String get goToSettings => 'فتح الإعدادات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get done => 'تم';

  @override
  String get sourceOnline => 'المصدر: CloudConvert';

  @override
  String get sourceOffline => 'المصدر: دون اتصال';
}
