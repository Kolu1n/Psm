// fcm_auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FCMAuthService {
  static String? _accessToken;
  static DateTime? _tokenExpiry;

  // Вставь сюда свой Service Account JSON
  static const _serviceAccountJson = '''
  {
    "type": "service_account",
    "project_id": "psm-prjct",
    "private_key_id": "15b8ee6b1eb70e7305a2d0c7fd05a253af1ef286",
    "private_key": "-----BEGIN PRIVATE KEY-----\\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCpTOabC62j2zoB\\n6zRxdcsYNp/WhYYx6RGYRaJUFYzyjvYd0+fuNmzha0IEynbhWkA1OoTVHfJVlZI0\\nEDaG75/2UxzGsYpWYbhbrg6SqCFL6nghZbpA2f5gArfcUQTdAAOgBmnxKnhCKH2T\\n3JREtmclrKFCZdvPjgYJkMLwT+QitXhxGticB5At+eSLHM6kV4lVwAQlv4qo4E2/\\nWpfYFabOMSxjbgkIIeJHwygZvc+NqpzP0PnBQlDIHP7Q9AR9vBu+gIv5M+Y5Drgo\\nfnF6qZF0+7Z9Jb5ElXiBvlBvJj+/BOfqa0GkBw+Dm1PhjiEVaLN8Ue28nsJJkYhb\\noDwYEu8pAgMBAAECggEAN4FxZ6rUApE4+vEQsBQ1AlrCW7RKM2nc7WYDGvs3yzyI\\nv22+sBBi8SLXsbdpc2fB/lGRxEd9sIaJuQ0Ju4KrmLhWCmSh3MFMDq7Js1ZxGDEm\\nsphmEKYH6pVpj092vzgmeBwyNrG8XMBmr4gVilOdDLKE6j536xv+qbsu1lfzDVeV\\nel0gMU1EUp0krd5kNzdk4QTAINo5p7i53wPebeU6jytRP5uhxyAeUw3hZh+MbJkC\\nwDvSrMp4gjvXbFX4UZ9lMzEJCx4Uj9ZNF+nThs9lXlrMxe7+N8HnY5enKmnHxEyj\\n0qXPxDfVTssOARR9t9ny9VOiB68U99VBpI0w7vQIQwKBgQDnu88Lu0U8gxeIkS4K\\ntmgtu5EIcTxTHCiJVmAUivEAGDlyPMFUBkMEz8uvcET5S5A3+FzLj8ipv0CCn4Ou\\nAUqq0rMknGTj+DI3xf8n6nYhKEQKHmYVc4PA7JGX1O5tBYK1Uq4ldy8m665XW8dz\\nuUfoht/fZwXEKBJujKy4wZ8svwKBgQC7B2pOfYGVCaDeM4CjlhszrxX9q3ccn6a9\\niFWlsfqzcU/lJre/RkXQBWaZGVx/cp6awGqVnYgZ5L0I+OTiGsWVRuvcOskROxcl\\nMeSk9RyB1bOyxXdLkLAfwb8FiIUP+1xkP67tSprB3rYOphgXUSiqIZNaR4BhruBx\\nNY33XvKWFwKBgAd3xfRa1KBemSONii5OMo1GviXHgGotPiEu52nCEIIwRamoy5Ip\\noX9GMwo0VAS0qrEjD9p/h7fwseODwHqbEAzxPVSwtY+jL/scJlzi8WugIJEy6ZdH\\nYbeV6Bs8gXKB+vRc9b+/V4WpkrS+AG96SRb1QcGxUD5CDFYDso1BsB+BAoGBAJHH\\nA9tOBBSwvoyzRA89ztIIJHHmlh7fac3NWESgZzI6nfWUqiASnBO6QfAPToOgSXOB\\nixI3CYB1Q8qchXqfN2ZVMz4jK9mcXzwEmZzh2Ghys3AibgueKUl3cHbVpDGC0M7q\\nvGQEhH+cIfdlCt4RykphhUMW/EAnWJWlEpS/kwHdAoGAII75cbkMK7o+5QRXbdSl\\nuQze0bjVKcas5yzS/ZH8up7JswqghsiDxHcliGi9cknEpkYBgLLuVRmUcR1YKvf/\\n5OnhK97x1RdM+nbLNvx26kdriiPNGtDqRmi4msSz+xF+ZPtYiYbvnh39Anf2TflC\\nXC3G8Keb9Fc72qEQJf9lKC4=\\n-----END PRIVATE KEY-----\\n",
    "client_email": "firebase-adminsdk-fbsvc@psm-prjct.iam.gserviceaccount.com",
    "client_id": "109424588459456546282",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40psm-prjct.iam.gserviceaccount.com"
  }
  ''';

  static Future<String> getAccessToken() async {
    // Если токен есть и еще не истек, возвращаем его
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }

    try {
      final serviceAccount = jsonDecode(_serviceAccountJson);

      // Создаем JWT
      final now = DateTime.now();
      final expiry = now.add(Duration(minutes: 55));

      final header = base64Url.encode(utf8.encode(jsonEncode({
        'alg': 'RS256',
        'typ': 'JWT'
      })));

      final payload = base64Url.encode(utf8.encode(jsonEncode({
        'iss': serviceAccount['client_email'],
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
        'aud': serviceAccount['token_uri'],
        'exp': expiry.millisecondsSinceEpoch ~/ 1000,
        'iat': now.millisecondsSinceEpoch ~/ 1000
      })));

      // Для подписи JWT нужна библиотека, но для простоты можно получить токен через HTTP
      // Давай упростим и получим токен по-другому

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': _createJWT(serviceAccount, now, expiry),
        }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
        return _accessToken!;
      } else {
        throw Exception('Ошибка получения токена: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ Ошибка получения OAuth2 токена: $e');
      rethrow;
    }
  }

  static String _createJWT(Map<String, dynamic> serviceAccount, DateTime now, DateTime expiry) {
    // Это упрощенная версия, на практике нужна библиотека для создания JWT
    // Для тестирования можно использовать полученный токен через Firebase CLI
    return '';
  }

  // Альтернативный метод - получи токен через Firebase CLI один раз
  static Future<String> getAccessTokenViaCLI() async {
    // ВСТАВЬ СЮДА ТВОЙ ПОЛУЧЕННЫЙ ACCESS TOKEN
    return 'ya29.c.c0AZ1aNiVALhXCDlC9BKK3E76i-kY52lTvnL6LuvSc5fIX378oKaFHCWVLk97zdBXJY0BsbiCncB4lPIbruXTZeHL2w0B51d1oFox64sH-lJk2AfBa9SzsX49O6R6A1ToBDIuB9BnDE-qEhQS-vRIXOH9-Ylc1z5T07XLZeCBjFAbhYy1_4BQxR1mg1FWQONitOISBdCFMyknO8Cm2ZrZRvTAhdMKzbCpimmacEU4KSOEd9SNNbbEVceIHgD-NxoxTTVZnaP-8jaJdZLdt1bEeT8yOxS_lGh0ayWnvmTFWLPYZs83Fb9m6C1JAkR0eNmvgRYgtD-TlcBkCMTAr2EGUalNZD2SCk3VCWtNe7PB4ZIeYhcNB4Q9nSCaTbyeGlAtsekHjfwT399DO0e_q6JtZed2M6XJvtFmutcIVo92BmJzZxyUki73dsFryv1-4kOR7zjVz79jdFl5dUrBwmB9cFFqmYJdr3lj-j9RkY3b7F8nwm8amSwOW4j2cd0JtU5bbMy3xw1f88WljprvkY5l8F-QbFlyIjwqciq3sOnmh5df7qtt1MZhvJnlw0mbMs4Stm6_M-8Si_wpQZV6tpkXWSB8Oo0U7euqFerRJRXVn4kxx7MFadByWvpOdx2VOekcylcybUsfnut5Ou40Q30RXUOjcjlpdznxSuJ8pvnuUpXvOWb3hJ4dr-Qse3y5ntMJuwh2JQbX9c97604ecul6Mw3-gz9p5i36x7ZfXIgRlhVY--c22bQZ88MdFc6lR4o73f73Ibhfrfs8cxMZ7XlfbodfJ9pMhOlyqmax749F_Sm4uVcvIdU_c119W6q2q5x9mlo2dVhBjIrvaxXstk4bXUhinFtsvqZapmiSnbM1yko6zZBMcjVq5snIUVyzr-bcgF-qSF-zzhqvmdc_YdW0jamMr_w6Xfhv78QXupWqU11q4fqmmMXuUlh8cp1Q25nvfkdFUipsSMihZ8osa6rlqyuxS11umFBVO4Bm3IXF_7h5O-cnIuWZxcgo';
  }
}