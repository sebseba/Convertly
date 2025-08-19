// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => 'Converter';

  @override
  String get tabHistory => 'Histórico';

  @override
  String get tabSettings => 'Configurações';

  @override
  String get imageTab => 'Imagem';

  @override
  String get documentTab => 'Documento';

  @override
  String get selectImage => 'Selecionar imagem';

  @override
  String get noImageSelected => 'Nenhuma imagem selecionada';

  @override
  String get selectFromGallery => 'Da galeria';

  @override
  String get takePhoto => 'Tirar foto';

  @override
  String get selectDocument => 'Selecionar documento (PDF/Word)';

  @override
  String get targetFormat => 'Formato de destino';

  @override
  String get convert => 'Converter';

  @override
  String get converting => 'Convertendo...';

  @override
  String get convertedImage => 'Imagem convertida';

  @override
  String get convertedDocument => 'Documento convertido';

  @override
  String get saveToDevice => 'Salvar no dispositivo';

  @override
  String get formatLabel => 'Formato';

  @override
  String get sizeLabel => 'Tamanho';

  @override
  String get conversionHistory => 'Histórico de conversões';

  @override
  String get clearHistory => 'Limpar histórico';

  @override
  String get about => 'Sobre';

  @override
  String get aboutSubtitle => 'Versão e informações';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Alterar idioma';

  @override
  String get permissionTitle => 'Permissão necessária';

  @override
  String get permissionBody =>
      'Precisamos de acesso ao armazenamento para salvar arquivos.';

  @override
  String get goToSettings => 'Abrir configurações';

  @override
  String get cancel => 'Cancelar';

  @override
  String get done => 'Concluir';

  @override
  String get sourceOnline => 'Fonte: CloudConvert';

  @override
  String get sourceOffline => 'Fonte: Offline';
}
