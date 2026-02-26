import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:psm/main.dart';

class MainS_W extends StatefulWidget {
  const MainS_W({Key? key}) : super(key: key);

  @override
  State<MainS_W> createState() => _MainS_WState();
}

class _MainS_WState extends State<MainS_W> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

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

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    // Запуск анимаций
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFC),
      body: SafeArea(
        child: Column(
          children: [
            // Верхняя панель с настройками
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/Sett'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    children: [
                      // Логотип с анимацией
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 200.w,
                          height: 80.h,
                          margin: EdgeInsets.only(top: 40.h, bottom: 60.h),
                          child: Image.asset(
                            'assets/PSM.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // Приветственный текст
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Column(
                            children: [
                              Text(
                                'Добро пожаловать!',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontFamily: 'GolosB',
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A2E),
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Войдите в систему для управления производственными задачами',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GolosR',
                                  color: const Color(0xFF6B7280),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 48.h),

                      // Карточка с кнопками
                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(28.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24.r),
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
                              children: [
                                // Кнопка входа
                                _buildPrimaryButton(
                                  label: 'Войти в аккаунт',
                                  icon: Icons.login_rounded,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushReplacementNamed(context, '/Whod');
                                  },
                                ),

                                SizedBox(height: 16.h),

                                // Кнопка регистрации
                                _buildSecondaryButton(
                                  label: 'Создать аккаунт',
                                  icon: Icons.person_add_alt_1_rounded,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushReplacementNamed(context, '/Reg');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      // Дополнительная информация
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'PSM — система управления задачами\nдля производственных команд',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: 'GolosR',
                            color: const Color(0xFF9CA3AF),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 22.w,
            color: const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDC2626),
                Color(0xFFB91C1C),
              ],
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: 'GolosB',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFFDC2626),
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                label,
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

// Тёмная версия
class MainS_B extends StatefulWidget {
  const MainS_B({Key? key}) : super(key: key);

  @override
  State<MainS_B> createState() => _MainS_BState();
}

class _MainS_BState extends State<MainS_B> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
      Future.delayed(const Duration(milliseconds: 400), () {
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () => Navigator.pushNamed(context, '/Sett'),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 200.w,
                          height: 80.h,
                          margin: EdgeInsets.only(top: 40.h, bottom: 60.h),
                          child: Image.asset(
                            'assets/PSM-B.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Column(
                            children: [
                              Text(
                                'Добро пожаловать!',
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontFamily: 'GolosB',
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Войдите в систему для управления производственными задачами',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontFamily: 'GolosR',
                                  color: const Color(0xFF9CA3AF),
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 48.h),

                      FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(28.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: const Color(0xFF2D2D44),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF000000).withOpacity(0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildPrimaryButton(
                                  label: 'Войти в аккаунт',
                                  icon: Icons.login_rounded,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushReplacementNamed(context, '/Whod');
                                  },
                                ),

                                SizedBox(height: 16.h),

                                _buildSecondaryButton(
                                  label: 'Создать аккаунт',
                                  icon: Icons.person_add_alt_1_rounded,
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushReplacementNamed(context, '/Reg');
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40.h),

                      FadeTransition(
                        opacity: _fadeIn,
                        child: Text(
                          'PSM — система управления задачами\nдля производственных команд',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: 'GolosR',
                            color: const Color(0xFF6B7280),
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFF2D2D44),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            size: 22.w,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFDC2626),
                Color(0xFFB91C1C),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontFamily: 'GolosB',
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required IconData icon,
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
            color: const Color(0xFF2D2D44),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: const Color(0xFFDC2626),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: const Color(0xFFDC2626),
                size: 22.w,
              ),
              SizedBox(width: 12.w),
              Text(
                label,
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