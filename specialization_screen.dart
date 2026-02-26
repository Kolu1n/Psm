import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:psm/custom_snackbar.dart';

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({Key? key}) : super(key: key);

  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen>
    with TickerProviderStateMixin {

  // Пароли только для ИТР и ИПК
  final int passwordITM = 333444;
  final int passwordIPK = 555666;

  String userName = 'Пользователь';
  String userEmail = '';
  bool isLoading = true;

  // Анимационные контроллеры
  late AnimationController _logoController;
  late AnimationController _contentController;
  late AnimationController _buttonsController;

  late Animation<double> _logoScale;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _buttonsStagger;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    // Анимация логотипа
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Анимация контента
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Анимация кнопок
    _buttonsController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _buttonsStagger = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonsController, curve: Curves.easeOut),
    );

    // Запуск анимаций последовательно
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        _contentController.forward();
        Future.delayed(const Duration(milliseconds: 200), () {
          _buttonsController.forward();
        });
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            userName = doc.data()?['displayName'] ?? 'Пользователь';
            userEmail = doc.data()?['email'] ?? user.email ?? '';
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
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  int _getSpecValue(String spec) {
    switch (spec) {
      case 'Сборщик': return 1;
      case 'Монтажник': return 2;
      case 'Пакетирование': return 3;
      case 'ИТР': return 4;
      case 'ИПК': return 5;
      default: return 0;
    }
  }

  bool _needsPassword(String spec) => spec == 'ИТР' || spec == 'ИПК';

  int _getSpecPassword(String spec) {
    switch (spec) {
      case 'ИТР': return passwordITM;
      case 'ИПК': return passwordIPK;
      default: return 0;
    }
  }

  Future<void> _saveFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void _onSpecSelected(String spec) {
    HapticFeedback.lightImpact();
    if (_needsPassword(spec)) {
      _showPasswordDialog(spec);
    } else {
      _processSpec(spec);
    }
  }

  void _showPasswordDialog(String spec) {
    final TextEditingController ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Индикатор
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              Text(
                'Введите код доступа',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontFamily: 'GolosB',
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Для специализации "$spec"',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontFamily: 'GolosR',
                  color: const Color(0xFF6B7280),
                ),
              ),
              SizedBox(height: 24.h),

              // Поле ввода пароля
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      fontSize: 20.sp,
                      color: const Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h
                    ),
                    counterText: '',
                  ),
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontFamily: 'GolosB',
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),

              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                      ),
                      child: Text(
                        'Отмена',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'GolosB',
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final entered = ctrl.text.trim();
                        final expected = _getSpecPassword(spec).toString();
                        if (entered == expected && expected != '0') {
                          Navigator.pop(context);
                          _processSpec(spec);
                        } else {
                          CustomSnackBar.showError(
                              context: context,
                              message: 'Неверный код доступа'
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        elevation: 0,
                      ),
                      child: Text(
                        'Войти',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: 'GolosB',
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processSpec(String spec) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        CustomSnackBar.showError(
            context: context,
            message: 'Пользователь не авторизован'
        );
        return;
      }

      final value = _getSpecValue(spec);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'displayName': userName,
        'email': userEmail,
        'specialization': value,
        'specializationText': spec,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _saveFCMToken();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('userSpecialization', value);

      if (!mounted) return;
      _navigateBySpec(spec);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(
          context: context,
          message: 'Ошибка сохранения: $e'
      );
    }
  }

  void _navigateBySpec(String spec) {
    switch (spec) {
      case 'Сборщик':
        Navigator.pushReplacementNamed(context, '/Sborka');
        break;
      case 'Монтажник':
        Navigator.pushReplacementNamed(context, '/Montasch');
        break;
      case 'Пакетирование':
        Navigator.pushReplacementNamed(context, '/Pacet');
        break;
      case 'ИТР':
        Navigator.pushReplacementNamed(context, '/MasterScreen');
        break;
      case 'ИПК':
        Navigator.pushReplacementNamed(context, '/IPKScreen');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/master');
    }
  }

  Widget _buildSpecButton(String spec, IconData icon, int index) {
    final bool needsPassword = _needsPassword(spec);
    final delay = index * 0.1;

    return AnimatedBuilder(
      animation: _buttonsController,
      builder: (context, child) {
        final double slideValue = _buttonsController.value;
        final double delayedValue = (slideValue - delay).clamp(0.0, 1.0) / (1.0 - delay);

        return Transform.translate(
          offset: Offset(0, 50 * (1 - delayedValue)),
          child: Opacity(
            opacity: delayedValue,
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 10.h), // Уменьшил отступ с 12 до 10
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onSpecSelected(spec),
            borderRadius: BorderRadius.circular(12.r), // Уменьшил с 16 до 12
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h), // Уменьшил padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r), // Уменьшил с 16 до 12
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.05),
                    blurRadius: 8, // Уменьшил с 10 до 8
                    offset: const Offset(0, 2), // Уменьшил смещение с 4 до 2
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Иконка - уменьшил размер
                  Container(
                    width: 44.w, // Уменьшил с 52
                    height: 44.w, // Уменьшил с 52
                    decoration: BoxDecoration(
                      color: needsPassword
                          ? const Color(0xFFDC2626).withOpacity(0.1)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10.r), // Уменьшил с 14
                    ),
                    child: Icon(
                      icon,
                      color: needsPassword
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFDC2626),
                      size: 22.w, // Уменьшил с 26
                    ),
                  ),
                  SizedBox(width: 12.w), // Уменьшил с 16
                  // Текст - уменьшил шрифты
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec,
                          style: TextStyle(
                            fontSize: 16.sp, // Уменьшил с 18
                            fontFamily: 'GolosB',
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 2.h), // Уменьшил с 4
                        Text(
                          needsPassword
                              ? 'Требуется код'
                              : 'Выбрать',
                          style: TextStyle(
                            fontSize: 12.sp, // Уменьшил с 13
                            fontFamily: 'GolosR',
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Стрелка или иконка замка
                  Icon(
                    needsPassword ? Icons.lock_outline : Icons.arrow_forward_ios,
                    color: needsPassword
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF9CA3AF),
                    size: 18.w, // Уменьшил с 20
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
            : Column(
          children: [
            // Верхняя панель с кнопкой назад
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Material(
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
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w), // Уменьшил с 28
                child: Column(
                  children: [
                    // Логотип с анимацией
                    ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 200.w,
                        height: 80.h,
                        margin: EdgeInsets.only(top: 16.h, bottom: 32.h), // Уменьшил отступы
                        child: Image.asset(
                          'assets/PSM.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Приветствие с анимацией
                    FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Column(
                          children: [
                            // ИСПРАВЛЕНО: убрал \ перед $
                            Text(
                              "Привет, $userName! 👋",
                              style: TextStyle(
                                fontSize: 22.sp, // Уменьшил с 24
                                fontFamily: 'GolosB',
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 10.h), // Уменьшил с 12
                            Text(
                              'Выберите вашу специализацию',
                              style: TextStyle(
                                fontSize: 14.sp, // Уменьшил с 15
                                fontFamily: 'GolosR',
                                color: const Color(0xFF6B7280),
                                height: 1.4, // Уменьшил с 1.5
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h), // Уменьшил с 40

                    // Кнопки специализаций с stagger-анимацией
                    _buildSpecButton('Сборщик', Icons.build_outlined, 0),
                    _buildSpecButton('Монтажник', Icons.power_outlined, 1),
                    _buildSpecButton('Пакетирование', Icons.inventory_2_outlined, 2),
                    _buildSpecButton('ИТР', Icons.manage_accounts_outlined, 3),
                    _buildSpecButton('ИПК', Icons.security_outlined, 4),

                    SizedBox(height: 24.h), // Уменьшил с 30
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}