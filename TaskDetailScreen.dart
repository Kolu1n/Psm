// TaskDetailScreen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:psm/pages/task_image_loader.dart';

class TaskDetailScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final int taskNumber;
  final String orderNumber;
  final String collectionName;
  final String taskId;

  const TaskDetailScreen({
    Key? key,
    required this.task,
    required this.taskNumber,
    required this.orderNumber,
    required this.collectionName,
    required this.taskId,
  }) : super(key: key);

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  int? userSpec;
  bool isLoading = false;
  String creatorName = 'Загрузка...';
  String executorName = 'Загрузка...';
  String reviewerName = 'Загрузка...';
  String? originalImageBase64;
  String? resultImageBase64;

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
    _loadUserSpec();
    _loadUserNames();
    _loadImages();
  }

  Future<void> _loadImages() async {
    // Загружаем изображения через TaskImageLoader
    if (widget.task['imageRef'] != null) {
      originalImageBase64 = await TaskImageLoader.getImageBase64(widget.task['imageRef']);
    }
    if (widget.task['resultImageRef'] != null) {
      resultImageBase64 = await TaskImageLoader.getImageBase64(widget.task['resultImageRef']);
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadUserSpec() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userSpec = doc.data()?['specialization'] ?? 0;
        });
      }
    }
  }

  Future<void> _loadUserNames() async {
    if (widget.task['createdBy'] != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.task['createdBy']).get();
        if (doc.exists) {
          setState(() {
            creatorName = doc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (_) {}
    }
    if (widget.task['completedBy'] != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.task['completedBy']).get();
        if (doc.exists) {
          setState(() {
            executorName = doc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (_) {}
    }
    if (widget.task['reviewedBy'] != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(widget.task['reviewedBy']).get();
        if (doc.exists) {
          setState(() {
            reviewerName = doc.data()?['displayName'] ?? 'Неизвестно';
          });
        }
      } catch (_) {}
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
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

  IconData _statusIcon(String status) {
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

  String _statusText(String status) {
    switch (status) {
      case 'active':
        return 'Активно';
      case 'completed':
        return 'Выполнено (ожидает проверки)';
      case 'approved':
        return 'Подтверждено';
      case 'rejected':
        return 'Отклонено (требует доработки)';
      default:
        return 'Неизвестно';
    }
  }

  // 🔴 ОБНОВЛЁННЫЙ метод проверки задачи
  Future<void> _reviewTask(bool approved) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final taskRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.orderNumber)
          .collection('tasks')
          .doc(widget.taskId);

      final taskDoc = await taskRef.get();
      if (!taskDoc.exists) throw Exception('Задание не найдено');

      final taskData = taskDoc.data()!;
      final bool isIPK = taskData['isIPK'] == true;
      final String? createdBy = taskData['createdBy'];

      // ✅ ИПК может проверять ТОЛЬКО свои задания
      if (userSpec == 5 && isIPK && createdBy != user?.uid) {
        CustomSnackBar.showWarning(context: context, message: 'Вы можете проверять только свои задания');
        setState(() => isLoading = false);
        return;
      }

      // ✅ ИТМ не может проверять задания ИПК
      if (userSpec == 4 && isIPK) {
        CustomSnackBar.showWarning(context: context, message: 'ИТМ не может проверять задания ИПК');
        setState(() => isLoading = false);
        return;
      }

      if (approved) {
        // Удаляем задачу и переносим в completed_tasks
        await taskRef.delete();
        await _moveTaskToCompleted(taskData);

        // Проверяем оставшиеся задачи
        final remaining = await FirebaseFirestore.instance
            .collection(widget.collectionName)
            .doc(widget.orderNumber)
            .collection('tasks')
            .get();

        final hasIPK = remaining.docs.any((d) => d.data()['isIPK'] == true);

        if (remaining.docs.isEmpty) {
          await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).delete();
          CustomSnackBar.showSuccess(
            context: context,
            message: 'Задание подтверждено и заказ завершён',
          );
        } else {
          await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).update({
            'taskCount': remaining.docs.length,
            'hasIPKTask': hasIPK,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          CustomSnackBar.showSuccess(
            context: context,
            message: 'Задание подтверждено и перенесено в завершённые',
          );
        }
      } else {
        // Отклоняем задачу
        await taskRef.update({
          'status': 'rejected',
          'reviewedBy': user?.uid,
          'reviewedAt': DateTime.now().toIso8601String(),
        });
        CustomSnackBar.showWarning(context: context, message: 'Задание отправлено на доработку');
      }
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _moveTaskToCompleted(Map<String, dynamic> taskData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final completedTaskData = {
        'originalOrderNumber': widget.orderNumber,
        'originalCollection': widget.collectionName,
        'task': taskData,
        'taskNumber': widget.taskNumber,
        'approvedBy': user?.uid,
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedByName': await _getCurrentUserName(),
      };
      await FirebaseFirestore.instance.collection('completed_tasks').add(completedTaskData);
    } catch (e) {
      print('Ошибка при переносе задания в завершённые: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['displayName'] ?? 'ИТМ';
      }
    }
    return 'ИТМ';
  }

  Future<void> _confirmDeleteTask() async {
    final scale = getScaleFactor(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Удаление задания', style: TextStyle(fontFamily: 'GolosB', fontSize: 19)),
        content: Text('Вы уверены, что хотите удалить задание №${widget.taskNumber}?',
            style: TextStyle(fontFamily: 'GolosR')),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: Text('Отмена', style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 14)),
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  child: Text('Да', style: TextStyle(color: Colors.white, fontFamily: 'GolosB', fontSize: 14)),
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) await _deleteTask();
  }

  Future<void> _deleteTask() async {
    try {
      final bool isIPK = widget.task['isIPK'] == true;
      final String status = widget.task['status'] ?? 'active';

      // Проверка прав
      if (isIPK && userSpec != 5) {
        CustomSnackBar.showWarning(context: context, message: 'ИПК-задания может удалять только ИПК');
        return;
      }

      if (!isIPK && userSpec != 4) {
        CustomSnackBar.showWarning(context: context, message: 'У вас нет прав на удаление');
        return;
      }

      // ИПК может удалять свои выполненные задания
      if ((status == 'completed' || status == 'approved') && !(isIPK && userSpec == 5)) {
        CustomSnackBar.showWarning(context: context, message: 'Нельзя удалить завершённое задание');
        return;
      }

      final orderRef = FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.orderNumber);

      // Удаляем изображения
      final imageRef = widget.task['imageRef'];
      final resultImageRef = widget.task['resultImageRef'];

      if (imageRef != null) {
        await FirebaseFirestore.instance.collection('task_images').doc(imageRef).delete();
      }
      if (resultImageRef != null) {
        await FirebaseFirestore.instance.collection('task_images').doc(resultImageRef).delete();
      }

      // Удаляем задачу
      await orderRef.collection('tasks').doc(widget.taskId).delete();

      // Перенумеровываем
      final remaining = await orderRef.collection('tasks').orderBy('taskNumber').get();
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < remaining.docs.length; i++) {
        final doc = remaining.docs[i];
        final newNum = i + 1;
        if (doc.data()['taskNumber'] != newNum) {
          batch.update(doc.reference, {'taskNumber': newNum});
        }
      }
      await batch.commit();

      final hasIPK = remaining.docs.any((d) => d.data()['isIPK'] == true);

      if (remaining.docs.isEmpty) {
        await orderRef.delete();
        CustomSnackBar.showInfo(context: context, message: 'Все задания удалены. Заказ закрыт.');
      } else {
        await orderRef.update({
          'taskCount': remaining.docs.length,
          'hasIPKTask': hasIPK,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }

      CustomSnackBar.showSuccess(context: context, message: 'Задание №${widget.taskNumber} удалено');
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка удаления задания: $e');
    }
  }

  Widget _buildReviewButtons(BuildContext context) {
    final scale = getScaleFactor(context);
    final status = widget.task['status'] ?? 'active';
    final bool isIPK = widget.task['isIPK'] == true;

    if (status != 'completed') return const SizedBox.shrink();

    // ИТМ может проверять ВСЕ задания, КРОМЕ заданий ИПК
    if (userSpec == 4 && !isIPK) {
      return _buildButtonContainer();
    }

    // ИПК может проверять ТОЛЬКО свои задания
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String? createdBy = widget.task['createdBy'];
    if (userSpec == 5 && isIPK && createdBy == currentUserId) {
      return _buildButtonContainer();
    }

    return const SizedBox.shrink();
  }

  Widget _buildButtonContainer() {
    final scale = getScaleFactor(context);
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
          Text('Проверка выполнения:', style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosB', color: Colors.black87)),
          SizedBox(height: 15 * scale),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 45 * scale,
                  margin: EdgeInsets.only(right: 8 * scale),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _reviewTask(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: Colors.white, size: 20 * scale),
                        SizedBox(width: 8 * scale),
                        Flexible(
                          child: Text('Подтвердить',
                              style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosB', color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 45 * scale,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () => _reviewTask(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                    ),
                    child: isLoading
                        ? CircularProgressIndicator(strokeWidth: 2)
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, color: Colors.red, size: 20 * scale),
                        SizedBox(width: 8 * scale),
                        Flexible(
                          child: Text('На доработку',
                              style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosB', color: Colors.red),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteTaskSection(BuildContext context) {
    final scale = getScaleFactor(context);
    final bool isIPK = widget.task['isIPK'] == true;

    if (userSpec != 4 && userSpec != 5) return const SizedBox.shrink();
    if (isIPK && userSpec == 4) return const SizedBox.shrink();
    if (!isIPK && userSpec == 5) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _confirmDeleteTask,
      child: Container(
        margin: EdgeInsets.only(top: 20 * scale, bottom: 10 * scale),
        padding: EdgeInsets.all(16 * scale),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 20 * scale),
            SizedBox(width: 10 * scale),
            Text('Удалить задание',
                style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosB', color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard(String title, String name, String? date, IconData icon, Color color) {
    final scale = getScaleFactor(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12 * scale),
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12 * scale),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40 * scale,
            height: 40 * scale,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10 * scale)),
            child: Icon(icon, color: Colors.white, size: 20 * scale),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontFamily: 'GolosB', fontSize: 12 * scale, color: Colors.grey[600])),
                SizedBox(height: 4 * scale),
                Text(name, style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale, color: color)),
                if (date != null) ...[
                  SizedBox(height: 4 * scale),
                  Text(_formatDate(date), style: TextStyle(fontFamily: 'GolosR', fontSize: 12 * scale, color: Colors.grey[500])),
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
    final hasImage = widget.task['hasImage'] == true;
    final hasResultImage = widget.task['hasResultImage'] == true;
    final status = widget.task['status'] ?? 'active';
    final bool isIPK = widget.task['isIPK'] == true;

    final String? completedBy = widget.task['completedBy'];
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool canRedo = status == 'rejected' && completedBy == currentUserId;

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
                child: Text('Задание ${widget.taskNumber} - №${widget.orderNumber}',
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12 * scale),
                      decoration: BoxDecoration(
                        color: _statusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10 * scale),
                        border: Border.all(color: _statusColor(status)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_statusIcon(status), color: _statusColor(status), size: 20 * scale),
                          SizedBox(width: 8 * scale),
                          Flexible(
                            child: Text(
                              _statusText(status),
                              style: TextStyle(
                                  fontSize: status == 'completed' || status == 'rejected' ? 14 * scale : 16 * scale,
                                  fontFamily: 'GolosB',
                                  color: _statusColor(status)),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20 * scale),
                    Text('Заказ:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 5 * scale),
                    Text('№${widget.orderNumber}', style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.black87)),
                    SizedBox(height: 20 * scale),
                    Text('Участники задания:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 12 * scale),
                    _buildUserInfoCard('ЗАКАЗЧИК', creatorName, widget.task['createdAt'], Icons.person_outline, Colors.blue),
                    if (widget.task['completedBy'] != null)
                      _buildUserInfoCard('ИСПОЛНИТЕЛЬ', executorName, widget.task['completedAt'], Icons.work_outline, Colors.green),
                    if (widget.task['reviewedBy'] != null)
                      _buildUserInfoCard('ПРОВЕРИЛ', reviewerName, widget.task['reviewedAt'], Icons.verified_outlined, Colors.orange),
                    SizedBox(height: 20 * scale),
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
                        widget.task['taskDescription']?.toString() ?? 'Описание отсутствует',
                        style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.black87, height: 1.4),
                      ),
                    ),
                    SizedBox(height: 30 * scale),
                    Text('Исходное изображение:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                    SizedBox(height: 10 * scale),
                    if (hasImage && originalImageBase64 != null) ...[
                      _buildInteractiveImage(context, originalImageBase64!, 'Исходное изображение', Colors.blue),
                      SizedBox(height: 10 * scale),
                      Text('Нажмите на изображение для приближения',
                          style: TextStyle(fontFamily: 'GolosR', color: Colors.blue, fontSize: 12 * scale),
                          textAlign: TextAlign.center),
                    ] else if (hasImage) ...[
                      Center(child: CircularProgressIndicator()),
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
                            Icon(Icons.photo_library, color: Colors.grey, size: 50 * scale),
                            SizedBox(height: 10 * scale),
                            Text('Исходное изображение не прикреплено',
                                style: TextStyle(fontFamily: 'GolosR', color: Colors.grey, fontSize: 14 * scale)),
                          ],
                        ),
                      ),
                    ],
                    if (hasResultImage && resultImageBase64 != null) ...[
                      SizedBox(height: 30 * scale),
                      Text('Фото результата:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                      SizedBox(height: 10 * scale),
                      _buildInteractiveImage(context, resultImageBase64!, 'Фото выполненной работы', Colors.green),
                      SizedBox(height: 10 * scale),
                      Text('Нажмите на изображение для приближения',
                          style: TextStyle(fontFamily: 'GolosR', color: Colors.green, fontSize: 12 * scale),
                          textAlign: TextAlign.center),
                    ] else if (hasResultImage) ...[
                      SizedBox(height: 30 * scale),
                      Center(child: CircularProgressIndicator()),
                    ],
                    _buildReviewButtons(context),
                    _buildDeleteTaskSection(context),
                    if (canRedo) ...[
                      SizedBox(height: 20 * scale),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16 * scale),
                        margin: EdgeInsets.only(top: 10 * scale),
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
                                Icon(Icons.info, color: Colors.orange, size: 20 * scale),
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
                              '${isIPK ? 'ИПК' : 'ИТМ'} отклонил предыдущее фото. Сделайте новое фото результата.',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontFamily: 'GolosR',
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 15 * scale),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/TaskPhotoScreen', arguments: {
                                  'orderNumber': widget.orderNumber,
                                  'collectionName': widget.collectionName,
                                  'taskId': widget.taskId,
                                  'task': widget.task,
                                  'taskNumber': widget.taskNumber,
                                  'screenTitle': widget.task['isIPK'] == true ? 'ИПК' : 'Задание',
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 20 * scale),
                                  SizedBox(width: 8 * scale),
                                  Flexible(
                                    child: Text('Переделать задание',
                                        style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosB', color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildInteractiveImage(BuildContext context, String base64String, String title, Color color) {
    final scale = getScaleFactor(context);
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, base64String, title),
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

  void _showFullScreenImage(BuildContext context, String base64String, String title) {
    try {
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
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка открытия изображения');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateString;
    }
  }
}