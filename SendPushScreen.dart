// SendPushScreen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:psm/fcm_service.dart';

class SendPushScreen extends StatefulWidget {
  @override
  _SendPushScreenState createState() => _SendPushScreenState();
}

class _SendPushScreenState extends State<SendPushScreen> {
  bool _montaschSelected = false;
  bool _sborkaSelected = false;
  bool _pacetSelected = false;
  bool _isLoading = false;
  String _userName = 'ИТМ';

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
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['displayName'] ?? 'ИТМ';
        });
      }
    }
  }

  // 🔴 НОВЫЙ МЕТОД: Получаем детальную статистику по заказам
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _getDetailedStatistics() async {
    Map<String, Map<String, List<Map<String, dynamic>>>> stats = {
      'Montasch': {},  // orderNumber -> tasks
      'Sborka': {},
      'Pacet': {},
    };

    try {
      // 🔴 СТАТИСТИКА ПО МОНТАЖУ
      final montaschSnapshot = await FirebaseFirestore.instance
          .collection('Montasch')
          .get();

      for (var doc in montaschSnapshot.docs) {
        final orderData = doc.data();
        final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
        final tasks = orderData['tasks'] as List? ?? [];

        final notCompletedTasks = tasks.where((task) => task['status'] == 'active').toList();

        if (notCompletedTasks.isNotEmpty) {
          stats['Montasch']![orderNumber] = notCompletedTasks.map((task) {
            return {
              'taskNumber': task['taskNumber'] ?? 0,
              'description': task['taskDescription']?.toString() ?? 'Без описания',
            };
          }).toList();
        }
      }

      // 🔴 СТАТИСТИКА ПО СБОРКЕ
      final sborkaSnapshot = await FirebaseFirestore.instance
          .collection('Sborka')
          .get();

      for (var doc in sborkaSnapshot.docs) {
        final orderData = doc.data();
        final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
        final tasks = orderData['tasks'] as List? ?? [];

        final notCompletedTasks = tasks.where((task) => task['status'] == 'active').toList();

        if (notCompletedTasks.isNotEmpty) {
          stats['Sborka']![orderNumber] = notCompletedTasks.map((task) {
            return {
              'taskNumber': task['taskNumber'] ?? 0,
              'description': task['taskDescription']?.toString() ?? 'Без описания',
            };
          }).toList();
        }
      }

      // 🔴 СТАТИСТИКА ПО ПАКЕТИРОВАНИЮ
      final pacetSnapshot = await FirebaseFirestore.instance
          .collection('Pacet')
          .get();

      for (var doc in pacetSnapshot.docs) {
        final orderData = doc.data();
        final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
        final tasks = orderData['tasks'] as List? ?? [];

        final notCompletedTasks = tasks.where((task) => task['status'] == 'active').toList();

        if (notCompletedTasks.isNotEmpty) {
          stats['Pacet']![orderNumber] = notCompletedTasks.map((task) {
            return {
              'taskNumber': task['taskNumber'] ?? 0,
              'description': task['taskDescription']?.toString() ?? 'Без описания',
            };
          }).toList();
        }
      }

      print('📊 Детальная статистика собрана:');
      for (var collection in stats.keys) {
        final orders = stats[collection]!;
        if (orders.isNotEmpty) {
          print('   $collection: ${orders.length} заказов с невыполненными заданиями');
          for (var orderNumber in orders.keys) {
            print('      Заказ $orderNumber: ${orders[orderNumber]!.length} заданий');
          }
        }
      }

    } catch (e) {
      print('❌ Ошибка получения детальной статистики: $e');
    }

    return stats;
  }

  // 🔴 ФОРМИРУЕМ СООБЩЕНИЕ В НУЖНОМ ФОРМАТЕ
  String _formatMessage(String specialization, Map<String, List<Map<String, dynamic>>> orders) {
    if (orders.isEmpty) {
      return '';
    }

    String message = '$_userName напоминает $specialization:\n';

    for (var orderNumber in orders.keys) {
      final tasks = orders[orderNumber]!;
      message += 'Заказ "$orderNumber" - ${tasks.length} не выполненных заданий\n';
    }

    return message.trim();
  }

  // 🔴 ПОЛУЧАЕМ НАЗВАНИЕ СПЕЦИАЛИЗАЦИИ
  String _getSpecializationName(int specializationCode) {
    switch (specializationCode) {
      case 1: return 'сборщикам';
      case 2: return 'монтажникам';
      case 3: return 'пакетировщикам';
      default: return 'работникам';
    }
  }

  Future<void> _sendPushNotifications() async {
    if (!_montaschSelected && !_sborkaSelected && !_pacetSelected) {
      CustomSnackBar.showWarning(
        context: context,
        message: 'Выберите хотя бы одну специализацию',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 🔴 ПОЛУЧАЕМ ДЕТАЛЬНУЮ СТАТИСТИКУ
      final detailedStats = await _getDetailedStatistics();

      // 🔴 ДЛЯ МОНТАЖНИКОВ
      if (_montaschSelected) {
        final montaschOrders = detailedStats['Montasch']!;
        if (montaschOrders.isNotEmpty) {
          final tokens = await FCMService.getTokensBySpecialization(2); // 2 = Монтажник
          if (tokens.isNotEmpty) {
            String message = _formatMessage('монтажникам', montaschOrders);

            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от ИТМ',
              body: message,
              data: {
                'type': 'manager_notification',
                'sender': _userName,
                'specialization': 'montasch',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // 🔴 ДЛЯ СБОРЩИКОВ
      if (_sborkaSelected) {
        final sborkaOrders = detailedStats['Sborka']!;
        if (sborkaOrders.isNotEmpty) {
          final tokens = await FCMService.getTokensBySpecialization(1); // 1 = Сборщик
          if (tokens.isNotEmpty) {
            String message = _formatMessage('сборщикам', sborkaOrders);

            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от ИТМ',
              body: message,
              data: {
                'type': 'manager_notification',
                'sender': _userName,
                'specialization': 'sborka',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // 🔴 ДЛЯ ПАКЕТИРОВЩИКОВ
      if (_pacetSelected) {
        final pacetOrders = detailedStats['Pacet']!;
        if (pacetOrders.isNotEmpty) {
          final tokens = await FCMService.getTokensBySpecialization(3); // 3 = Пакетировщик
          if (tokens.isNotEmpty) {
            String message = _formatMessage('пакетировщикам', pacetOrders);

            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от ИТМ',
              body: message,
              data: {
                'type': 'manager_notification',
                'sender': _userName,
                'specialization': 'pacet',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // Сохраняем историю отправки
      await _saveNotificationHistory(detailedStats);

      CustomSnackBar.showSuccess(
        context: context,
        message: 'Напоминания отправлены работникам',
      );

      Navigator.pop(context);

    } catch (e) {
      print('❌ Ошибка отправки: $e');
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка отправки: ${e.toString()}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🔴 СОХРАНЕНИЕ ИСТОРИИ С ДЕТАЛЬНОЙ СТАТИСТИКОЙ
  Future<void> _saveNotificationHistory(Map<String, Map<String, List<Map<String, dynamic>>>> stats) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {

        String fullMessage = '$_userName отправил напоминания:\n\n';

        // Монтаж
        if (_montaschSelected && stats['Montasch']!.isNotEmpty) {
          fullMessage += 'Монтажникам:\n';
          final montaschOrders = stats['Montasch']!;
          for (var orderNumber in montaschOrders.keys) {
            final tasks = montaschOrders[orderNumber]!;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} не выполненных заданий\n';
          }
          fullMessage += '\n';
        }

        // Сборка
        if (_sborkaSelected && stats['Sborka']!.isNotEmpty) {
          fullMessage += 'Сборщикам:\n';
          final sborkaOrders = stats['Sborka']!;
          for (var orderNumber in sborkaOrders.keys) {
            final tasks = sborkaOrders[orderNumber]!;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} не выполненных заданий\n';
          }
          fullMessage += '\n';
        }

        // Пакетирование
        if (_pacetSelected && stats['Pacet']!.isNotEmpty) {
          fullMessage += 'Пакетировщикам:\n';
          final pacetOrders = stats['Pacet']!;
          for (var orderNumber in pacetOrders.keys) {
            final tasks = pacetOrders[orderNumber]!;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} не выполненных заданий\n';
          }
        }

        await FirebaseFirestore.instance
            .collection('notification_history')
            .add({
          'senderId': user.uid,
          'senderName': _userName,
          'message': fullMessage,
          'montaschSelected': _montaschSelected,
          'sborkaSelected': _sborkaSelected,
          'pacetSelected': _pacetSelected,
          'sentAt': DateTime.now().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
          'stats': {
            'Montasch': _formatStatsForFirestore(stats['Montasch']!),
            'Sborka': _formatStatsForFirestore(stats['Sborka']!),
            'Pacet': _formatStatsForFirestore(stats['Pacet']!),
          },
        });
        print('✅ История уведомления сохранена с детальной статистикой');
      }
    } catch (e) {
      print('❌ Ошибка сохранения истории: $e');
    }
  }

  // 🔴 ФОРМАТИРУЕМ СТАТИСТИКУ ДЛЯ FIRESTORE
  Map<String, dynamic> _formatStatsForFirestore(Map<String, List<Map<String, dynamic>>> orders) {
    Map<String, dynamic> result = {};

    for (var orderNumber in orders.keys) {
      result[orderNumber] = {
        'count': orders[orderNumber]!.length,
        'tasks': orders[orderNumber]!.map((task) => {
          'taskNumber': task['taskNumber'],
          'description': task['description'],
        }).toList(),
      };
    }

    return result;
  }

  Widget _buildSpecializationCheckbox(String label, bool value, Function(bool?) onChanged, BuildContext context) {
    final scale = getScaleFactor(context);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        margin: EdgeInsets.only(bottom: 15 * scale),
        padding: EdgeInsets.all(15 * scale),
        decoration: BoxDecoration(
          color: value ? Colors.blue.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(15 * scale),
          border: Border.all(
            color: value ? Colors.blue : Colors.grey[300]!,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24 * scale,
              height: 24 * scale,
              decoration: BoxDecoration(
                color: value ? Colors.blue : Colors.transparent,
                borderRadius: BorderRadius.circular(6 * scale),
                border: Border.all(
                  color: value ? Colors.blue : Colors.grey,
                  width: 2,
                ),
              ),
              child: value
                  ? Icon(
                Icons.check,
                size: 16 * scale,
                color: Colors.white,
              )
                  : null,
            ),
            SizedBox(width: 15 * scale),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontFamily: 'GolosB',
                  color: value ? Colors.blue : Colors.black87,
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
              Color(0xFFF0F8FF),
            ],
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                'Отправить напоминание',
                style: TextStyle(
                  fontFamily: 'GolosB',
                  fontSize: 18 * scale,
                  color: Colors.black,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.blue),
              centerTitle: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 20 * scale),
                      padding: EdgeInsets.all(15 * scale),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15 * scale),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: Colors.blue,
                            size: 24 * scale,
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Text(
                              'Отправьте напоминание работникам о невыполненных заданиях',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                fontSize: 14 * scale,
                                color: Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      'Выберите специализации:',
                      style: TextStyle(
                        fontSize: 18 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 15 * scale),

                    _buildSpecializationCheckbox(
                      'Монтажникам',
                      _montaschSelected,
                          (value) => setState(() => _montaschSelected = value ?? false),
                      context,
                    ),

                    _buildSpecializationCheckbox(
                      'Сборщикам',
                      _sborkaSelected,
                          (value) => setState(() => _sborkaSelected = value ?? false),
                      context,
                    ),

                    _buildSpecializationCheckbox(
                      'Пакетировщикам',
                      _pacetSelected,
                          (value) => setState(() => _pacetSelected = value ?? false),
                      context,
                    ),

                    SizedBox(height: 30 * scale),

                    Container(
                      padding: EdgeInsets.all(15 * scale),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(15 * scale),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Формат напоминания:',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontFamily: 'GolosB',
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Container(
                            padding: EdgeInsets.all(12 * scale),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10 * scale),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Пример:',
                                  style: TextStyle(
                                    fontFamily: 'GolosB',
                                    color: Colors.blue,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                SizedBox(height: 5 * scale),
                                Text(
                                  'Владимир напоминает сборщикам:\n'
                                      'Заказ "12345" - 3 не выполненных заданий\n'
                                      'Заказ "67890" - 1 не выполненное задание',
                                  style: TextStyle(
                                    fontFamily: 'GolosR',
                                    color: Colors.black87,
                                    fontSize: 13 * scale,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10 * scale),
                          Text(
                            '📱 Уведомление будет отправлено на устройства работников',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              fontSize: 12 * scale,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40 * scale),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Container(
                            height: 50 * scale,
                            margin: EdgeInsets.only(right: 10 * scale),
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15 * scale),
                                ),
                              ),
                              child: Text(
                                'Отмена',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 50 * scale,
                            margin: EdgeInsets.only(left: 10 * scale),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _sendPushNotifications,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15 * scale),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                'Отправить',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 20 * scale),

                    if (_isLoading)
                      Container(
                        padding: EdgeInsets.all(10 * scale),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 10 * scale),
                            Text(
                              'Отправка напоминаний...',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                fontFamily: 'GolosR',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
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