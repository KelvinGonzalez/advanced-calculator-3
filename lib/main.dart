import 'package:advanced_calculator_3/models/app_state.dart';
import 'package:advanced_calculator_3/pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: String.fromEnvironment("apiKey"),
          projectId: String.fromEnvironment("projectId"),
          messagingSenderId: String.fromEnvironment("messagingSenderId"),
          appId: String.fromEnvironment("appId")));
  runApp(MyApp(preferences: preferences));
}

class MyApp extends StatelessWidget {
  final SharedPreferences preferences;

  const MyApp({super.key, required this.preferences});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => AppCubit(preferences),
        child: const HomePage(),
      ),
    );
  }
}
