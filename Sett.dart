import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:psm/custom_snackbar.dart';
import 'package:psm/main.dart';

class Sett extends StatefulWidget {
  @override
  _SettState createState() => _SettState();
}

class _SettState extends State<Sett> with TickerProviderStateMixin {
  int theme = 0;
  String _userName = 'Пользователь';
  String _userEmail = '';
  String _userRole = '';
  bool _isLoading = false;

  // Анимация
  late AnimationController _animationController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Фокус ноды для анимации полей
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _currentPasswordFocus = FocusNode();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Инициализация анимаций
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

    _loadSettings();
    _loadUserData();

    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      theme = prefs.getInt('theme') ?? 0;
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName = data['displayName'] ?? 'Пользователь';
          _userEmail = data['email'] ?? user.email ?? '';
          _userRole = _getRoleText(data['specialization'] ?? 0);
          _nameController.text = _userName;
        });
      }
    }
  }

  String _getRoleText(int spec) {
    switch (spec) {
      case 1: return 'Сборщик';
      case 2: return 'Монтажник';
      case 3: return 'Пакетировщик';
      case 4: return 'ИТР (Мастер)';
      case 5: return 'ИПК (Мастер)';
      default: return 'Не назначена';
    }
  }

  void _saveTheme(int newTheme) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      theme = newTheme;
    });
    await prefs.setInt('theme', newTheme);
    CustomSnackBar.showInfo(
      context: context,
      message: 'Функция смены темы находится в разработке и пока недоступна',
    );
  }

  void _showEditProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Редактировать профиль',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontFamily: 'GolosB',
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Измените ваше отображаемое имя',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontFamily: 'GolosR',
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: 'Имя и фамилия',
                        hint: 'Иван Иванов',
                        icon: Icons.person_outline,
                        validator: (v) => null,
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryButton(
                              label: 'Отмена',
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildPrimaryButton(
                              label: 'Сохранить',
                              onTap: () async {
                                await _updateProfileName();
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ],
                      ),
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

  Future<void> _updateProfileName() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'displayName': _nameController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        setState(() {
          _userName = _nameController.text.trim();
        });
        CustomSnackBar.showSuccess(context: context, message: 'Имя обновлено');
      }
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Ошибка обновления: \$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44.w,
                                height: 44.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.lock_outline,
                                  color: const Color(0xFFDC2626),
                                  size: 22.w,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Сменить пароль',
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontFamily: 'GolosB',
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Введите текущий и новый пароль',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontFamily: 'GolosR',
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.h),
                          
                          // Информационный блок
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBEAFE),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFF2563EB),
                                  size: 20.w,
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Text(
                                    'Новый пароль должен содержать минимум 6 символов',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontFamily: 'GolosR',
                                      color: const Color(0xFF1E40AF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20.h),

                          _buildPasswordField(
                            controller: _currentPasswordController,
                            focusNode: _currentPasswordFocus,
                            label: 'Текущий пароль',
                            hint: 'Введите текущий пароль',
                            obscureText: _obscureCurrentPassword,
                            onToggleVisibility: () {
                              setDialogState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          SizedBox(height: 16.h),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            focusNode: _newPasswordFocus,
                            label: 'Новый пароль',
                            hint: 'Минимум 6 символов',
                            obscureText: _obscureNewPassword,
                            onToggleVisibility: () {
                              setDialogState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          SizedBox(height: 16.h),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocus,
                            label: 'Подтвердите пароль',
                            hint: 'Повторите новый пароль',
                            obscureText: _obscureConfirmPassword,
                            onToggleVisibility: () {
                              setDialogState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          SizedBox(height: 24.h),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSecondaryButton(
                                  label: 'Отмена',
                                  onTap: () {
                                    Navigator.pop(context);
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  },
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _buildPrimaryButton(
                                  label: 'Сменить',
                                  onTap: _isLoading ? null : () async {
                                    if (_currentPasswordController.text.isEmpty) {
                                      CustomSnackBar.showWarning(context: context, message: 'Введите текущий пароль');
                                      return;
                                    }
                                    if (_newPasswordController.text.length < 6) {
                                      CustomSnackBar.showWarning(context: context, message: 'Новый пароль должен быть минимум 6 символов');
                                      return;
                                    }
                                    if (_newPasswordController.text != _confirmPasswordController.text) {
                                      CustomSnackBar.showWarning(context: context, message: 'Новые пароли не совпадают');
                                      return;
                                    }
                                    if (_currentPasswordController.text == _newPasswordController.text) {
                                      CustomSnackBar.showWarning(context: context, message: 'Новый пароль должен отличаться от текущего');
                                      return;
                                    }
                                    Navigator.pop(context);
                                    await _changePassword();
                                  },
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changePassword() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        CustomSnackBar.showError(context: context, message: 'Пользователь не авторизован');
        return;
      }

      if (user.email == null) {
        CustomSnackBar.showError(context: context, message: 'Email пользователя не найден');
        return;
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Неверный текущий пароль';
            break;
          case 'user-mismatch':
            errorMessage = 'Пользователь не найден';
            break;
          case 'invalid-credential':
            errorMessage = 'Неверные учётные данные';
            break;
          default:
            errorMessage = 'Ошибка проверки: \${e.message}';
        }
        CustomSnackBar.showError(context: context, message: errorMessage);
        return;
      }

      await user.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      CustomSnackBar.showSuccess(context: context, message: 'Пароль успешно изменён!');

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Пароль слишком слабый. Используйте минимум 6 символов';
          break;
        case 'requires-recent-login':
          errorMessage = 'Требуется повторный вход. Выйдите и войдите снова';
          break;
        case 'invalid-credential':
          errorMessage = 'Сессия устарела. Выйдите и войдите заново';
          break;
        default:
          errorMessage = 'Ошибка: \${e.message}';
      }
      CustomSnackBar.showError(context: context, message: errorMessage);
    } catch (e) {
      CustomSnackBar.showError(context: context, message: 'Неизвестная ошибка: \$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
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
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'О приложении',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontFamily: 'GolosB',
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Информация по использованию системы',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontFamily: 'GolosR',
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _buildHelpItem(
                      icon: Icons.assignment_outlined,
                      title: 'Создание задач',
                      description: 'ИТР и ИПК могут создавать задачи для сборщиков, монтажников и пакетировщиков.',
                    ),
                    SizedBox(height: 16.h),
                    _buildHelpItem(
                      icon: Icons.camera_alt_outlined,
                      title: 'Фото отчёты',
                      description: 'Исполнители прикрепляют фото выполненной работы для проверки.',
                    ),
                    SizedBox(height: 16.h),
                    _buildHelpItem(
                      icon: Icons.check_circle_outline,
                      title: 'Подтверждение',
                      description: 'ИТР подтверждает обычные задачи, ИПК — только свои ИПК-задачи.',
                    ),
                    SizedBox(height: 16.h),
                    _buildHelpItem(
                      icon: Icons.notifications_outlined,
                      title: 'Уведомления',
                      description: 'Используйте кнопку "Отправить пуш" для напоминаний работникам.',
                    ),
                    SizedBox(height: 24.h),
                    _buildPrimaryButton(
                      label: 'Понятно',
                      onTap: () => Navigator.pop(context),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: const Color(0xFFDC2626), size: 20.w),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'GolosB',
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontFamily: 'GolosR',
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _navigateToHome();
    }
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userSpecialization = prefs.getInt('userSpecialization') ?? 0;

    String route = '/MS_W';

    if (isLoggedIn && userSpecialization > 0) {
      switch (userSpecialization) {
        case 4:
          route = '/MasterScreen';
          break;
        case 5:
          route = '/IPKScreen';
          break;
        case 1:
          route = '/Sborka';
          break;
        case 2:
          route = '/Montasch';
          break;
        case 3:
          route = '/Pacet';
          break;
        default:
          route = '/specialization';
          break;
      }
    } else {
      route = theme == 0 ? '/MS_W' : '/MS_B';
    }

    Navigator.pushReplacementNamed(context, route);
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
                      'Настройки',
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20.h),

                        // Заголовок
                        Text(
                          'Настройки профиля ⚙️',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontFamily: 'GolosB',
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Управляйте вашим аккаунтом и настройками приложения',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontFamily: 'GolosR',
                            color: const Color(0xFF6B7280),
                          ),
                        ),

                        SizedBox(height: 32.h),

                        // ПРОФИЛЬ
                        _buildSectionTitle('Профиль'),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56.w,
                                height: 56.w,
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
                                  child: Text(
                                    _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontFamily: 'GolosB',
                                      fontSize: 24.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: TextStyle(
                                        fontFamily: 'GolosB',
                                        fontSize: 17.sp,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      _userEmail,
                                      style: TextStyle(
                                        fontFamily: 'GolosR',
                                        fontSize: 13.sp,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 6.h),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Text(
                                        _userRole,
                                        style: TextStyle(
                                          fontFamily: 'GolosB',
                                          fontSize: 11.sp,
                                          color: const Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _showEditProfileDialog,
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Container(
                                    width: 40.w,
                                    height: 40.w,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(10.r),
                                      border: Border.all(color: const Color(0xFFFCA5A5)),
                                    ),
                                    child: Icon(
                                      Icons.edit_outlined,
                                      color: const Color(0xFFDC2626),
                                      size: 20.w,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // ВНЕШНИЙ ВИД
                        _buildSectionTitle('Внешний вид'),
                        SizedBox(height: 12.h),
                        Container(
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Тема приложения',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontFamily: 'GolosB',
                                  color: const Color(0xFF1A1A2E),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Функция находится в разработке и пока недоступна',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontFamily: 'GolosR',
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              SizedBox(height: 20.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildThemeOption(
                                    0,
                                    'Светлая',
                                    Icons.light_mode_outlined,
                                    Colors.white,
                                    const Color(0xFF1A1A2E),
                                  ),
                                  _buildThemeOption(
                                    1,
                                    'Тёмная',
                                    Icons.dark_mode_outlined,
                                    const Color(0xFF1A1A2E),
                                    Colors.white,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // БЕЗОПАСНОСТЬ
                        _buildSectionTitle('Безопасность'),
                        SizedBox(height: 12.h),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildActionTile(
                            icon: Icons.lock_outlined,
                            title: 'Сменить пароль',
                            subtitle: 'Обновить пароль от аккаунта',
                            onTap: _showChangePasswordDialog,
                          ),
                        ),

                        SizedBox(height: 24.h),

                        // ПОДДЕРЖКА
                        _buildSectionTitle('Поддержка'),
                        SizedBox(height: 12.h),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF000000).withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildActionTile(
                            icon: Icons.help_outline,
                            title: 'О приложении',
                            subtitle: 'Информация по использованию',
                            onTap: _showHelpDialog,
                          ),
                        ),

                        SizedBox(height: 40.h),

                        // Версия
                        Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              'PSM v1.0.0',
                              style: TextStyle(
                                fontFamily: 'GolosR',
                                fontSize: 12.sp,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 24.h),
                      ],
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
        onTap: _goBack,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12.sp,
        fontFamily: 'GolosB',
        color: const Color(0xFFDC2626),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildThemeOption(
    int themeValue,
    String label,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    final isSelected = theme == themeValue;

    return GestureDetector(
      onTap: () => _saveTheme(themeValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 120.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28.w,
              color: iconColor,
            ),
            SizedBox(height: 12.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: isSelected ? 'GolosB' : 'GolosR',
                fontSize: 13.sp,
                color: iconColor,
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: 8.h),
              Container(
                width: 6.w,
                height: 6.w,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, color: const Color(0xFFDC2626), size: 24.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'GolosB',
                        fontSize: 15.sp,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'GolosR',
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: const Color(0xFF9CA3AF),
                size: 16.w,
              ),
            ],
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
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
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
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
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
                Icons.lock_outline,
                size: 22.w,
                color: isFocused ? const Color(0xFFDC2626) : const Color(0xFF9CA3AF),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF9CA3AF),
                  size: 22.w,
                ),
                onPressed: onToggleVisibility,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17.sp,
                fontFamily: 'GolosB',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17.sp,
                fontFamily: 'GolosB',
                color: const Color(0xFFDC2626),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

