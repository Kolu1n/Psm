import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:psm/pages/Main-S.dart';
import 'package:psm/pages/Sett.dart';
import 'package:psm/pages/Whod-Reg.dart';
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
import 'package:psm/pages/TaskPhotoScreen.dart';
import 'package:psm/pages/SendPushScreen.dart';
import 'package:psm/pages/ipk_screen.dart';
import 'package:psm/pages/ipk_montasch_screen.dart';
import 'package:psm/pages/ipk_sborka_screen.dart';
import 'package:psm/pages/ipk_pacet_screen.dart';
import 'package:psm/pages/create_ipk_task_screen.dart';
import 'package:psm/pages/ipk_worker_task_screen.dart'; // ✅ Новый экран
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/fcm_service.dart';

late String initialRoute;
int theme = 0;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FCMService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userSpecialization = prefs.getInt('userSpecialization') ?? 0;
  theme = prefs.getInt('theme') ?? 0;

  if (theme == 0) {
    initialRoute = '/MS_W';
  } else {
    initialRoute = '/MS_B';
  }

  if (isLoggedIn && userSpecialization > 0) {
    switch (userSpecialization) {
      case 4:
        initialRoute = '/MasterScreen';
        break;
      case 5:
        initialRoute = '/IPKScreen';
        break;
      case 1:
        initialRoute = '/Sborka';
        break;
      case 2:
        initialRoute = '/Montasch';
        break;
      case 3:
        initialRoute = '/Pacet';
        break;
      default:
        initialRoute = '/specialization';
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
      initialRoute: initialRoute,
      routes: {
        '/MS_W': (_) => MainS_W(),
        '/MS_B': (_) => MainS_B(),
        '/Sett': (_) => Sett(),
        '/Whod': (_) => Whod(),
        '/Reg': (_) => Reg(),
        '/VerifyEmail': (_) => VerifyEmailScreen(),
        '/specialization': (_) => SpecializationScreen(),
        '/MasterScreen': (_) => MasterS(),
        '/IPKScreen': (_) => IPKScreen(),
        '/CreateTask': (_) => CreateTaskScreen(),
        '/CreateIPKTask': (_) => CreateIPKTaskScreen(),
        '/Sborka': (_) => SborkaScreen(),
        '/Montasch': (_) => MontaschScreen(),
        '/Pacet': (_) => PacetScreen(),
        '/IPKMontasch': (_) => IPKMontaschScreen(),
        '/IPKSborka': (_) => IPKSborkaScreen(),
        '/IPKPacet': (_) => IPKPacetScreen(),
        '/TaskPhotoScreen': (_) => TaskPhotoScreen(),
        '/SendPushScreen': (_) => SendPushScreen(),

        // ✅ Новый маршрут для ИТМ как рабочего персонала в ИПК-заданиях
        '/IPKWorkerTask': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return IPKWorkerTaskScreen(
            orderNumber: args['orderNumber'],
            collectionName: args['collectionName'],
            taskIndex: args['taskIndex'],
            task: args['task'],
            taskNumber: args['taskNumber'],
          );
        },

        // Маршруты с аргументами
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