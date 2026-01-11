// specialization_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({Key? key}) : super(key: key);

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final int PasswordSborka = 123456;
  final int PasswordMontazch = 654321;
  final int PasswordPacket = 111222;
  final int PasswordITM = 333444;

  String userName = 'Пользователь';
  String userEmail = '';
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc.data()?['displayName'] ?? 'Пользователь';
            userEmail = userDoc.data()?['email'] ?? user.email ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            userName = user.displayName ?? 'Пользователь';
            userEmail = user.email ?? '';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки данных пользователя: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  int _getSpecializationValue(String specialization) {
    switch (specialization) {
      case 'Сборщик':
        return 1;
      case 'Монтажник':
        return 2;
      case 'Пакетирование':
        return 3;
      case 'ИТМ':
        return 4;
      default:
        return 0;
    }
  }

  int _getSpecializationPassword(String specialization) {
    switch (specialization) {
      case 'Сборщик':
        return PasswordSborka;
      case 'Монтажник':
        return PasswordMontazch;
      case 'Пакетирование':
        return PasswordPacket;
      case 'ИТМ':
        return PasswordITM;
      default:
        return 0;
    }
  }

  void _showPasswordDialog(String specialization, BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    final scale = getScaleFactor(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * scale),
          ),
          child: Container(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Введите код доступа',
                  style: TextStyle(fontSize: 20 * scale, fontFamily: 'GolosB'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 15 * scale),
                Text(
                  'Для специализации "$specialization"',
                  style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR'),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20 * scale),
                TextField(
                  controller: passwordController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: '6-значный код',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10 * scale),
                    ),
                    counterText: '',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 15 * scale,
                      vertical: 12 * scale,
                    ),
                  ),
                  style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosR'),
                  onSubmitted: (_) => _onPasswordSubmit(specialization, ctx, passwordController.text),
                ),
                SizedBox(height: 25 * scale),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Container(
                        height: 45 * scale,
                        margin: EdgeInsets.only(right: 8 * scale),
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10 * scale),
                            ),
                          ),
                          child: Text(
                            'Отмена',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              color: Colors.grey,
                              fontSize: 16 * scale,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 45 * scale,
                        margin: EdgeInsets.only(left: 8 * scale),
                        child: ElevatedButton(
                          onPressed: () =>
                              _onPasswordSubmit(specialization, ctx, passwordController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10 * scale),
                            ),
                          ),
                          child: Text(
                            'Вход',
                            style: TextStyle(
                              fontFamily: 'GolosR',
                              color: Colors.white,
                              fontSize: 16 * scale,
                            ),
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
      },
    );
  }

  void _onPasswordSubmit(
      String specialization, BuildContext dialogContext, String rawCode) {
    final String enteredCode = rawCode.trim();
    final String expected = _getSpecializationPassword(specialization).toString();

    if (enteredCode == expected && expected != '0') {
      Navigator.of(dialogContext).pop();
      _processSpecialization(specialization, context);
    } else {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        SnackBar(
          content: Text('Неверный код доступа'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processSpecialization(String specialization, BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Пользователь не авторизован')),
        );
        return;
      }

      final int specValue = _getSpecializationValue(specialization);
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        await userDoc.set({
          'displayName': userName,
          'email': userEmail,
          'specialization': specValue,
          'specializationText': specialization,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await userDoc.set({
          'uid': user.uid,
          'displayName': userName,
          'email': userEmail,
          'specialization': specValue,
          'specializationText': specialization,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Сохраняем специализацию пользователя
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userSpecialization', specValue);

      if (!mounted) return;
      _navigateBySpecialization(specialization, context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e')),
      );
    }
  }

  void _navigateBySpecialization(String specialization, BuildContext context) {
    switch (specialization) {
      case 'Сборщик':
        Navigator.pushReplacementNamed(context, '/Sborka');
        break;
      case 'Монтажник':
        Navigator.pushReplacementNamed(context, '/Montasch');
        break;
      case 'Пакетирование':
        Navigator.pushReplacementNamed(context, '/Pacet');
        break;
      case 'ИТМ':
        Navigator.pushReplacementNamed(context, '/MasterScreen');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/master');
    }
  }

  void _onSpecializationPressed(String specialization, BuildContext context) {
    _showPasswordDialog(specialization, context);
  }

  Widget _buildSpecializationButton(String specialization, BuildContext context) {
    final scale = getScaleFactor(context);

    return Container(
      width: double.infinity,
      height: 55 * scale,
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: ElevatedButton(
        onPressed: () => _onSpecializationPressed(specialization, context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
          elevation: 4,
        ),
        child: Text(
          specialization,
          style: TextStyle(
            fontSize: 18 * scale,
            fontFamily: 'GolosB',
            color: Colors.red,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 85 * scale),
                  child: Image.asset(
                    'assets/PSM.png',
                    width: 250 * scale,
                    height: 50 * scale,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.business_center, size: 50 * scale, color: Colors.red);
                    },
                  ),
                ),
                isLoading
                    ? CircularProgressIndicator()
                    : Column(
                  children: [
                    Text(
                      'Добро пожаловать, $userName!',
                      style: TextStyle(
                        fontSize: 22 * scale,
                        fontFamily: 'GolosB',
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15 * scale),
                    Text(
                      'Выберите вашу специализацию:',
                      style: TextStyle(
                        fontSize: 16 * scale,
                        fontFamily: 'GolosR',
                        color: Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                SizedBox(height: 40 * scale),
                _buildSpecializationButton('Сборщик', context),
                _buildSpecializationButton('Монтажник', context),
                _buildSpecializationButton('Пакетирование', context),
                _buildSpecializationButton('ИТМ', context),
                SizedBox(height: 30 * scale),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30 * scale),

                ),
                SizedBox(height: 20 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}