// ipk_worker_task_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data'; // Добавьте в начало файла

Future<List<int>> _compressImage(List<int> bytes, {required int maxSizeKB}) async {
  if (bytes.length <= maxSizeKB * 1024) {
    return bytes;
  }

  // 🔴 ИСПРАВЛЕНИЕ: Преобразуем в Uint8List
  final Uint8List uint8Bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
  img.Image? image = img.decodeImage(uint8Bytes);

  if (image == null) return bytes;

  const int maxDimension = 1200;
  if (image.width > maxDimension || image.height > maxDimension) {
    if (image.width > image.height) {
      image = img.copyResize(image, width: maxDimension);
    } else {
      image = img.copyResize(image, height: maxDimension);
    }
  }

  int quality = 85;
  List<int> compressed = img.encodeJpg(image, quality: quality);

  while (compressed.length > maxSizeKB * 1024 && quality > 30) {
    quality -= 10;
    compressed = img.encodeJpg(image, quality: quality);
  }

  return compressed;
}

/// ИТМ выполняет ИПК-задание (только фото + статус «completed»)
class IPKWorkerTaskScreen extends StatefulWidget {
  final String orderNumber;
  final String collectionName;
  final String taskId;
  final Map<String, dynamic> task;
  final int taskNumber;

  const IPKWorkerTaskScreen({
    Key? key,
    required this.orderNumber,
    required this.collectionName,
    required this.taskId,
    required this.task,
    required this.taskNumber,
  }) : super(key: key);

  @override
  State<IPKWorkerTaskScreen> createState() => _IPKWorkerTaskScreenState();
}

class _IPKWorkerTaskScreenState extends State<IPKWorkerTaskScreen> {
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;
  bool isLoading = false;
  String? originalImageBase64;

  double getScaleFactor(BuildContext context) {
    final d = MediaQuery.of(context).size.shortestSide;
    if (d < 300) return 0.65;
    if (d < 350) return 0.75;
    if (d < 400) return 0.85;
    if (d < 450) return 0.9;
    if (d < 500) return 0.95;
    if (d < 600) return 1.0;
    if (d < 700) return 1.1;
    if (d < 800) return 1.2;
    if (d < 1000) return 1.3;
    return 1.4;
  }

  @override
  void initState() {
    super.initState();
    _loadOriginalImage();
    _loadExistingResult();
  }

  /// Загружаем исходное фото задания
  Future<void> _loadOriginalImage() async {
    final imageRef = widget.task['imageRef'];
    if (imageRef == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('task_images')
          .doc(imageRef)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          originalImageBase64 = doc.data()?['imageBase64'];
        });
      }
    } catch (e) {
      print('Ошибка загрузки исходного фото: $e');
    }
  }

  /// Загружаем существующее фото результата (если задача на доработке)
  Future<void> _loadExistingResult() async {
    final resultRef = widget.task['resultImageRef'];
    if (resultRef == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('task_images')
          .doc(resultRef)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _base64Image = doc.data()?['imageBase64'];
        });
      }
    } catch (e) {
      print('Ошибка загрузки фото результата: $e');
    }
  }

  /// Сжатие изображения до maxSizeKB
  Future<List<int>> _compressImage(List<int> bytes, {required int maxSizeKB}) async {
    if (bytes.length <= maxSizeKB * 1024) return bytes;

    img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    if (image == null) return bytes;

    const int maxDimension = 1200;
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width > image.height) {
        image = img.copyResize(image, width: maxDimension);
      } else {
        image = img.copyResize(image, height: maxDimension);
      }
    }

    int quality = 85;
    List<int> compressed = img.encodeJpg(image, quality: quality);

    while (compressed.length > maxSizeKB * 1024 && quality > 30) {
      quality -= 10;
      compressed = img.encodeJpg(image, quality: quality);
    }

    return compressed;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await File(image.path).readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        CustomSnackBar.showWarning(context: context, message: 'Фото > 5 МБ');
        return;
      }

      final compressedBytes = await _compressImage(bytes, maxSizeKB: 500);
      final base64 = base64Encode(compressedBytes);

      if (base64.length > 700000) {
        CustomSnackBar.showWarning(context: context, message: 'Фото слишком детализированное');
        return;
      }

      setState(() {
        _base64Image = base64;
      });
      CustomSnackBar.showSuccess(context: context, message: 'Фото загружено');
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка: $e');
    }
  }

  void _removeImage() {
    setState(() => _base64Image = null);
    CustomSnackBar.showInfo(context: context, message: 'Фото удалено');
  }

  /// 🔴 ОБНОВЛЁННЫЙ метод отправки работы
  Future<void> _submitWork() async {
    if (_base64Image == null) {
      CustomSnackBar.showWarning(context: context, message: 'Прикрепите фото');
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Ссылка на задачу в подколлекции
      final taskRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.orderNumber)
          .collection('tasks')
          .doc(widget.taskId);

      // Проверяем существование задачи
      final taskDoc = await taskRef.get();
      if (!taskDoc.exists) throw Exception('Задание не найдено');

      // Удаляем старое фото результата если есть
      final oldResultRef = widget.task['resultImageRef'];
      if (oldResultRef != null) {
        await FirebaseFirestore.instance.collection('task_images').doc(oldResultRef).delete();
      }

      // Сохраняем новое фото результата
      final now = DateTime.now().toIso8601String();
      final imageDoc = await FirebaseFirestore.instance.collection('task_images').add({
        'imageBase64': _base64Image,
        'orderNumber': widget.orderNumber,
        'collectionName': widget.collectionName,
        'taskNumber': widget.taskNumber,
        'createdBy': user?.uid,
        'createdAt': now,
        'taskType': 'result',
        'isIPK': true,
      });

      // Обновляем задачу
      await taskRef.update({
        'status': 'completed',
        'resultImageRef': imageDoc.id,
        'hasResultImage': true,
        'completedBy': user?.uid,
        'completedAt': now,
        'reviewedBy': null,
        'reviewedAt': null,
      });

      CustomSnackBar.showSuccess(
        context: context,
        message: 'Задание выполнено и отправлено на проверку',
      );
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildImage(String? base64String, String title, Color color) {
    final scale = getScaleFactor(context);
    if (base64String == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(20 * scale),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library, color: Colors.grey, size: 50 * scale),
            SizedBox(height: 10 * scale),
            Text('Фото не прикреплено',
                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 14 * scale)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreen(base64String, title),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(maxHeight: 300 * scale, minHeight: 200 * scale),
              child: Image.memory(
                base64Decode(base64String),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error, color: Colors.red, size: 40 * scale)),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.zoom_in, color: color, size: 16 * scale),
                  SizedBox(width: 6 * scale),
                  Text('Нажмите для приближения',
                      style: TextStyle(fontFamily: 'GolosR', color: color, fontSize: 12 * scale)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(String base64String, String title) {
    final bytes = base64Decode(base64String);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.black,
                child: Row(
                  children: [
                    Icon(Icons.photo, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(fontFamily: 'GolosB', color: Colors.white, fontSize: 16),
                          overflow: TextOverflow.ellipsis),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.1,
                  maxScale: 5.0,
                  boundaryMargin: EdgeInsets.all(20),
                  child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
                ),
              ),
              Container(
                padding: EdgeInsets.all(12),
                color: Colors.black54,
                child: Text('Используйте жесты для масштабирования',
                    style: TextStyle(fontFamily: 'GolosR', color: Colors.white, fontSize: 12),
                    textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourceDialog() {
    final scale = getScaleFactor(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
        title: Text('Выберите источник фото', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'GolosB', fontSize: 18 * scale)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 50 * scale,
              margin: EdgeInsets.only(bottom: 10 * scale),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.white, size: 20 * scale),
                    SizedBox(width: 10 * scale),
                    Text('Сделать снимок', style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.white)),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              height: 50 * scale,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red, width: 2),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, color: Colors.red, size: 20 * scale),
                    SizedBox(width: 10 * scale),
                    Text('Выбрать из галереи', style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR', color: Colors.red)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
    final status = widget.task['status'] ?? 'active';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Color(0xFFFEF2F2)],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Text('ИПК задание ${widget.taskNumber} - №${widget.orderNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale, color: Colors.black)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.red),
              centerTitle: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статус задачи
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12 * scale),
                      margin: EdgeInsets.only(bottom: 20 * scale),
                      decoration: BoxDecoration(
                        color: status == 'rejected' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: status == 'rejected' ? Colors.orange : Colors.blue),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            status == 'rejected' ? Icons.warning : Icons.info,
                            color: status == 'rejected' ? Colors.orange : Colors.blue,
                            size: 20 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            status == 'rejected' ? 'Требует доработки' : 'Активно',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontFamily: 'GolosB',
                              color: status == 'rejected' ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text('Описание задания:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 10 * scale),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(15 * scale),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        widget.task['taskDescription'] ?? 'Описание отсутствует',
                        style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.black87, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 30 * scale),

                    // Исходное фото
                    Text('Исходное фото:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 10 * scale),
                    originalImageBase64 != null
                        ? _buildImage(originalImageBase64, 'Исходное фото', Colors.blue)
                        : Container(
                      height: 200 * scale,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    SizedBox(height: 30 * scale),

                    // Фото результата
                    Text('Фото результата:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 10 * scale),
                    if (_base64Image != null) ...[
                      Container(
                        padding: EdgeInsets.all(12 * scale),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(15 * scale),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16 * scale),
                                SizedBox(width: 5 * scale),
                                Text('Фото прикреплено',
                                    style: TextStyle(fontFamily: 'GolosB', color: Colors.green, fontSize: 16 * scale)),
                                Spacer(),
                                GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    padding: EdgeInsets.all(4 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: BorderRadius.circular(15 * scale),
                                    ),
                                    child: Icon(Icons.close, color: Colors.black, size: 16 * scale),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * scale),
                            _buildImage(_base64Image, 'Ваше фото', Colors.green),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20 * scale),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(15 * scale),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.photo_camera, color: Colors.grey, size: 50 * scale),
                            SizedBox(height: 10 * scale),
                            Text('Фото результата не прикреплено',
                                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 16 * scale)),
                            SizedBox(height: 5 * scale),
                            Text('Сделайте снимок или выберите из галереи',
                                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 12 * scale),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 30 * scale),

                    // Кнопка прикрепления фото
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 45 * scale,
                        margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                        child: ElevatedButton(
                          onPressed: _showSourceDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.white, size: 20 * scale),
                              SizedBox(width: 10 * scale),
                              Text(_base64Image != null ? 'Заменить фото' : 'Прикрепить фото',
                                  style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR', color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 30 * scale),

                    // Кнопка отправки
                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 45 * scale,
                        margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                        child: ElevatedButton(
                          onPressed: _base64Image != null && !isLoading ? _submitWork : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _base64Image != null ? Colors.green : Colors.grey,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 20 * scale),
                              SizedBox(width: 10 * scale),
                              Flexible(
                                child: Text('Отправить на проверку',
                                    style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosB', color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10 * scale),
                    Center(
                      child: Text(
                        'Кнопка станет активной после прикрепления фото',
                        style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 12 * scale),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 40 * scale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}