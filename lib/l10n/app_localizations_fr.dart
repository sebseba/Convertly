// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Convertir';

  @override
  String get tabHistory => 'Historique';

  @override
  String get tabSettings => 'Réglages';

  @override
  String get imageTab => 'Image';

  @override
  String get documentTab => 'Document';

  @override
  String get selectImage => 'Sélectionner une image';

  @override
  String get noImageSelected => 'Aucune image sélectionnée';

  @override
  String get selectFromGallery => 'Depuis la galerie';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get selectDocument => 'Sélectionner un document (PDF/Word)';

  @override
  String get targetFormat => 'Format cible';

  @override
  String get convert => 'Convertir';

  @override
  String get converting => 'Conversion...';

  @override
  String get convertedImage => 'Image convertie';

  @override
  String get convertedDocument => 'Document converti';

  @override
  String get saveToDevice => 'Enregistrer sur l\'appareil';

  @override
  String get formatLabel => 'Format';

  @override
  String get sizeLabel => 'Taille';

  @override
  String get conversionHistory => 'Historique des conversions';

  @override
  String get clearHistory => 'Effacer l\'historique';

  @override
  String get about => 'À propos';

  @override
  String get aboutSubtitle => 'Version & informations';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Changer la langue';

  @override
  String get permissionTitle => 'Autorisation requise';

  @override
  String get permissionBody =>
      'Nous avons besoin de l\'accès stockage pour enregistrer les fichiers.';

  @override
  String get goToSettings => 'Ouvrir les réglages';

  @override
  String get cancel => 'Annuler';

  @override
  String get done => 'Terminé';

  @override
  String get sourceOnline => 'Source : CloudConvert';

  @override
  String get sourceOffline => 'Source : Hors ligne';

  @override
  String get shareFile => 'Share';
}
