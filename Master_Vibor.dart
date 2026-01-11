import 'package:flutter/material.dart';

class Master extends StatelessWidget {
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
        body: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 60 * scale, bottom: 10 * scale),
                  child: Center(
                    child: Container(
                      width: 280 * scale,
                      height: 55 * scale,
                      child: Image(image: AssetImage('assets/PSM.png')),
                    ),
                  ),
                ),
                SizedBox(height: 95 * scale),
                Container(
                  child: Text('Добро', style: TextStyle(fontFamily: 'GolosB', fontSize: 35 * scale)),
                ),
                Container(
                  child: Text('Пожаловать!', style: TextStyle(fontFamily: 'GolosB', fontSize: 35 * scale)),
                ),
                Container(
                  child: Text('Войдите, что бы продолжить',
                      style: TextStyle(fontFamily: 'GolosR', fontSize: 18 * scale)),
                  margin: EdgeInsets.fromLTRB(0, 5 * scale, 0, 50 * scale),
                ),
                Container(
                  width: double.infinity,
                  height: 70 * scale,
                  margin: EdgeInsets.symmetric(horizontal: 20 * scale),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/Whod');
                    },
                    child: Text('Войти',
                      style: TextStyle(fontSize: 27 * scale, fontFamily: 'GolosR', color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 70 * scale,
                  margin: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 20 * scale),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/Reg');
                    },
                    child: Text('Зарегистрироваться',
                      style: TextStyle(fontSize: 23 * scale, fontFamily: 'GolosR', color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red, width: 2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20 * scale),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}