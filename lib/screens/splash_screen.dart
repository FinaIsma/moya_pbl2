import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// ─── ROUTES ─────────────────────────────────────────────────────
const String _routeUserDashboard = '/dashboard';               // User biasa
const String _routePsychDashboard = '/psychologist-dashboard'; // Psikolog
const String _routeLoggedOut     = '/opening';                // Belum login

// ─── ASSET PATHS ────────────────────────────────────────────────
const String _icon1Path = 'assets/images/icon1.png';
const String _iconsCombinedPath = 'assets/images/icons.png';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ─── Content animations ──────────────────────────────────────
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _iconsController;
  late AnimationController _subtitleController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _iconsFade;
  late Animation<double> _subtitleFade;

  // ─── Loading bar ─────────────────────────────────────────────
  late AnimationController _loadingController;
  late Animation<double> _loadingProgress;

  late AnimationController _floatingController;
  late Animation<double> _floatingAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _iconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeOut),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    // Loading bar — 3 detik total
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _loadingProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));

    // Logo & loading bar mulai bersamaan
    _logoController.forward();
    _logoController.forward().then((_) {
    _pulseController.repeat(reverse: true);
  });
  
    _loadingController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _iconsController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _subtitleController.forward();

    // Jalankan cek session + tunggu loading bar — keduanya paralel
    // Navigate setelah KEDUANYA selesai
    final results = await Future.wait([
      _checkSession(),                          // Sekarang mengembalikan string route tujuan
      _loadingController.forward(              // tunggu bar penuh
        from: _loadingController.value,
      ).orCancel.then((_) => true).catchError((_) => true),
    ]);

    if (!mounted) return;

    final String targetRoute = results[0] as String;
    Navigator.pushReplacementNamed(
      context,
      targetRoute,
    );
  }

  Future<void> _saveFcmToken(String uid, String collection) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection(collection)
        .doc(uid)
        .set({'fcm_token': token}, SetOptions(merge: true));
  }

 Future<String> _checkSession() async {
  User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return _routeLoggedOut;

    try {
      // Cek collection users (user biasa)
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        await _saveFcmToken(user.uid, 'users');
        return _routeUserDashboard;
      }

        print('userDoc.exists: ${userDoc.exists}');

      // Cek collection psychologists
      QuerySnapshot psychQuery = await FirebaseFirestore.instance
          .collection('psychologists')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

          print('psychQuery count: ${psychQuery.docs.length}');

      if (psychQuery.docs.isNotEmpty) {
        final psychDocId = psychQuery.docs.first.id;

        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await FirebaseFirestore.instance
              .collection('psychologists')
              .doc(psychDocId)
              .set({
            'fcm_token': token,
          }, SetOptions(merge: true));
        }

        return _routePsychDashboard;
      }

      // Tidak ditemukan di keduanya
      await FirebaseAuth.instance.signOut();
      return _routeLoggedOut;

    } catch (e) {
      return _routeLoggedOut;
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _iconsController.dispose();
    _subtitleController.dispose();
    _loadingController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Column(
            children: [
              const SizedBox(height: 48),

              // ── Logo + Loading Bar ─────────────────────────
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    children: [

                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Image.asset(
                          _icon1Path,
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5CBCB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.sentiment_satisfied_alt,
                              color: Color(0xFF748DAE),
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Animated Loading Bar
                      AnimatedBuilder(
                        animation: _loadingProgress,
                        builder: (context, _) {
                          return SizedBox(
                            width: 40,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // Track
                                  Container(
                                    width: 40,
                                    height: 4,
                                    color: const Color(0xFFE4ECF0),
                                  ),
                                  // Fill
                                  Positioned(
                                    child: Container(
                                      width: 40 * _loadingProgress.value,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF9ECAD6),
                                            Color(0xFF748DAE),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Glow Dot
                                  Positioned(
                                    left: (40 * _loadingProgress.value) - 4,
                                    top: -2,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF9ECAD6).withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Headline ────────────────────────────────────
              FadeTransition(
                opacity: _textFade,
                child: SlideTransition(
                  position: _textSlide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Feel, Reflect,\nUnderstand',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A2E),
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ── Scattered Icons ──────────────────────────────
              FadeTransition(
                opacity: _iconsFade,
                child: SizedBox(
                  width: size.width,
                  height: size.width * 0.82,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _floatingAnimation,
                      builder: (_, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingAnimation.value),
                          child: child,
                        );
                      },
                      child: Image.asset(
                        _iconsCombinedPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Subtitle ────────────────────────────────────
              FadeTransition(
                opacity: _subtitleFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Every emotion tells a story.\nTake time to understand yours.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5A6A7E),
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}