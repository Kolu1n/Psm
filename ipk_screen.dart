import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/custom_snackbar.dart';

class IPKScreen extends StatelessWidget {
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

  Future<void> _logout(BuildContext ctx) async {
    final scale = getScaleFactor(ctx);
    final yes = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
        title: Text('Подтверждение выхода', style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB')),
        content: Text('Вы уверены, что хотите выйти из аккаунта?',
            style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR')),
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
                  onPressed: () => Navigator.pop(ctx, false),
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
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Выйти', style: TextStyle(color: Colors.grey, fontSize: 14 * scale)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (yes != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setInt('userSpecialization', 0);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(ctx, '/MS_W');
  }

  Widget _btn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color txt = Colors.black,
    Color bg = Colors.white,
    required BuildContext context,
  }) {
    final scale = getScaleFactor(context);
    return Container(
      width: double.infinity,
      height: 60 * scale,
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: txt,
          side: BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 40 * scale, child: Icon(icon, size: 24 * scale, color: txt)),
            SizedBox(width: 10 * scale),
            Expanded(
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosB', color: txt)),
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
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: Colors.red)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Color(0xFFFEF2F2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(top: 5 * scale, left: 20 * scale, right: 20 * scale, bottom: 5 * scale),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50 * scale,
                      height: 50 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15 * scale),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10 * scale, offset: Offset(0, 5 * scale))],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/Sett'),
                        icon: Icon(Icons.settings, color: Colors.black, size: 24 * scale),
                      ),
                    ),
                    Container(width: 185 * scale, height: 50 * scale, child: Image(image: AssetImage('assets/PSM.png'))),
                    Container(width: 50 * scale),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(left: 25 * scale, right: 25 * scale, top: 45 * scale, bottom: 25 * scale),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 40 * scale),
                        child: Text('Меню ИПК',
                            style: TextStyle(fontSize: 28 * scale, fontFamily: 'GolosB', color: Colors.black)),
                      ),
                      _btn(icon: Icons.power_outlined, label: 'Заказы: электромонтаж', onTap: () => Navigator.pushNamed(context, '/IPKMontasch'), context: context),
                      _btn(icon: Icons.build_outlined, label: 'Заказы: сборка', onTap: () => Navigator.pushNamed(context, '/IPKSborka'), context: context),
                      _btn(icon: Icons.inventory_2_outlined, label: 'Заказы: пакетирование', onTap: () => Navigator.pushNamed(context, '/IPKPacet'), context: context),
                      _btn(icon: Icons.note_alt_outlined, label: 'Добавить замечание', onTap: () => Navigator.pushNamed(context, '/CreateIPKTask'), bg: Colors.red, txt: Colors.white, context: context),
                      SizedBox(height: 60 * scale),
                      _btn(icon: Icons.notifications_active, label: 'Отправить пуш работникам', onTap: () => Navigator.pushNamed(context, '/SendPushScreen'), bg: Colors.blue, txt: Colors.white, context: context),
                      SizedBox(height: 80 * scale),
                      Text('Выйти из аккаунта?', style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR', color: Colors.grey)),
                      SizedBox(height: 10 * scale),
                      Container(
                        width: 150 * scale,
                        height: 40 * scale,
                        child: OutlinedButton.icon(
                          onPressed: () => _logout(context),
                          icon: Icon(Icons.exit_to_app, size: 20 * scale, color: Colors.red),
                          label: Text('Выйти', style: TextStyle(fontSize: 14 * scale, fontFamily: 'GolosR', color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 2),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 * scale),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}