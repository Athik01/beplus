import 'package:flutter/material.dart';
import 'dart:async';

class BuildCarousel extends StatefulWidget {
  @override
  _BuildCarouselState createState() => _BuildCarouselState();
}

class _BuildCarouselState extends State<BuildCarousel> {
  int _currentIndex = 0;
  final List<String> _imageList = [
    'lib/assets/2.png',
    'lib/assets/3.png',
    'lib/assets/4.png',
    'lib/assets/5.png',
  ];

  final PageController _pageController = PageController(
    viewportFraction: 0.85, // Shows a glimpse of adjacent images
  );

  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();

    // Automatically switch images every 4 seconds.
    _carouselTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentIndex + 1) % _imageList.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  List<Widget> _buildPageIndicator() {
    return List.generate(_imageList.length, (i) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(horizontal: 4),
        width: _currentIndex == i ? 16 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentIndex == i
              ? Colors.blueGrey.shade700
              : Colors.blueGrey.shade200,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250, // Increased height for a more impactful display
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _imageList.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.2)).clamp(0.8, 1.0);
                  }
                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) * 250,
                      child: child,
                    ),
                  );
                },
                child: Container(
                  // Outer container with border image and shadow.
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('lib/assets/back2.png'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    // Inner container with margin to reveal border image.
                    margin: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _imageList[index],
                            fit: BoxFit.cover,
                          ),
                          // BlueGrey gradient overlay for a premium look.
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blueGrey.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Positioned page indicators at the bottom center.
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildPageIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
