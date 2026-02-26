import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
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

class CreateIPKTaskScreen extends StatefulWidget {
  const CreateIPKTaskScreen({Key? key}) : super(key: key);

  @override
  _CreateIPKTaskScreenState createState() => _CreateIPKTaskScreenState();
}

class _CreateIPKTaskScreenState extends State<CreateIPKTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();

  String? _selectedTaskType;
  File? _selectedFile;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  final List<String> _taskTypes = ['Сборка', 'Монтаж', 'Пакетирование'];

  final Map<String, String> _collectionMap = {
    'Сборка': 'Sborka',
    'Монтаж': 'Montasch',
    'Пакетирование': 'Pacet'
  };

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
    _taskController.addListener(_updateCharacterCount);
    _acceptArguments();
  }

  void _acceptArguments() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final order = args['orderNumber'] as String?;
        final spec = args['preselectedTaskType'] as String?;
        if (order != null) _orderController.text = order;
        if (spec != null && _taskTypes.contains(spec)) {
          setState(() {
            _selectedTaskType = spec;
          });
        }
      }
    });
  }

  void _updateCharacterCount() => setState(() {});

  Future<void> _showImageSourceDialog() async {
    final scale = getScaleFactor(context);
    await showDialog(
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
                  _pickImageFromCamera();
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
                  _pickImageFromGallery();
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

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) await _processImage(File(image.path));
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка при съемке фото: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) await _processImage(File(image.path));
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка при выборе фото: $e');
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

  Future<void> _processImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        CustomSnackBar.showWarning(context: context, message: 'Фото слишком большое. Выберите файл меньше 5MB');
        return;
      }

      final compressedBytes = await _compressImage(bytes, maxSizeKB: 500);
      final base64 = base64Encode(compressedBytes);

      if (base64.length > 700000) {
        CustomSnackBar.showWarning(context: context, message: 'Фото слишком детализированное. Попробуйте другое.');
        return;
      }

      setState(() {
        _selectedFile = file;
        _base64Image = base64;
      });
      CustomSnackBar.showSuccess(context: context, message: 'Фото успешно загружено');
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка обработки фото: $e');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFile = null;
      _base64Image = null;
    });
    CustomSnackBar.showInfo(context: context, message: 'Фото удалено');
  }

  // 🔴 ОБНОВЛЁННЫЙ МЕТОД: Создание ИПК-задачи в подколлекции
  Future<void> _publishTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTaskType == null) {
      CustomSnackBar.showWarning(context: context, message: 'Выберите тип задания');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final orderNumber = _orderController.text.trim();
      final taskDescription = _taskController.text.trim();
      final collectionName = _collectionMap[_selectedTaskType]!;
      final now = DateTime.now().toIso8601String();

      final orderDocRef = FirebaseFirestore.instance.collection(collectionName).doc(orderNumber);
      final orderSnapshot = await orderDocRef.get();

      int taskNumber = 1;
      if (orderSnapshot.exists) {
        final tasksSnapshot = await orderDocRef.collection('tasks').get();
        taskNumber = tasksSnapshot.docs.length + 1;
      } else {
        await orderDocRef.set({
          'orderNumber': orderNumber,
          'createdAt': now,
          'updatedAt': now,
          'hasIPKTask': false,
        });
      }

      // Сохраняем изображение
      String? imageRef;
      if (_base64Image != null) {
        final imageDoc = await FirebaseFirestore.instance.collection('task_images').add({
          'imageBase64': _base64Image,
          'orderNumber': orderNumber,
          'collectionName': collectionName,
          'taskNumber': taskNumber,
          'createdBy': user.uid,
          'createdAt': now,
          'taskType': 'original',
          'isIPK': true,
        });
        imageRef = imageDoc.id;
      }

      // 🔴 СОЗДАЁМ ИПК-задачу в подколлекции
      final taskData = {
        'taskNumber': taskNumber,
        'taskDescription': taskDescription,
        'createdBy': user.uid,
        'createdAt': now,
        'status': 'active',
        'completedBy': null,
        'completedAt': null,
        'reviewedBy': null,
        'reviewedAt': null,
        'isIPK': true,
        'hasImage': imageRef != null,
        'imageRef': imageRef,
        'resultImageRef': null,
        'hasResultImage': false,
      };

      await orderDocRef.collection('tasks').doc('task_$taskNumber').set(taskData);

      // Обновляем метаданные заказа
      await orderDocRef.update({
        'updatedAt': now,
        'hasIPKTask': true,
        'taskCount': taskNumber,
      });

      CustomSnackBar.showSuccess(context: context, message: 'ИПК-задание №$taskNumber успешно опубликовано');
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка публикации: $e');
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    final scale = getScaleFactor(context);
    if (_selectedFile != null && _base64Image != null) {
      return Container(
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
            Container(
              width: double.infinity,
              height: 200 * scale,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(10 * scale),
              ),
              child: Image.memory(
                base64.decode(_base64Image!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(child: Icon(Icons.error, color: Colors.red, size: 40 * scale)),
              ),
            ),
          ],
        ),
      );
    } else {
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
            Icon(Icons.photo_camera, color: Colors.grey, size: 50 * scale),
            SizedBox(height: 10 * scale),
            Text('Фото не прикреплено',
                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 16 * scale)),
            SizedBox(height: 5 * scale),
            Text('Нажмите кнопку ниже чтобы добавить фото',
                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 12 * scale),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
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
                child: Text('Создание задания ИПК',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GolosB', color: Colors.black, fontSize: 16 * scale)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.red),
              centerTitle: true,
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20 * scale),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Заказ', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                        SizedBox(height: 10 * scale),
                        TextFormField(
                          controller: _orderController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Введите номер заказа',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15 * scale, vertical: 15 * scale),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Введите номер заказа';
                            if (!RegExp(r'^[0-9]+$').hasMatch(val)) return 'Только цифры';
                            return null;
                          },
                        ),
                        SizedBox(height: 20 * scale),
                        Text('Тип задания', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                        SizedBox(height: 10 * scale),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(15 * scale),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTaskType,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 15 * scale, vertical: 15 * scale),
                            ),
                            hint: Text('Выберите тип задания', style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale)),
                            items: _taskTypes.map((val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val, style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale)),
                              );
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedTaskType = v),
                            validator: (v) => v == null ? 'Выберите тип задания' : null,
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        Text('Задание', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                        SizedBox(height: 10 * scale),
                        TextFormField(
                          controller: _taskController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Опишите задание...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                              borderSide: BorderSide(color: Colors.red, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 15 * scale, vertical: 15 * scale),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Введите описание задания' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 5 * scale),
                            child: Text('${_taskController.text.length} символов',
                                style: TextStyle(fontSize: 12 * scale, fontFamily: 'GolosR', color: Colors.red)),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        Text('Прикрепленное фото',
                            style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                        SizedBox(height: 10 * scale),
                        _buildImagePreview(context),
                        SizedBox(height: 20 * scale),
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 50 * scale,
                            margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                            child: ElevatedButton(
                              onPressed: _showImageSourceDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.white, size: 20 * scale),
                                  SizedBox(width: 10 * scale),
                                  Text('Прикрепить фото',
                                      style: TextStyle(fontSize: 15 * scale, fontFamily: 'GolosR', color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Center(
                          child: Text('Нажмите для выбора источника фото',
                              style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 12 * scale)),
                        ),
                        SizedBox(height: 30 * scale),
                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 50 * scale,
                            margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                            child: ElevatedButton(
                              onPressed: _publishTask,
                              child: Text('Опубликовать',
                                  style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskController.removeListener(_updateCharacterCount);
    _orderController.dispose();
    _taskController.dispose();
    super.dispose();
  }
}