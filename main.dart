import 'package:flutter/material.dart';
import 'package:psm/pages/Main-S.dart';
import 'package:psm/pages/Sett.dart';
import 'package:psm/pages/TaskPhotoScreen.dart';
import 'package:psm/pages/Whod-Reg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:psm/pages/Reg.dart';
import 'package:psm/pages/verify_email_screen.dart';
import 'package:psm/pages/specialization_screen.dart';
import 'package:psm/pages/master.dart';
import 'package:psm/pages/CreateTaskScreen.dart';
import 'package:psm/pages/SborkaScreen.dart';
import 'package:psm/pages/MontaschScreen.dart';
import 'package:psm/pages/PacetScreen.dart';
import 'package:psm/pages/TasksScreen.dart';
import 'package:psm/pages/TaskDetailScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

late String ProverkaThem;
int theme = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userSpecialization = prefs.getInt('userSpecialization') ?? 0;
  theme = prefs.getInt('theme') ?? 0;

  if (theme == 0)
    ProverkaThem = '/MS_W';
  else
    ProverkaThem = '/MS_B';

  // Если пользователь уже авторизован, перенаправляем на соответствующий экран
  if (isLoggedIn && userSpecialization > 0) {
    switch (userSpecialization) {
      case 4:
        ProverkaThem = '/MasterScreen';
        break;
      case 1:
        ProverkaThem = '/Sborka';
        break;
      case 2:
        ProverkaThem = '/Montasch';
        break;
      case 3:
        ProverkaThem = '/Pacet';
        break;
      default:
        ProverkaThem = '/specialization';
        break;
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: ProverkaThem,
      routes: {
        '/MS_W': (context) => MainS_W(),
        '/MS_B': (context) => MainS_B(),
        '/Sett': (context) => Sett(),
        '/Whod': (context) => Whod(),
        '/Reg': (context) => Reg(),
        '/VerifyEmail': (context) => VerifyEmailScreen(),
        '/specialization': (context) => SpecializationScreen(),
        '/MasterScreen': (context) => MasterS(),
        '/CreateTask': (context) => CreateTaskScreen(),
        '/Sborka': (context) => SborkaScreen(),
        '/Montasch': (context) => MontaschScreen(),
        '/Pacet': (context) => PacetScreen(),
        '/TaskPhotoScreen': (context) => TaskPhotoScreen(),
        '/Tasks': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TasksScreen(
            orderNumber: args['orderNumber'],
            collectionName: args['collectionName'],
            screenTitle: args['screenTitle'],
          );
        },
        '/TaskDetail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return TaskDetailScreen(
            task: args['task'],
            taskNumber: args['taskNumber'],
            orderNumber: args['orderNumber'],
            collectionName: args['collectionName'],
            taskIndex: args['taskIndex'],
          );
        },
      },
    );
  }
}