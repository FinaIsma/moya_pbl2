import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── ROUTES ─────────────────────────────────────────────────────
const String _routeSignUp = '/register';
const String _routeSignIn = '/login';

// ─── ASSETS ─────────────────────────────────────────────────────
const String _topIconPath  = 'assets/images/icon1.png';
const String _illustration = 'assets/images/icons1.png'; // brain + clouds jadi 1 gambar

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {

  // ─── Fade-in animations ──────────────────────────────────────
  late AnimationController _topController;
  late AnimationController _textController;
  late AnimationController _btnController;
  late AnimationController _illustrationController;

  late Animation<double> _topFade;
  late Animation<double> _textFade;
  late Animation<Offset>  _textSlide;
  late Animation<double> _btnFade;
  late Animation<Offset>  _btnSlide;
  late Animation<double> _illustrationFade;
  late Animation<Offset>  _illustrationSlide;
  late AnimationController _floatingController;

  late Animation<double> _brainFloat;
  late Animation<double> _cloudLeftMove;
  late Animation<double> _cloudRightMove;
  late Animation<double> _textScale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startSequence();
  }

  void _initAnimations() {
    _topController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _topFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _topController, curve: Curves.easeOut),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutBack,
      ),
    );

    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _btnFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );
    _btnSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _btnController, curve: Curves.easeOut),
    );

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _illustrationFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeOut),
    );
    _illustrationSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _illustrationController, curve: Curves.easeOutBack),
    );

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _brainFloat = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    _cloudLeftMove = Tween<double>(
      begin: -12,
      end: 12,
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );

    _cloudRightMove = Tween<double>(
      begin: 12,
      end: -12,
    ).animate(
      CurvedAnimation(
        parent: _floatingController,
        curve: Curves.easeInOut,
      ),
    );
    _textScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutBack,
      ),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _topController.forward();

    await Future.delayed(const Duration(milliseconds: 350));
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _btnController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _illustrationController.forward();
  }

  @override
  void dispose() {
    _topController.dispose();
    _textController.dispose();
    _btnController.dispose();
    _illustrationController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Icon ──────────────────────────────────────
            const SizedBox(height: 40),
            FadeTransition(
              opacity: _topFade,
              child: Image.asset(
                _topIconPath,
                width: 72,
                height: 72,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CBCB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.sentiment_satisfied_alt,
                    color: Color(0xFF748DAE),
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // ── Headline + Subtitle ────────────────────────────
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: ScaleTransition(
                  scale: _textScale,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Column(
                      children: [
                      Text(
                        'Learn and\nGrow from\nYour Feelings',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1A2E),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Take a moment to reflect, track your emotions,\nand learn more about yourself every day.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5A6A7E),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),

            const SizedBox(height: 40),

            // ── Buttons ───────────────────────────────────────
            FadeTransition(
              opacity: _btnFade,
              child: SlideTransition(
                position: _btnSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      // Sign Up button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, _routeSignUp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9ECAD6),
                            foregroundColor: const Color(0xFF1A4A54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A4A54),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Already have an account? Sign In
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF1A1A2E),
                          ),
                          children: [
                            const TextSpan(
                                text: 'Already have an account? '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, _routeSignIn),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF748DAE),
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
            ),

            const Spacer(),

            // ── Bottom Illustration (1 gambar) ───────────────
            FadeTransition(
              opacity: _illustrationFade,
              child: SlideTransition(
                position: _illustrationSlide,
                child: SizedBox(
                  width: size.width,
                  height: size.width * 0.7,
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (_, __) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [

                          // cloud kiri
                          Transform.translate(
                            offset: Offset(_cloudLeftMove.value, 0),
                            child: Align(
                              alignment: const Alignment(-0.8, -0.65),
                              child: Image.asset(
                                'assets/images/cloud1.png',
                                width: 110,
                              ),
                            ),
                          ),

                          // cloud kanan
                          Transform.translate(
                            offset: Offset(_cloudRightMove.value, 0),
                            child: Align(
                              alignment: const Alignment(0.8,0.4),
                              child: Image.asset(
                                'assets/images/cloud2.png',
                                width: 110,
                              ),
                            ),
                          ),

                          // brain
                          Transform.translate(
                            offset: Offset(0, _brainFloat.value),
                            child: Image.asset(
                              'assets/images/icon2.png',
                              width: size.width * 0.65,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}


