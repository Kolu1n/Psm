import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psm/pages/TasksScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/custom_snackbar.dart';

class IPKPacetScreen extends StatefulWidget {
  const IPKPacetScreen({Key? key}) : super(key: key);
  @override
  State<IPKPacetScreen> createState() => _IPKPacetScreenState();
}

class _IPKPacetScreenState extends State<IPKPacetScreen> {
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
        content: Text('Вы уверены, что хотите удалить этот заказ?',
            style: TextStyle(fontFamily: 'GolosR')),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(right: 8 * scale),
                  child: OutlinedButton(
                    child: Text('Отмена', style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 14 * scale)),
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(left: 8 * scale),
                  child: ElevatedButton(
                    child: Text('Да', style: TextStyle(color: Colors.white, fontFamily: 'GolosB', fontSize: 14 * scale)),
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes == true) {
      await FirebaseFirestore.instance.collection('IPKPacet').doc(docId).delete();
      CustomSnackBar.showError(context: context, message: 'Заказ удалён');
    }
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(right: 8 * scale),
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
              ),
              Expanded(
                child: Container(
                  height: 40 * scale,
                  margin: EdgeInsets.only(left: 8 * scale),
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
            icon: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20 * scale),
            onPressed: () => _confirmDelete(orderId),
          ),
        ),
      );
    }
    return Container(
      width: 40 * scale,
      height: 40 * scale,
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10 * scale)),
      child: Center(child: Icon(Icons.assignment, color: Colors.white, size: 20 * scale)),
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
                child: Text('Заказы ИПК Пакетировка',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'GolosB', fontSize: 18 * scale, color: Colors.black)),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.red, size: 24 * scale),
              centerTitle: true,
              actions: [
                if (userSpec != null && userSpec != 5)
                  Padding(
                    padding: EdgeInsets.only(right: 8.0 * scale),
                    child: IconButton(
                      icon: Icon(Icons.logout, size: 24 * scale),
                      onPressed: _logout,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('IPKPacet').orderBy('orderNumber').snapshots(),
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
                      child: Text('Заказов для пакетировки пока нет',
                          style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale, color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.all(15 * scale),
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final order = orders[i];
                      final data = order.data() as Map<String, dynamic>;
                      final tasks = data['tasks'] as List? ?? [];
                      final bool hasIPKTask = tasks.any((t) => t['isIPK'] == true);

                      return Card(
                        color: Colors.white.withOpacity(0.98),
                        margin: EdgeInsets.only(bottom: 12 * scale),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15 * scale),
                          side: hasIPKTask ? BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: EdgeInsets.all(15 * scale),
                          leading: _leading(order.id),
                          title: Row(
                            children: [
                              if (hasIPKTask)
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
                              if (hasIPKTask) SizedBox(width: 6 * scale),
                              Expanded(
                                child: Text('Заказ №${data['orderNumber']}',
                                    style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale)),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4 * scale),
                              Text('Заданий: ${tasks.length}',
                                  style: TextStyle(fontFamily: 'GolosR', color: Colors.black, fontSize: 14 * scale)),
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
                              'collectionName': 'IPKPacet',
                              'screenTitle': 'ИПК Пакетировка',
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