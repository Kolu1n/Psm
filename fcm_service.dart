// fcm_service.dart (исправленный метод _getAccessTokenFallback)
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  // 🔴 ВСТАВЬТЕ ВАШ ТОКЕН СЮДА:
  static const String _firebaseCiToken = '1//0561MvLUFhZPXCgYIARAAGAUSNwF-L9IrMvPrBIxUquQTmlRtIm09w5kXAzRBzmlzfp9mUBtWLyLqp0XCjlgXFOPLjVFtzylXdiY';

  // 🔴 Упрощенный метод получения токена через Firebase CLI токен
  static Future<String> _getAccessToken() async {
    // Если токен еще действителен (действителен 1 час)
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      print('♻️ Использую кэшированный Access Token');
      return _cachedAccessToken!;
    }

    print('🔄 Получаю новый Access Token...');

    try {
      // 🔴 СПОСОБ 1: Используем Firebase CLI токен для получения access_token
      final accessToken = await _getAccessTokenFromFirebaseToken();

      if (accessToken.isNotEmpty) {
        _cachedAccessToken = accessToken;
        _tokenExpiry = DateTime.now().add(Duration(minutes: 55));

        // Сохраняем в SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_access_token', accessToken);
        await prefs.setString('fcm_token_expiry', _tokenExpiry!.toIso8601String());

        print('✅ Access Token получен! Действителен до: $_tokenExpiry');
        return accessToken;
      }

      throw Exception('Не удалось получить токен');

    } catch (e) {
      print('❌ Ошибка получения токена: $e');

      // 🔴 Запасной вариант: проверяем сохраненный токен
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_access_token');
      final savedExpiry = prefs.getString('fcm_token_expiry');

      if (savedToken != null && savedExpiry != null) {
        final expiryDate = DateTime.parse(savedExpiry);
        if (expiryDate.isAfter(DateTime.now())) {
          _cachedAccessToken = savedToken;
          _tokenExpiry = expiryDate;
          print('✅ Использую сохраненный токен');
          return savedToken;
        }
      }

      // 🔴 Критический fallback
      print('⚠️ Использую ручной токен');
      return _getManualToken();
    }
  }

  // 🔴 НОВЫЙ МЕТОД: Получение Access Token через Firebase CLI токен
  static Future<String> _getAccessTokenFromFirebaseToken() async {
    try {
      print('🔐 Пробую получить токен через Firebase CLI token...');

      // Firebase CLI токен - это refresh token, из него можно получить access token
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _firebaseCiToken, // 🔴 ВАШ ТОКЕН ЗДЕСЬ
          'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com', // Firebase CLI client ID
          'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi', // Firebase CLI client secret
        }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] as String;

        print('✅ Получен Access Token через Firebase CLI');
        return accessToken;
      } else {
        print('❌ Ошибка Firebase CLI: ${response.statusCode} ${response.body}');

        // 🔴 Альтернатива: попробуем использовать токен как есть
        print('🔄 Пробую использовать Firebase CLI токен напрямую...');
        return _firebaseCiToken;
      }

    } catch (e) {
      print('❌ Ошибка при работе с Firebase CLI токеном: $e');
      return '';
    }
  }

  // 🔴 Ручной токен (используйте только если выше не работает)
  static String _getManualToken() {
    // 🔴 ЕСЛИ НИЧЕГО НЕ РАБОТАЕТ, ПОПРОБУЙТЕ ЭТОТ ТОКЕН:
    // Получите через: gcloud auth print-access-token

    const manualToken = 'ya29.c.c0AZ1aNiREPLACE_WITH_REAL_TOKEN'; // 🔴 ЗАМЕНИТЕ

    _tokenExpiry = DateTime.now().add(Duration(minutes: 55));

    return manualToken;
  }

  // 🔴 Упрощенный метод отправки с автоматическим обновлением токена
  static Future<Map<String, dynamic>> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (tokens.isEmpty) {
      print('⚠️ Нет токенов для отправки');
      return {'success': false, 'error': 'Нет токенов', 'sent': 0, 'failed': 0};
    }

    print('🔄 Начинаю отправку ${tokens.length} уведомлений...');

    int successCount = 0;
    int failCount = 0;

    try {
      // 🔴 ПОЛУЧАЕМ СВЕЖИЙ ТОКЕН
      final accessToken = await _getAccessToken();

      if (accessToken.isEmpty) {
        throw Exception('Не удалось получить Access Token');
      }

      for (var token in tokens) {
        try {
          print('📤 Отправляю на токен: ${token.substring(0, 20)}...');

          final response = await http.post(
            Uri.parse('https://fcm.googleapis.com/v1/projects/psm-prjct/messages:send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({
              'message': {
                'token': token,
                'notification': {
                  'title': title,
                  'body': body,
                },
                'data': {
                  ...data,
                  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                },
              }
            }),
          );

          if (response.statusCode == 200) {
            successCount++;
            print('   ✅ Успешно');
          } else {
            failCount++;
            print('   ❌ Ошибка ${response.statusCode}');

            // Если токен истек (401) - сбрасываем кэш
            if (response.statusCode == 401) {
              print('   🔄 Токен истек. Сбрасываю кэш...');
              _cachedAccessToken = null;
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('fcm_access_token');
              await prefs.remove('fcm_token_expiry');
            }
          }

          await Future.delayed(Duration(milliseconds: 50));

        } catch (e) {
          failCount++;
          print('   ❌ Исключение: $e');
        }
      }

      print('📊 ИТОГ отправки: ✅ $successCount, ❌ $failCount');

      return {
        'success': successCount > 0,
        'sent': successCount,
        'failed': failCount,
        'total': tokens.length,
      };

    } catch (e) {
      print('❌ Критическая ошибка отправки: $e');
      return {'success': false, 'error': e.toString(), 'sent': 0, 'failed': tokens.length};
    }
  }

  // 🔴 МЕТОД ДЛЯ РУЧНОГО ОБНОВЛЕНИЯ ТОКЕНА
  static Future<void> refreshTokenManually() async {
    print('🔄 Ручное обновление токена...');

    _cachedAccessToken = null;
    _tokenExpiry = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_access_token');
    await prefs.remove('fcm_token_expiry');

    print('✅ Кэш токена очищен. Токен будет обновлен при следующей отправке.');
  }

  // 🔴 МЕТОД ДЛЯ ПРОВЕРКИ ТОКЕНА
  static Future<void> testToken() async {
    print('🧪 Тестирую токен...');

    try {
      final token = await _getAccessToken();

      if (token.isEmpty) {
        print('❌ Токен не получен');
        return;
      }

      print('✅ Токен получен: ${token.substring(0, 50)}...');

      // Тестовая отправка
      final testResponse = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/psm-prjct/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'message': {
            'token': 'test_token', // Тестовый токен
            'notification': {
              'title': 'Test',
              'body': 'Test notification',
            },
          }
        }),
      );

      print('🧪 Тестовый запрос: ${testResponse.statusCode}');

    } catch (e) {
      print('❌ Ошибка тестирования токена: $e');
    }
  }

  // Остальные методы без изменений...
  static Future<void> initialize() async {
    print('🚀 Инициализация FCM...');

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('✅ Разрешение на уведомления: ${settings.authorizationStatus}');

      String? token = await _fcm.getToken();
      if (token != null) {
        print('✅ FCM Token пользователя: ${token.substring(0, 30)}...');
        await _saveTokenToFirestore(token);
      } else {
        print('⚠️ Не удалось получить FCM Token');
      }

      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      // 🔴 Тестируем токен при инициализации
      await testToken();

      print('✅ FCM успешно инициализирован');

    } catch (e) {
      print('❌ Ошибка инициализации FCM: $e');
    }
  }

  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('❌ Ошибка сохранения токена: $e');
    }
  }

  static Future<List<String>> getTokensBySpecialization(int specialization) async {
    List<String> tokens = [];

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('specialization', isEqualTo: specialization)
          .where('fcmToken', isNotEqualTo: null)
          .get();

      for (var doc in usersSnapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      print('✅ Найдено ${tokens.length} токенов для специализации $specialization');

    } catch (e) {
      print('❌ Ошибка получения токенов: $e');
    }

    return tokens;
  }
}