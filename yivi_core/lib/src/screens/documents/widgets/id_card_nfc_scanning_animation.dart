import "package:flutter/material.dart";

import "../../../util/test_detection.dart";

class IdCardNfcScanningAnimation extends StatelessWidget {
  const IdCardNfcScanningAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    final isIntegrationTest = TestContext.isRunningIntegrationTest(context);
    return TickerMode(
      enabled: !isIntegrationTest,
      child: _DutchIdCardAnimation(),
    );
  }
}

class _DutchIdCardAnimation extends StatefulWidget {
  const _DutchIdCardAnimation();

  @override
  State<_DutchIdCardAnimation> createState() => _DutchIdCardAnimationState();
}

class _DutchIdCardAnimationState extends State<_DutchIdCardAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPositioningDiagram() {
    return Stack(
      alignment: .topCenter,
      children: [
        Positioned(bottom: 120, child: _buildDutchIdCardIllustration()),
        Positioned(
          top: 40 + (_positionAnimation.value * 20),
          child: _buildPhoneIllustration(),
        ),
      ],
    );
  }

  Widget _buildPhoneIllustration() {
    return Container(
      width: 80,
      height: 160,
      decoration: BoxDecoration(
        border: .all(color: Colors.black, width: 3),
        borderRadius: .circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 6,
            margin: const .only(top: 8),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: .circular(3),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDutchIdCardIllustration() {
    return Container(
      width: 155,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCEAFE), // very light ice blue
            Color(0xFFE6D9F7), // faint lavender / purple tint
          ],
          begin: .topLeft,
          end: .bottomRight,
        ),
        border: .all(color: Color(0xFF9CA9C9), width: 1.2),
        borderRadius: .circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(40),
            blurRadius: 3,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const .all(6),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            const SizedBox(height: 2),

            const Text(
              "IDENTITEITSKAART / IDENTITY CARD",
              style: TextStyle(
                color: Color(0xFF553C99),
                fontWeight: .bold,
                fontSize: 6.3,
                letterSpacing: 0.4,
              ),
            ),

            const SizedBox(height: 5),

            Expanded(
              child: Row(
                crossAxisAlignment: .center,
                children: [
                  // Photo placeholder
                  Container(
                    width: 38,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: .circular(3),
                      border: .all(color: Colors.grey[400]!),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: .spaceEvenly,
                      crossAxisAlignment: .start,
                      children: [
                        _placeholderBar(60),
                        _placeholderBar(45),
                        _placeholderBar(40),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Bottom instruction bar
            Container(
              width: .infinity,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(100),
                borderRadius: .circular(3),
              ),
              child: const Center(
                child: Text(
                  "PLACE ID CARD AGAINST PHONE",
                  style: TextStyle(
                    fontSize: 5.5,
                    fontWeight: .w600,
                    letterSpacing: 0.8,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderBar(double width) {
    return Container(
      height: 4,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(150),
        borderRadius: .circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const requestedHeight = 250.0;
        final scale = constraints.maxHeight / requestedHeight;

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            height: requestedHeight,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: const Offset(0, -25),
                  child: _buildPositioningDiagram(),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
