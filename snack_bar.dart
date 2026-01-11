import 'dart:async';
import 'package:flutter/material.dart';

class SnackBarService {
  static const errorColor = Color(0xFFF44336);
  static const okColor = Color(0xFF4CAF50);

  static OverlayEntry? _currentOverlay;
  static Timer? _dismissTimer;

  static Future<void> showSnackBar(
      BuildContext context, String message, bool error) async {

    _dismissCurrent();

    final backgroundColor = error ? errorColor : okColor;
    final icon = error ? Icons.error_outline : Icons.check_circle;
    final duration = Duration(seconds: error ? 4 : 3);

    // Рассчитываем ширину на основе текста
    final textPainter = TextPainter(
      text: TextSpan(
        text: message,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'GolosR',
          fontWeight: FontWeight.w500,
        ),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 140); // Учитываем место для кнопки "Назад"

    final textWidth = textPainter.width;
    final screenWidth = MediaQuery.of(context).size.width;

    // Определяем ширину уведомления с учетом кнопки "Назад"
    final leftPaddingForBackButton = 60.0; // Место для кнопки "Назад"
    final rightPadding = 20.0; // Отступ справа

    double notificationWidth;
    if (textWidth < 100) {
      // Для коротких сообщений
      notificationWidth = textWidth + 100;
    } else if (textWidth > screenWidth - leftPaddingForBackButton - rightPadding - 100) {
      // Для длинных сообщений
      notificationWidth = screenWidth - leftPaddingForBackButton - rightPadding;
    } else {
      // Для нормальных сообщений
      notificationWidth = textWidth + 100;
    }

    // Ограничиваем минимальную и максимальную ширину
    final minWidth = 200.0;
    final maxWidth = screenWidth - leftPaddingForBackButton - rightPadding;
    notificationWidth = notificationWidth.clamp(minWidth, maxWidth);

    // Рассчитываем позицию с учетом кнопки "Назад"
    final leftPosition = leftPaddingForBackButton + (screenWidth - leftPaddingForBackButton - rightPadding - notificationWidth) / 2;

    // Создаем OverlayEntry
    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: leftPosition,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: _dismissCurrent,
            child: Container(
              width: notificationWidth,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'GolosR',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: _dismissCurrent,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Вставляем в Overlay
    Overlay.of(context).insert(_currentOverlay!);

    // Автоматическое скрытие через duration
    _dismissTimer = Timer(duration, _dismissCurrent);
  }

  static void _dismissCurrent() {
    _dismissTimer?.cancel();
    _currentOverlay?.remove();
    _currentOverlay = null;
  }
}