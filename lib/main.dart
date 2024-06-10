import 'package:flutter/material.dart';
import 'package:cart_ray/pages/home_page.dart';
import 'package:cart_ray/utils/constants.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('events_box');
  Constants.prefs = await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Brazilian Portuguese
      ],
      debugShowCheckedModeBanner: false, //if set to false, disables the debug banner
      home: const HomePage(),
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white10, // Set up the app bar background color
        ),
      ),
      routes: {
        HomePage.routeName : (context)=> const HomePage(), // Set up the route for the home page
      },
    );
  }
}