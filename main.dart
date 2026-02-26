import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psm/fcm_service.dart';
import 'package:psm/pages/Main-S.dart';
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
import 'package:psm/pages/ipk_worker_task_screen.dart';
import 'package:psm/pages/Sett.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late String initialRoute;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Фиксация ориентации
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Системный UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Firebase.initializeApp();
  await FCMService.initialize();

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final userSpecialization = prefs.getInt('userSpecialization') ?? 0;
  final theme = prefs.getInt('theme') ?? 0;

  // Определяем начальный роут
  if (isLoggedIn && userSpecialization > 0) {
    switch (userSpecialization) {
      case 4: initialRoute = '/MasterScreen'; break;
      case 5: initialRoute = '/IPKScreen'; break;
      case 1: initialRoute = '/Sborka'; break;
      case 2: initialRoute = '/Montasch'; break;
      case 3: initialRoute = '/Pacet'; break;
      default: initialRoute = '/specialization'; break;
    }
  } else {
    initialRoute = theme == 0 ? '/MS_W' : '/MS_B';
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        title: 'PSM — Управление задачами',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC2626),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFFAFBFC),
          fontFamily: 'GolosR',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFDC2626),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF0F0F1A),
          fontFamily: 'GolosR',
        ),
        initialRoute: initialRoute,
        routes: {
          '/MS_W': (_) => const MainS_W(),
          '/MS_B': (_) => const MainS_B(),
          '/Whod': (_) => const Whod(),
          '/Reg': (_) => const Reg(),
          '/VerifyEmail': (_) => const VerifyEmailScreen(),
          '/specialization': (_) => const SpecializationScreen(),
          '/MasterScreen': (_) => MasterS(),
          '/IPKScreen': (_) =>  IPKScreen(),
          '/CreateTask': (_) => const CreateTaskScreen(),
          '/CreateIPKTask': (_) => const CreateIPKTaskScreen(),
          '/Sborka': (_) => const SborkaScreen(),
          '/Montasch': (_) => const MontaschScreen(),
          '/Pacet': (_) => const PacetScreen(),
          '/IPKMontasch': (_) => const IPKMontaschScreen(),
          '/IPKSborka': (_) => const IPKSborkaScreen(),
          '/IPKPacet': (_) => const IPKPacetScreen(),
          '/TaskPhotoScreen': (_) => const TaskPhotoScreen(),
          '/SendPushScreen': (_) => SendPushScreen(),
          '/Sett': (_) => Sett(),

          '/IPKWorkerTask': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return IPKWorkerTaskScreen(
              orderNumber: args['orderNumber'],
              collectionName: args['collectionName'],
              taskId: args['taskId'], // 🔴 Изменено с taskIndex
              task: args['task'],
              taskNumber: args['taskNumber'],
            );
          },

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
              taskId: args['taskId'], // 🔴 Изменено с taskIndex
            );
          },
          '/TaskPhotoScreen': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return TaskPhotoScreen(); // Аргументы передаются через ModalRoute
          },

        },
      ),
    );
  }
}