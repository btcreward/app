import 'dart:math' as math;

import 'package:bitcoin_cloud_mining/providers/auth_provider.dart';
import 'package:bitcoin_cloud_mining/utils/storage_utils.dart';
import 'package:bitcoin_cloud_mining/widgets/login_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _pulseAnimation;
  bool _isNavigating = false;

  // Add primary color
  late Color primaryColor;

  void _stopAnimations() {
    _mainController.stop();
    _rotationController.stop();
    _pulseController.stop();
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // Start auth check immediately - no delay!
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final token = await StorageUtils.getToken();

      if (token == null) {
        // No token = not logged in, show login after brief animation
        // Give 1.5 seconds for the splash animation to show
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          _showLoginDialog();
        }
        return;
      }

      // Token exists - verify and navigate immediately
      if (!mounted || !context.mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initializeAuth();
      final currentToken = await authProvider.getToken();

      if (currentToken != null && authProvider.isAuthenticated) {
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          _stopAnimations();
          Navigator.of(context).pushReplacementNamed('/navigation');
        }
      } else {
        if (mounted && !_isNavigating) {
          _isNavigating = true;
          _showLoginDialog();
        }
      }
    } catch (e) {
      if (mounted && !_isNavigating) {
        _isNavigating = true;
        _showLoginDialog();
      }
    }
  }

  void _initializeAnimations() {
    // Shortened animation duration for faster startup
    const duration = Duration(seconds: 2);

    // Main controller for fade and scale
    _mainController = AnimationController(
      duration: duration,
      vsync: this,
    );

    // Rotation controller (continuous)
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _rotationController.repeat();

    // Pulse controller (continuous)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseController.repeat(reverse: true);

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Scale animation
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Rotation animation
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.linear,
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _mainController.forward();
  }

  void _showLoginDialog() {
    if (!mounted) return;
    _stopAnimations();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginDialog(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
              Color.fromRGBO(66, 165, 245, 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background animated circles
              ...List.generate(5, (index) {
                final random = math.Random();
                final size = random.nextDouble() * 100 + 50;
                final left =
                    random.nextDouble() * MediaQuery.of(context).size.width;
                final top =
                    random.nextDouble() * MediaQuery.of(context).size.height;

                return Positioned(
                  left: left,
                  top: top,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Container(
                            width: size,
                            height: size,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(255, 255, 255, 0.05),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: Listenable.merge(
                            [_rotationController, _pulseController]),
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value,
                            child: Transform.scale(
                              scale: _pulseAnimation.value,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Color.fromRGBO(
                                          primaryColor.r.toInt(),
                                          primaryColor.g.toInt(),
                                          primaryColor.b.toInt(),
                                          0.15),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromRGBO(
                                              primaryColor.r.toInt(),
                                              primaryColor.g.toInt(),
                                              primaryColor.b.toInt(),
                                              0.5),
                                          blurRadius: 30,
                                          spreadRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.currency_bitcoin,
                                            size: 120,
                                            color: Colors.amber,
                                          ),
                                        ),
                                        ...List.generate(4, (index) {
                                          final angle = (index * math.pi / 2) +
                                              _rotateAnimation.value;
                                          return Positioned(
                                            left: 90 + math.cos(angle) * 60,
                                            top: 90 + math.sin(angle) * 60,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Color.fromRGBO(
                                                    primaryColor.r.toInt(),
                                                    primaryColor.g.toInt(),
                                                    primaryColor.b.toInt(),
                                                    0.5),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Color.fromRGBO(
                                                        primaryColor.r.toInt(),
                                                        primaryColor.g.toInt(),
                                                        primaryColor.b.toInt(),
                                                        0.3),
                                                    blurRadius: 10,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Animated Title
                    RepaintBoundary(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _mainController,
                              curve: const Interval(0.3, 0.7,
                                  curve: Curves.easeOut),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: Tween<double>(begin: 1.0, end: 1.05)
                                    .animate(_pulseController)
                                    .value,
                                child: ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.amber,
                                      Colors.orange,
                                      Colors.amber.shade300,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    transform: GradientRotation(
                                        _rotateAnimation.value * 0.5),
                                  ).createShader(bounds),
                                  child: Stack(
                                    children: [
                                      // Shadow Text
                                      Text(
                                        'BTC Reward',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28, // reduced from 40
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromRGBO(
                                              0, 0, 0, 0.3),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      // Main Text
                                      Text(
                                        'BTC Reward',
                                        style: GoogleFonts.poppins(
                                          fontSize: 28, // reduced from 40
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                          shadows: [
                                            const Shadow(
                                              color: Color.fromRGBO(
                                                  255, 193, 7, 0.5),
                                              offset: Offset(0, 2),
                                              blurRadius: 15,
                                            ),
                                            Shadow(
                                              color: Color.fromRGBO(
                                                  primaryColor.r.toInt(),
                                                  primaryColor.g.toInt(),
                                                  primaryColor.b.toInt(),
                                                  0.3),
                                              offset: const Offset(2, 0),
                                              blurRadius: 10,
                                            ),
                                            const Shadow(
                                              color: Color.fromRGBO(
                                                  255, 255, 255, 0.3),
                                              offset: Offset(-2, -2),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Shine Effect
                                      Positioned.fill(
                                        child: RepaintBoundary(
                                          child: AnimatedBuilder(
                                            animation: _rotationController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: _rotateAnimation.value,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Color.fromRGBO(
                                                            primaryColor.r
                                                                .toInt(),
                                                            primaryColor.g
                                                                .toInt(),
                                                            primaryColor.b
                                                                .toInt(),
                                                            0),
                                                        Color.fromRGBO(
                                                            primaryColor.r
                                                                .toInt(),
                                                            primaryColor.g
                                                                .toInt(),
                                                            primaryColor.b
                                                                .toInt(),
                                                            0.3),
                                                        Color.fromRGBO(
                                                            primaryColor.r
                                                                .toInt(),
                                                            primaryColor.g
                                                                .toInt(),
                                                            primaryColor.b
                                                                .toInt(),
                                                            0),
                                                      ],
                                                      stops: const [
                                                        0.0,
                                                        0.5,
                                                        1.0
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Animated Subtitle
                    RepaintBoundary(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _mainController,
                              curve: const Interval(0.4, 0.8,
                                  curve: Curves.easeOut),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Text(
                                'Start Mining Today',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  color: Color.fromRGBO(
                                      primaryColor.r.toInt(),
                                      primaryColor.g.toInt(),
                                      primaryColor.b.toInt(),
                                      0.8),
                                  letterSpacing: 1.2,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black26,
                                      offset: Offset(1, 1),
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
