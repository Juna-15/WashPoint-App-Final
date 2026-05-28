import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import 'main_nav.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    _animationController.forward();

    _routeBasedOnSession();
  }

  Future<void> _routeBasedOnSession() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      debugPrint("User sudah login, menuju ke Home");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNav()),
      );
    } else {
      debugPrint("User belum login, menuju ke Sign In");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: size.width,
            height: size.height,
            child: FadeTransition(
              opacity: _animation,
              child: Image.asset(
                'assets/images/splash_full.png',
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.12,
            left: size.width * 0.25,
            right: size.width * 0.25,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const LinearProgressIndicator(
                minHeight: 6.0,
                backgroundColor: Color(0xFFD3EAF5),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B6DF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
