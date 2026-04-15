import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── PASTE YOUR NEXT ROUTE HERE ────────────────────────────────
// Ganti '/login' dengan route halaman setelah splash
const String _nextRoute = '/login';

// ─── ASSET PATHS ────────────────────────────────────────────────
const String _icon1Path = 'assets/images/icon1.png';         // brain atas
const String _iconsPath = 'assets/images/icons.png';            // folder icons

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ─── Animation Controllers ──────────────────────────────────
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

  @override
  void initState() {
    super.initState();

    // Logo animation
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

    // Text animation
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

    // Icons animation
    _iconsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconsFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconsController, curve: Curves.easeOut),
    );

    // Subtitle animation
    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _iconsController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _subtitleController.forward();

    // Auto navigate after 2.8s total
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      Navigator.pushReplacementNamed(context, _nextRoute);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _iconsController.dispose();
    _subtitleController.dispose();
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
          child: Stack(
            children: [
              // ─── Main Column Content ──────────────────────────
              Column(
                children: [
                  const SizedBox(height: 48),

                  // ── Top Logo Icon ────────────────────────────
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Column(
                        children: [
                          Image.asset(
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
                          const SizedBox(height: 10),
                          // Garis pendek di bawah logo
                          Container(
                            width: 36,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD9D9D9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Headline Text ────────────────────────────
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

                  // ── Scattered Icons Area ─────────────────────
                  FadeTransition(
                    opacity: _iconsFade,
                    child: SizedBox(
                      width: size.width,
                      height: size.width * 0.82,
                      child: _ScatteredIcons(
                        iconPath: _iconsPath,
                        containerWidth: size.width,
                        ),
                    ),
                  ),

                  const Spacer(),

                  // ── Subtitle ─────────────────────────────────
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
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Scattered Icons Widget ─────────────────────────────────────
class _ScatteredIcons extends StatelessWidget {
  final String iconPath;
  final double containerWidth;

  const _ScatteredIcons({
    required this.iconPath,
    required this.containerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        iconPath,
        width: containerWidth * 0.9,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: containerWidth * 0.9,
          height: containerWidth * 0.7,
          decoration: BoxDecoration(
            color: const Color(0xFFF5CBCB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.image_not_supported,
            size: 40,
            color: Color(0xFF748DAE),
          ),
        ),
      ),
    );
  }
}

// ─── Fallback ketika asset belum ada ────────────────────────────
class _FallbackIcon extends StatelessWidget {
  final int index;
  final double size;

  const _FallbackIcon({required this.index, required this.size});

  static const List<Color> _colors = [
    Color(0xFFF5CBCB),
    Color(0xFFF5CBCB),
    Color(0xFFF5CBCB),
    Color(0xFFF5CBCB),
    Color(0xFFF5CBCB),
    Color(0xFFFF6B6B), // merah
    Color(0xFFFFD93D), // kuning
    Color(0xFFADD8E6), // biru muda
    Color(0xFFFF69B4), // pink
  ];

  static const List<IconData> _icons = [
    Icons.mood,
    Icons.sentiment_neutral,
    Icons.sentiment_very_satisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_very_dissatisfied,
    Icons.local_fire_department,
    Icons.star,
    Icons.water_drop,
    Icons.favorite,
  ];

  @override
  Widget build(BuildContext context) {
    final color = index < _colors.length
        ? _colors[index]
        : const Color(0xFFF5CBCB);
    final icon = index < _icons.length
        ? _icons[index]
        : Icons.circle;

    // Brain shapes (index 0-4) pakai rounded container
    if (index < 5) {
      return Container(
        width: size,
        height: size * 0.8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.35),
        ),
        child: Icon(icon, size: size * 0.4, color: const Color(0xFF1A1A2E)),
      );
    }

    // Decorative items (index 5-8) lebih kecil
    return Icon(icon, size: size, color: color);
  }
}