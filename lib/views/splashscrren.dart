import 'package:flutter/material.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vchat/views/chat_screen.dart';
import 'package:vchat/views/login_page.dart';
import 'package:vchat/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _supabase = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await NotificationService().init();

    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.initialSession) {
        _navigateBasedOnAuth(session);
      }
    });

    final currentSession = _supabase.auth.currentSession;
    _navigateBasedOnAuth(currentSession);
  }

  void _navigateBasedOnAuth(Session? session) {
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => session != null ? ChatScreen() : LoginPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/chat.gif',
              width: 300,
              height: 400,
            ),
          ],
        ),
      ),
    );
  }
}