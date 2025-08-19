// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Dönüştür';

  @override
  String get tabHistory => 'Geçmiş';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get imageTab => 'Resim';

  @override
  String get documentTab => 'Döküman';

  @override
  String get selectImage => 'Resim Seç';

  @override
  String get noImageSelected => 'Resim seçilmedi';

  @override
  String get selectFromGallery => 'Galeriden Seç';

  @override
  String get takePhoto => 'Fotoğraf Çek';

  @override
  String get selectDocument => 'Döküman Seç (PDF/Word)';

  @override
  String get targetFormat => 'Hedef Format';

  @override
  String get convert => 'Dönüştür';

  @override
  String get converting => 'Dönüştürülüyor...';

  @override
  String get convertedImage => 'Dönüştürülmüş Resim';

  @override
  String get convertedDocument => 'Dönüştürülmüş Döküman';

  @override
  String get saveToDevice => 'Telefona Kaydet';

  @override
  String get formatLabel => 'Format';

  @override
  String get sizeLabel => 'Boyut';

  @override
  String get conversionHistory => 'Dönüştürme Geçmişi';

  @override
  String get clearHistory => 'Geçmişi Temizle';

  @override
  String get about => 'Hakkında';

  @override
  String get aboutSubtitle => 'Uygulama sürümü ve bilgileri';

  @override
  String get language => 'Dil';

  @override
  String get languageSubtitle => 'Uygulama dilini değiştir';

  @override
  String get permissionTitle => 'İzin Gerekli';

  @override
  String get permissionBody =>
      'Dosyayı kaydetmek için depolama iznine ihtiyacımız var. Lütfen ayarlardan izin verin.';

  @override
  String get goToSettings => 'Ayarlar';

  @override
  String get cancel => 'İptal';

  @override
  String get done => 'Tamam';

  @override
  String get sourceOnline => 'Kaynak: CloudConvert';

  @override
  String get sourceOffline => 'Kaynak: Offline mod';
}
