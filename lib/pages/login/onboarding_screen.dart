import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _floatController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initialization();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _fadeController,
          curve: Curves.easeInOut
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _floatAnimation = Tween<double>(
        begin: 0.0, end: 10.0
    ).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _startAnimations();

    _floatController.repeat(reverse: true);
  }

  void initialization() async {
    FlutterNativeSplash.remove();
  }

  void _startAnimations() {
    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _resetAnimations(){
    _fadeController.reset();
    _slideController.reset();
    _floatController.reset();
    _scaleController.reset();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _floatController.dispose();
    _scaleController.dispose();

    super.dispose();
  }

  void _onPageChanged(int page){
    setState(() {
      _currentPage = page;
    });

    _resetAnimations();
    _startAnimations();

    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut
      );
    }
  }

  void _skipOnboarding() {
    Navigator.of(context).pushReplacementNamed('/auth');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Container(
        color: const Color(0xFFFAFAFA),
        child: SafeArea(child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                        color: Color(0xFF0B1215).withOpacity(0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: [
                _buildPage(
                  assetName: 'assets/images/OB1.png',
                  title: "Apa itu TukarIn",
                  description:
                  "TukarIn adalah aplikasi smart waste collection yang mengubah sampah terpilah menjadi poin bernilai.",
                  isFirst: true,
                ),
                _buildPage(
                  assetName: 'assets/images/OB2.png',
                  title: "Mau dijemput atau setor sendiri?",
                  description:
                  "Kamu bisa pilih: setor langsung ke bank sampah terdekat atau jadwalkan penjemputan di rumah.",
                  isFirst: false,
                ),
                _buildPage(
                  assetName: 'assets/images/OB3.png',
                  title: "Jadi bagian dari solusi lingkungan",
                  description:
                  "Dengan TukarIn, kamu ikut mengurangi timbunan sampah, mendukung daur ulang dan menjaga bumi lebih bersih.",
                  isFirst: false,
                ),
              ],
            ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) => _buildDot(index)),
                  ),
                  SizedBox(height: 32),
                  _buildNavigationsButtons(),
                ],
              ),
            ),
            SizedBox(height: 44),
            Center(child: Text('2025 @ TukarIn', style: TextStyle(fontSize: 12, color: Color(0xFF0B1215)))),
            SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );


  }

  Widget _buildPage({
    required String assetName,
    required String title,
    required String description,
    required bool isFirst,
  }){
    return  FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _floatAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_floatAnimation.value),
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Image.asset(assetName, height: 160),
                    ),
                  );
                },
              ),
              SizedBox(height: 32),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B1215),
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF0B1215).withOpacity(0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );


  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF85A947) : const Color(0xFF123524),
        borderRadius: BorderRadius.circular(12),
      ),
    );


  }

  Widget _buildNavigationsButtons(){
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFC5C6C4).withOpacity(0.3),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                    onTap: _previousPage,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF0B1215),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Back',
                            style: TextStyle(
                              color: Color(0xFF0B1215),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                ),
              ),
            ),
          ),

        if (_currentPage > 0) SizedBox(width: 16),
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF123524),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: _nextPage,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == 2 ? 'Get Started' : 'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentPage != 2)...[
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  )
              ),
            ),
          ),
        ),

      ],
    );
  }
}
