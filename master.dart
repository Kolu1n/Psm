// master.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MasterS extends StatelessWidget {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ошибка при выходе: $e',
            style: TextStyle(fontFamily: 'GolosR'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔴 НОВЫЙ МЕТОД: Кнопка с заголовком и подписью
  Widget buildMenuButtonWithSubtitle({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onPressed,
    Color textColor = Colors.black,
    Color bgColor = Colors.white,
    Color borderColor = Colors.red,
    required BuildContext context,
  }) {
    final scale = getScaleFactor(context);

    return Container(
      width: double.infinity,
      height: 70 * scale, // Увеличена высота для двух строк
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15 * scale),
          ),
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 20 * scale),
        ),
        child: Row(
          children: [
            // Иконка с фоном
            Container(
              width: 44 * scale,
              height: 44 * scale,
              decoration: BoxDecoration(
                color: borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              child: Icon(icon, size: 24 * scale, color: borderColor),
            ),
            SizedBox(width: 15 * scale),
            // Текстовая часть
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18 * scale, // УВЕЛИЧЕН шрифт заголовка
                      fontFamily: 'GolosB',
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2 * scale),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        fontFamily: 'GolosR',
                        color: textColor.withOpacity(0.6),
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Стрелка вправо
            Icon(
              Icons.arrow_forward_ios,
              size: 18 * scale,
              color: borderColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  // 🔴 Кнопка для "Добавить замечание" и "Отправить пуш" — компактная, без подписи
  Widget buildCompactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color textColor = Colors.black,
    Color bgColor = Colors.white,
    Color borderColor = Colors.red,
    required BuildContext context,
  }) {
    final scale = getScaleFactor(context);

    return Container(
      width: double.infinity,
      height: 55 * scale,
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: BorderSide(color: borderColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15 * scale),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22 * scale, color: textColor),
            SizedBox(width: 10 * scale),
            Text(
              label,
              style: TextStyle(
                fontSize: 16 * scale,
                fontFamily: 'GolosB',
                color: textColor,
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.red),
      ),
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
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 5 * scale,
                  left: 20 * scale,
                  right: 20 * scale,
                  bottom: 5 * scale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50 * scale,
                      height: 50 * scale,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 5 * scale),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/Sett');
                        },
                        icon: Icon(Icons.settings,
                            color: Colors.black,
                            size: 24 * scale
                        ),
                      ),
                    ),
                    Container(
                      width: 185 * scale,
                      height: 50 * scale,
                      child: Image(image: AssetImage('assets/PSM.png')),
                    ),
                    Container(width: 50 * scale),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 25 * scale,
                    right: 25 * scale,
                    top: 45 * scale,
                    bottom: 25 * scale,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 40 * scale),
                        child: Text(
                          'Меню ИТР',
                          style: TextStyle(
                            fontSize: 28 * scale,
                            fontFamily: 'GolosB',
                            color: Colors.black,
                          ),
                        ),
                      ),

                      // 🔴 ОСНОВНЫЕ РАЗДЕЛЫ — с подписями и увеличенным шрифтом
                      buildMenuButtonWithSubtitle(
                        icon: Icons.power_outlined,
                        title: 'Электромонтаж',
                        onPressed: () => Navigator.pushNamed(context, '/Montasch'),
                        context: context,
                      ),
                      buildMenuButtonWithSubtitle(
                        icon: Icons.build_outlined,
                        title: 'Сборка',
                        onPressed: () => Navigator.pushNamed(context, '/Sborka'),
                        context: context,
                      ),
                      buildMenuButtonWithSubtitle(
                        icon: Icons.inventory_2_outlined,
                        title: 'Пакетирование',
                        onPressed: () => Navigator.pushNamed(context, '/Pacet'),
                        context: context,
                      ),

                      // Разделитель
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 15 * scale),
                        child: Divider(
                          color: Colors.grey[300],
                          thickness: 1,
                        ),
                      ),

                      buildCompactButton(
                        icon: Icons.note_alt_outlined,
                        label: 'Добавить замечание',
                        onPressed: () => Navigator.pushNamed(context, '/CreateTask'),
                        textColor: Colors.white,
                        bgColor: Colors.red,
                        borderColor: Colors.red,
                        context: context,
                      ),
                      SizedBox(height: 25 * scale),
                      buildCompactButton(
                        icon: Icons.notifications_active,
                        label: 'Отправить пуш работникам',
                        onPressed: () => Navigator.pushNamed(context, '/SendPushScreen'),
                        textColor: Colors.white,
                        bgColor: Colors.blue,
                        borderColor: Colors.blue,
                        context: context,
                      ),

                      SizedBox(height: 60 * scale),

                      Container(
                        margin: EdgeInsets.only(bottom: 10 * scale),
                        child: Text(
                          'Выйти из аккаунта?',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            fontFamily: 'GolosR',
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Container(
                        width: 150 * scale,
                        height: 40 * scale,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLogoutDialog(context),
                          icon: Icon(Icons.exit_to_app, size: 20 * scale, color: Colors.red),
                          label: Text(
                            'Выйти',
                            style: TextStyle(
                              fontSize: 14 * scale,
                              fontFamily: 'GolosR',
                              color: Colors.red,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 2),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15 * scale),
                            ),
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