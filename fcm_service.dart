// fcm_service.dart
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

  // 🔴 КЭШ для уникальных токенов (чтобы не отправлять дубликаты в одной сессии)
  static final Set<String> _sentTokensCache = {};

  static const String _firebaseCiToken = '1//0561MvLUFhZPXCgYIARAAGAUSNwF-L9IrMvPrBIxUquQTmlRtIm09w5kXAzRBzmlzfp9mUBtWLyLqp0XCjlgXFOPLjVFtzylXdiY';

  static Future<String> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        _tokenExpiry!.isAfter(DateTime.now().add(Duration(minutes: 5)))) {
      return _cachedAccessToken!;
    }

    try {
      final accessToken = await _getAccessTokenFromFirebaseToken();

      if (accessToken.isNotEmpty) {
        _cachedAccessToken = accessToken;
        _tokenExpiry = DateTime.now().add(Duration(minutes: 55));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_access_token', accessToken);
        await prefs.setString('fcm_token_expiry', _tokenExpiry!.toIso8601String());

        return accessToken;
      }

      throw Exception('Не удалось получить токен');

    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('fcm_access_token');
      final savedExpiry = prefs.getString('fcm_token_expiry');

      if (savedToken != null && savedExpiry != null) {
        final expiryDate = DateTime.parse(savedExpiry);
        if (expiryDate.isAfter(DateTime.now())) {
          _cachedAccessToken = savedToken;
          _tokenExpiry = expiryDate;
          return savedToken;
        }
      }

      return _getManualToken();
    }
  }

  static Future<String> _getAccessTokenFromFirebaseToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _firebaseCiToken,
          'client_id': '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
          'client_secret': 'j9iVZfS8kkCEFUPaAeJV0sAi',
        }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String;
      } else {
        return _firebaseCiToken;
      }

    } catch (e) {
      return '';
    }
  }

  static String _getManualToken() {
    const manualToken = 'ya29.c.c0AZ1aNiREPLACE_WITH_REAL_TOKEN';
    _tokenExpiry = DateTime.now().add(Duration(minutes: 55));
    return manualToken;
  }

  // 🔴 ОЧИСТКА кэша отправленных токенов (вызывать при старте новой отправки)
  static void clearSentCache() {
    _sentTokensCache.clear();
    print('🧹 Кэш отправленных токенов очищен');
  }

  // 🔴 ОСНОВНОЙ МЕТОД ОТПРАВКИ с дедупликацией
  static Future<Map<String, dynamic>> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (tokens.isEmpty) {
      return {'success': false, 'error': 'Нет токенов', 'sent': 0, 'failed': 0};
    }

    // 🔴 УНИКАЛИЗАЦИЯ: убираем дубликаты токенов
    final uniqueTokens = tokens.toSet().toList();
    print('📊 Уникальных токенов: ${uniqueTokens.length} (из ${tokens.length})');

    // 🔴 ФИЛЬТРАЦИЯ: убираем уже отправленные в этой сессии
    final tokensToSend = uniqueTokens.where((t) => !_sentTokensCache.contains(t)).toList();
    print('📤 Новых токенов для отправки: ${tokensToSend.length}');

    if (tokensToSend.isEmpty) {
      print('✅ Все токены уже обработаны в этой сессии');
      return {'success': true, 'sent': 0, 'failed': 0, 'skipped': uniqueTokens.length};
    }

    print('🔄 Начинаю отправку ${tokensToSend.length} уведомлений...');

    int successCount = 0;
    int failCount = 0;
    int invalidTokenCount = 0;

    try {
      final accessToken = await _getAccessToken();

      if (accessToken.isEmpty) {
        throw Exception('Не удалось получить Access Token');
      }

      // 🔴 ОТПРАВКА ПАЧКАМИ по 500 штук (лимит FCM)
      const batchSize = 500;
      for (var i = 0; i < tokensToSend.length; i += batchSize) {
        final batch = tokensToSend.skip(i).take(batchSize).toList();

        for (var token in batch) {
          try {
            // 🔴 ПРОВЕРКА: не отправляли ли уже
            if (_sentTokensCache.contains(token)) {
              print('   ⏭️ Пропуск (уже отправлено): ${token.substring(0, 20)}...');
              continue;
            }

            print('📤 Отправляю на: ${token.substring(0, 20)}...');

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
              _sentTokensCache.add(token); // 🔴 Помечаем как отправленный
              print('   ✅ Успешно');
            } else {
              final errorBody = jsonDecode(response.body);
              final errorCode = errorBody['error']?['code'] ?? '';

              // 🔴 ОБРАБОТКА НЕВАЛИДНЫХ ТОКЕНОВ
              if (errorCode == 'NOT_FOUND' || errorCode == 'INVALID_ARGUMENT') {
                invalidTokenCount++;
                print('   🗑️ Токен невалиден, помечаем для удаления: $errorCode');
                await _markTokenAsInvalid(token);
              } else if (response.statusCode == 401) {
                print('   🔄 Токен доступа истек, сбрасываю кэш...');
                _cachedAccessToken = null;
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('fcm_access_token');
                await prefs.remove('fcm_token_expiry');
                failCount++;
              } else {
                failCount++;
                print('   ❌ Ошибка ${response.statusCode}: ${response.body.substring(0, 100)}');
              }
            }

            // 🔴 НЕБОЛЬШАЯ ЗАДЕРЖКА чтобы не перегружать API
            await Future.delayed(Duration(milliseconds: 10));

          } catch (e) {
            failCount++;
            print('   ❌ Исключение: $e');
          }
        }
      }

      print('📊 ИТОГ: ✅ $successCount, ❌ $failCount, 🗑️ $invalidTokenCount невалидных');

      return {
        'success': successCount > 0,
        'sent': successCount,
        'failed': failCount,
        'invalid': invalidTokenCount,
        'total': tokensToSend.length,
      };

    } catch (e) {
      print('❌ Критическая ошибка отправки: $e');
      return {'success': false, 'error': e.toString(), 'sent': 0, 'failed': tokensToSend.length};
    }
  }

  // 🔴 ПОМЕТКА невалидного токена в Firestore
  static Future<void> _markTokenAsInvalid(String token) async {
    try {
      // Ищем пользователя с этим токеном
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isEqualTo: token)
          .get();

      for (var doc in usersSnapshot.docs) {
        await doc.reference.update({
          'fcmToken': null,
          'fcmTokenInvalid': true,
          'fcmTokenInvalidAt': FieldValue.serverTimestamp(),
        });
        print('   🗑️ Токен удалён у пользователя ${doc.id}');
      }
    } catch (e) {
      print('   ⚠️ Не удалось удалить невалидный токен: $e');
    }
  }

  // 🔴 ПОЛУЧЕНИЕ ТОКЕНОВ с фильтрацией дубликатов и невалидных
  static Future<List<String>> getTokensBySpecialization(int specialization) async {
    List<String> tokens = [];

    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('specialization', isEqualTo: specialization)
          .where('fcmToken', isNotEqualTo: null)
          .get();

      final Set<String> uniqueTokens = {};

      for (var doc in usersSnapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        final isInvalid = doc.data()['fcmTokenInvalid'] == true;

        // 🔴 ПРОВЕРКИ: токен должен быть валидным и уникальным
        if (token != null &&
            token.isNotEmpty &&
            !isInvalid &&
            token.length > 50 && // Минимальная длина валидного FCM токена
            !uniqueTokens.contains(token)) {
          uniqueTokens.add(token);
        }
      }

      tokens = uniqueTokens.toList();
      print('✅ Найдено ${tokens.length} уникальных валидных токенов для спец. $specialization');

    } catch (e) {
      print('❌ Ошибка получения токенов: $e');
    }

    return tokens;
  }

  // 🔴 ИНИЦИАЛИЗАЦИЯ с проверкой существующего токена
  static Future<void> initialize() async {
    print('🚀 Инициализация FCM...');

    try {
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('✅ Разрешение: ${settings.authorizationStatus}');

      String? token = await _fcm.getToken();
      if (token != null) {
        print('✅ FCM Token: ${token.substring(0, 30)}...');
        await _saveTokenToFirestore(token);
      }

      _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

      print('✅ FCM инициализирован');

    } catch (e) {
      print('❌ Ошибка инициализации FCM: $e');
    }
  }

  // 🔴 СОХРАНЕНИЕ ТОКЕНА с проверкой на дубликаты
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 🔴 ПРОВЕРКА: не сохранён ли уже такой токен у другого пользователя
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmToken', isEqualTo: token)
          .get();

      // Удаляем токен у других пользователей (один токен = один пользователь)
      for (var doc in existingUsers.docs) {
        if (doc.id != user.uid) {
          await doc.reference.update({
            'fcmToken': null,
            'fcmTokenReplacedBy': user.uid,
            'fcmTokenReplacedAt': FieldValue.serverTimestamp(),
          });
          print('🔄 Токен перенесён от пользователя ${doc.id} к ${user.uid}');
        }
      }

      // Сохраняем токен текущему пользователю
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        'fcmTokenInvalid': false, // Сбрасываем флаг невалидности
      }, SetOptions(merge: true));

      print('✅ Токен сохранён для ${user.uid}');

    } catch (e) {
      print('❌ Ошибка сохранения токена: $e');
    }
  }

  // 🔴 РУЧНОЕ ОБНОВЛЕНИЕ ТОКЕНА
  static Future<void> refreshTokenManually() async {
    _cachedAccessToken = null;
    _tokenExpiry = null;
    _sentTokensCache.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fcm_access_token');
    await prefs.remove('fcm_token_expiry');

    print('✅ Кэш очищен');
  }

  // 🔴 ТЕСТИРОВАНИЕ
  static Future<void> testToken() async {
    print('🧪 Тестирую токен...');
    try {
      final token = await _getAccessToken();
      if (token.isEmpty) {
        print('❌ Токен не получен');
        return;
      }
      print('✅ Токен: ${token.substring(0, 50)}...');
    } catch (e) {
      print('❌ Ошибка: $e');
    }
  }
}