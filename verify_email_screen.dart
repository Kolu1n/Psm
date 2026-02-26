// verify_email_screen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:psm/pages/Main-S.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = true;
  bool isLoading = false;
  Timer? timer;

  double getScaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final diagonal = MediaQuery.of(context).size.shortestSide;

    if (diagonal < 350) return 0.7;
    if (diagonal < 400) return 0.8;
    if (diagonal < 500) return 0.9;
    return 1.0;
  }

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isEmailVerified = user.emailVerified;

      if (!isEmailVerified) {
        timer = Timer.periodic(
          const Duration(seconds: 3),
              (_) => checkEmailVerified(),
        );
      }
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/Whod');
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    try {
      await FirebaseAuth.instance.currentUser!.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        setState(() {
          isEmailVerified = user.emailVerified;
        });

        if (isEmailVerified) {
          timer?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/specialization');
          });
        }
      }
    } catch (e) {
      print('Ошибка при проверке email: $e');
    }
  }

  Future<void> sendVerificationEmail() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      canResendEmail = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
        CustomSnackBar.showSuccess(
          context: context,
          message: 'Письмо для подтверждения отправлено!',
        );
      }
    } catch (e) {
      print('Ошибка при отправке email: $e');
      CustomSnackBar.showError(
        context: context,
        message: 'Не удалось отправить письмо для подтверждения. Попробуйте позже.',
      );
    } finally {
      Future.delayed(const Duration(seconds: 60), () {
        if (mounted) {
          setState(() {
            canResendEmail = true;
            isLoading = false;
          });
        }
      });
    }
  }

  Future<void> _cancelRegistration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
      }
      Navigator.of(context).pushReplacementNamed('/Whod');
    } catch (e) {
      print('Ошибка при отмене регистрации: $e');
      CustomSnackBar.showError(
        context: context,
        message: 'Не удалось отменить регистрацию. Попробуйте войти в систему или обратитесь к администратору для удаления аккаунт вручную.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    if (isEmailVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/specialization');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,

      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                size: 80 * scale,
                color: Colors.blue,
              ),
              SizedBox(height: 20 * scale),
              Text(
                'Подтвердите ваш email',
                style: TextStyle(
                    fontSize: 22 * scale,
                    fontFamily: 'GolosB'
                ),
              ),
              SizedBox(height: 20 * scale),
              Text(
                'Мы отправили письмо с подтверждением на вашу электронную почту. Пожалуйста, проверьте вашу почту и перейдите по ссылке в письме.',
                style: TextStyle(
                    fontSize: 16 * scale,
                    fontFamily: 'GolosR'
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 17 * scale),
              Text('(В случает отсутсвия письма, проверьте спам)',
                  style: TextStyle(
                  fontSize: 11 * scale,
                  fontFamily: 'GolosR'
              ),
          textAlign: TextAlign.center,),
              SizedBox(height: 30 * scale),
              OutlinedButton.icon(
                onPressed: canResendEmail && !isLoading ? sendVerificationEmail : null,
                icon: isLoading
                    ? CircularProgressIndicator(
                    color: Colors.grey,
                    strokeWidth: 2
                )
                    : Icon(Icons.email,
                    color: Colors.blue,
                    size: 20 * scale
                ),
                label: isLoading
                    ? Text(
                  '  Отправка...',
                  style: TextStyle(
                    fontFamily: 'GolosR',
                    color: Colors.black,
                    fontSize: 16 * scale,
                  ),
                )
                    : Text(
                  'Отправить письмо повторно',
                  style: TextStyle(
                    fontFamily: 'GolosR',
                    color: Colors.black,
                    fontSize: 13 * scale,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  fixedSize: Size(320 * scale, 60 * scale),
                  side: BorderSide(color: Colors.black, width: 2),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20 * scale),
                  ),
                ),
              ),
              SizedBox(height: 20 * scale),
              if (!canResendEmail)
                Text(
                  'Повторная отправка будет доступна через 60 секунд',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14 * scale,
                  ),
                ),
              SizedBox(height: 10 * scale),
              TextButton(
                onPressed: _cancelRegistration,
                child: Text(
                  'Отменить регистрацию',
                  style: TextStyle(
                    fontSize: 16 * scale,
                    color: Colors.red,
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