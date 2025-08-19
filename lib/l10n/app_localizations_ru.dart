// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Конвертировать';

  @override
  String get tabHistory => 'История';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get imageTab => 'Изображение';

  @override
  String get documentTab => 'Документ';

  @override
  String get selectImage => 'Выбрать изображение';

  @override
  String get noImageSelected => 'Изображение не выбрано';

  @override
  String get selectFromGallery => 'Из галереи';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get selectDocument => 'Выбрать документ (PDF/Word)';

  @override
  String get targetFormat => 'Целевой формат';

  @override
  String get convert => 'Конвертировать';

  @override
  String get converting => 'Конвертация...';

  @override
  String get convertedImage => 'Преобразованное изображение';

  @override
  String get convertedDocument => 'Преобразованный документ';

  @override
  String get saveToDevice => 'Сохранить на устройство';

  @override
  String get formatLabel => 'Формат';

  @override
  String get sizeLabel => 'Размер';

  @override
  String get conversionHistory => 'История конвертаций';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get about => 'О приложении';

  @override
  String get aboutSubtitle => 'Версия и информация';

  @override
  String get language => 'Язык';

  @override
  String get languageSubtitle => 'Изменить язык';

  @override
  String get permissionTitle => 'Требуется разрешение';

  @override
  String get permissionBody => 'Нужен доступ к памяти для сохранения файлов.';

  @override
  String get goToSettings => 'Открыть настройки';

  @override
  String get cancel => 'Отмена';

  @override
  String get done => 'Готово';

  @override
  String get sourceOnline => 'Источник: CloudConvert';

  @override
  String get sourceOffline => 'Источник: Офлайн';

  @override
  String get shareFile => 'Share';
}
