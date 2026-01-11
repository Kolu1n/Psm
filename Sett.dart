// Sett.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/pages/Main-S.dart';
import 'package:psm/pages/Whod-Reg.dart';

class Sett extends StatefulWidget {
  @override
  _SettState createState() => _SettState();
}

class _SettState extends State<Sett> {
  int theme = 0;

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
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      theme = prefs.getInt('theme') ?? 0;
    });
  }

  _saveTheme(int newTheme) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      theme = newTheme;
      prefs.setInt('theme', newTheme);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.greenAccent),
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Настройки',
            style: TextStyle(
              fontSize: 20 * scale,
              fontFamily: 'GolosB',
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.red),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
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
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20 * scale),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 80.0 * scale),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 100 * scale,
                          height: 100 * scale,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 250 * scale,
                          height: 50 * scale,
                          child: Image(image: AssetImage('assets/PSM.png')),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30 * scale),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25 * scale),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20 * scale,
                          offset: Offset(0, 10 * scale),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20 * scale),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15 * scale),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Тема приложения',
                                style: TextStyle(
                                  fontSize: 18 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 5 * scale),
                              Text(
                                '(еще в разработке...)',
                                style: TextStyle(
                                  fontSize: 14 * scale,
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 15 * scale),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _saveTheme(0);
                                      Navigator.pushReplacementNamed(context, '/MS_W');
                                    },
                                    child: Container(
                                      width: 120 * scale,
                                      height: 120 * scale,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15 * scale),
                                        border: Border.all(
                                          color: theme == 0 ? Colors.red : Colors.grey.withOpacity(0.3),
                                          width: theme == 0 ? 3 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10 * scale,
                                            offset: Offset(0, 5 * scale),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.light_mode,
                                            size: 40 * scale,
                                            color: Colors.black,
                                          ),
                                          SizedBox(height: 10 * scale),
                                          Text(
                                            'Светлая',
                                            style: TextStyle(
                                              fontSize: 16 * scale,
                                              fontFamily: 'GolosR',
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      _saveTheme(1);
                                      Navigator.pushReplacementNamed(context, '/MS_B');
                                    },
                                    child: Container(
                                      width: 120 * scale,
                                      height: 120 * scale,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(15 * scale),
                                        border: Border.all(
                                          color: theme == 1 ? Colors.red : Colors.grey.withOpacity(0.3),
                                          width: theme == 1 ? 3 : 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10 * scale,
                                            offset: Offset(0, 5 * scale),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.dark_mode,
                                            size: 40 * scale,
                                            color: Colors.white,
                                          ),
                                          SizedBox(height: 10 * scale),
                                          Text(
                                            'Тёмная',
                                            style: TextStyle(
                                              fontSize: 16 * scale,
                                              fontFamily: 'GolosR',
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30 * scale),
                        Container(
                          width: double.infinity,
                          height: 60 * scale,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/Whod');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15 * scale),
                              ),
                              shadowColor: Colors.red.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Выйти из аккаунта',
                                  style: TextStyle(
                                    fontSize: 15 * scale,
                                    fontFamily: 'GolosB',
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10 * scale),
                                Icon(
                                  Icons.logout_rounded,
                                  size: 20 * scale,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 65 * scale),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}