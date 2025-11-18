import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../shared/services/locale_provider.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  late LocaleProvider _localeProvider;

  @override
  void initState() {
    super.initState();
    _localeProvider = Modular.get<LocaleProvider>();
    _localeProvider.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _localeProvider.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    setState(() {
      // Trigger rebuild when locale changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AA 4Step Inventory',
      debugShowCheckedModeBanner: false,
      locale: _localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('da'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        primarySwatch: Colors.blue,
      ),
      routerConfig: Modular.routerConfig,
    );
  }
}