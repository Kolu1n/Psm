// Whod-Reg.dart
import 'package:email_validator/Email_validator.dart';
import 'package:flutter/material.dart';
import 'package:psm/pages/Sett.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

TextEditingController emailController = TextEditingController();
TextEditingController passwordController = TextEditingController();
final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

class Whod extends StatefulWidget {
  @override
  _WhodState createState() => _WhodState();
}

class _WhodState extends State<Whod> {
  int theme = 0;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

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
      navigatorKey: _navigatorKey,
      theme: ThemeData(primaryColor: Colors.greenAccent),
      home: ScaffoldMessenger(
        key: _scaffoldKey,
        child: Scaffold(
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
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 50.0 * scale, top: 1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120 * scale,
                            height: 120 * scale,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 280 * scale,
                            height: 55 * scale,
                            child: Image(image: AssetImage('assets/PSM.png')),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(bottom: 40.0 * scale),
                      child: Column(
                        children: [
                          Text(
                            'Вход в систему',
                            style: TextStyle(
                              fontSize: 32 * scale,
                              fontFamily: 'GolosB',
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          Text(
                            'Введите ваши данные для входа',
                            style: TextStyle(
                              fontSize: 16 * scale,
                              fontFamily: 'GolosR',
                              color: Colors.grey[600],
                            ),
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
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15 * scale),
                              color: Colors.grey[50],
                            ),
                            child: TextFormField(
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (email) =>
                              email != null && !EmailValidator.validate(email)
                                  ? 'Введите верную почту'
                                  : null,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Электронная почта...',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20 * scale,
                                    vertical: 18 * scale
                                ),
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.grey[500],
                                  size: 24 * scale,
                                ),
                                hintStyle: TextStyle(
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[500],
                                  fontSize: 16 * scale,
                                ),
                              ),
                              controller: emailController,
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15 * scale),
                              color: Colors.grey[50],
                            ),
                            child: TextFormField(
                              autocorrect: false,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (password) =>
                              password != null && password.length < 6
                                  ? 'Минимум 6 символов'
                                  : null,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Пароль...',
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20 * scale,
                                    vertical: 18 * scale
                                ),
                                prefixIcon: Icon(
                                  Icons.lock_outline,
                                  color: Colors.grey[500],
                                  size: 24 * scale,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.grey[500],
                                    size: 24 * scale,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                hintStyle: TextStyle(
                                  fontFamily: 'GolosR',
                                  color: Colors.grey[500],
                                  fontSize: 16 * scale,
                                ),
                              ),
                              controller: passwordController,
                            ),
                          ),
                          SizedBox(height: 30 * scale),
                          Container(
                            width: double.infinity,
                            height: 60 * scale,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => login(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15 * scale),
                                ),
                                shadowColor: Colors.red.withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                width: 20 * scale,
                                height: 20 * scale,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Войти в систему',
                                    style: TextStyle(
                                      fontSize: 18 * scale,
                                      fontFamily: 'GolosB',
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10 * scale),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20 * scale,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          Container(
                            width: double.infinity,
                            height: 55 * scale,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () {
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
                                    Icons.person_add_alt_1_outlined,
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
                    Container(
                      width: 160 * scale,
                      height: 50 * scale,
                      child: OutlinedButton(
                        onPressed: () {
                          if (theme == 0)
                            Navigator.pushReplacementNamed(context, '/MS_W');
                          else
                            Navigator.pushReplacementNamed(context, '/MS_B');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12 * scale),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back_rounded,
                              size: 18 * scale,
                            ),
                            SizedBox(width: 8 * scale),
                            Text(
                              'Назад',
                              style: TextStyle(
                                fontSize: 15 * scale,
                                fontFamily: 'GolosR',
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30 * scale),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> login(BuildContext context) async {
  String emailText = emailController.text.trim();
  String passwordText = passwordController.text.trim();

  _WhodState state = _scaffoldKey.currentContext!.findAncestorStateOfType<_WhodState>()!;
  state.setState(() {
    state._isLoading = true;
  });

  if (!EmailValidator.validate(emailText) || passwordText.length < 6) {
    CustomSnackBar.showError(
      context: context,
      message: 'Проверьте правильность введенных данных',
    );
    state.setState(() {
      state._isLoading = false;
    });
    return;
  }

  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailText,
      password: passwordText,
    );

    // Сохраняем состояние авторизации
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);

    await _checkUserSpecialization(context);

  } on FirebaseAuthException catch (e) {
    print(e.code);

    String errorMessage;
    if (e.code == 'user-not-found' || e.code == 'wrong-password') {
      errorMessage = 'Неправильный email или пароль. Повторите попытку';
    } else if (e.code == 'user-disabled') {
      errorMessage = 'Аккаунт отключен. Обратитесь в поддержку.';
    } else if (e.code == 'invalid-email') {
      errorMessage = 'Неверный формат email адреса.';
    } else {
      errorMessage = 'Неизвестная ошибка! Попробуйте еще раз или обратитесь в поддержку.';
    }

    CustomSnackBar.showError(
      context: context,
      message: errorMessage,
    );
  } catch (e) {
    CustomSnackBar.showError(
      context: context,
      message: 'Произошла ошибка. Попробуйте еще раз.',
    );
  } finally {
    state.setState(() {
      state._isLoading = false;
    });
  }
}

Future<void> _checkUserSpecialization(BuildContext context) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final specialization = userData?['specialization'] ?? 0;

        // Сохраняем специализацию пользователя
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userSpecialization', specialization);

        switch (specialization) {
          case 4:
            Navigator.of(context).pushReplacementNamed('/MasterScreen');
            break;
          case 1:
            Navigator.of(context).pushReplacementNamed('/Sborka');
            break;
          case 2:
            Navigator.of(context).pushReplacementNamed('/Montasch');
            break;
          case 3:
            Navigator.of(context).pushReplacementNamed('/Pacet');
            break;
          default:
            Navigator.of(context).pushReplacementNamed('/specialization');
            break;
        }
      } else {
        Navigator.of(context).pushReplacementNamed('/specialization');
      }
    }
  } catch (e) {
    print('Ошибка при проверке специализации: $e');
    Navigator.of(context).pushReplacementNamed('/MS_W');
  }
}