import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:psm/pages/TasksScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:async/async.dart';

class PacetScreen extends StatefulWidget {
  const PacetScreen({Key? key}) : super(key: key);
  @override
  State<PacetScreen> createState() => _PacetScreenState();
}

class _PacetScreenState extends State<PacetScreen> {
  int? userSpec;
  bool isLoading = true;
  bool _isMenuOpen = false;

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

  Future<void> _confirmDelete(BuildContext context, String docId, bool isIPK) async {
    if (userSpec != 4) return;
    final scale = getScaleFactor(context);

    final orderDoc = await FirebaseFirestore.instance.collection('Pacet').doc(docId).get();
    if (orderDoc.exists) {
      final data = orderDoc.data()!;
      if (data['hasIPKTask'] == true) {
        CustomSnackBar.showWarning(context: context, message: 'Нельзя удалять заказы с ИПК-заданиями');
        return;
      }
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('Удаление заказа', style: TextStyle(fontFamily: 'GolosB', fontSize: 19 * scale)),
        content: Text('Вы уверены, что хотите удалить этот заказ?',
            style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale)),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  child: Text('Отмена', style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 14 * scale)),
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey)),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  child: Text('Да', style: TextStyle(color: Colors.white, fontFamily: 'GolosB', fontSize: 14 * scale)),
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
      await FirebaseFirestore.instance.collection('Pacet').doc(docId).delete();
      CustomSnackBar.showError(context: context, message: 'Заказ удалён');
    }
  }

  Future<void> _logout(BuildContext context) async {
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
                  onPressed: () => Navigator.of(context).pop(),
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
                    Navigator.of(context).pop();
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

  Future<void> _switchSpec(int newSpec, String route) async {
    setState(() => _isMenuOpen = false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userSpecialization', newSpec);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String specText = newSpec == 1 ? 'Сборщик' : 'Монтажник';
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'specialization': newSpec,
        'specializationText': specText,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    Navigator.pushReplacementNamed(context, route);
  }

  Widget _buildLeading(String orderId, bool isIPK) {
    final scale = getScaleFactor(context);
    if (isLoading) {
      return Container(width: 40 * scale, height: 40 * scale, child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (userSpec == 4) {
      return Container(
        width: 40 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10 * scale)),
        child: Center(
          child: IconButton(
            icon: Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20 * scale),
            onPressed: () => _confirmDelete(context, orderId, isIPK),
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

  Widget _buildTitle(BuildContext context) {
    final scale = getScaleFactor(context);

    if (userSpec == 3) {
      return GestureDetector(
        onTap: () => setState(() => _isMenuOpen = !_isMenuOpen),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          padding: EdgeInsets.symmetric(vertical: 8 * scale, horizontal: 12 * scale),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10 * scale),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Заказы Пакетировка',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'GolosB', fontSize: 17 * scale, color: Colors.black)),
              SizedBox(width: 8 * scale),
              AnimatedRotation(
                turns: _isMenuOpen ? 0.5 : 0,
                duration: Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down, color: Colors.red, size: 20 * scale),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.7,
      child: Text('Заказы Пакетировка',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'GolosB', fontSize: 17 * scale, color: Colors.black)),
    );
  }

  // 🔴 НОВЫЙ МЕТОД: Определяем leading для AppBar
  Widget? _buildAppBarLeading(BuildContext context) {
    final scale = getScaleFactor(context);

    // Для ИТР (4) и ИПК (5) показываем стрелку назад
    if (userSpec == 4 || userSpec == 5) {
      return IconButton(
        icon: Icon(Icons.arrow_back_outlined, color: Colors.red, size: 24 * scale),
        onPressed: () => Navigator.of(context).pop(),
      );
    }

    // Для остальных (рабочих) показываем кнопку настроек
    return Container(
      margin: EdgeInsets.only(left: 8 * scale),
      child: Container(
        width: 40 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5 * scale,
              offset: Offset(0, 2 * scale),
            ),
          ],
        ),
        child: IconButton(
          onPressed: () => Navigator.pushNamed(context, '/Sett'),
          icon: Icon(Icons.settings, color: Colors.black, size: 22 * scale),
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
        child: Stack(
          children: [
            Column(
              children: [
                // 🔴 ОБНОВЛЁННЫЙ AppBar с условным leading
                AppBar(
                  title: _buildTitle(context),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: Colors.red, size: 24 * scale),
                  centerTitle: true,
                  // 🔴 Условный leading: стрелка для ИТР/ИПК, настройки для рабочих
                  leading: _buildAppBarLeading(context),
                  actions: [
                    if (userSpec != null && userSpec != 4)
                      Padding(
                        padding: EdgeInsets.only(right: 8.0 * scale),
                        child: IconButton(
                          icon: Icon(Icons.logout, size: 24 * scale),
                          onPressed: () => _logout(context),
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
                        return Center(child: Text('Ошибка загрузки данных', style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale)));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Colors.red));
                      }

                      final allDocs = snapshot.data!.docs;

                      if (allDocs.isEmpty) {
                        return Center(
                          child: Text('Заказов для пакетирования пока нет',
                              style: TextStyle(fontFamily: 'GolosR', fontSize: 16 * scale, color: Colors.grey)),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(15 * scale),
                        itemCount: allDocs.length,
                        itemBuilder: (_, i) {
                          final order = allDocs[i];
                          final data = order.data() as Map<String, dynamic>;
                          final tasks = data['tasks'] as List? ?? [];
                          final bool isIPK = data['hasIPKTask'] == true;

                          return Card(
                            color: isIPK ? Colors.white.withOpacity(0.98) : Colors.white,
                            margin: EdgeInsets.only(bottom: 12 * scale),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                              side: isIPK ? BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                            ),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: EdgeInsets.all(15 * scale),
                              leading: _buildLeading(order.id, isIPK),
                              title: Row(
                                children: [
                                  if (isIPK)
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
                                  if (isIPK) SizedBox(width: 6 * scale),
                                  Expanded(
                                    child: Text(
                                      'Заказ №${data['orderNumber']}',
                                      style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale),
                                    ),
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
                                  'collectionName': 'Pacet',
                                  'screenTitle': isIPK ? 'ИПК Пакетировка' : 'Пакетировка',
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
            if (_isMenuOpen && userSpec == 3)
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top,
                left: 20 * scale,
                right: 20 * scale,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15 * scale),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10 * scale,
                        offset: Offset(0, 5 * scale),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(
                        icon: Icons.build_outlined,
                        title: 'Сборщик',
                        subtitle: 'Сборка изделий',
                        onTap: () => _switchSpec(1, '/Sborka'),
                        scale: scale,
                      ),
                      Divider(height: 1),
                      _buildMenuItem(
                        icon: Icons.power_outlined,
                        title: 'Монтажник',
                        subtitle: 'Электромонтаж',
                        onTap: () => _switchSpec(2, '/Montasch'),
                        scale: scale,
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required double scale,
  }) {
    return ListTile(
      leading: Container(
        width: 40 * scale,
        height: 40 * scale,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10 * scale),
        ),
        child: Icon(icon, color: Colors.red, size: 24 * scale),
      ),
      title: Text(title, style: TextStyle(fontFamily: 'GolosB', fontSize: 16 * scale)),
      subtitle: Text(subtitle, style: TextStyle(fontFamily: 'GolosR', fontSize: 12 * scale, color: Colors.grey)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16 * scale),
      onTap: onTap,
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