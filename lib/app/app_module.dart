import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/inventory_entry.dart';
import '../services/drive_service.dart';
import '../services/inventory_service.dart';
import '../services/locale_provider.dart';
import '../pages/modular_inventory_home.dart';

class AppModule extends Module {
  @override
  void binds(Injector i) {
    // Core services - singleton instances
    i.addSingleton<DriveService>(() => DriveService.instance);
    i.addLazySingleton<InventoryService>(InventoryService.new);
    i.addSingleton<LocaleProvider>(LocaleProvider.new);
    
    // Hive boxes - lazy singletons
    i.addLazySingleton<Box<InventoryEntry>>(() => Hive.box<InventoryEntry>('entries'));
    i.addLazySingleton<Box>(() => Hive.box('settings'));
  }

  @override
  void routes(RouteManager r) {
    r.child('/', child: (context) => const AppHomePage());
  }
}

// Simple wrapper for locale management
class AppHomePage extends StatelessWidget {
  const AppHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Modular.get<LocaleProvider>();
    final currentLocale = Localizations.localeOf(context);
    
    return ModularInventoryHome(
      currentLocale: currentLocale,
      setLocale: localeProvider.changeLocale,
    );
  }
}