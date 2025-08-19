// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Convertly';

  @override
  String get tabConvert => '转换';

  @override
  String get tabHistory => '历史';

  @override
  String get tabSettings => '设置';

  @override
  String get imageTab => '图片';

  @override
  String get documentTab => '文档';

  @override
  String get selectImage => '选择图片';

  @override
  String get noImageSelected => '未选择图片';

  @override
  String get selectFromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get selectDocument => '选择文档（PDF/Word）';

  @override
  String get targetFormat => '目标格式';

  @override
  String get convert => '转换';

  @override
  String get converting => '正在转换…';

  @override
  String get convertedImage => '已转换的图片';

  @override
  String get convertedDocument => '已转换的文档';

  @override
  String get saveToDevice => '保存到设备';

  @override
  String get formatLabel => '格式';

  @override
  String get sizeLabel => '大小';

  @override
  String get conversionHistory => '转换历史';

  @override
  String get clearHistory => '清除历史';

  @override
  String get about => '关于';

  @override
  String get aboutSubtitle => '版本与信息';

  @override
  String get language => '语言';

  @override
  String get languageSubtitle => '更改应用语言';

  @override
  String get permissionTitle => '需要权限';

  @override
  String get permissionBody => '保存文件需要存储权限，请在设置中启用。';

  @override
  String get goToSettings => '打开设置';

  @override
  String get cancel => '取消';

  @override
  String get done => '完成';

  @override
  String get sourceOnline => '来源：CloudConvert';

  @override
  String get sourceOffline => '来源：离线';
}
