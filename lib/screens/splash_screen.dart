import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_study/screens/dashboard_screen.dart';
import 'package:focus_study/screens/welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // App theme colors
  static const Color _primaryBlue = Color(0xFF5394ED);
  static const Color _darkBlue = Color(0xFF1A52CE);
  static const Color _background = Color(0xFFF0F3FF);
  static const Color _trackBlue = Color(0xFFDCE6F8);

  bool _visible = false;

  static const _minSplashTime = Duration(milliseconds: 4000);
  static const _fadeInDuration = Duration(milliseconds: 1000);
  static const _fadeOutDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();

    // Trigger the fade-in after the first frame is drawn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });

    _goNext();
  }

  Future<void> _goNext() async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
      Future.delayed(_minSplashTime),
    ]);

    final prefs = results[0] as SharedPreferences;
    final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;

    if (!mounted) return;

    final Widget next = hasOnboarded
        ? const DashboardScreen()
        : const WelcomeScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: _fadeOutDuration,
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _fadeInDuration,
              curve: Curves.easeIn,
              child: AnimatedScale(
                scale: _visible ? 1 : 0.92,
                duration: _fadeInDuration,
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/graduate.png', width: 170, height: 200),
                    const Text(
                      'FocusForge',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: _darkBlue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'TRACK YOUR TIME\nSEE YOUR PROGRESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        height: 1.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: _minSplashTime,
                          curve: Curves.easeInOut,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 4,
                                backgroundColor: _trackBlue,
                                valueColor: const AlwaysStoppedAnimation(
                                  _primaryBlue,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
