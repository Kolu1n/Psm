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
  String _userName = 'ИПК';
  String? _currentUserId;
  int _userSpec = 0;

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
      setState(() {
        _currentUserId = user.uid;
      });
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final spec = userDoc.data()?['specialization'] ?? 0;
        setState(() {
          _userSpec = spec;
          // 🔴 ИСПРАВЛЕНО: ИТР (4) = "ИТР", ИПК (5) = "ИПК"
          if (spec == 4) {
            _userName = 'ИТР';
          } else if (spec == 5) {
            _userName = 'ИПК';
          } else {
            _userName = userDoc.data()?['displayName'] ?? 'Пользователь';
          }
        });
      }
    }
  }

  // Получаем статистику заданий
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> _getDetailedStatistics() async {
    Map<String, Map<String, List<Map<String, dynamic>>>> stats = {
      'Montasch': {},
      'Sborka': {},
      'Pacet': {},
    };

    try {
      final bool isIPK = _userSpec == 5;

      // Статистика по монтажу
      if (_montaschSelected) {
        final montaschSnapshot = await FirebaseFirestore.instance
            .collection('Montasch')
            .get();

        for (var doc in montaschSnapshot.docs) {
          final orderData = doc.data();
          final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
          final tasks = orderData['tasks'] as List? ?? [];

          final filteredTasks = tasks.where((task) {
            final bool taskIsIPK = task['isIPK'] == true;
            final String status = task['status'] ?? 'active';
            final String? createdBy = task['createdBy'];

            if (isIPK) {
              return taskIsIPK && createdBy == _currentUserId && (status == 'active' || status == 'completed');
            }
            return !taskIsIPK && (status == 'active');
          }).toList();

          if (filteredTasks.isNotEmpty) {
            stats['Montasch']![orderNumber] = filteredTasks.map((task) {
              return {
                'taskNumber': task['taskNumber'] ?? 0,
                'description': task['taskDescription']?.toString() ?? 'Без описания',
                'isIPK': task['isIPK'] == true,
                'createdBy': task['createdBy'] ?? '',
              };
            }).toList();
          }
        }
      }

      // Статистика по сборке
      if (_sborkaSelected) {
        final sborkaSnapshot = await FirebaseFirestore.instance
            .collection('Sborka')
            .get();

        for (var doc in sborkaSnapshot.docs) {
          final orderData = doc.data();
          final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
          final tasks = orderData['tasks'] as List? ?? [];

          final filteredTasks = tasks.where((task) {
            final bool taskIsIPK = task['isIPK'] == true;
            final String status = task['status'] ?? 'active';
            final String? createdBy = task['createdBy'];

            if (isIPK) {
              return taskIsIPK && createdBy == _currentUserId && (status == 'active' || status == 'completed');
            }
            return !taskIsIPK && (status == 'active');
          }).toList();

          if (filteredTasks.isNotEmpty) {
            stats['Sborka']![orderNumber] = filteredTasks.map((task) {
              return {
                'taskNumber': task['taskNumber'] ?? 0,
                'description': task['taskDescription']?.toString() ?? 'Без описания',
                'isIPK': task['isIPK'] == true,
                'createdBy': task['createdBy'] ?? '',
              };
            }).toList();
          }
        }
      }

      // Статистика по пакетированию
      if (_pacetSelected) {
        final pacetSnapshot = await FirebaseFirestore.instance
            .collection('Pacet')
            .get();

        for (var doc in pacetSnapshot.docs) {
          final orderData = doc.data();
          final orderNumber = orderData['orderNumber']?.toString() ?? 'Без номера';
          final tasks = orderData['tasks'] as List? ?? [];

          final filteredTasks = tasks.where((task) {
            final bool taskIsIPK = task['isIPK'] == true;
            final String status = task['status'] ?? 'active';
            final String? createdBy = task['createdBy'];

            if (isIPK) {
              return taskIsIPK && createdBy == _currentUserId && (status == 'active' || status == 'completed');
            }
            return !taskIsIPK && (status == 'active');
          }).toList();

          if (filteredTasks.isNotEmpty) {
            stats['Pacet']![orderNumber] = filteredTasks.map((task) {
              return {
                'taskNumber': task['taskNumber'] ?? 0,
                'description': task['taskDescription']?.toString() ?? 'Без описания',
                'isIPK': task['isIPK'] == true,
                'createdBy': task['createdBy'] ?? '',
              };
            }).toList();
          }
        }
      }

      print('📊 Статистика собрана для $_userName:');
      for (var collection in stats.keys) {
        final orders = stats[collection]!;
        if (orders.isNotEmpty) {
          print('   $collection: ${orders.length} заказов');
          for (var orderNumber in orders.keys) {
            final ipkCount = orders[orderNumber]!.where((t) => t['isIPK'] == true).length;
            print('      Заказ $orderNumber: ${orders[orderNumber]!.length} заданий (ИПК: $ipkCount)');
          }
        }
      }

    } catch (e) {
      print('❌ Ошибка получения статистики: $e');
    }

    return stats;
  }

  // Формируем сообщение
  String _formatMessage(
      String specialization,
      Map<String, List<Map<String, dynamic>>> orders,
      ) {
    if (orders.isEmpty) return '';

    String message = '$_userName напоминает $specialization:\n';

    for (var orderNumber in orders.keys) {
      final tasks = orders[orderNumber]!;
      final int taskCount = tasks.length;
      final int ipkCount = tasks.where((t) => t['isIPK'] == true).length;
      final int regularCount = taskCount - ipkCount;

      String taskInfo = '';
      if (ipkCount > 0 && regularCount > 0) {
        taskInfo = '$taskCount заданий (ИПК: $ipkCount, Обычных: $regularCount)';
      } else if (ipkCount > 0) {
        taskInfo = '$ipkCount ИПК-заданий';
      } else {
        taskInfo = '$taskCount заданий';
      }

      message += 'Заказ "$orderNumber" — $taskInfo\n';
    }

    return message.trim();
  }

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
      final detailedStats = await _getDetailedStatistics();

      final bool hasMontasch = detailedStats['Montasch']!.isNotEmpty;
      final bool hasSborka = detailedStats['Sborka']!.isNotEmpty;
      final bool hasPacet = detailedStats['Pacet']!.isNotEmpty;

      if (!hasMontasch && !hasSborka && !hasPacet) {
        CustomSnackBar.showWarning(
          context: context,
          message: 'Нет заданий для отправки напоминаний',
        );
        setState(() => _isLoading = false);
        return;
      }

      // Монтажники
      if (_montaschSelected && hasMontasch) {
        final tokens = await FCMService.getTokensBySpecialization(2);
        if (tokens.isNotEmpty) {
          String message = _formatMessage('монтажникам', detailedStats['Montasch']!);
          if (message.isNotEmpty) {
            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от $_userName',
              body: message,
              data: {
                'type': _userSpec == 5 ? 'ipk_notification' : 'manager_notification',
                'sender': _userName,
                'specialization': 'montasch',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // Сборщики
      if (_sborkaSelected && hasSborka) {
        final tokens = await FCMService.getTokensBySpecialization(1);
        if (tokens.isNotEmpty) {
          String message = _formatMessage('сборщикам', detailedStats['Sborka']!);
          if (message.isNotEmpty) {
            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от $_userName',
              body: message,
              data: {
                'type': _userSpec == 5 ? 'ipk_notification' : 'manager_notification',
                'sender': _userName,
                'specialization': 'sborka',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

      // Пакетировщики
      if (_pacetSelected && hasPacet) {
        final tokens = await FCMService.getTokensBySpecialization(3);
        if (tokens.isNotEmpty) {
          String message = _formatMessage('пакетировщикам', detailedStats['Pacet']!);
          if (message.isNotEmpty) {
            await FCMService.sendPushNotification(
              tokens: tokens,
              title: 'Напоминание от $_userName',
              body: message,
              data: {
                'type': _userSpec == 5 ? 'ipk_notification' : 'manager_notification',
                'sender': _userName,
                'specialization': 'pacet',
                'timestamp': DateTime.now().toIso8601String(),
              },
            );
          }
        }
      }

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

  Future<void> _saveNotificationHistory(Map<String, Map<String, List<Map<String, dynamic>>>> stats) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String fullMessage = '$_userName отправил напоминания:\n\n';

        if (_montaschSelected && stats['Montasch']!.isNotEmpty) {
          fullMessage += 'Монтажникам:\n';
          final montaschOrders = stats['Montasch']!;
          for (var orderNumber in montaschOrders.keys) {
            final tasks = montaschOrders[orderNumber]!;
            final ipkCount = tasks.where((t) => t['isIPK'] == true).length;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} заданий (ИПК: $ipkCount)\n';
          }
          fullMessage += '\n';
        }

        if (_sborkaSelected && stats['Sborka']!.isNotEmpty) {
          fullMessage += 'Сборщикам:\n';
          final sborkaOrders = stats['Sborka']!;
          for (var orderNumber in sborkaOrders.keys) {
            final tasks = sborkaOrders[orderNumber]!;
            final ipkCount = tasks.where((t) => t['isIPK'] == true).length;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} заданий (ИПК: $ipkCount)\n';
          }
          fullMessage += '\n';
        }

        if (_pacetSelected && stats['Pacet']!.isNotEmpty) {
          fullMessage += 'Пакетировщикам:\n';
          final pacetOrders = stats['Pacet']!;
          for (var orderNumber in pacetOrders.keys) {
            final tasks = pacetOrders[orderNumber]!;
            final ipkCount = tasks.where((t) => t['isIPK'] == true).length;
            fullMessage += '  Заказ "$orderNumber" - ${tasks.length} заданий (ИПК: $ipkCount)\n';
          }
        }

        await FirebaseFirestore.instance
            .collection('notification_history')
            .add({
          'senderId': user.uid,
          'senderName': _userName,
          'senderSpecialization': _userSpec,
          'message': fullMessage,
          'montaschSelected': _montaschSelected,
          'sborkaSelected': _sborkaSelected,
          'pacetSelected': _pacetSelected,
          'sentAt': DateTime.now().toIso8601String(),
          'timestamp': FieldValue.serverTimestamp(),
          'isIPK': _userSpec == 5,
          'stats': {
            'Montasch': _formatStatsForFirestore(stats['Montasch']!),
            'Sborka': _formatStatsForFirestore(stats['Sborka']!),
            'Pacet': _formatStatsForFirestore(stats['Pacet']!),
          },
        });
        print('✅ История уведомления сохранена');
      }
    } catch (e) {
      print('❌ Ошибка сохранения истории: $e');
    }
  }

  Map<String, dynamic> _formatStatsForFirestore(Map<String, List<Map<String, dynamic>>> orders) {
    Map<String, dynamic> result = {};

    for (var orderNumber in orders.keys) {
      final tasks = orders[orderNumber]!;
      result[orderNumber] = {
        'count': tasks.length,
        'ipkCount': tasks.where((t) => t['isIPK'] == true).length,
        'tasks': tasks.map((task) => {
          'taskNumber': task['taskNumber'],
          'description': task['description'],
          'isIPK': task['isIPK'] ?? false,
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
    final bool isIPK = _userSpec == 5;

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
                isIPK ? 'Отправить напоминание (ИПК)' : 'Отправить напоминание',
                style: TextStyle(
                  fontFamily: 'GolosB',
                  fontSize: 18 * scale,
                  color: Colors.black,
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
                      margin: EdgeInsets.only(bottom: 20 * scale),
                      padding: EdgeInsets.all(15 * scale),
                      decoration: BoxDecoration(
                        color: isIPK ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15 * scale),
                        border: Border.all(color: isIPK ? Colors.red : Colors.blue),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: isIPK ? Colors.red : Colors.blue,
                            size: 24 * scale,
                          ),
                          SizedBox(width: 10 * scale),
                          Expanded(
                            child: Text(
                              isIPK
                                  ? 'Отправьте напоминание работникам о невыполненных ИПК-заданиях'
                                  : 'Отправьте напоминание работникам о невыполненных заданиях',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                fontSize: 14 * scale,
                                color: isIPK ? Colors.red[800] : Colors.blue[800],
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
                                    color: isIPK ? Colors.red : Colors.red,
                                    fontSize: 14 * scale,
                                  ),
                                ),
                                SizedBox(height: 5 * scale),
                                // 🔴 ИСПРАВЛЕНО: пример показывает правильную роль
                                Text(
                                  isIPK
                                      ? 'Иван ИПК напоминает сборщикам:\n'
                                      'Заказ "12345" - 3 ИПК-заданий\n'
                                      'Заказ "67890" - 1 ИПК-задание'
                                      : 'Иван ИТР напоминает сборщикам:\n'
                                      'Заказ "12345" - 3 не выполненных заданий (ИПК: 1)\n'
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
                            isIPK
                                ? '📱 Уведомление будет отправлено только о ваших ИПК-заданиях'
                                : '📱 Уведомление будет отправлено на устройства работников',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              fontSize: 12 * scale,
                              color: isIPK ? Colors.red : Colors.red,
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
                                backgroundColor: isIPK ? Colors.red : Colors.red,
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
                              isIPK ? 'Отправка напоминаний ИПК...' : 'Отправка напоминаний...',
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