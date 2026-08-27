import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'controller.dart';
import 'home_page.dart';

class ServiceManagerApp extends StatefulWidget {
  const ServiceManagerApp({
    required this.controller,
    required this.onSetLaunchAtLogin,
    this.onOpenLogDirectory,
    this.onExit,
    this.onLocalizationsChanged,
    this.showLaunchAtLogin = true,
    super.key,
  });

  final ServiceController controller;
  final Future<void> Function(bool enabled) onSetLaunchAtLogin;
  final Future<void> Function()? onOpenLogDirectory;
  final Future<void> Function()? onExit;
  final void Function(AppLocalizations localizations)? onLocalizationsChanged;
  final bool showLaunchAtLogin;

  @override
  State<ServiceManagerApp> createState() => ServiceManagerAppState();
}

class ServiceManagerAppState extends State<ServiceManagerApp> {
  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<void>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.controller.changes.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  Future<void> confirmExit() async {
    final context = navigatorKey.currentContext;
    if (context == null || widget.onExit == null) return;
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.exitTitle),
        content: Text(localizations.exitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.exit),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onExit!();
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = widget.controller.settings.localeCode;
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Service Manager',
      debugShowCheckedModeBanner: false,
      locale: localeCode == null ? null : Locale(localeCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff176b5b),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff4f6f3),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6fc5af),
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        controller: widget.controller,
        onSetLaunchAtLogin: widget.onSetLaunchAtLogin,
        onOpenLogDirectory: widget.onOpenLogDirectory,
        onExit: widget.onExit == null ? null : confirmExit,
        onLocalizationsChanged: widget.onLocalizationsChanged,
        showLaunchAtLogin: widget.showLaunchAtLogin,
      ),
    );
  }
}
