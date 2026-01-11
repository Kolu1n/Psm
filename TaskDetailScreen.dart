// TaskDetailScreen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final int taskNumber;
  final String orderNumber;
  final String collectionName;
  final int taskIndex;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.taskNumber,
    required this.orderNumber,
    required this.collectionName,
    required this.taskIndex,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int? userSpecialization;
  bool isLoading = false;
  String creatorName = 'Загрузка...';
  String executorName = 'Загрузка...';
  String reviewerName = 'Загрузка...';

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
    _loadUserSpecialization();
    _loadUserNames();
  }

  Future<void> _loadUserSpecialization() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userSpecialization = userDoc.data()?['specialization'] ?? 0;
        });
      }
    }
  }

  Future<void> _loadUserNames() async {
    if (widget.task['createdBy'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.task['createdBy'])
            .get();

        if (userDoc.exists) {
          setState(() {
            creatorName = userDoc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (e) {
        print('Ошибка загрузки имени создателя: $e');
      }
    }

    if (widget.task['completedBy'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.task['completedBy'])
            .get();

        if (userDoc.exists) {
          setState(() {
            executorName = userDoc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (e) {
        print('Ошибка загрузки имени исполнителя: $e');
      }
    }

    if (widget.task['reviewedBy'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.task['reviewedBy'])
            .get();

        if (userDoc.exists) {
          setState(() {
            reviewerName = userDoc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (e) {
        print('Ошибка загрузки имени проверяющего: $e');
      }
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
        return 'Выполнено (ожидает проверки)';
      case 'approved':
        return 'Подтверждено ИТМ';
      case 'rejected':
        return 'Отклонено (требует доработки)';
      default:
        return 'Неизвестно';
    }
  }

  Future<void> _reviewTask(bool approved) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      final orderDoc = await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.orderNumber)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Заказ не найден');
      }

      final orderData = orderDoc.data()!;
      final tasks = List.from(orderData['tasks']);

      if (widget.taskIndex >= tasks.length) {
        throw Exception('Задание не найдено в списке');
      }

      if (approved) {
        tasks.removeAt(widget.taskIndex);

        for (int i = 0; i < tasks.length; i++) {
          tasks[i]['taskNumber'] = i + 1;
        }

        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.orderNumber)
            .update({
          'tasks': tasks,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        await _moveTaskToCompleted();

        if (tasks.isEmpty) {
          await FirebaseFirestore.instance
              .collection(widget.collectionName)
              .doc(widget.orderNumber)
              .delete();
        }

        CustomSnackBar.showSuccess(
          context: context,
          message: tasks.isEmpty
              ? 'Задание подтверждено и заказ завершен'
              : 'Задание подтверждено и перенесено в завершенные',
        );

      } else {
        tasks[widget.taskIndex] = {
          ...tasks[widget.taskIndex],
          'status': 'rejected',
          'reviewedBy': user?.uid,
          'reviewedAt': DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.orderNumber)
            .update({
          'tasks': tasks,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        CustomSnackBar.showWarning(
          context: context,
          message: 'Задание отправлено на доработку',
        );
      }

      Navigator.of(context).pop();

    } catch (e) {
      print('Ошибка при обновлении задания: $e');
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

  Future<void> _moveTaskToCompleted() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      final completedTaskData = {
        'originalOrderNumber': widget.orderNumber,
        'originalCollection': widget.collectionName,
        'task': widget.task,
        'taskNumber': widget.taskNumber,
        'approvedBy': user?.uid,
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedByName': await _getCurrentUserName(),
      };

      await FirebaseFirestore.instance
          .collection('completed_tasks')
          .add(completedTaskData);

      print('Задание перенесено в завершенные');

    } catch (e) {
      print('Ошибка при переносе задания в завершенные: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['displayName'] ?? 'ИТМ';
      }
    }
    return 'ИТМ';
  }

  Widget _buildReviewButtons(BuildContext context) {
    final scale = getScaleFactor(context);

    if (userSpecialization != 4) return SizedBox();
    if (widget.task['status'] != 'completed') return SizedBox();

    return Container(
      margin: EdgeInsets.only(top: 20 * scale, bottom: 10 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15 * scale),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            'Проверка выполнения:',
            style: TextStyle(
              fontSize: 16 * scale,
              fontFamily: 'GolosB',
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 15 * scale),
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 45 * scale,
                margin: EdgeInsets.only(bottom: 10 * scale),
                child: ElevatedButton(
                  onPressed: isLoading ? null : () => _reviewTask(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check,
                          color: Colors.white,
                          size: 20 * scale
                      ),
                      SizedBox(width: 8 * scale),
                      Flexible(
                        child: Text(
                          'Подтвердить выполнение',
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
                ),
              ),
              Container(
                width: double.infinity,
                height: 45 * scale,
                child: OutlinedButton(
                  onPressed: isLoading ? null : () => _reviewTask(false),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(strokeWidth: 2)
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close,
                          color: Colors.red,
                          size: 20 * scale
                      ),
                      SizedBox(width: 8 * scale),
                      Flexible(
                        child: Text(
                          'Отправить на доработку',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10 * scale),
          Text(
            'При подтверждении задание будет перенесено в завершенные',
            style: TextStyle(
              fontFamily: 'GolosR',
              color: Colors.grey[600],
              fontSize: 12 * scale,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(String title, String name, String? date, IconData icon, Color color, BuildContext context) {
    final scale = getScaleFactor(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10 * scale),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20 * scale,
            ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'GolosB',
                    fontSize: 12 * scale,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'GolosB',
                    fontSize: 16 * scale,
                    color: color,
                  ),
                ),
                if (date != null) ...[
                  SizedBox(height: 4 * scale),
                  Text(
                    _formatDate(date),
                    style: TextStyle(
                      fontFamily: 'GolosR',
                      fontSize: 12 * scale,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
    final hasImage = widget.task['imageBase64'] != null && widget.task['imageBase64'].isNotEmpty;
    final hasResultImage = widget.task['resultImageBase64'] != null && widget.task['resultImageBase64'].isNotEmpty;
    final status = widget.task['status'] ?? 'active';

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
                  'Задание ${widget.taskNumber} - №${widget.orderNumber}',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12 * scale),
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
                          Flexible(
                            child: Text(
                              _getStatusText(status),
                              style: TextStyle(
                                fontSize: _getStatusFontSize(status) * scale,
                                fontFamily: 'GolosB',
                                color: _getStatusColor(status),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20 * scale),

                    Text(
                      'Заказ:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Text(
                      '№${widget.orderNumber}',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontFamily: 'GolosR',
                        color: Colors.black87,
                      ),
                    ),

                    SizedBox(height: 20 * scale),

                    Text(
                      'Участники задания:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 12 * scale),

                    _buildUserInfoCard(
                      'ЗАКАЗЧИК',
                      creatorName,
                      widget.task['createdAt'],
                      Icons.person_outline,
                      Colors.blue,
                      context,
                    ),

                    if (widget.task['completedBy'] != null)
                      _buildUserInfoCard(
                        'ИСПОЛНИТЕЛЬ',
                        executorName,
                        widget.task['completedAt'],
                        Icons.work_outline,
                        Colors.green,
                        context,
                      ),

                    if (widget.task['reviewedBy'] != null)
                      _buildUserInfoCard(
                        'ПРОВЕРИЛ',
                        reviewerName,
                        widget.task['reviewedAt'],
                        Icons.verified_outlined,
                        Colors.orange,
                        context,
                      ),

                    SizedBox(height: 20 * scale),

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
                        widget.task['taskDescription']?.toString() ?? 'Описание отсутствует',
                        style: TextStyle(
                          fontSize: 16 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),

                    SizedBox(height: 30 * scale),

                    Text(
                      'Исходное изображение:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10 * scale),

                    if (hasImage) ...[
                      _buildInteractiveImage(
                        context,
                        widget.task['imageBase64']!,
                        'Исходное изображение задания',
                        Colors.blue,
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'Нажмите на изображение для приближения',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          color: Colors.blue,
                          fontSize: 12 * scale,
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
                              Icons.photo_library,
                              color: Colors.grey,
                              size: 50 * scale,
                            ),
                            SizedBox(height: 10 * scale),
                            Text(
                              'Исходное изображение не прикреплено',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey,
                                fontSize: 14 * scale,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (hasResultImage) ...[
                      SizedBox(height: 30 * scale),
                      Text(
                        'Фото результата:',
                        style: TextStyle(
                          fontSize: 18 * scale,
                          fontFamily: 'GolosB',
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 10 * scale),
                      _buildInteractiveImage(
                        context,
                        widget.task['resultImageBase64']!,
                        'Фото выполненной работы',
                        Colors.green,
                      ),
                      SizedBox(height: 10 * scale),
                      Text(
                        'Нажмите на изображение для приближения',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          color: Colors.green,
                          fontSize: 12 * scale,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    _buildReviewButtons(context),

                    if (userSpecialization != 4 && status == 'rejected') ...[
                      SizedBox(height: 20 * scale),
                      Container(
                        width: double.infinity,
                        height: 45 * scale,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/TaskPhotoScreen',
                              arguments: {
                                'orderNumber': widget.orderNumber,
                                'collectionName': widget.collectionName,
                                'taskIndex': widget.taskIndex,
                                'task': widget.task,
                                'taskNumber': widget.taskNumber,
                              },
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10 * scale),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh,
                                  color: Colors.white,
                                  size: 20 * scale
                              ),
                              SizedBox(width: 8 * scale),
                              Flexible(
                                child: Text(
                                  'Переделать задание',
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontFamily: 'GolosB',
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    SizedBox(height: 30 * scale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveImage(
      BuildContext context,
      String base64String,
      String title,
      Color color, {
        bool isResult = false,
      }) {
    final scale = getScaleFactor(context);

    return GestureDetector(
      onTap: () {
        _showFullScreenImage(context, base64String, title);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Column(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: 300 * scale,
                minHeight: 200 * scale,
              ),
              child: _buildImageFromBase64(base64String, context),
            ),
            Container(
              padding: EdgeInsets.all(10 * scale),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10 * scale),
                  bottomRight: Radius.circular(10 * scale),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.zoom_in,
                    color: color,
                    size: 16 * scale,
                  ),
                  SizedBox(width: 6 * scale),
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

  Widget _buildImageFromBase64(String base64String, BuildContext context) {
    final scale = getScaleFactor(context);

    try {
      final bytes = base64.decode(base64String);
      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200 * scale,
            padding: EdgeInsets.all(20 * scale),
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
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        height: 200 * scale,
        padding: EdgeInsets.all(20 * scale),
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
                'Неверный формат изображения',
                style: TextStyle(
                  fontFamily: 'GolosR',
                  color: Colors.red,
                  fontSize: 14 * scale,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  double _getStatusFontSize(String status) {
    switch (status) {
      case 'completed':
        return 14.0;
      case 'rejected':
        return 14.0;
      default:
        return 16.0;
    }
  }
}