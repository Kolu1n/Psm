const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { google } = require('googleapis');

admin.initializeApp();

// Получение Access Token
exports.getAccessToken = functions.https.onRequest(async (req, res) => {
  try {
    // Проверяем аутентификацию
    const idToken = req.headers.authorization?.split('Bearer ')[1];

    if (!idToken) {
      return res.status(401).json({ error: 'Не авторизован' });
    }

    // Верифицируем токен
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // Получаем Access Token
    const accessToken = await getGoogleAccessToken();

    res.json({
      access_token: accessToken,
      expires_in: 3600,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Отправка уведомлений
exports.sendPushNotification = functions.https.onRequest(async (req, res) => {
  try {
    const { tokens, title, body, data } = req.body;

    const message = {
      notification: { title, body },
      data: data || {},
      tokens: tokens
    };

    const response = await admin.messaging().sendEachForMulticast(message);

    res.json({
      successCount: response.successCount,
      failureCount: response.failureCount,
      results: response.responses
    });

  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

// Получение Access Token для Google API
async function getGoogleAccessToken() {
  const key = require('./service-account-key.json'); // Сервисный аккаунт
  const jwtClient = new google.auth.JWT(
    key.client_email,
    null,
    key.private_key,
    ['https://www.googleapis.com/auth/firebase.messaging']
  );

  const tokens = await jwtClient.authorize();
  return tokens.access_token;
}