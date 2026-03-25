import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'screens/components_screen.dart';

void main() {
  runApp(const WidgetCatalogApp());
}

class WidgetCatalogApp extends StatefulWidget {
  const WidgetCatalogApp({super.key});

  @override
  State<WidgetCatalogApp> createState() => _WidgetCatalogAppState();
}

class _WidgetCatalogAppState extends State<WidgetCatalogApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenLeaf Widget Catalog',
      debugShowCheckedModeBanner: false,
      theme: GreenLeafTheme.light(),
      darkTheme: GreenLeafTheme.dark(),
      themeMode: _themeMode,
      home: ComponentsScreen(
        onToggleTheme: toggleTheme,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}
