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
  int? userSpec;
  bool isLoading = false;
  String creatorName = 'Загрузка...';
  String executorName = 'Загрузка...';
  String reviewerName = 'Загрузка...';

  late final bool isIPK;

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
    isIPK = widget.task['isIPK'] == true;
    _loadUserSpec();
    _loadUserNames();
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
        return 'Подтверждено ИТР';
      case 'rejected':
        return 'Отклонено (требует доработки)';
      default:
        return 'Неизвестно';
    }
  }

  Future<void> _reviewTask(bool approved) async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderDoc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).get();
      if (!orderDoc.exists) throw Exception('Заказ не найден');
      final orderData = orderDoc.data()!;
      final tasks = List.from(orderData['tasks']);
      if (widget.taskIndex >= tasks.length) throw Exception('Задание не найдено');

      final bool isIPK = tasks[widget.taskIndex]['isIPK'] == true;
      final String? createdBy = tasks[widget.taskIndex]['createdBy'];

      // ✅ ИПК может проверять ТОЛЬКО свои задания
      if (userSpec == 5 && isIPK && createdBy != user?.uid) {
        CustomSnackBar.showWarning(context: context, message: 'Вы можете проверять только свои задания');
        setState(() => isLoading = false);
        return;
      }

      // ✅ ИТР не может проверять задания ИПК
      if (userSpec == 4 && isIPK) {
        CustomSnackBar.showWarning(context: context, message: 'ИТР не может проверять задания ИПК');
        setState(() => isLoading = false);
        return;
      }

      if (approved) {
        tasks.removeAt(widget.taskIndex);
        for (int i = 0; i < tasks.length; i++) {
          tasks[i]['taskNumber'] = i + 1;
        }
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).update({
          'tasks': tasks,
          'updatedAt': DateTime.now().toIso8601String(),
        });
        await _moveTaskToCompleted();
        if (tasks.isEmpty) {
          await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).delete();
        }
        CustomSnackBar.showSuccess(
          context: context,
          message: tasks.isEmpty ? 'Задание подтверждено и заказ завершен' : 'Задание подтверждено и перенесено в завершенные',
        );
      } else {
        tasks[widget.taskIndex] = {
          ...tasks[widget.taskIndex],
          'status': 'rejected',
          'reviewedBy': user?.uid,
          'reviewedAt': DateTime.now().toIso8601String(),
        };
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).update({
          'tasks': tasks,
          'updatedAt': DateTime.now().toIso8601String(),
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
      await FirebaseFirestore.instance.collection('completed_tasks').add(completedTaskData);
    } catch (e) {
      print('Ошибка при переносе задания в завершенные: $e');
    }
  }

  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['displayName'] ?? 'ИТР';
      }
    }
    return 'ИТР';
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
      final orderDoc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).get();
      if (!orderDoc.exists) throw Exception('Заказ не найден');
      final orderData = orderDoc.data()!;
      final tasks = List.from(orderData['tasks']);
      if (widget.taskIndex >= tasks.length) throw Exception('Задание не найдено');

      final bool isIPK = tasks[widget.taskIndex]['isIPK'] == true;
      final String status = tasks[widget.taskIndex]['status'] ?? 'active';

      // Проверка прав
      if (isIPK && userSpec != 5) {
        CustomSnackBar.showWarning(context: context, message: 'ИПК-задания нельзя удалять');
        return;
      }

      // ИПК может удалять свои задания, даже если они выполнены
      if ((status == 'completed' || status == 'approved') && !(isIPK && userSpec == 5)) {
        CustomSnackBar.showWarning(context: context, message: 'Нельзя удалить завершенное задание');
        return;
      }

      tasks.removeAt(widget.taskIndex);
      for (int i = 0; i < tasks.length; i++) {
        tasks[i]['taskNumber'] = i + 1;
      }

      // Проверяем, остались ли ИПК-задания
      final bool stillHasIPK = tasks.any((t) => t['isIPK'] == true);

      await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).update({
        'tasks': tasks,
        'updatedAt': DateTime.now().toIso8601String(),
        'hasIPKTask': stillHasIPK,
      });

      CustomSnackBar.showSuccess(context: context, message: 'Задание №${widget.taskNumber} удалено');
      if (tasks.isEmpty) {
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).delete();
        CustomSnackBar.showInfo(context: context, message: 'Все задания удалены. Заказ закрыт.');
      }
      Navigator.of(context).pop();
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка удаления задания: $e');
    }
  }

  // ИСПРАВЛЕННЫЙ МЕТОД: Проверка прав для показа кнопок проверки
  Widget _buildReviewButtons(BuildContext context) {
    final scale = getScaleFactor(context);
    final status = widget.task['status'] ?? 'active';
    final bool isIPK = widget.task['isIPK'] == true;
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final String? createdBy = widget.task['createdBy'];

    // Показываем кнопки только выполненным заданиям
    if (status != 'completed') return const SizedBox.shrink();

    // ИТР может проверять ВСЕ задания, КРОМЕ заданий ИПК
    if (userSpec == 4 && !isIPK) {
      return _buildButtonContainer();
    }

    // ИПК может проверять ТОЛЬКО свои задания
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
                          child: Text('Подтвердить выполнение',
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
                          child: Text('Отправить на доработку',
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
          SizedBox(height: 10 * scale),
          Text('При подтверждении задание будет перенесено в завершенные',
              style: TextStyle(fontFamily: 'GolosR', color: Colors.grey[600], fontSize: 12 * scale),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDeleteTaskSection(BuildContext context) {
    final scale = getScaleFactor(context);
    final bool isIPK = widget.task['isIPK'] == true;

    // Скрываем кнопку удаления для неавторизованных
    if (userSpec != 4 && userSpec != 5) return const SizedBox.shrink();

    // ИТР не может удалять ИПК-задания
    if (isIPK && userSpec == 4) return const SizedBox.shrink();

    // ИПК не может удалять задания ИТР
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8 * scale, offset: Offset(0, 2 * scale))],
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
                Text(title,
                    style: TextStyle(fontFamily: 'GolosB', fontSize: 12 * scale, color: Colors.grey[600])),
                SizedBox(height: 4 * scale),
                Text(name,
                    style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale, color: color)),
                if (date != null) ...[
                  SizedBox(height: 4 * scale),
                  Text(_formatDate(date),
                      style: TextStyle(fontFamily: 'GolosR', fontSize: 12 * scale, color: Colors.grey[500])),
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
    final bool isIPK = widget.task['isIPK'] == true;

    // Проверяем, является ли текущий пользователь исполнителем задания
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
                    if (hasImage) ...[
                      _buildInteractiveImage(context, widget.task['imageBase64']!, 'Исходное изображение задания', Colors.blue),
                      SizedBox(height: 10 * scale),
                      Text('Нажмите на изображение для приближения',
                          style: TextStyle(fontFamily: 'GolosR', color: Colors.blue, fontSize: 12 * scale),
                          textAlign: TextAlign.center),
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
                    if (hasResultImage) ...[
                      SizedBox(height: 30 * scale),
                      Text('Фото результата:', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
                      SizedBox(height: 10 * scale),
                      _buildInteractiveImage(context, widget.task['resultImageBase64']!, 'Фото выполненной работы', Colors.green),
                      SizedBox(height: 10 * scale),
                      Text('Нажмите на изображение для приближения',
                          style: TextStyle(fontFamily: 'GolosR', color: Colors.green, fontSize: 12 * scale),
                          textAlign: TextAlign.center),
                    ],
                    _buildReviewButtons(context),
                    _buildDeleteTaskSection(context),

                    // КНОПКА "ПЕРЕДЕЛАТЬ ЗАДАНИЕ" - показывается только исполнителю при статусе 'rejected'
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
                              '${isIPK ? 'ИПК' : 'ИТР'} отклонил предыдущее фото. Сделайте новое фото результата, оно заменит предыдущее.',
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
                                  'taskIndex': widget.taskIndex,
                                  'task': widget.task,
                                  'taskNumber': widget.taskNumber,
                                  'screenTitle': widget.task['isIPK'] == true ? 'ИПК ${widget.collectionName.replaceAll(RegExp(r'Sborka|Montasch|Pacet'), '')}' : 'Задания для ${widget.collectionName.replaceAll(RegExp(r'Sborka|Montasch|Pacet'), '')}',
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
                Container(
                  padding: EdgeInsets.all(12),
                  color: Colors.black54,
                  child: Text('Используйте жесты для масштабирования и перемещения',
                      style: TextStyle(fontFamily: 'GolosR', color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center),
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