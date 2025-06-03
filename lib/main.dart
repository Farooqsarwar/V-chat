import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';  // Add the import for GetX
import 'package:vchat/services/notification_service.dart';
import 'package:vchat/views/chat_screen.dart';
import 'package:vchat/views/splashscrren.dart';
import 'controller/user_controller.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://krtjekawgovqjlsqufgs.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtydGpla2F3Z292cWpsc3F1ZmdzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2NjUxNzUsImV4cCI6MjA1OTI0MTE3NX0.oGOS0TS1QRARqtC94gcosKZlOdvfIYB0exrzoVCHu6M',  // Replace with your Supabase Anon Key
  );
  await NotificationService().init();
  // Initialize the UserController
  Get.put(UserController());
  Get.put(NotificationService());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp (
      title: 'V chat',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Use a dynamic home based on user session
      initialRoute: '/',
      getPages: [
        GetPage(name: '/chat', page: () => ChatScreen()),
      ],
    );
  }
}