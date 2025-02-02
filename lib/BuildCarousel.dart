import 'package:flutter/material.dart';
import 'dart:async'; // For Timer

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

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    // Start the timer to change images every 2 seconds
    Timer.periodic(Duration(seconds: 2), (timer) {
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          (_currentIndex + 1) % _imageList.length,
          duration: Duration(milliseconds: 600), // Smooth transition
          curve: Curves.easeInOut, // Smooth curve
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Set the height for the carousel
      width: double.infinity, // Make it full width
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(8), // Rounded images
                child: Image.asset(
                  _imageList[index],
                  fit: BoxFit.cover, // Make sure images cover the container
                ),
              );
            },
          ),
          Positioned(
            bottom: 10,
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

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _imageList.length; i++) {
      indicators.add(
        Container(
          width: 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentIndex == i ? Colors.tealAccent : Colors.grey,
          ),
        ),
      );
    }
    return indicators;
  }
}
