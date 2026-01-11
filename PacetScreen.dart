// PacetScreen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psm/pages/TasksScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/custom_snackbar.dart';

class PacetScreen extends StatefulWidget {
  const PacetScreen({Key? key}) : super(key: key);

  @override
  State<PacetScreen> createState() => _PacetScreenState();
}

class _PacetScreenState extends State<PacetScreen> {
  int? userSpecialization;
  bool isLoading = true;

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
  }

  Future<void> _loadUserSpecialization() async {
    try {
      // Сначала пробуем загрузить из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedSpecialization = prefs.getInt('userSpecialization');

      if (savedSpecialization != null && savedSpecialization != 0) {
        setState(() {
          userSpecialization = savedSpecialization;
          isLoading = false;
        });
        return;
      }

      // Если в SharedPreferences нет, загружаем из Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final spec = userDoc.data()?['specialization'] ?? 0;
          setState(() {
            userSpecialization = spec;
            isLoading = false;
          });

          // Сохраняем в SharedPreferences для будущих запусков
          await prefs.setInt('userSpecialization', spec);
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки специализации: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(BuildContext context, String docId) async {
    if (userSpecialization != 4) return;

    final scale = getScaleFactor(context);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15 * scale),
        ),
        title: Text(
          'Удаление заказа',
          style: TextStyle(fontFamily: 'GolosB', fontSize: 19 * scale),
        ),
        content: Text(
          'Вы уверены, что хотите удалить этот заказ?',
          style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(right: 8 * scale),
                  child: OutlinedButton(
                    child: Text(
                      'Отмена',
                      style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 14 * scale),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(left: 8 * scale),
                  child: ElevatedButton(
                    child: Text(
                      'Да',
                      style: TextStyle(color: Colors.white, fontFamily: 'GolosB', fontSize: 14 * scale),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await FirebaseFirestore.instance.collection('Pacet').doc(docId).delete();
      CustomSnackBar.showError(
        context: context,
        message: 'Заказ удалён',
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final scale = getScaleFactor(context);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          title: Text(
            'Подтверждение выхода',
            style: TextStyle(
              fontSize: 18 * scale,
              fontFamily: 'GolosB',
              color: Colors.black,
            ),
          ),
          content: Text(
            'Вы уверены, что хотите выйти из аккаунта?',
            style: TextStyle(
              fontSize: 14 * scale,
              fontFamily: 'GolosR',
              color: Colors.black54,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    height: 40 * scale,
                    margin: EdgeInsets.only(right: 8 * scale),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red, width: 2),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 40 * scale,
                    margin: EdgeInsets.only(left: 8 * scale),
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _signOut(context);
                      },
                      child: Text(
                        'Выйти',
                        style: TextStyle(
                          fontSize: 14 * scale,
                          fontFamily: 'GolosR',
                          color: Colors.grey,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey, width: 2),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Очищаем сохраненные данные
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.setInt('userSpecialization', 0);

      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/MS_W');
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Ошибка при выходе: $e',
      );
    }
  }

  Widget _buildLeadingWidget(String orderId, BuildContext context) {
    final scale = getScaleFactor(context);

    if (isLoading) {
      return Container(
        width: 40 * scale,
        height: 40 * scale,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (userSpecialization == 4) {
      return Container(
        width: 40 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: IconButton(
          icon: Icon(Icons.delete_forever_rounded,
              color: Colors.white,
              size: 20 * scale
          ),
          onPressed: () => _confirmDelete(context, orderId),
        ),
      );
    }

    return Container(
      width: 40 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10 * scale),
      ),
      child: Center(
        child: Icon(
          Icons.assignment,
          color: Colors.white,
          size: 20 * scale,
        ),
      ),
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
              colors: [
                Colors.white,
                Colors.white,
                Color(0xFFFEF2F2),
              ],
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
                  'Заказы Пакетировка',
                  style: TextStyle(
                    fontFamily: 'GolosB',
                    fontSize: 18 * scale,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.red, size: 24 * scale),
              centerTitle: true,
              actions: [
                // Показываем кнопку выхода только для специализаций 1, 2, 3 (не ИТМ)
                if (userSpecialization != null && userSpecialization != 4)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0 * scale),
                    child: IconButton(
                      icon: Icon(Icons.logout, size: 24 * scale),
                      onPressed: () => _showLogoutDialog(context),
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Pacet')
                    .orderBy('orderNumber')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Ошибка загрузки данных',
                        style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.red));
                  }

                  final orders = snapshot.data!.docs;

                  if (orders.isEmpty) {
                    return Center(
                      child: Text(
                        'Заказов для пакетировки пока нет',
                        style: TextStyle(
                          fontFamily: 'GolosR',
                          fontSize: 16 * scale,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(15 * scale),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final orderData = order.data() as Map<String, dynamic>;
                      final tasks = orderData['tasks'] as List? ?? [];

                      return Card(
                        margin: EdgeInsets.only(bottom: 12 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15 * scale),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15 * scale),
                          leading: _buildLeadingWidget(order.id, context),
                          title: Text(
                            'Заказ №${orderData['orderNumber']}',
                            style: TextStyle(
                              fontFamily: 'GolosB',
                              fontSize: 16 * scale,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4 * scale),
                              Text(
                                'Заданий: ${tasks.length}',
                                style: TextStyle(
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[600],
                                  fontSize: 14 * scale,
                                ),
                              ),
                              if (orderData['createdAt'] != null)
                                SizedBox(height: 4 * scale),
                              if (orderData['createdAt'] != null)
                                Text(
                                  'Создан: ${_formatDate(orderData['createdAt'])}',
                                  style: TextStyle(
                                    fontFamily: 'GolosR',
                                    fontSize: 12 * scale,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.red,
                              size: 16 * scale
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/Tasks',
                              arguments: {
                                'orderNumber': orderData['orderNumber'],
                                'collectionName': 'Pacet',
                                'screenTitle': 'Пакетировка',
                              },
                            );
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}