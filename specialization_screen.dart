import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SpecializationScreen extends StatefulWidget {
  const SpecializationScreen({Key? key}) : super(key: key);
  @override
  State<SpecializationScreen> createState() => _SpecializationScreenState();
}

class _SpecializationScreenState extends State<SpecializationScreen> {
  final int passwordSborka = 123456;
  final int passwordMontazch = 654321;
  final int passwordPacket = 111222;
  final int passwordITM = 333444;
  final int passwordIPK = 555666;

  String userName = 'Пользователь';
  String userEmail = '';
  bool isLoading = true;

  double getScaleFactor(BuildContext context) {
    final d = MediaQuery.of(context).size.shortestSide;
    if (d < 300) return 0.65;
    if (d < 350) return 0.75;
    if (d < 400) return 0.85;
    if (d < 450) return 0.9;
    if (d < 500) return 0.95;
    if (d < 600) return 1.0;
    if (d < 700) return 1.1;
    if (d < 800) return 1.2;
    if (d < 1000) return 1.3;
    return 1.4;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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
      case 'Сборщик':
        return 1;
      case 'Монтажник':
        return 2;
      case 'Пакетирование':
        return 3;
      case 'ИТМ':
        return 4;
      case 'ИПК':
        return 5;
      default:
        return 0;
    }
  }

  int _getSpecPassword(String spec) {
    switch (spec) {
      case 'Сборщик':
        return passwordSborka;
      case 'Монтажник':
        return passwordMontazch;
      case 'Пакетирование':
        return passwordPacket;
      case 'ИТМ':
        return passwordITM;
      case 'ИПК':
        return passwordIPK;
      default:
        return 0;
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

  void _showPasswordDialog(String spec) {
    final TextEditingController ctrl = TextEditingController();
    final scale = getScaleFactor(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20 * scale)),
        child: Container(
          padding: EdgeInsets.all(20 * scale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Введите код доступа', style: TextStyle(fontSize: 20 * scale, fontFamily: 'GolosB'), textAlign: TextAlign.center),
              SizedBox(height: 15 * scale),
              Text('Для специализации "$spec"', style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR'), textAlign: TextAlign.center),
              SizedBox(height: 20 * scale),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: '6-значный код',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10 * scale)),
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(horizontal: 15 * scale, vertical: 12 * scale),
                ),
                style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosR'),
                onSubmitted: (_) => _onPassword(spec, ctrl.text.trim()),
              ),
              SizedBox(height: 25 * scale),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text('Отмена', style: TextStyle(color: Colors.grey, fontFamily: 'GolosR', fontSize: 16 * scale)),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10 * scale)),
                      ),
                      onPressed: () => _onPassword(spec, ctrl.text.trim()),
                      child: Text('Вход', style: TextStyle(color: Colors.white, fontFamily: 'GolosR', fontSize: 16 * scale)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPassword(String spec, String raw) {
    final entered = raw.trim();
    final expected = _getSpecPassword(spec).toString();
    if (entered == expected && expected != '0') {
      Navigator.pop(context);
      _processSpec(spec);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Неверный код доступа'), backgroundColor: Colors.red));
    }
  }

  Future<void> _processSpec(String spec) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Пользователь не авторизован')));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
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
      case 'ИТМ':
        Navigator.pushReplacementNamed(context, '/MasterScreen');
        break;
      case 'ИПК':
        Navigator.pushReplacementNamed(context, '/IPKScreen');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/master');
    }
  }

  Widget _buildButton(String spec) {
    final scale = getScaleFactor(context);
    return Container(
      width: double.infinity,
      height: 55 * scale,
      margin: EdgeInsets.only(bottom: 15 * scale),
      child: ElevatedButton(
        onPressed: () => _showPasswordDialog(spec),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide(color: Colors.red, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15 * scale)),
          elevation: 4,
        ),
        child: Text(spec, style: TextStyle(fontSize: 18 * scale, fontFamily: 'GolosB', color: Colors.red)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = getScaleFactor(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20 * scale),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 85 * scale),
                  child: Image.asset('assets/PSM.png', width: 250 * scale, height: 50 * scale,
                      errorBuilder: (_, __, ___) => Icon(Icons.business_center, size: 50 * scale, color: Colors.red)),
                ),
                isLoading
                    ? CircularProgressIndicator()
                    : Column(
                  children: [
                    Text('Добро пожаловать, $userName!',
                        style: TextStyle(fontSize: 22 * scale, fontFamily: 'GolosB', color: Colors.black),
                        textAlign: TextAlign.center),
                    SizedBox(height: 15 * scale),
                    Text('Выберите вашу специализацию:',
                        style: TextStyle(fontSize: 16 * scale, fontFamily: 'GolosR', color: Colors.black54),
                        textAlign: TextAlign.center),
                  ],
                ),
                SizedBox(height: 40 * scale),
                _buildButton('Сборщик'),
                _buildButton('Монтажник'),
                _buildButton('Пакетирование'),
                _buildButton('ИТМ'),
                _buildButton('ИПК'),
                SizedBox(height: 30 * scale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}