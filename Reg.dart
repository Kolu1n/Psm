// Reg.dart
import 'package:email_validator/Email_validator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';

class Reg extends StatefulWidget {
  @override
  _Reg createState() => _Reg();
}

class _Reg extends State<Reg> {
  bool isHiddenPassword = true;
  bool isLoading = false;
  TextEditingController usernameTextInputController = TextEditingController();
  TextEditingController emailTextInputController = TextEditingController();
  TextEditingController passwordTextInputController = TextEditingController();
  TextEditingController passwordTextRepeatInputController = TextEditingController();
  final formKey = GlobalKey<FormState>();

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
  void dispose() {
    usernameTextInputController.dispose();
    emailTextInputController.dispose();
    passwordTextInputController.dispose();
    passwordTextRepeatInputController.dispose();
    super.dispose();
  }

  void togglePasswordView() {
    setState(() {
      isHiddenPassword = !isHiddenPassword;
    });
  }

  Future<void> signUp() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final navigator = Navigator.of(context);

    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (passwordTextInputController.text != passwordTextRepeatInputController.text) {
      CustomSnackBar.showError(
        context: context,
        message: 'Пароли должны совпадать',
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextInputController.text.trim(),
        password: passwordTextInputController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(usernameTextInputController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'displayName': usernameTextInputController.text.trim(),
        'email': emailTextInputController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      await userCredential.user!.sendEmailVerification();

      navigator.pushReplacementNamed('/VerifyEmail');

    } on FirebaseAuthException catch (e) {
      print(e.code);

      if (e.code == 'email-already-in-use') {
        CustomSnackBar.showError(
          context: context,
          message: 'Такой Email уже используется, повторите попытку с использованием другого Email',
        );
      } else if (e.code == 'weak-password') {
        CustomSnackBar.showError(
          context: context,
          message: 'Пароль слишком слабый. Используйте более сложный пароль.',
        );
      } else if (e.code == 'invalid-email') {
        CustomSnackBar.showError(
          context: context,
          message: 'Неверный формат email адреса.',
        );
      } else {
        CustomSnackBar.showError(
          context: context,
          message: 'Ошибка регистрации: ${e.message}',
        );
      }
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Неизвестная ошибка! Попробуйте еще раз или обратитесь в поддержку.',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);

    return Scaffold(
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
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 40.0 * scale),
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
                  margin: EdgeInsets.only(bottom: 40.0 * scale),
                  child: Column(
                    children: [
                      Text(
                        'Создание аккаунта',
                        style: TextStyle(
                          fontSize: 27 * scale,
                          fontFamily: 'GolosB',
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8 * scale),
                      Text(
                        'Заполните данные для регистрации',
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
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15 * scale),
                            color: Colors.grey[50],
                          ),
                          child: TextFormField(
                            controller: usernameTextInputController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите имя пользователя';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Имя Фамилия...',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20 * scale,
                                  vertical: 18 * scale
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[500],
                                size: 24 * scale,
                              ),
                              hintStyle: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey[500],
                                fontSize: 16 * scale,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20 * scale),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15 * scale),
                            color: Colors.grey[50],
                          ),
                          child: TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            controller: emailTextInputController,
                            validator: (email) =>
                            email != null && !EmailValidator.validate(email)
                                ? 'Введите правильный Email'
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
                            controller: passwordTextInputController,
                            obscureText: isHiddenPassword,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) =>
                            value != null && value.length < 6
                                ? 'Минимум 6 символов'
                                : null,
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
                                  isHiddenPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[500],
                                  size: 24 * scale,
                                ),
                                onPressed: togglePasswordView,
                              ),
                              hintStyle: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey[500],
                                fontSize: 16 * scale,
                              ),
                            ),
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
                            controller: passwordTextRepeatInputController,
                            obscureText: isHiddenPassword,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) =>
                            value != null && value.length < 6
                                ? 'Минимум 6 символов'
                                : null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Повторите пароль...',
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
                                  isHiddenPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.grey[500],
                                  size: 24 * scale,
                                ),
                                onPressed: togglePasswordView,
                              ),
                              hintStyle: TextStyle(
                                fontFamily: 'GolosR',
                                color: Colors.grey[500],
                                fontSize: 16 * scale,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30 * scale),
                        Container(
                          width: double.infinity,
                          height: 60 * scale,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15 * scale),
                              ),
                              shadowColor: Colors.red.withOpacity(0.3),
                            ),
                            child: isLoading
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
                                  'Создать аккаунт',
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
                            onPressed: isLoading ? null : () {
                              Navigator.pushReplacementNamed(context, '/Whod');
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
                                  Icons.login_rounded,
                                  size: 20 * scale,
                                ),
                                SizedBox(width: 10 * scale),
                                Text(
                                  'Войти в аккаунт',
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
    );
  }
}