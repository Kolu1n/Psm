import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psm/pages/TasksScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/custom_snackbar.dart';

class IPKMontaschScreen extends StatefulWidget {
  const IPKMontaschScreen({Key? key}) : super(key: key);
  @override
  State<IPKMontaschScreen> createState() => _IPKMontaschScreenState();
}

class _IPKMontaschScreenState extends State<IPKMontaschScreen> {
  int? userSpec;
  bool isLoading = true;

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
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('userSpecialization');
    if (saved != null && saved != 0) {
      setState(() {
        userSpec = saved;
        isLoading = false;
      });
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final s = doc.data()?['specialization'] ?? 0;
        setState(() {
          userSpec = s;
          isLoading = false;
        });
        await prefs.setInt('userSpecialization', s);
      } else {
        setState(() => isLoading = false);
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmDelete(String docId) async {
    if (userSpec != 5) return;
    final scale = getScaleFactor(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Удаление заказа', style: TextStyle(fontFamily: 'GolosB', fontSize: 19)),
        content: Text('Вы уверены, что хотите удалить ИПК-задания из этого заказа?',
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
              SizedBox(width: 8),
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
    if (yes == true) {
      // 🔴 ИЗМЕНЕНО: Удаляем только ИПК-задания, оставляем задания ИТР
      final orderDoc = FirebaseFirestore.instance.collection('Montasch').doc(docId);
      final orderSnapshot = await orderDoc.get();

      if (orderSnapshot.exists) {
        final data = orderSnapshot.data()!;
        final tasks = data['tasks'] as List? ?? [];

        // Оставляем только задания ИТР (не ИПК)
        final nonIPKTasks = tasks.where((task) => task['isIPK'] != true).toList();

        if (nonIPKTasks.isEmpty) {
          // Если заданий ИТР не осталось, удаляем весь заказ
          await orderDoc.delete();
          CustomSnackBar.showSuccess(context: context, message: 'Заказ полностью удалён');
        } else {
          // Иначе обновляем заказ с заданиями ИТР
          for (int i = 0; i < nonIPKTasks.length; i++) {
            nonIPKTasks[i]['taskNumber'] = i + 1;
          }
          await orderDoc.update({
            'tasks': nonIPKTasks,
            'hasIPKTask': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
          CustomSnackBar.showSuccess(context: context, message: 'ИПК-задания удалены');
        }
      }

      // 🔴 ДОБАВЛЕНО: Автоматический выход
      Navigator.of(context).pop();
    }  }

  Future<void> _logout() async {
    final scale = getScaleFactor(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
        title: Text('Подтверждение выхода',
            style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.black)),
        content: Text('Вы уверены, что хотите выйти из аккаунта?',
            style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR', color: Colors.black54)),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red, width: 2),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Отмена', style: TextStyle(color: Colors.white, fontSize: 14 * scale)),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey, width: 2),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _doLogout();
                  },
                  child: Text('Выйти', style: TextStyle(color: Colors.grey, fontSize: 14 * scale)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) _doLogout();
  }

  Future<void> _doLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setInt('userSpecialization', 0);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/MS_W');
  }

  Widget _leading(String orderId) {
    final scale = getScaleFactor(context);
    if (isLoading) {
      return Container(width: 40 * scale, height: 40 * scale, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (userSpec == 5) {
      return Container(
        width: 40 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10 * scale)),
        child: Center(
          child: IconButton(
            icon: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 22 * scale),
            onPressed: () => _confirmDelete(orderId),
          ),
        ),
      );
    }
    return Container(
      width: 40 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10 * scale)),
      child: Center(child: Icon(Icons.assignment, color: Colors.white, size: 22 * scale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
    if (isLoading) {
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
          child: Center(child: CircularProgressIndicator(color: Colors.red)),
        ),
      );
    }
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
                child: Text('Заказы ИПК Монтаж',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GolosB', fontSize: 18 * scale, color: Colors.black)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.red),
              centerTitle: true,
              actions: [
                if (userSpec != null && userSpec != 5)
                  IconButton(
                    icon: Icon(Icons.logout, size: 24 * scale, color: Colors.red),
                    onPressed: _logout,
                  ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // 🔴 ИЗМЕНЕНО: Читаем из основной коллекции, фильтруя по hasIPKTask
                stream: FirebaseFirestore.instance
                    .collection('Montasch')
                    .where('hasIPKTask', isEqualTo: true)
                    .orderBy('orderNumber')
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Ошибка загрузки данных', style: TextStyle(fontFamily: 'GolosR')));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.red));
                  }
                  final orders = snap.data!.docs;
                  if (orders.isEmpty) {
                    return Center(
                      child: Text('Заказов для монтажа пока нет',
                          style: TextStyle(fontFamily: 'GolosR', fontSize: 18 * scale, color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(20 * scale),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      final data = order.data() as Map<String, dynamic>;
                      final tasks = data['tasks'] as List? ?? [];

                      // ✅ ФИЛЬТРАЦИЯ: Считаем только ИПК-задания
                      final ipkTasks = tasks.where((t) => t['isIPK'] == true).toList();
                      final int taskCount = ipkTasks.length; // Используем отфильтрованное количество

                      return Card(
                        color: Colors.white.withOpacity(0.98),
                        margin: EdgeInsets.only(bottom: 15 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15 * scale),
                          side: BorderSide(color: Colors.red, width: 2), // Всегда красная рамка для ИПК
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15 * scale),
                          leading: _leading(order.id),
                          title: Row(
                            children: [
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
                              SizedBox(width: 6 * scale),
                              Expanded(
                                child: Text('Заказ №${data['orderNumber']}',
                                    style: TextStyle(fontFamily: 'GolosB', fontSize: 18 * scale, color: Colors.black87)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 8 * scale),
                              // ✅ ИЗМЕНЕНО: показываем количество ИПК-заданий
                              Text('Заданий: $taskCount',
                                  style: TextStyle(fontFamily: 'GolosR', color: Colors.grey[600], fontSize: 14 * scale)),
                              if (data['createdAt'] != null) ...[
                                SizedBox(height: 4 * scale),
                                Text('Создан: ${_formatDate(data['createdAt'])}',
                                    style: TextStyle(fontFamily: 'GolosR', fontSize: 12 * scale, color: Colors.grey)),
                              ],
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16 * scale),
                          onTap: () {
                            Navigator.pushNamed(context, '/Tasks', arguments: {
                              'orderNumber': data['orderNumber'],
                              'collectionName': 'Montasch',
                              'screenTitle': 'ИПК Монтаж',
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}.${dt.month}.${dt.year}';
    } catch (_) {
      return d;
    }
  }
}