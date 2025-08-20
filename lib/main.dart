import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:convertly_mobile_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';


/// Seçili dili (Locale) tutar
final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // .env içeriğini oku

  // Kaydedilmiş dil varsa yükle
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('app_locale');
  if (saved != null && saved.isNotEmpty) {
    appLocale.value = Locale(saved);
  }

  runApp(MyApp());
}

class ConversionHistory {
  final String id;
  final Uint8List? imageBytes; // Nullable for document files
  final String format;
  final String filePath;
  final DateTime timestamp;
  final int fileSize;
  final String fileName;
  final ConversionType type; // Image or Document

  ConversionHistory({
    required this.id,
    this.imageBytes,
    required this.format,
    required this.filePath,
    required this.timestamp,
    required this.fileSize,
    required this.fileName,
    required this.type,
  });
}

enum ConversionType { image, document }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (_, locale, __) {
        return MaterialApp(
          title: 'Convertly',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, supported) {
            if (locale != null) return locale;
            if (device == null) return const Locale('en');
            for (final l in supported) {
              if (l.languageCode == device.languageCode) return l;
            }
            return const Locale('en');
          },
          theme: ThemeData(
            primarySwatch: Colors.purple,
            scaffoldBackgroundColor: const Color(0xFFE8D5F0),
            fontFamily: 'Roboto',
          ),
          home: ImageConverterScreen(),
        );
      },
    );
  }
}

/// context.l10n kısayolu
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class ImageConverterScreen extends StatefulWidget {
  @override
  _ImageConverterScreenState createState() => _ImageConverterScreenState();
}

class _ImageConverterScreenState extends State<ImageConverterScreen> {
  File? _selectedImage;
  File? _selectedDocument; // PDF or Word document
  Uint8List? _convertedImageBytes;
  Uint8List? _convertedDocumentBytes;
  String _selectedFormat = 'JPG';
  String _selectedDocumentFormat = 'PDF';
  String _originalFormat = '';
  String _originalDocumentFormat = '';
  int _originalSize = 0;
  int _convertedSize = 0;
  bool _isConverting = false;
  int _selectedBottomNavIndex = 0;
  int _selectedConverterTab = 0; // 0: Image, 1: Document
  List<ConversionHistory> _conversionHistory = [];

  final ImagePicker _picker = ImagePicker();
  final List<String> _formats = ['JPG', 'PNG'];
  final List<String> _documentFormats = ['PDF', 'DOCX'];

  // Method channel for native operations
  static const MethodChannel _platform = MethodChannel('com.convertly.channel');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // "Conve" normal yazı
            Text(
              'Convertly',
              style: GoogleFonts.pacifico(
                textStyle: const TextStyle(
                  fontSize: 36,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),

        centerTitle: true,
      ),
      body: _selectedBottomNavIndex == 0
          ? _buildConverterPage()
          : _selectedBottomNavIndex == 1
              ? _buildHistoryPage()
              : _buildSettingsPage(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildConverterPage() {
    return Column(
      children: [
        // Tab Bar for Image/Document selection
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedConverterTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedConverterTab == 0
                          ? const Color(0xFF6B46C1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          color: _selectedConverterTab == 0
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.imageTab,
                          style: TextStyle(
                            color: _selectedConverterTab == 0
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedConverterTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedConverterTab == 1
                          ? const Color(0xFF6B46C1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description,
                          color: _selectedConverterTab == 1
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.documentTab,
                          style: TextStyle(
                            color: _selectedConverterTab == 1
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content based on selected tab
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _selectedConverterTab == 0
                ? _buildImageConverter()
                : _buildDocumentConverter(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageConverter() {
    return Column(
      children: [
        // Image Selection Section
        _buildImageSelectionCard(),

        const SizedBox(height: 20),

        // Target Format Selection
        _buildFormatSelectionCard(),

        const SizedBox(height: 20),

        // Convert Button
        _buildConvertButton(),

        const SizedBox(height: 20),

        // Converted Image Section
        if (_convertedImageBytes != null) _buildConvertedImageCard(),
      ],
    );
  }

  Widget _buildDocumentConverter() {
    return Column(
      children: [
        // Document Selection Section
        _buildDocumentSelectionCard(),

        const SizedBox(height: 20),

        // Target Document Format Selection
        _buildDocumentFormatSelectionCard(),

        const SizedBox(height: 20),

        // Convert Document Button
        _buildConvertDocumentButton(),

        const SizedBox(height: 20),

        // Converted Document Section
        if (_convertedDocumentBytes != null) _buildConvertedDocumentCard(),
      ],
    );
  }

  Widget _buildDocumentSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectDocument.replaceAll(' (PDF/Word)', ''),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedDocument == null)
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noImageSelected, // kısa boş durum metni
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _originalDocumentFormat == 'PDF'
                        ? Icons.picture_as_pdf
                        : Icons.description,
                    size: 40,
                    color: const Color(0xFF6B46C1),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDocument!.path.split('/').last,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${context.l10n.formatLabel}: $_originalDocumentFormat',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.folder_open, color: Colors.white),
              label: Text(
                context.l10n.selectDocument,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          if (_selectedDocument != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${context.l10n.sizeLabel}: ${(_originalSize / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDocumentFormatSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.targetFormat,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: _selectedDocumentFormat,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDocumentFormat = newValue!;
                });
              },
              items:
                  _documentFormats.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Icon(
                        value == 'PDF'
                            ? Icons.picture_as_pdf
                            : Icons.description,
                        color: const Color(0xFF6B46C1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        value == 'PDF' ? 'PDF' : 'Word (.docx)',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertDocumentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed:
            _selectedDocument != null && !_isConverting ? _convertDocument : null,
        icon: _isConverting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.transform, color: Colors.white),
        label: Text(
          _isConverting ? context.l10n.converting : context.l10n.convert,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedDocument != null ? const Color(0xFF6B46C1) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConvertedDocumentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.convertedDocument,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedDocumentFormat == 'PDF'
                      ? Icons.picture_as_pdf
                      : Icons.description,
                  size: 60,
                  color: const Color(0xFF6B46C1),
                ),
                const SizedBox(height: 12),
                Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
                Text(
                  '${context.l10n.formatLabel}: $_selectedDocumentFormat',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${context.l10n.sizeLabel}: ${(_convertedSize / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveDocumentToDevice,
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: Text(
                context.l10n.saveToDevice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.conversionHistory,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          if (_conversionHistory.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '—',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ' ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: _conversionHistory.length,
                itemBuilder: (context, index) {
                  final history = _conversionHistory[index];
                  return _buildHistoryCard(history);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ConversionHistory history) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image or Document Icon
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: history.type == ConversionType.image
                    ? Colors.blue[50]
                    : Colors.purple[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: history.type == ConversionType.image &&
                      history.imageBytes != null
                  ? ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.memory(
                        history.imageBytes!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            history.format == 'PDF'
                                ? Icons.picture_as_pdf
                                : Icons.description,
                            size: 40,
                            color: const Color(0xFF6B46C1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            history.fileName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Info Section
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format and Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B46C1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.format,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: history.type == ConversionType.image
                              ? Colors.blue[100]
                              : Colors.purple[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          history.type == ConversionType.image ? 'IMG' : 'DOC',
                          style: TextStyle(
                            color: history.type == ConversionType.image
                                ? Colors.blue[700]
                                : Colors.purple[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // File size
                  Text(
                    '${(history.fileSize / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),

                  // Date
                  Text(
                    _formatDate(history.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),

                  const Spacer(),

                  // Open folder button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: InkWell(
                      onTap: () => _openFileLocation(history.filePath),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8D5F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.folder_open,
                          size: 18,
                          color: Color(0xFF6B46C1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPage() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tabSettings,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // Dil seçimi
          _buildSettingItem(
            icon: Icons.language,
            title: context.l10n.language,
            subtitle: context.l10n.languageSubtitle,
            onTap: _showLanguagePicker,
          ),

          _buildSettingItem(
            icon: Icons.history,
            title: context.l10n.clearHistory,
            subtitle: context.l10n.conversionHistory,
            onTap: _clearHistory,
          ),

          _buildSettingItem(
            icon: Icons.info_outline,
            title: context.l10n.about,
            subtitle: context.l10n.aboutSubtitle,
            onTap: () => _showAboutDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFE8D5F0),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6B46C1),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
      ),
    );
  }

  // Dil seçici
  Future<void> _showLanguagePicker() async {
    final langs = <({String code, String label})>[
      (code: 'en', label: 'English'),
      (code: 'tr', label: 'Türkçe'),
      (code: 'de', label: 'Deutsch'),
      (code: 'fr', label: 'Français'),
      (code: 'es', label: 'Español'),
      (code: 'it', label: 'Italiano'),
      (code: 'pt', label: 'Português'),
      (code: 'ar', label: 'العربية'),
      (code: 'ru', label: 'Русский'),
      (code: 'hi', label: 'हिन्दी'),
      (code: 'zh', label: '中文(简体)'),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          children: [
            for (final it in langs)
              ListTile(
                title: Text(it.label),
                onTap: () async {
                  appLocale.value = Locale(it.code);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('app_locale', it.code);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildImageSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.selectImage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedImage == null)
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.noImageSelected,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImageFromGallery(),
                  icon: const Icon(Icons.photo_library, color: Colors.white),
                  label: Text(
                    context.l10n.selectFromGallery,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickImageFromCamera(),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: Text(
                    context.l10n.takePhoto,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B46C1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '${context.l10n.formatLabel}: $_originalFormat | ${context.l10n.sizeLabel}: ${(_originalSize / 1024).toStringAsFixed(1)} KB',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormatSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.targetFormat,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: _selectedFormat,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedFormat = newValue!;
                });
              },
              items: _formats.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConvertButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _selectedImage != null && !_isConverting ? _convertImage : null,
        icon: _isConverting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh, color: Colors.white),
        label: Text(
          _isConverting ? context.l10n.converting : context.l10n.convert,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _selectedImage != null ? const Color(0xFF6B46C1) : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildConvertedImageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.convertedImage,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _convertedImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '${context.l10n.formatLabel}: $_selectedFormat | ${context.l10n.sizeLabel}: ${(_convertedSize / 1024).toStringAsFixed(1)} KB',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveImageToDevice,
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: Text(
                context.l10n.saveToDevice,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareImageFile,
              icon: const Icon(Icons.share, color: Colors.white),
              label: Text(
                context.l10n.shareFile ?? 'Paylaş',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46C1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImageFile() async {
    if (_convertedImageBytes == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/converted_$timestamp.${_selectedFormat.toLowerCase()}';
      final file = File(filePath);
      await file.writeAsBytes(_convertedImageBytes!);


      await Share.shareXFiles([XFile(filePath)], text: 'Convertly ile dönüştürdüğüm dosya!');
    } catch (e) {
    _showErrorMessage('Paylaşım başarısız: \$e');
    }
  }
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomNavIndex,
      onTap: (index) {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.black87,
      selectedItemColor: const Color(0xFF6B46C1),
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.transform),
          label: context.l10n.tabConvert,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: context.l10n.tabHistory,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.settings),
          label: context.l10n.tabSettings,
        ),
      ],
    );
  }

  // Document Picker Function
  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        _setSelectedDocument(file);
      }
    } catch (e) {
      _showErrorMessage('Dosya seçme sırasında hata oluştu: $e');
    }
  }

  void _setSelectedDocument(File documentFile) {
    setState(() {
      _selectedDocument = documentFile;
      _convertedDocumentBytes = null;
      _originalSize = documentFile.lengthSync();

      // Detect original format from file extension
      String extension = documentFile.path.split('.').last.toUpperCase();
      if (extension == 'DOC' || extension == 'DOCX') {
        _originalDocumentFormat = 'DOCX';
        _selectedDocumentFormat = 'PDF';
      } else if (extension == 'PDF') {
        _originalDocumentFormat = 'PDF';
        _selectedDocumentFormat = 'DOCX';
      }
    });
  }

  // Document Conversion Function - REAL Implementation with CloudConvert API
  Future<void> _convertDocument() async {
    if (_selectedDocument == null) return;

    setState(() => _isConverting = true);
    try {
      final bytes = await _selectedDocument!.readAsBytes();
      final base64Doc = base64Encode(bytes);

      // 'pdf' veya 'docx' olacak
      final fromFormat = _originalDocumentFormat.toLowerCase();
      final toFormat = _selectedDocumentFormat.toLowerCase();

      // ⚠️ docx'i 'doc' yapma! Doğrudan 'docx' kullan.
      final converted =
          await _callCloudConvertAPI(base64Doc, fromFormat, toFormat);

      if (converted != null) {
        setState(() {
          _convertedDocumentBytes = converted;
          _convertedSize = converted.length;
        });
        _showSuccessMessage('Döküman başarıyla dönüştürüldü!');
      } else {
        await _convertDocumentOffline(); // placeholder fallback
      }
    } catch (e) {
      debugPrint('Online conversion failed: $e');
      await _convertDocumentOffline();
    } finally {
      setState(() => _isConverting = false);
    }
  }

  // 🔑 Yardımcı: API anahtarını iki kaynaktan okumayı dener
  String _readCloudConvertKey() {
    // --dart-define
    const fromDefine =
        String.fromEnvironment('CLOUDCONVERT_API_KEY', defaultValue: '');
    if (fromDefine.isNotEmpty) return fromDefine;

    // .env (dotenv.load çağırdıysan)
    try {
      final fromEnv = dotenv.env['CLOUDCONVERT_API_KEY'];
      if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    } catch (_) {}

    return '';
  }

  // 🌐 CloudConvert API Implementation (güncel)
  Future<Uint8List?> _callCloudConvertAPI(
    String base64File,
    String fromFormat,
    String toFormat,
  ) async {
    final apiKey = _readCloudConvertKey();
    if (apiKey.isEmpty) {
      debugPrint(
          'CloudConvert API key missing. Provide via --dart-define or .env');
      return null; // offline fallback devreye girer
    }

    try {
      // 1) Job oluştur
      final createJobResp = await http
          .post(
            Uri.parse('https://api.cloudconvert.com/v2/jobs'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'tasks': {
                'import-file': {
                  'operation': 'import/base64',
                  'file': base64File,
                  'filename': 'input.$fromFormat',
                },
                'convert-file': {
                  'operation': 'convert',
                  'input': 'import-file',
                  'output_format': toFormat,
                },
                'export-file': {
                  'operation': 'export/url',
                  'input': 'convert-file',
                },
              }
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (createJobResp.statusCode != 201) {
        debugPrint(
            'Create job failed: ${createJobResp.statusCode} ${createJobResp.body}');
        return null;
      }

      final jobId =
          (jsonDecode(createJobResp.body)['data']['id'] as String);

      // 2) Tamamlanana kadar bekle
      await _waitForJobCompletion(jobId, apiKey);

      // 3) İndirme URL’si al ve indir
      final downloadUrl = await _getDownloadUrl(jobId, apiKey);
      if (downloadUrl == null) {
        debugPrint('Download URL not found for job $jobId');
        return null;
      }

      final downloadResp =
          await http.get(Uri.parse(downloadUrl)).timeout(const Duration(minutes: 2));

      if (downloadResp.statusCode == 200) {
        return downloadResp.bodyBytes;
      } else {
        debugPrint(
            'Download failed: ${downloadResp.statusCode} ${downloadResp.body}');
        return null;
      }
    } catch (e, st) {
      debugPrint('CloudConvert API error: $e\n$st');
      return null;
    }
  }

  Future<void> _waitForJobCompletion(String jobId, String apiKey) async {
    for (int i = 0; i < 60; i++) {
      // ~60 sn
      await Future.delayed(const Duration(seconds: 1));
      final resp = await http.get(
        Uri.parse('https://api.cloudconvert.com/v2/jobs/$jobId'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      if (resp.statusCode != 200) continue;
      final data = jsonDecode(resp.body);
      final status = data['data']['status'] as String?;
      if (status == 'finished') return;
      if (status == 'error') throw Exception('CloudConvert job failed');
    }
    throw Exception('CloudConvert job timeout');
  }

  Future<String?> _getDownloadUrl(String jobId, String apiKey) async {
    final resp = await http.get(
      Uri.parse('https://api.cloudconvert.com/v2/jobs/$jobId'),
      headers: {'Authorization': 'Bearer $apiKey'},
    );
    if (resp.statusCode != 200) return null;

    final data = jsonDecode(resp.body);
    final List tasks = (data['data']['tasks'] as List?) ?? [];
    for (final t in tasks) {
      if (t is Map &&
          t['operation'] == 'export/url' &&
          t['status'] == 'finished') {
        final files = t['result']?['files'];
        if (files is List && files.isNotEmpty) {
          final url = files.first['url'];
          if (url is String) return url;
        }
      }
    }
    return null;
  }

  // Offline fallback conversion (simplified)
  Future<void> _convertDocumentOffline() async {
    try {
      Uint8List originalBytes = await _selectedDocument!.readAsBytes();

      // Simple text-based conversion for demo purposes
      if (_originalDocumentFormat == 'PDF' &&
          _selectedDocumentFormat == 'DOCX') {
        _convertedDocumentBytes = await _createSimpleWordDoc(originalBytes);
      } else if (_originalDocumentFormat == 'DOCX' &&
          _selectedDocumentFormat == 'PDF') {
        _convertedDocumentBytes = await _createSimplePDF(originalBytes);
      } else {
        _convertedDocumentBytes = originalBytes;
      }

      setState(() {
        _convertedSize = _convertedDocumentBytes!.length;
      });

      _showSuccessMessage(
          'Döküman dönüştürüldü (Offline mod - Sınırlı kalite)');
    } catch (e) {
      _showErrorMessage('Dönüştürme sırasında hata oluştu: $e');
    }
  }

  // Create a simple Word document (placeholder)
  Future<Uint8List> _createSimpleWordDoc(Uint8List pdfBytes) async {
    String content = '''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:r>
        <w:t>Bu dosya PDF'den Word'e dönüştürülmüştür.</w:t>
      </w:r>
    </w:p>
    <w:p>
      <w:r>
        <w:t>Gerçek içerik için CloudConvert API kullanınız.</w:t>
      </w:r>
    </w:p>
  </w:body>
</w:document>
    ''';
    return Uint8List.fromList(utf8.encode(content));
  }

  // Create a simple PDF document (placeholder)
  Future<Uint8List> _createSimplePDF(Uint8List docxBytes) async {
    String pdfContent = '''%PDF-1.4
1 0 obj
<<
/Type /Catalog
/Pages 2 0 R
>>
endobj

2 0 obj
<<
/Type /Pages
/Kids [3 0 R]
/Count 1
>>
endobj

3 0 obj
<<
/Type /Page
/Parent 2 0 R
/MediaBox [0 0 612 792]
/Contents 4 0 R
>>
endobj

4 0 obj
<<
/Length 64
>>
stream
BT
/F1 12 Tf
100 700 Td
(Bu dosya Word'den PDF'e dönüştürülmüştür.) Tj
ET
endstream
endobj

xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000206 00000 n 
trailer
<<
/Size 5
/Root 1 0 R
>>
startxref
320
%%EOF''';
    return Uint8List.fromList(utf8.encode(pdfContent));
  }

  Future<void> _saveDocumentToDevice() async {
    if (_convertedDocumentBytes == null) return;

    try {
      // Permission handling (same as image saving)
      PermissionStatus status;

      if (Platform.isAndroid) {
        status = await Permission.storage.request();

        if (status != PermissionStatus.granted) {
          status = await Permission.photos.request();
        }

        if (status != PermissionStatus.granted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (status != PermissionStatus.granted) {
          bool shouldOpenSettings = await _showPermissionDialog();
          if (shouldOpenSettings) {
            await openAppSettings();
          }
          return;
        }
      }

      // Directory determination
      Directory? directory;

      if (Platform.isAndroid) {
        List<String> possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Documents',
          '/storage/emulated/0/Pictures',
        ];

        for (String path in possiblePaths) {
          Directory testDir = Directory(path);
          if (await testDir.exists()) {
            directory = testDir;
            break;
          }
        }

        if (directory == null) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null || !await directory.exists()) {
        _showErrorMessage('Kaydetme klasörü bulunamadı!');
        return;
      }

      // Create filename
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension =
          _selectedDocumentFormat.toLowerCase() == 'pdf' ? 'pdf' : 'docx';
      String filename = 'Convertly_Document_$timestamp.$fileExtension';
      String filePath = '${directory.path}/$filename';

      // Save file
      File savedFile = File(filePath);
      await savedFile.writeAsBytes(_convertedDocumentBytes!);

      // Add to history
      _addToHistory(
        null, // No image bytes for documents
        _selectedDocumentFormat,
        filePath,
        ConversionType.document,
        filename,
      );

      _showSuccessMessage('Döküman kaydedildi:\n${directory.path}/$filename');
    } catch (e) {
      _showErrorMessage('Kaydetme sırasında hata oluştu:\n$e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _setSelectedImage(File(image.path));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      _setSelectedImage(File(image.path));
    }
  }

  void _setSelectedImage(File imageFile) {
    setState(() {
      _selectedImage = imageFile;
      _convertedImageBytes = null;
      _originalSize = imageFile.lengthSync();

      // Detect original format from file extension
      String extension = imageFile.path.split('.').last.toUpperCase();
      _originalFormat = extension;

      // Set target format to opposite of original
      if (extension == 'PNG') {
        _selectedFormat = 'JPG';
      } else {
        _selectedFormat = 'PNG';
      }
    });
  }

  Future<void> _convertImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isConverting = true;
    });

    try {
      // Read image bytes
      Uint8List imageBytes = await _selectedImage!.readAsBytes();

      // Decode image
      ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
      ui.FrameInfo frameInfo = await codec.getNextFrame();
      ui.Image image = frameInfo.image;

      // Convert to target format
      ByteData? byteData;
      if (_selectedFormat == 'PNG') {
        byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      } else {
        byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          // Basit şekilde PNG'ye alıyoruz (JPEG encoder yok)
          byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        }
      }

      if (byteData != null) {
        setState(() {
          _convertedImageBytes = byteData!.buffer.asUint8List();
          _convertedSize = _convertedImageBytes!.length;
        });

        _showSuccessMessage('Resim başarıyla dönüştürüldü!');
      }
    } catch (e) {
      _showErrorMessage('Dönüştürme sırasında hata oluştu: $e');
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  Future<void> _saveImageToDevice() async {
    if (_convertedImageBytes == null) return;

    try {
      // Android 13+ için photos permission, eski versiyonlar için storage
      PermissionStatus status;

      if (Platform.isAndroid) {
        status = await Permission.storage.request();

        if (status != PermissionStatus.granted) {
          status = await Permission.photos.request();
        }

        if (status != PermissionStatus.granted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (status != PermissionStatus.granted) {
          bool shouldOpenSettings = await _showPermissionDialog();
          if (shouldOpenSettings) {
            await openAppSettings();
          }
          return;
        }
      }

      // Dizin belirleme
      Directory? directory;

      if (Platform.isAndroid) {
        List<String> possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Pictures',
          '/storage/emulated/0/DCIM/Camera',
        ];

        for (String path in possiblePaths) {
          Directory testDir = Directory(path);
          if (await testDir.exists()) {
            directory = testDir;
            break;
          }
        }

        // Hiçbiri bulunamazsa external storage kullan
        if (directory == null) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null || !await directory.exists()) {
        _showErrorMessage('Kaydetme klasörü bulunamadı!');
        return;
      }

      // Dosya adı oluştur
      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String filename = 'Convertly_$timestamp.${_selectedFormat.toLowerCase()}';
      String filePath = '${directory.path}/$filename';

      // Dosyayı kaydet
      File savedFile = File(filePath);
      await savedFile.writeAsBytes(_convertedImageBytes!);

      // Geçmişe ekle
      _addToHistory(_convertedImageBytes!, _selectedFormat, filePath,
          ConversionType.image, filename);

      _showSuccessMessage('Resim kaydedildi:\n${directory.path}/$filename');
    } catch (e) {
      _showErrorMessage('Kaydetme sırasında hata oluştu:\n$e');
    }
  }

  Future<bool> _showPermissionDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(context.l10n.permissionTitle),
              content: Text(context.l10n.permissionBody),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(context.l10n.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(context.l10n.goToSettings),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    // Format: dd.MM.yyyy HH:mm
    return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  // Düzeltilmiş klasör açma fonksiyonu
  Future<void> _openFileLocation(String filePath) async {
    try {
      // Dosyanın bulunduğu klasörü al
      String folderPath = filePath.substring(0, filePath.lastIndexOf('/'));

      // Native method channel ile klasörü aç
      await _platform.invokeMethod('openFolder', {'folderPath': folderPath});

      _showSuccessMessage('Klasör açılıyor...');
    } catch (e) {
      // Hata durumunda alternatif çözüm
      try {
        // Dosyanın kendisini açmayı dene
        await _platform.invokeMethod('openFile', {'filePath': filePath});
        _showSuccessMessage('Dosya açılıyor...');
      } catch (e2) {
        _showErrorMessage(
            'Dosya konumu açılamadı. Dosya: ${filePath.split('/').last}');
      }
    }
  }

  void _clearHistory() {
    setState(() {
      _conversionHistory.clear();
    });
    _showSuccessMessage('Dönüştürme geçmişi temizlendi!');
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: context.l10n.appTitle,
      applicationVersion: '2.0.0',
      applicationIcon:
          const Icon(Icons.transform, size: 48, color: Color(0xFF6B46C1)),
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            '${context.l10n.aboutSubtitle}\n\n'
            '• Image: JPG ↔ PNG\n'
            '• Document: PDF ↔ Word\n\n'
            '© 2024 Convertly',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _addToHistory(Uint8List? imageBytes, String format, String filePath,
      ConversionType type, String fileName) {
    setState(() {
      _conversionHistory.insert(
        0, // En yenileri başa ekle
        ConversionHistory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          imageBytes: imageBytes,
          format: format,
          filePath: filePath,
          timestamp: DateTime.now(),
          fileSize: imageBytes?.length ?? _convertedDocumentBytes?.length ?? 0,
          fileName: fileName,
          type: type,
        ),
      );
    });
  }
}
