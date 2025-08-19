// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Convert';

  @override
  String get tabHistory => 'History';

  @override
  String get tabSettings => 'Settings';

  @override
  String get imageTab => 'Image';

  @override
  String get documentTab => 'Document';

  @override
  String get selectImage => 'Select Image';

  @override
  String get noImageSelected => 'No image selected';

  @override
  String get selectFromGallery => 'Pick from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get selectDocument => 'Select Document (PDF/Word)';

  @override
  String get targetFormat => 'Target Format';

  @override
  String get convert => 'Convert';

  @override
  String get converting => 'Converting...';

  @override
  String get convertedImage => 'Converted Image';

  @override
  String get convertedDocument => 'Converted Document';

  @override
  String get saveToDevice => 'Save to device';

  @override
  String get formatLabel => 'Format';

  @override
  String get sizeLabel => 'Size';

  @override
  String get conversionHistory => 'Conversion History';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get about => 'About';

  @override
  String get aboutSubtitle => 'App version & information';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Change app language';

  @override
  String get permissionTitle => 'Permission required';

  @override
  String get permissionBody =>
      'We need storage permission to save files. Please enable it in settings.';

  @override
  String get goToSettings => 'Open settings';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get sourceOnline => 'Source: CloudConvert';

  @override
  String get sourceOffline => 'Source: Offline fallback';

  @override
  String get shareFile => 'Share';
}
