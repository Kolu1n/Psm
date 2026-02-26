import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:psm/custom_snackbar.dart';

class Whod extends StatefulWidget {
  const Whod({Key? key}) : super(key: key);

  @override
  State<Whod> createState() => _WhodState();
}

class _WhodState extends State<Whod> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  // Фокус ноды для анимации полей
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Слушатели фокуса
    _emailFocus.addListener(() {
      setState(() => _emailFocused = _emailFocus.hasFocus);
    });
    _passwordFocus.addListener(() {
      setState(() => _passwordFocused = _passwordFocus.hasFocus);
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Сохраняем состояние
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('rememberMe', _rememberMe);

      // FCM токен
      await _saveFCMToken(userCredential.user!.uid);

      // Проверка специализации
      await _checkUserSpecialization();

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь не найден';
          break;
        case 'wrong-password':
          message = 'Неверный пароль';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
        case 'user-disabled':
          message = 'Аккаунт отключён';
          break;
        default:
          message = 'Ошибка входа. Попробуйте позже';
      }

      CustomSnackBar.showError(context: context, message: message);
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Произошла ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveFCMToken(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
          'lastLogin': DateTime.now().toIso8601String(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  Future<void> _checkUserSpecialization() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final spec = doc.data()?['specialization'] ?? 0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userSpecialization', spec);

    String route;
    switch (spec) {
      case 4: route = '/MasterScreen'; break;
      case 5: route = '/IPKScreen'; break;
      case 1: route = '/Sborka'; break;
      case 2: route = '/Montasch'; break;
      case 3: route = '/Pacet'; break;
      default: route = '/specialization'; break;
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  _buildBackButton(),
                  Expanded(
                    child: Text(
                      'Вход в систему',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontFamily: 'GolosB',
                        color: const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 44.w), // Для баланса
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20.h),

                          // Заголовок
                          Text(
                            'С возвращением! 👋',
                            style: TextStyle(
                              fontSize: 23.sp,
                              fontFamily: 'GolosB',
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Введите свои данные для входа в систему',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontFamily: 'GolosR',
                              color: const Color(0xFF6B7280),
                            ),
                          ),

                          SizedBox(height: 40.h),

                          // Поле email
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: 'Email',
                            hint: 'name@company.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите email';
                              }
                              if (!EmailValidator.validate(value)) {
                                return 'Неверный формат email';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // Поле пароля
                          _buildTextField(
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            label: 'Пароль',
                            hint: '••••••••',
                            icon: Icons.lock_outlined,
                            obscureText: !_isPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 22.w,
                              ),
                              onPressed: () {
                                setState(() => _isPasswordVisible = !_isPasswordVisible);
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите пароль';
                              }
                              if (value.length < 6) {
                                return 'Минимум 6 символов';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 16.h),

                          // Запомнить меня и Забыли пароль
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Запомнить меня
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                      activeColor: const Color(0xFFDC2626),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Запомнить меня',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontFamily: 'GolosR',
                                      color: const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),

                              // Забыли пароль
                              GestureDetector(
                                onTap: () => _showForgotPasswordDialog(),
                                child: Text(
                                  'Забыли пароль?',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontFamily: 'GolosB',
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 32.h),

                          // Кнопка входа
                          _buildLoginButton(),

                          SizedBox(height: 24.h),

                          // Разделитель
                          Row(
                            children: [
                              Expanded(child: Divider(color: const Color(0xFFE5E7EB))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: Text(
                                  'или',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontFamily: 'GolosR',
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: const Color(0xFFE5E7EB))),
                            ],
                          ),

                          SizedBox(height: 24.h),

                          // Кнопка регистрации
                          _buildRegisterButton(),

                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, '/MS_W'),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 22.w,
            color: const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontFamily: 'GolosB',
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8.h),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isFocused ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused ? [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ] : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            style: TextStyle(
              fontSize: 16.sp,
              fontFamily: 'GolosR',
              color: const Color(0xFF1A1A2E),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 16.sp,
                fontFamily: 'GolosR',
                color: const Color(0xFF9CA3AF),
              ),
              prefixIcon: Icon(
                icon,
                size: 22.w,
                color: isFocused ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
              ),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _login,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Войти',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontFamily: 'GolosB',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22.w,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, '/Reg'),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          height: 56.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFFFCA5A5),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_add_alt_1_rounded,
                color: const Color(0xFFDC2626),
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Создать аккаунт',
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: 'GolosB',
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        // Отступ для клавиатуры
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          // Фиксированная высота вместо DraggableScrollableSheet
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Индикатор
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(top: 16.h, bottom: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Прокручиваемый контент
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Восстановление пароля',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontFamily: 'GolosB',
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Введите email, указанный при регистрации. Мы отправим ссылку для сброса пароля.',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontFamily: 'GolosR',
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Поле email
                      _buildTextField(
                        controller: emailController,
                        focusNode: FocusNode(),
                        label: 'Email',
                        hint: 'name@company.com',
                        icon: Icons.email_outlined,
                        validator: (v) => null,
                      ),

                      SizedBox(height: 24.h),

                      // Кнопка отправки — теперь внутри прокрутки
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (emailController.text.isNotEmpty) {
                              try {
                                await FirebaseAuth.instance.sendPasswordResetEmail(
                                  email: emailController.text.trim(),
                                );
                                Navigator.pop(context);
                                CustomSnackBar.showSuccess(
                                  context: context,
                                  message: 'Письмо отправлено! Проверьте почту',
                                );
                              } catch (e) {
                                CustomSnackBar.showError(
                                  context: context,
                                  message: 'Ошибка: $e',
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(16.r),
                          child: Container(
                            width: double.infinity,
                            height: 56.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Center(
                              child: Text(
                                'Отправить ссылку',
                                style: TextStyle(
                                  fontSize: 17.sp,
                                  fontFamily: 'GolosB',
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Дополнительный отступ снизу
                      SizedBox(height: 16.h),
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