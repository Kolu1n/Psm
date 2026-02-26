import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';

class Reg extends StatefulWidget {
  const Reg({Key? key}) : super(key: key);

  @override
  State<Reg> createState() => _RegState();
}

class _RegState extends State<Reg> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  // УБРАНО: bool _agreeToTerms = false;

  // Индикаторы сложности пароля
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

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

    // Слушатель для индикаторов пароля
    _passwordController.addListener(_checkPasswordStrength);

    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 6;
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    // УБРАНО: проверка согласия с условиями
    if (_passwordController.text != _confirmPasswordController.text) {
      CustomSnackBar.showError(context: context, message: 'Пароли не совпадают');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await userCredential.user!.updateDisplayName(_nameController.text.trim());

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'displayName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      await userCredential.user!.sendEmailVerification();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/VerifyEmail');
      }

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Этот email уже используется';
          break;
        case 'weak-password':
          message = 'Пароль слишком слабый';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
        default:
          message = 'Ошибка регистрации: ${e.message}';
      }
      CustomSnackBar.showError(context: context, message: message);
    } catch (e) {
      CustomSnackBar.showError(
        context: context,
        message: 'Неизвестная ошибка. Попробуйте позже',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      'Регистрация',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontFamily: 'GolosB',
                        color: const Color(0xFF1A1A2E),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 44.w),
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
                          SizedBox(height: 16.h),

                          // Заголовок
                          Text(
                            'Создайте аккаунт 🚀',
                            style: TextStyle(
                              fontSize: 23.sp,
                              fontFamily: 'GolosB',
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Заполните данные для регистрации в системе',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontFamily: 'GolosR',
                              color: const Color(0xFF6B7280),
                            ),
                          ),

                          SizedBox(height: 32.h),

                          // Имя
                          _buildTextField(
                            controller: _nameController,
                            focusNode: _nameFocus,
                            label: 'Имя и фамилия',
                            hint: 'Иван Иванов',
                            icon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Введите имя';
                              if (v.length < 2) return 'Слишком короткое';
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // Email
                          _buildTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: 'Email',
                            hint: 'name@company.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Введите email';
                              if (!EmailValidator.validate(v)) return 'Неверный формат';
                              return null;
                            },
                          ),

                          SizedBox(height: 20.h),

                          // Пароль
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
                              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Введите пароль';
                              if (v.length < 6) return 'Минимум 6 символов';
                              return null;
                            },
                          ),

                          SizedBox(height: 12.h),

                          // Индикаторы сложности пароля
                          _buildPasswordStrengthIndicator(),

                          SizedBox(height: 20.h),

                          // Подтверждение пароля
                          _buildTextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmFocus,
                            label: 'Подтвердите пароль',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: !_isConfirmPasswordVisible,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: 22.w,
                              ),
                              onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Подтвердите пароль';
                              if (v != _passwordController.text) return 'Пароли не совпадают';
                              return null;
                            },
                          ),

                          SizedBox(height: 30.h),

                          // Кнопка регистрации
                          _buildRegisterButton(),
                          SizedBox(height: 24.h),
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

                          // Кнопка входа
                          _buildLoginButton(),

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

  Widget _buildPasswordStrengthIndicator() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Требования к паролю:',
            style: TextStyle(
              fontSize: 13.sp,
              fontFamily: 'GolosB',
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: 12.h),
          _buildRequirement('Минимум 6 символов', _hasMinLength),
          SizedBox(height: 8.h),
          _buildRequirement('Содержит цифру', _hasNumber),
          SizedBox(height: 8.h),
          _buildRequirement('Содержит спецсимвол (!@#*&)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: met ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: met
              ? Icon(Icons.check, size: 14.w, color: Colors.white)
              : Icon(Icons.circle, size: 8.w, color: const Color(0xFF9CA3AF)),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontFamily: 'GolosR',
            color: met ? const Color(0xFF10B981) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isLoading ? null : _signUp,
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
                  'Создать аккаунт',
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

  Widget _buildLoginButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushReplacementNamed(context, '/Whod'),
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
                Icons.login_rounded,
                color: const Color(0xFFDC2626),
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                'Уже есть аккаунт',
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
}