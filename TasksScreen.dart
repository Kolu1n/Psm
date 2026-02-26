// TasksScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:psm/pages/CreateTaskScreen.dart';
import 'package:psm/pages/create_ipk_task_screen.dart';

class TasksScreen extends StatefulWidget {
  final String orderNumber;
  final String collectionName;
  final String screenTitle;

  const TasksScreen({
    Key? key,
    required this.orderNumber,
    required this.collectionName,
    required this.screenTitle,
  }) : super(key: key);

  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  int? userSpec;
  bool isLoadingUserSpec = true;
  Map<String, String> userNames = {};

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
  }

  Future<void> _loadUserSpec() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userSpec = doc.data()?['specialization'] ?? 0;
          isLoadingUserSpec = false;
        });
        return;
      }
    }
    setState(() {
      userSpec = 0;
      isLoadingUserSpec = false;
    });
  }

  Future<String> _getUserName(String uid) async {
    if (userNames.containsKey(uid)) return userNames[uid]!;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final name = doc.data()?['displayName'] ?? 'Неизвестно';
        userNames[uid] = name;
        return name;
      }
    } catch (_) {}
    return 'Неизвестно';
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
        return 'Выполнено';
      case 'approved':
        return 'Подтверждено';
      case 'rejected':
        return 'На доработке';
      default:
        return 'Неизвестно';
    }
  }

  Future<void> _confirmDeleteTask(int taskIndex, Map<String, dynamic> task, int taskNumber) async {
    final scale = getScaleFactor(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Удаление задания', style: TextStyle(fontFamily: 'GolosB', fontSize: 19)),
        content: Text('Вы уверены, что хотите удалить задание №$taskNumber?',
            style: TextStyle(fontFamily: 'GolosR')),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: Text('Отмена', style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 14)),
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  child: Text('Да', style: TextStyle(color: Colors.white, fontFamily: 'GolosB', fontSize: 14)),
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) {
      // Проверка перед удалением
      final bool isIPK = task['isIPK'] == true;
      final String status = task['status'] ?? 'active';

      // ✅ ИПК может удалять свои задания, даже если они выполнены
      if (isIPK && userSpec != 5) {
        CustomSnackBar.showWarning(context: context, message: 'ИПК-задания нельзя удалять');
        return;
      }

      // ✅ ИПК может удалять выполненные задания, ИТР - нет
      if ((status == 'completed' || status == 'approved') && !(isIPK && userSpec == 5)) {
        CustomSnackBar.showWarning(context: context, message: 'Нельзя удалить завершенное задание');
        return;
      }

      await _deleteTask(taskIndex, taskNumber);
    }
  }

  Future<void> _deleteTask(int taskIndex, int taskNumber) async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).get();
      if (!orderDoc.exists) throw Exception('Заказ не найден');
      final orderData = orderDoc.data()!;
      final tasks = List.from(orderData['tasks']);
      if (taskIndex >= tasks.length) throw Exception('Задание не найдено');

      final bool isIPK = tasks[taskIndex]['isIPK'] == true;
      final String status = tasks[taskIndex]['status'] ?? 'active';

      // ✅ ИПК может удалять свои задания, даже если они выполнены
      if (isIPK && userSpec != 5) {
        CustomSnackBar.showWarning(context: context, message: 'ИПК-задания нельзя удалять');
        return;
      }

      // ✅ ИПК может удалять выполненные задания, ИТР - нет
      if ((status == 'completed' || status == 'approved') && !(isIPK && userSpec == 5)) {
        CustomSnackBar.showWarning(context: context, message: 'Нельзя удалить завершенное задание');
        return;
      }

      tasks.removeAt(taskIndex);
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

      CustomSnackBar.showError(context: context, message: 'Задание №$taskNumber удалено');
      if (tasks.isEmpty) {
        await FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).delete();
        CustomSnackBar.showInfo(context: context, message: 'Все задания удалены. Заказ закрыт.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка удаления задания: $e');
    }
  }

  void _navigateToTaskPhoto(Map<String, dynamic> task, int taskNumber, int taskIndex) {
    Navigator.pushNamed(context, '/TaskPhotoScreen', arguments: {
      'orderNumber': widget.orderNumber,
      'collectionName': widget.collectionName,
      'taskIndex': taskIndex,
      'task': task,
      'taskNumber': taskNumber,
      'screenTitle': widget.screenTitle, // ✅ ДОБАВЛЕНО: передаем screenTitle
    });
  }

  void _navigateToTaskDetail(Map<String, dynamic> task, int taskNumber, int taskIndex) {
    Navigator.pushNamed(context, '/TaskDetail', arguments: {
      'task': task,
      'taskNumber': taskNumber,
      'orderNumber': widget.orderNumber,
      'collectionName': widget.collectionName,
      'taskIndex': taskIndex,
    });
  }

  void _handleTaskTap(Map<String, dynamic> task, int taskNumber, int taskIndex) {
    final status = task['status'] ?? 'active';
    final bool isIPK = task['isIPK'] == true;

    // ИТР может выполнять ИПК-задания, но не проверять
    if (isIPK && userSpec == 4 && status == 'active') {
      Navigator.pushNamed(context, '/IPKWorkerTask', arguments: {
        'orderNumber': widget.orderNumber,
        'collectionName': widget.collectionName,
        'taskIndex': taskIndex,
        'task': task,
        'taskNumber': taskNumber,
      });
      return;
    }

    // Остальные случаи без изменений
    if (userSpec == 4 || userSpec == 5) {
      _navigateToTaskDetail(task, taskNumber, taskIndex);
      return;
    }
    switch (status) {
      case 'active':
        _navigateToTaskPhoto(task, taskNumber, taskIndex);
        break;
      case 'completed':
      case 'approved':
      case 'rejected':
      default:
        _navigateToTaskDetail(task, taskNumber, taskIndex);
        break;
    }
  }

  void _onAddTask() {
    final bool isUserIPK = userSpec == 5;
    final String spec = _detectSpecFromCollection(widget.collectionName);

    final args = {
      'orderNumber': widget.orderNumber,
      'preselectedTaskType': spec,
    };

    final route = isUserIPK ? '/CreateIPKTask' : '/CreateTask';
    Navigator.pushNamed(context, route, arguments: args).then((_) {
      setState(() {});
    });
  }

  String _detectSpecFromCollection(String col) {
    if (col.contains('Sborka')) return 'Сборка';
    if (col.contains('Montasch')) return 'Монтаж';
    if (col.contains('Pacet')) return 'Пакетирование';
    return 'Сборка';
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
    final shortTitle = widget.screenTitle.replaceAll('Задания для ', '').replaceAll('ИПК ', '');

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: (userSpec == 4 || userSpec == 5)
          ? FloatingActionButton(
        heroTag: 'addTaskBtn',
        onPressed: _onAddTask,
        backgroundColor: Colors.red,
        mini: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16 * scale),
        ),
        child: Icon(Icons.add, color: Colors.white, size: 28 * scale),
      )
          : null,
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
                child: Text('$shortTitle - №${widget.orderNumber}',
                    maxLines: 2,
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection(widget.collectionName).doc(widget.orderNumber).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка загрузки данных', style: TextStyle(fontFamily: 'GolosR')));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.red));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Center(child: Text('Заказ не найден', style: TextStyle(fontFamily: 'GolosR')));
                  }

                  final orderData = snapshot.data!.data() as Map<String, dynamic>;
                  List<dynamic> allTasks = [];
                  try {
                    final tasksData = orderData['tasks'];
                    if (tasksData is List) allTasks = tasksData;
                  } catch (_) {}

                  if (isLoadingUserSpec) {
                    return Center(child: CircularProgressIndicator(color: Colors.red));
                  }

                  final bool isIPKScreen = widget.screenTitle.contains('ИПК');
                  final bool isUserIPK = userSpec == 5;

                  final tasks = (isIPKScreen && isUserIPK)
                      ? allTasks.where((t) => t['isIPK'] == true).toList()
                      : allTasks;

                  if (tasks.isEmpty) {
                    return Center(
                      child: Text(
                          isUserIPK ? 'ИПК-заданий в этом заказе пока нет' : 'Заданий в этом заказе пока нет',
                          style: TextStyle(fontFamily: 'GolosR', fontSize: 18 * scale, color: Colors.grey)),
                    );
                  }

                  final allApproved = tasks.every((t) => t['status'] == 'approved');
                  final approvedCount = tasks.where((t) => t['status'] == 'approved').length;

                  return Column(
                    children: [
                      if (userSpec == 4 || userSpec == 5)
                        Container(
                          padding: EdgeInsets.all(12 * scale),
                          margin: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 10 * scale),
                          decoration: BoxDecoration(
                            color: allApproved ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10 * scale),
                            border: Border.all(color: allApproved ? Colors.green : Colors.blue),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(allApproved ? Icons.check_circle : Icons.info,
                                  color: allApproved ? Colors.green : Colors.blue, size: 20 * scale),
                              SizedBox(width: 8 * scale),
                              Flexible(
                                child: Text(
                                  allApproved
                                      ? 'Все задания подтверждены'
                                      : 'Статус: $approvedCount/${tasks.length} подтверждено',
                                  style: TextStyle(
                                      fontFamily: 'GolosR',
                                      color: allApproved ? Colors.green : Colors.blue,
                                      fontSize: 14 * scale),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.all(20 * scale),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            try {
                              final task = tasks[index] is Map<String, dynamic>
                                  ? tasks[index] as Map<String, dynamic>
                                  : Map<String, dynamic>.from(tasks[index] ?? {});

                              final bool isUserIPK = userSpec == 5;
                              final bool isIPKScreen = widget.screenTitle.contains('ИПК');
                              final displayTaskNumber = (isUserIPK && isIPKScreen) ? index + 1 : (task['taskNumber'] ?? index + 1);

                              final hasImage = task['imageBase64'] != null && task['imageBase64'].isNotEmpty;
                              final hasResultImage = task['resultImageBase64'] != null && task['resultImageBase64'].isNotEmpty;
                              final status = task['status'] ?? 'active';
                              final taskDescription = task['taskDescription']?.toString() ?? '';
                              final bool isIPK = task['isIPK'] == true;

                              // ✅ ИПК может удалять свои выполненные задания
                              final bool canDelete = (userSpec == 4 && !isIPK) || (userSpec == 5 && isIPK);

                              return GestureDetector(
                                onTap: () => _handleTaskTap(task, displayTaskNumber, index),
                                child: Card(
                                  margin: EdgeInsets.only(bottom: 15 * scale),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15 * scale),
                                  ),
                                  elevation: 2,
                                  child: Container(
                                    padding: EdgeInsets.all(15 * scale),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 40 * scale,
                                          height: 40 * scale,
                                          decoration: BoxDecoration(
                                            color: isIPK ? Colors.red[800] : Colors.red,
                                            borderRadius: BorderRadius.circular(10 * scale),
                                          ),
                                          child: Center(
                                            child: Text('$displayTaskNumber',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontFamily: 'GolosB',
                                                    fontSize: 16 * scale)),
                                          ),
                                        ),
                                        SizedBox(width: 15 * scale),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text('Задание ',
                                                      style: TextStyle(
                                                          fontFamily: 'GolosB',
                                                          fontSize: 18 * scale,
                                                          color: Colors.black87)),
                                                  Text('№$displayTaskNumber',
                                                      style: TextStyle(
                                                          fontFamily: 'GolosB',
                                                          fontSize: 18 * scale,
                                                          color: Colors.black87)),
                                                ],
                                              ),
                                              SizedBox(height: 8 * scale),
                                              if (taskDescription.isNotEmpty) ...[
                                                Text(taskDescription,
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        fontFamily: 'GolosR',
                                                        color: Colors.black87,
                                                        fontSize: 14 * scale)),
                                                SizedBox(height: 8 * scale),
                                              ],
                                              if (task['createdBy'] != null)
                                                FutureBuilder<String>(
                                                  future: _getUserName(task['createdBy']),
                                                  builder: (context, snap) {
                                                    if (snap.connectionState == ConnectionState.waiting) {
                                                      return Text('Заказчик: Загрузка...',
                                                          style: TextStyle(
                                                              fontFamily: 'GolosR',
                                                              fontSize: 12 * scale,
                                                              color: Colors.grey[600]));
                                                    }
                                                    return Text('Заказчик: ${snap.data ?? 'Неизвестно'}',
                                                        style: TextStyle(
                                                            fontFamily: 'GolosR',
                                                            fontSize: 12 * scale,
                                                            color: Colors.grey[600]));
                                                  },
                                                ),
                                              SizedBox(height: 8 * scale),
                                              Row(
                                                children: [
                                                  Icon(
                                                    hasImage ? Icons.photo_library : Icons.photo_library_outlined,
                                                    color: hasImage ? Colors.green : Colors.grey,
                                                    size: 18 * scale,
                                                  ),
                                                  SizedBox(width: 5 * scale),
                                                  Text(hasImage ? 'Есть фото' : 'Нет фото',
                                                      style: TextStyle(
                                                          fontFamily: 'GolosR',
                                                          fontSize: 12 * scale,
                                                          color: hasImage ? Colors.green : Colors.grey)),
                                                ],
                                              ),
                                              if (hasResultImage) ...[
                                                SizedBox(height: 5 * scale),
                                                Row(
                                                  children: [
                                                    Icon(Icons.photo_camera_back, color: Colors.green, size: 18 * scale),
                                                    SizedBox(width: 5 * scale),
                                                    Text('Есть результат',
                                                        style: TextStyle(
                                                            fontFamily: 'GolosR',
                                                            fontSize: 12 * scale,
                                                            color: Colors.green)),
                                                  ],
                                                ),
                                              ],
                                              SizedBox(height: 8 * scale),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                        horizontal: 12 * scale, vertical: 6 * scale),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(status).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8 * scale),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(_statusIcon(status),
                                                            color: _statusColor(status), size: 14 * scale),
                                                        SizedBox(width: 6 * scale),
                                                        Flexible(
                                                          child: Text(_statusText(status),
                                                              style: TextStyle(
                                                                  fontFamily: 'GolosB',
                                                                  fontSize: 12 * scale,
                                                                  color: _statusColor(status)),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  if (isIPK) ...[
                                                    SizedBox(width: 8 * scale),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(
                                                        horizontal: 6 * scale,
                                                        vertical: 2 * scale,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(6 * scale),
                                                        border: Border.all(color: Colors.red, width: 1),
                                                      ),
                                                      child: Text(
                                                        'ИПК',
                                                        style: TextStyle(
                                                          fontFamily: 'GolosB',
                                                          fontSize: 9 * scale,
                                                          color: Colors.red,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (canDelete) ...[
                                          SizedBox(width: 10 * scale),
                                          GestureDetector(
                                            onTap: () => _confirmDeleteTask(index, task, displayTaskNumber),
                                            child: Container(
                                              width: 40 * scale,
                                              height: 40 * scale,
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(10 * scale),
                                                border: Border.all(color: Colors.red, width: 1),
                                              ),
                                              child: Center(
                                                child: Icon(Icons.delete_outline, color: Colors.red, size: 22 * scale),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } catch (_) {
                              return Card(
                                margin: EdgeInsets.only(bottom: 15 * scale),
                                child: ListTile(
                                  leading: Icon(Icons.error, color: Colors.red, size: 24 * scale),
                                  title: Text('Ошибка загрузки задания', style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale)),
                                  subtitle: Text('Невозможно отобразить задание', style: TextStyle(fontFamily: 'GolosR', fontSize: 14 * scale)),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}