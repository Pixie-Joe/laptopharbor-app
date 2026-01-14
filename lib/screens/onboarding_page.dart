
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'login_screen.dart';                   

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      image: 'assets/images/onboarding_1.jpg',
      title: 'Welcome to LaptopHarbor',
      description: 'Discover the best laptops for your needs.',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_2.jpeg',
      title: 'Browse Laptops Easily',
      description: 'Search, compare, and pick the perfect laptop.',
    ),
    OnboardingItem(
      image: 'assets/images/onboarding_3.jpg',
      title: 'Track Your Orders',
      description: 'Keep track of your orders in real-time.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              onPageChanged: (value) => setState(() => _currentPage = value),
              itemCount: _pages.length,
              itemBuilder: (context, index) => OnboardingContent(item: _pages[index]),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Color.fromARGB(255, 19, 164, 221),         
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: Color.fromARGB(255, 19, 164, 221),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: 50,
              left: 30,
              right: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: Color.fromARGB(255, 19, 164, 221), 
                      dotColor: Colors.grey,
                      dotHeight: 9,
                      dotWidth: 9,
                      spacing: 8,
                      expansionFactor: 3.5,
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 19, 164, 221),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───── Content & Model (unchanged) ─────
class OnboardingContent extends StatelessWidget {
  final OnboardingItem item;
  const OnboardingContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.image,
            height: MediaQuery.of(context).size.height * 0.48,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 60),
          Text(item.title, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(item.description, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.6)),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String image, title, description;
  OnboardingItem({required this.image, required this.title, required this.description});
}