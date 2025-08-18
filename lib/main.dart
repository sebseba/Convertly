import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const ConvertlyApp());
}

class ConvertlyApp extends StatelessWidget {
  const ConvertlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Convertly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  final List<Widget> _pages = [
    const ImageConverterPage(),
    const HistoryPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.image),
            label: 'Dönüştür',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Geçmiş',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}

class ImageConverterPage extends StatefulWidget {
  const ImageConverterPage({super.key});

  @override
  State<ImageConverterPage> createState() => _ImageConverterPageState();
}

class _ImageConverterPageState extends State<ImageConverterPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _selectedFormat = 'JPG';
  bool _isConverting = false;
  String? _convertedImagePath;
  
  final List<String> _formats = ['JPG', 'PNG', 'BMP', 'TIFF'];

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.photos.request();
    await Permission.manageExternalStorage.request();
    await Permission.accessMediaLocation.request();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );
      
      if (image != null) {
        final File selectedFile = File(image.path);
        print('Seçilen resim: ${image.path}');
        print('Seçilen resim boyutu: ${await selectedFile.length()} bytes');
        print('Seçilen resim uzantısı: ${image.path.split('.').last}');
        
        setState(() {
          _selectedImage = selectedFile;
          _convertedImagePath = null;
        });
      }
    } catch (e) {
      print('Resim seçme hatası: $e');
      _showSnackBar('Resim seçilirken hata oluştu: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _convertedImagePath = null;
        });
      }
    } catch (e) {
      _showSnackBar('Fotoğraf çekilirken hata oluştu: $e');
    }
  }

  Future<void> _convertImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Lütfen önce bir resim seçin');
      return;
    }

    setState(() {
      _isConverting = true;
    });

    try {
      // Resmi oku
      final Uint8List imageBytes = await _selectedImage!.readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        throw Exception('Resim okunamadı');
      }

      print('Orijinal resim boyutu: ${originalImage.width}x${originalImage.height}');
      print('Seçilen format: $_selectedFormat');

      // Format dönüştürme
      List<int> convertedBytes;
      String fileExtension;
      
      switch (_selectedFormat) {
        case 'JPG':
          convertedBytes = img.encodeJpg(originalImage, quality: 90);
          fileExtension = 'jpg';
          print('JPG dönüştürme tamamlandı. Boyut: ${convertedBytes.length} bytes');
          break;
        case 'PNG':
          convertedBytes = img.encodePng(originalImage);
          fileExtension = 'png';
          print('PNG dönüştürme tamamlandı. Boyut: ${convertedBytes.length} bytes');
          break;
        case 'BMP':
          convertedBytes = img.encodeBmp(originalImage);
          fileExtension = 'bmp';
          print('BMP dönüştürme tamamlandı. Boyut: ${convertedBytes.length} bytes');
          break;
        case 'TIFF':
          convertedBytes = img.encodeTiff(originalImage);
          fileExtension = 'tiff';
          print('TIFF dönüştürme tamamlandı. Boyut: ${convertedBytes.length} bytes');
          break;
        default:
          convertedBytes = img.encodeJpg(originalImage, quality: 90);
          fileExtension = 'jpg';
          print('Varsayılan JPG dönüştürme tamamlandı. Boyut: ${convertedBytes.length} bytes');
      }

      // Dönüştürülmüş resmi kaydet
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = 'converted_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String filePath = '${appDir.path}/$fileName';
      
      final File convertedFile = File(filePath);
      await convertedFile.writeAsBytes(convertedBytes);

      print('Dönüştürülmüş dosya kaydedildi: $filePath');
      print('Dosya boyutu: ${await convertedFile.length()} bytes');

      setState(() {
        _convertedImagePath = filePath;
        _isConverting = false;
      });

      // Geçmişe ekle
      _addToHistory(_selectedImage!.path, filePath, _selectedFormat);

      _showSnackBar('Resim başarıyla $_selectedFormat formatına dönüştürüldü!');
    } catch (e) {
      print('Dönüştürme hatası: $e');
      setState(() {
        _isConverting = false;
      });
      _showSnackBar('Dönüştürme sırasında hata oluştu: $e');
    }
  }

  void _addToHistory(String originalPath, String convertedPath, String format) {
    final historyItem = HistoryItem(
      originalPath: originalPath,
      convertedPath: convertedPath,
      format: format,
      timestamp: DateTime.now(),
    );
    
    // Geçmiş listesine ekle
    HistoryManager.addToHistory(historyItem);
  }

  Future<void> _saveToGallery() async {
    if (_convertedImagePath == null) {
      _showSnackBar('Önce bir resim dönüştürün');
      return;
    }

    try {
      // Dönüştürülmüş resmi oku
      final File convertedFile = File(_convertedImagePath!);
      if (!await convertedFile.exists()) {
        _showSnackBar('Dönüştürülmüş resim bulunamadı');
        return;
      }

      print('Kaydetme başlıyor...');
      print('Kaynak dosya: $_convertedImagePath');
      print('Kaynak dosya boyutu: ${await convertedFile.length()} bytes');

      bool saved = false;

      // Yöntem 1: DCIM klasörüne kaydet (Galeri klasörü)
      try {
        final String dcimPath = '/storage/emulated/0/DCIM';
        final Directory dcimDir = Directory(dcimPath);
        
        if (await dcimDir.exists()) {
          final String fileName = 'Convertly_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat.toLowerCase()}';
          final String filePath = '$dcimPath/$fileName';
          
          print('DCIM hedef dosya: $filePath');
          
          await convertedFile.copy(filePath);
          
          final File savedFile = File(filePath);
          print('DCIM kaydedilen dosya boyutu: ${await savedFile.length()} bytes');
          
          _showSnackBar('Resim galeriye kaydedildi: $fileName');
          saved = true;
        }
      } catch (e) {
        print('DCIM kaydetme hatası: $e');
      }

      // Yöntem 2: Downloads klasörüne kaydet
      if (!saved) {
        try {
          final String downloadsPath = '/storage/emulated/0/Download';
          final Directory downloadsDir = Directory(downloadsPath);
          
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
            print('Downloads klasörü oluşturuldu: $downloadsPath');
          }
          
          final String fileName = 'Convertly_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat.toLowerCase()}';
          final String filePath = '$downloadsPath/$fileName';
          
          print('Downloads hedef dosya: $filePath');
          
          await convertedFile.copy(filePath);
          
          final File savedFile = File(filePath);
          print('Downloads kaydedilen dosya boyutu: ${await savedFile.length()} bytes');
          
          _showSnackBar('Resim Downloads klasörüne kaydedildi: $fileName');
          saved = true;
        } catch (e) {
          print('Downloads kaydetme hatası: $e');
        }
      }

      // Yöntem 3: Pictures klasörüne kaydet
      if (!saved) {
        try {
          final String picturesPath = '/storage/emulated/0/Pictures';
          final Directory picturesDir = Directory(picturesPath);
          
          if (!await picturesDir.exists()) {
            await picturesDir.create(recursive: true);
            print('Pictures klasörü oluşturuldu: $picturesPath');
          }
          
          final String fileName = 'Convertly_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat.toLowerCase()}';
          final String filePath = '$picturesPath/$fileName';
          
          print('Pictures hedef dosya: $filePath');
          
          await convertedFile.copy(filePath);
          
          final File savedFile = File(filePath);
          print('Pictures kaydedilen dosya boyutu: ${await savedFile.length()} bytes');
          
          _showSnackBar('Resim Pictures klasörüne kaydedildi: $fileName');
          saved = true;
        } catch (e) {
          print('Pictures kaydetme hatası: $e');
        }
      }

      // Yöntem 4: Uygulama klasörüne kaydet (son çare)
      if (!saved) {
        try {
          final Directory appDir = await getApplicationDocumentsDirectory();
          final String fileName = 'Convertly_${DateTime.now().millisecondsSinceEpoch}.${_selectedFormat.toLowerCase()}';
          final String filePath = '${appDir.path}/$fileName';
          
          print('App hedef dosya: $filePath');
          
          await convertedFile.copy(filePath);
          
          final File savedFile = File(filePath);
          print('App kaydedilen dosya boyutu: ${await savedFile.length()} bytes');
          
          _showSnackBar('Resim uygulama klasörüne kaydedildi: $fileName');
          saved = true;
        } catch (e) {
          print('App kaydetme hatası: $e');
        }
      }

      if (!saved) {
        _showSnackBar('Resim kaydedilemedi. İzinleri kontrol edin.');
      }
    } catch (e) {
      print('Kaydetme hatası: $e');
      _showSnackBar('Kaydedilirken hata oluştu: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getFileSize(File file) {
    final int bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convertly'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Resim seçme alanı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resim Seç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImage == null)
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Resim seçilmedi',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Boyut: ${_getFileSize(_selectedImage!)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Galeriden Seç'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _takePhoto,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Fotoğraf Çek'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Format seçici
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hedef Format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _formats.map((String format) {
                        return DropdownMenuItem<String>(
                          value: format,
                          child: Text(format),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedFormat = newValue;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Dönüştür butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedImage != null && !_isConverting ? _convertImage : null,
                icon: _isConverting 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.transform),
                label: Text(_isConverting ? 'Dönüştürülüyor...' : 'Dönüştür'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Dönüştürülmüş resim
            if (_convertedImagePath != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dönüştürülmüş Resim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_convertedImagePath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Format: $_selectedFormat | Boyut: ${_getFileSize(File(_convertedImagePath!))}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _saveToGallery,
                              icon: const Icon(Icons.save),
                              label: const Text('Telefona Kaydet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                  _convertedImagePath = null;
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Yeni Resim'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32), // Alt boşluk
          ],
        ),
      ),
    );
  }
}

// Geçmiş öğesi sınıfı
class HistoryItem {
  final String originalPath;
  final String convertedPath;
  final String format;
  final DateTime timestamp;

  HistoryItem({
    required this.originalPath,
    required this.convertedPath,
    required this.format,
    required this.timestamp,
  });
}

// Geçmiş yönetici sınıfı
class HistoryManager {
  static final List<HistoryItem> _history = [];

  static void addToHistory(HistoryItem item) {
    _history.insert(0, item); // En yeni öğeyi başa ekle
    if (_history.length > 50) { // Maksimum 50 öğe tut
      _history.removeLast();
    }
  }

  static List<HistoryItem> getHistory() {
    return List.from(_history);
  }

  static void clearHistory() {
    _history.clear();
  }
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _historyItems = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyItems = HistoryManager.getHistory();
    });
  }

  String _getFileSize(String filePath) {
    try {
      final File file = File(filePath);
      final int bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geçmiş'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Geçmişi Temizle'),
                    content: const Text('Tüm geçmiş kayıtları silinecek. Bu işlem geri alınamaz.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          HistoryManager.clearHistory();
                          _loadHistory();
                          Navigator.pop(context);
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _historyItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz dönüştürme geçmişi yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _historyItems.length,
              itemBuilder: (context, index) {
                final item = _historyItems[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(item.convertedPath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.grey);
                          },
                        ),
                      ),
                    ),
                    title: Text('${item.format} formatına dönüştürüldü'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Boyut: ${_getFileSize(item.convertedPath)}'),
                        Text('Tarih: ${_formatTimestamp(item.timestamp)}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _historyItems.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Resim Kalitesi'),
            subtitle: const Text('Yüksek (90%)'),
            onTap: () {
              // Kalite ayarları
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder),
            title: const Text('Kayıt Klasörü'),
            subtitle: const Text('Downloads'),
            onTap: () {
              // Klasör ayarları
            },
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Tema'),
            subtitle: const Text('Açık tema'),
            onTap: () {
              // Tema değiştirme işlemi
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Dil'),
            subtitle: const Text('Türkçe'),
            onTap: () {
              // Dil değiştirme işlemi
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Hakkında'),
            subtitle: const Text('Convertly v1.0.0'),
            onTap: () {
              // Hakkında sayfası
            },
          ),
        ],
      ),
    );
  }
}
