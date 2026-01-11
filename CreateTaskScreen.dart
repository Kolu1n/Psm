// CreateTaskScreen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';

class CreateTaskScreen extends StatefulWidget {
  @override
  _CreateTaskScreenState createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderController = TextEditingController();
  final TextEditingController _taskController = TextEditingController();

  String? _selectedTaskType;
  File? _selectedFile;
  dynamic? _base64Image;
  final ImagePicker _picker = ImagePicker();

  final List<String> _taskTypes = ['Сборка', 'Монтаж', 'Пакетирование'];

  final Map<String, String> _collectionMap = {
    'Сборка': 'Sborka',
    'Монтаж': 'Montasch',
    'Пакетирование': 'Pacet'
  };

  double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
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
    _taskController.addListener(_updateCharacterCount);
  }

  void _updateCharacterCount() {
    setState(() {});
  }

  Future<void> _showImageSourceDialog() async {
    final scale = getScaleFactor(context);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15 * scale),
          ),
          title: Text(
            'Выберите источник фото',
            style: TextStyle(
              fontFamily: 'GolosB',
              fontSize: 18 * scale,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                height: 50 * scale,
                margin: EdgeInsets.only(bottom: 10 * scale),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImageFromCamera();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt,
                          color: Colors.white,
                          size: 20 * scale
                      ),
                      SizedBox(width: 10 * scale),
                      Text(
                        'Сделать снимок',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                height: 50 * scale,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImageFromGallery();
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library,
                          color: Colors.red,
                          size: 20 * scale
                      ),
                      SizedBox(width: 10 * scale),
                      Text(
                        'Выбрать из галереи',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка при съемке фото: $e',
      );
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

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка при выборе фото: $e',
      );
    }
  }

  Future<void> _processImage(File file) async {
    try {
      final bytes = await file.readAsBytes();

      if (bytes.length > 5 * 1024 * 1024) {
        CustomSnackBar.showWarning(
          context: context,
          message: 'Фото слишком большое. Выберите файл меньше 5MB',
        );
        return;
      }

      final base64 = base64Encode(bytes);

      setState(() {
        _selectedFile = file;
        _base64Image = base64;
      });

      CustomSnackBar.showSuccess(
        context: context,
        message: 'Фото успешно загружено',
      );
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка обработки фото: $e',
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedFile = null;
      _base64Image = null;
    });

    CustomSnackBar.showInfo(
      context: context,
      message: 'Фото удалено',
    );
  }

  Future<void> _publishTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTaskType == null) {
      CustomSnackBar.showWarning(
        context: context,
        message: 'Выберите тип задания',
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');

      final orderNumber = _orderController.text.trim();
      final taskDescription = _taskController.text.trim();
      final collectionName = _collectionMap[_selectedTaskType]!;

      final orderDoc = FirebaseFirestore.instance
          .collection(collectionName)
          .doc(orderNumber);

      final orderSnapshot = await orderDoc.get();
      final now = DateTime.now().toIso8601String();

      if (_base64Image != null && _base64Image!.length > 10000000) {
        CustomSnackBar.showWarning(
          context: context,
          message: 'Изображение слишком большое. Выберите файл меньше 1MB',
        );
        return;
      }

      final newTask = {
        'taskDescription': taskDescription,
        'createdBy': user.uid,
        'createdAt': now,
        'taskNumber': 1,
        'status': 'active',
        'completedBy': null,
        'completedAt': null,
        'reviewedBy': null,
        'reviewedAt': null,
      };

      if (_base64Image != null) {
        newTask['imageBase64'] = _base64Image;
        newTask['hasImage'] = true;
      }

      if (orderSnapshot.exists) {
        final tasks = orderSnapshot.data()!['tasks'] as List;
        newTask['taskNumber'] = tasks.length + 1;

        await orderDoc.update({
          'tasks': FieldValue.arrayUnion([newTask]),
          'updatedAt': now,
        });
      } else {
        await orderDoc.set({
          'orderNumber': orderNumber,
          'createdAt': now,
          'tasks': [newTask]
        });
      }

      CustomSnackBar.showSuccess(
        context: context,
        message: 'Задание успешно опубликовано',
      );

      _orderController.clear();
      _taskController.clear();
      setState(() {
        _selectedTaskType = null;
        _selectedFile = null;
        _base64Image = null;
      });

    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка публикации: $e',
      );
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
                Icon(Icons.check_circle,
                    color: Colors.green,
                    size: 16 * scale
                ),
                SizedBox(width: 5 * scale),
                Text(
                  'Фото прикреплено',
                  style: TextStyle(
                    fontFamily: 'GolosB',
                    color: Colors.green,
                    fontSize: 16 * scale,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: _removeImage,
                  child: Container(
                    padding: EdgeInsets.all(4 * scale),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(15 * scale),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 16 * scale,
                    ),
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
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(Icons.error,
                        color: Colors.red,
                        size: 40 * scale
                    ),
                  );
                },
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
            Icon(
              Icons.photo_camera,
              color: Colors.grey,
              size: 50 * scale,
            ),
            SizedBox(height: 10 * scale),
            Text(
              'Фото не прикреплено',
              style: TextStyle(
                fontFamily: 'GolosR',
                color: Colors.grey,
                fontSize: 16 * scale,
              ),
            ),
            SizedBox(height: 5 * scale),
            Text(
              'Нажмите кнопку ниже чтобы добавить фото',
              style: TextStyle(
                fontFamily: 'GolosR',
                color: Colors.grey,
                fontSize: 12 * scale,
              ),
              textAlign: TextAlign.center,
            ),
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
            colors: [
              Colors.white,
              Colors.white,
              Color(0xFFFEF2F2),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                child: Text(
                  'Создание задания',
                  style: TextStyle(
                    fontFamily: 'GolosB',
                    color: Colors.black,
                    fontSize: 16 * scale,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
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
                        Text(
                          'Заказ',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.black,
                          ),
                        ),
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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15 * scale,
                                vertical: 15 * scale
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите номер заказа';
                            }
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'Только цифры разрешены';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 20 * scale),

                        Text(
                          'Тип задания',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.black,
                          ),
                        ),
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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 15 * scale,
                                  vertical: 15 * scale
                              ),
                            ),
                            hint: Text(
                              'Выберите тип задания',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                fontSize: 16 * scale,
                              ),
                            ),
                            items: _taskTypes.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontFamily: 'GolosR',
                                    fontSize: 16 * scale,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedTaskType = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Выберите тип задания';
                              }
                              return null;
                            },
                          ),
                        ),

                        SizedBox(height: 20 * scale),

                        Text(
                          'Задание',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.black,
                          ),
                        ),
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
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 15 * scale,
                                vertical: 15 * scale
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Введите описание задания';
                            }
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 5 * scale),
                            child: Text(
                              '${_taskController.text.length} символов',
                              style: TextStyle(
                                fontSize: 12 * scale,
                                fontFamily: 'GolosR',
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20 * scale),

                        Text(
                          'Прикрепленное фото',
                          style: TextStyle(
                            fontSize: 18 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.black,
                          ),
                        ),
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15 * scale),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: Colors.white,
                                      size: 20 * scale
                                  ),
                                  SizedBox(width: 10 * scale),
                                  Text(
                                    'Прикрепить фото',
                                    style: TextStyle(
                                      fontSize: 15 * scale,
                                      fontFamily: 'GolosR',
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10 * scale),
                        Center(
                          child: Text(
                            'Нажмите для выбора источника фото',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              color: Colors.grey,
                              fontSize: 12 * scale,
                            ),
                          ),
                        ),

                        SizedBox(height: 30 * scale),

                        Center(
                          child: Container(
                            width: double.infinity,
                            height: 50 * scale,
                            margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                            child: ElevatedButton(
                              onPressed: _publishTask,
                              child: Text(
                                'Опубликовать',
                                style: TextStyle(
                                  fontSize: 18 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20 * scale),
                                ),
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