// TaskPhotoScreen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';

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

  late String orderNumber;
  late String collectionName;
  late int taskIndex;
  late Map<String, dynamic> task;
  late int taskNumber;

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
    taskIndex = args['taskIndex'];
    task = args['task'];
    taskNumber = args['taskNumber'];

    if (task['resultImageBase64'] != null && task['resultImageBase64'].isNotEmpty) {
      _base64Image = task['resultImageBase64'];
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.orange;
      case 'active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'approved':
        return Icons.verified;
      case 'rejected':
        return Icons.warning;
      case 'active':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'completed':
        return 'Выполнено';
      case 'approved':
        return 'Подтверждено';
      case 'rejected':
        return 'На доработке';
      default:
        return 'Неизвестно';
    }
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
                          fontSize: 14 * scale,
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

  Future<void> _markTaskCompleted() async {
    if (_base64Image == null) {
      CustomSnackBar.showWarning(
        context: context,
        message: 'Сначала прикрепите фото результата',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final orderDoc = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(orderNumber)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Заказ не найден');
      }

      final orderData = orderDoc.data()!;
      final tasks = List.from(orderData['tasks']);

      tasks[taskIndex] = {
        ...tasks[taskIndex],
        'status': 'completed',
        'resultImageBase64': _base64Image,
        'completedBy': user?.uid,
        'completedByName': userName,
        'completedAt': DateTime.now().toIso8601String(),
        'hasResultImage': true,
        'reviewedBy': null,
        'reviewedAt': null,
      };

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(orderNumber)
          .update({
        'tasks': tasks,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      CustomSnackBar.showSuccess(
        context: context,
        message: task['status'] == 'rejected'
            ? 'Фото отправлено на повторную проверку ИТМ'
            : 'Задание отправлено на проверку ИТМ',
      );

      Navigator.of(context).pop();

    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка: $e',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showFullScreenImage(BuildContext context, String base64String, String title) {
    try {
      final bytes = base64.decode(base64String);

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
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
                        Icon(Icons.photo,
                            color: Colors.white,
                            size: 20
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontFamily: 'GolosB',
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 24,
                            ),
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
                      child: Center(
                        child: Image.memory(
                          bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(12),
                    color: Colors.black54,
                    child: Text(
                      'Используйте жесты для масштабирования и перемещения',
                      style: TextStyle(
                        fontFamily: 'GolosR',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка открытия изображения',
      );
    }
  }

  Widget _buildInteractiveImage(
      BuildContext context,
      String base64String,
      String title,
      Color color,
      ) {
    final scale = getScaleFactor(context);

    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, base64String, title);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Column(
          children: [
            Container(
              height: 300 * scale,
              child: Image.memory(
                base64.decode(base64String),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200 * scale,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error,
                              color: Colors.red,
                              size: 40 * scale
                          ),
                          SizedBox(height: 10 * scale),
                          Text(
                            'Ошибка загрузки изображения',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              color: Colors.red,
                              fontSize: 14 * scale,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: color,
                    size: 16 * scale,
                  ),
                  SizedBox(width: 5 * scale),
                  Text(
                    'Нажмите для приближения',
                    style: TextStyle(
                      fontFamily: 'GolosR',
                      color: color,
                      fontSize: 12 * scale,
                    ),
                  ),
                ],
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
    final hasOriginalImage = task['imageBase64'] != null && task['imageBase64'].isNotEmpty;
    final status = task['status'] ?? 'active';
    final isRejected = status == 'rejected';

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
                  'Задание $taskNumber - №$orderNumber',
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

            if (userName != null)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 20 * scale,
                    vertical: 5 * scale
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person,
                        color: Colors.grey,
                        size: 16 * scale
                    ),
                    SizedBox(width: 8 * scale),
                    Text(
                      'Исполнитель: $userName',
                      style: TextStyle(
                        fontFamily: 'GolosR',
                        fontSize: 14 * scale,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12 * scale),
                      margin: EdgeInsets.only(bottom: 20 * scale),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(status),
                            color: _getStatusColor(status),
                            size: 20 * scale,
                          ),
                          SizedBox(width: 8 * scale),
                          Text(
                            isRejected ? 'Требует доработки' : _getStatusText(status),
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontFamily: 'GolosB',
                              color: _getStatusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isRejected)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16 * scale),
                        margin: EdgeInsets.only(bottom: 20 * scale),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10 * scale),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info,
                                    color: Colors.orange,
                                    size: 20 * scale
                                ),
                                SizedBox(width: 8 * scale),
                                Text(
                                  'Задание требует доработки',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontFamily: 'GolosB',
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8 * scale),
                            Text(
                              'ИТМ отклонил предыдущее фото. Сделайте новое фото результата, оно заменит предыдущее.',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontFamily: 'GolosR',
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                    Text(
                      'Описание задания:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
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
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    SizedBox(height: 30 * scale),

                    if (hasOriginalImage) ...[
                      Text(
                        'Исходное фото:',
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontFamily: 'GolosB',
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      _buildInteractiveImage(
                        context,
                        task['imageBase64'],
                        'Исходное фото задания',
                        Colors.blue,
                      ),
                      SizedBox(height: 20 * scale),
                      Text(
                        'Это исходное фото задания. Сделайте или выберите фото результата работы ниже.',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          color: Colors.grey[600],
                          fontSize: 14 * scale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30 * scale),
                    ],

                    Text(
                      'Фото результата:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
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
                                Icon(Icons.check_circle,
                                    color: Colors.green,
                                    size: 16 * scale
                                ),
                                SizedBox(width: 5 * scale),
                                Text(
                                  isRejected ? 'Новое фото для доработки' : 'Ваше фото результата',
                                  style: TextStyle(
                                    fontFamily: 'GolosB',
                                    color: Colors.green,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                Spacer(),
                                GestureDetector(
                                  onTap: _removeImage,
                                  child: Container(
                                    padding: EdgeInsets.all(6 * scale),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20 * scale),
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                      size: 18 * scale,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * scale),
                            _buildInteractiveImage(
                              context,
                              _base64Image!,
                              isRejected ? 'Новое фото результата' : 'Фото результата работы',
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        isRejected
                            ? 'Новое фото готово к отправке. Нажмите на фото для приближения.'
                            : 'Фото прикреплено. Нажмите на фото для приближения или кнопку ниже для отправки на проверку.',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          color: Colors.green,
                          fontSize: 14 * scale,
                        ),
                        textAlign: TextAlign.center,
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
                            Icon(
                              Icons.photo_camera,
                              color: Colors.grey,
                              size: 50 * scale,
                            ),
                            SizedBox(height: 10 * scale),
                            Text(
                              'Фото результата не прикреплено',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey,
                                fontSize: 16 * scale,
                              ),
                            ),
                            SizedBox(height: 10 * scale),
                            Text(
                              isRejected
                                  ? 'Сделайте новое фото результата для повторной проверки'
                                  : 'Сделайте снимок или выберите фото из галереи',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey,
                                fontSize: 12 * scale,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                                _base64Image != null ? 'Заменить фото' : 'Прикрепить фото',
                                style: TextStyle(
                                  fontSize: 14 * scale,
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

                    SizedBox(height: 20 * scale),

                    Center(
                      child: Container(
                        width: double.infinity,
                        height: 45 * scale,
                        margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                        child: ElevatedButton(
                          onPressed: _base64Image != null && !isLoading ? _markTaskCompleted : null,
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check,
                                  color: Colors.white,
                                  size: 20 * scale
                              ),
                              SizedBox(width: 10 * scale),
                              Flexible(
                                child: Text(
                                  isRejected ? 'Отправить повторно' : 'Отправить на проверку',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontFamily: 'GolosB',
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _base64Image != null ? Colors.green : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10 * scale),
                    Center(
                      child: Text(
                        'Кнопка станет активной после прикрепления фото',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          color: Colors.grey,
                          fontSize: 12 * scale,
                        ),
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