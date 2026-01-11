// Main-S.dart
import 'package:flutter/material.dart';
import 'package:psm/main.dart';

class MainS_W extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.greenAccent),
      home: Scaffold(
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
              Container(
                padding: EdgeInsets.only(
                  top: 60 * scale,
                  left: 20 * scale,
                  right: 20 * scale,
                  bottom: 20 * scale,
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
                          Navigator.pushReplacementNamed(context, '/Sett');
                        },
                        icon: Icon(Icons.settings,
                            color: Colors.black,
                            size: 24 * scale
                        ),
                      ),
                    ),
                    Container(
                      width: 190 * scale,
                      height: 50 * scale,
                      child: Image(image: AssetImage('assets/PSM.png')),
                    ),
                    Container(width: 50 * scale),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20 * scale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 60 * scale),
                          child: Column(
                            children: [
                              Text(
                                'Добро пожаловать!',
                                style: TextStyle(
                                  fontSize: 36 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.black,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 15 * scale),
                              Text(
                                'Войдите в систему для продолжения работы',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
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
                                height: 60 * scale,
                                margin: EdgeInsets.only(bottom: 20 * scale),
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
                                      Icon(
                                        Icons.login_rounded,
                                        size: 22 * scale,
                                      ),
                                      SizedBox(width: 12 * scale),
                                      Text(
                                        'Войти в аккаунт',
                                        style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontFamily: 'GolosB',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 55 * scale,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/Reg');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15 * scale),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 20 * scale,
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Text(
                                        'Создать аккаунт',
                                        style: TextStyle(
                                          fontSize: 16 * scale,
                                          fontFamily: 'GolosB',
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40 * scale),
                      ],
                    ),
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

class MainS_B extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.greenAccent),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.black,
                Color(0xFF1a1a1a),
              ],
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 60 * scale,
                  left: 20 * scale,
                  right: 20 * scale,
                  bottom: 20 * scale,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50 * scale,
                      height: 50 * scale,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(15 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10 * scale,
                            offset: Offset(0, 5 * scale),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/Sett');
                        },
                        icon: Icon(Icons.settings,
                            color: Colors.white,
                            size: 24 * scale
                        ),
                      ),
                    ),
                    Container(
                      width: 180 * scale,
                      height: 45 * scale,
                      child: Image(image: AssetImage('assets/PSM-B.png')),
                    ),
                    Container(width: 50 * scale),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20 * scale),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 60 * scale),
                          child: Column(
                            children: [
                              Text(
                                'Добро пожаловать!',
                                style: TextStyle(
                                  fontSize: 36 * scale,
                                  fontFamily: 'GolosB',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 15 * scale),
                              Text(
                                'Войдите в систему для продолжения работы',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[400],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(30 * scale),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(25 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20 * scale,
                                offset: Offset(0, 10 * scale),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey[800]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 60 * scale,
                                margin: EdgeInsets.only(bottom: 20 * scale),
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
                                      Icon(
                                        Icons.login_rounded,
                                        size: 22 * scale,
                                      ),
                                      SizedBox(width: 12 * scale),
                                      Text(
                                        'Войти в аккаунт',
                                        style: TextStyle(
                                          fontSize: 18 * scale,
                                          fontFamily: 'GolosB',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: 55 * scale,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(context, '/Reg');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: BorderSide(
                                      color: Colors.red,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15 * scale),
                                    ),
                                    backgroundColor: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_rounded,
                                        size: 20 * scale,
                                      ),
                                      SizedBox(width: 10 * scale),
                                      Text(
                                        'Создать аккаунт',
                                        style: TextStyle(
                                          fontSize: 16 * scale,
                                          fontFamily: 'GolosB',
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40 * scale),
                      ],
                    ),
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