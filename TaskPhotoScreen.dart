// TaskPhotoScreen.dart
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

class TaskPhotoScreen extends StatefulWidget {
  const TaskPhotoScreen({Key? key}) : super(key: key);

  @override
  _TaskPhotoScreenState createState() => _TaskPhotoScreenState();
}

class _TaskPhotoScreenState extends State<TaskPhotoScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  String? _base64Image;
  bool isLoading = false;
  String? userName;
  String? reviewerName;

  late String orderNumber;
  late String collectionName;
  late String taskId;
  late Map<String, dynamic> task;
  late int taskNumber;
  late String screenTitle;

  double getScaleFactor(BuildContext context) {
    final diagonal = MediaQuery.of(context).size.shortestSide;
    if (diagonal < 300) return 0.65;
    if (diagonal < 350) return 0.75;
    if (diagonal < 400) return 0.85;
    if (diagonal < 450) return 0.9;
    if (diagonal < 500) return 0.95;
    if (diagonal < 600) return 1.0;
    if (diagonal < 700) return 1.1;
    if (diagonal < 800) return 1.2;
    if (diagonal < 1000) return 1.3;
    return 1.4;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['displayName'] ?? 'Пользователь';
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    orderNumber = args['orderNumber'];
    collectionName = args['collectionName'];
    taskId = args['taskId'];
    task = args['task'];
    taskNumber = args['taskNumber'];
    screenTitle = args['screenTitle'] ?? 'Задания';

    // Загружаем существующее фото результата если есть
    if (task['resultImageRef'] != null) {
      _loadExistingResultImage();
    }
  }

  Future<void> _loadExistingResultImage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('task_images')
          .doc(task['resultImageRef'])
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _base64Image = doc.data()?['imageBase64'];
        });
      }
    } catch (e) {
      print('Ошибка загрузки существующего фото: $e');
    }
  }

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

  // 🔴 ОБНОВЛЁННЫЙ метод отправки задачи
  Future<void> _submitWork() async {
    if (_base64Image == null) {
      CustomSnackBar.showWarning(context: context, message: 'Прикрепите фото');
      return;
    }
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final taskRef = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(orderNumber)
          .collection('tasks')
          .doc(taskId);

      // Удаляем старое фото результата если есть
      final oldResultRef = task['resultImageRef'];
      if (oldResultRef != null) {
        await FirebaseFirestore.instance.collection('task_images').doc(oldResultRef).delete();
      }

      // Сохраняем новое фото
      final now = DateTime.now().toIso8601String();
      final imageDoc = await FirebaseFirestore.instance.collection('task_images').add({
        'imageBase64': _base64Image,
        'orderNumber': orderNumber,
        'collectionName': collectionName,
        'taskNumber': taskNumber,
        'createdBy': user?.uid,
        'createdAt': now,
        'taskType': 'result',
        'isIPK': task['isIPK'] == true,
      });

      // Обновляем задачу
      await taskRef.update({
        'status': 'completed',
        'resultImageRef': imageDoc.id,
        'hasResultImage': true,
        'completedBy': user?.uid,
        'completedByName': userName,
        'completedAt': now,
        'reviewedBy': null,
        'reviewedAt': null,
      });

      CustomSnackBar.showSuccess(
        context: context,
        message: task['status'] == 'rejected'
            ? 'Фото отправлено на повторную проверку'
            : 'Задание отправлено на проверку',
      );
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка: $e');
    } finally {
      setState(() => isLoading = false);
    }
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
    final hasOriginalImage = task['hasImage'] == true;
    final status = task['status'] ?? 'active';
    final isRejected = status == 'rejected';

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
                child: Text('Задание $taskNumber - №$orderNumber',
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
                        task['taskDescription'] ?? 'Описание отсутствует',
                        style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.black87, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 30 * scale),
                    if (hasOriginalImage) ...[
                      Text('Исходное фото:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                      SizedBox(height: 10 * scale),
                      // Здесь нужно загрузить оригинальное фото через TaskImageLoader
                      FutureBuilder<String?>(
                        future: _loadOriginalImage(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return _buildImagePreview(snapshot.data!, Colors.blue);
                          }
                          return Container(
                            height: 200 * scale,
                            child: Center(child: CircularProgressIndicator()),
                          );
                        },
                      ),
                      SizedBox(height: 30 * scale),
                    ],
                    Text('Фото результата:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 10 * scale),
                    if (_base64Image != null) ...[
                      _buildImagePreview(_base64Image!, Colors.green),
                      SizedBox(height: 10 * scale),
                      Center(
                        child: Text('Нажмите на фото для приближения',
                            style: TextStyle(fontFamily: 'GolosR', color: Colors.green, fontSize: 12 * scale)),
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
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 30 * scale),
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
                                child: Text(isRejected ? 'Отправить повторно' : 'Отправить на проверку',
                                    style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosB', color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
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

  Future<String?> _loadOriginalImage() async {
    if (task['imageRef'] == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('task_images')
        .doc(task['imageRef'])
        .get();
    return doc.data()?['imageBase64'];
  }

  Widget _buildImagePreview(String base64String, Color color) {
    final scale = getScaleFactor(context);
    return GestureDetector(
      onTap: () => _showFullScreen(base64String),
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
                base64.decode(base64String),
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

  void _showFullScreen(String base64String) {
    final bytes = base64.decode(base64String);
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
                      child: Text('Фото',
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
            ],
          ),
        ),
      ),
    );
  }
}