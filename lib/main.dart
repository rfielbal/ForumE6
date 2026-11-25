import 'package:flutter/material.dart';
import 'forum_controller.dart';
import 'pages/accueil_page.dart';
import 'theme.dart';

void main() => runApp(const ForumApp());

class ForumApp extends StatefulWidget {
  const ForumApp({super.key, this.controller});
  // Le paramètre facultatif permet de tester l'application sans le réseau.
  final ForumController? controller;
  @override
  State<ForumApp> createState() => _ForumAppState();
}

class _ForumAppState extends State<ForumApp> {
  late final ForumController controller;
  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? ForumController();
    controller.chargerMessages();
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Forum',
    debugShowCheckedModeBanner: false,
    theme: creerTheme(),
    home: AccueilPage(controller: controller),
  );
}
