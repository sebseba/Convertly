// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Convertir';

  @override
  String get tabHistory => 'Historial';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String get imageTab => 'Imagen';

  @override
  String get documentTab => 'Documento';

  @override
  String get selectImage => 'Seleccionar imagen';

  @override
  String get noImageSelected => 'Ninguna imagen seleccionada';

  @override
  String get selectFromGallery => 'Elegir de la galería';

  @override
  String get takePhoto => 'Tomar foto';

  @override
  String get selectDocument => 'Seleccionar documento (PDF/Word)';

  @override
  String get targetFormat => 'Formato de destino';

  @override
  String get convert => 'Convertir';

  @override
  String get converting => 'Convirtiendo...';

  @override
  String get convertedImage => 'Imagen convertida';

  @override
  String get convertedDocument => 'Documento convertido';

  @override
  String get saveToDevice => 'Guardar en el dispositivo';

  @override
  String get formatLabel => 'Formato';

  @override
  String get sizeLabel => 'Tamaño';

  @override
  String get conversionHistory => 'Historial de conversiones';

  @override
  String get clearHistory => 'Borrar historial';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutSubtitle => 'Versión e información';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Cambiar idioma';

  @override
  String get permissionTitle => 'Permiso requerido';

  @override
  String get permissionBody =>
      'Necesitamos acceso al almacenamiento para guardar archivos.';

  @override
  String get goToSettings => 'Abrir ajustes';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Listo';

  @override
  String get sourceOnline => 'Fuente: CloudConvert';

  @override
  String get sourceOffline => 'Fuente: Offline';
}
