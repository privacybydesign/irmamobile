import "package:flutter/material.dart";

class DrivingLicenceAnimation extends StatefulWidget {
  const DrivingLicenceAnimation({super.key});

  @override
  State<DrivingLicenceAnimation> createState() =>
      _DrivingLicenceAnimationState();
}

class _DrivingLicenceAnimationState extends State<DrivingLicenceAnimation>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();

    // Setup positioning animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _positionAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    // Start animation loop
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
        Positioned(bottom: 120, child: _buildDrivingLicenceIllustration()),
        Positioned(
          top: 40 + (_positionAnimation.value * 20),
          child: _buildPhoneIllustration(),
        ),
      ],
    );
  }

  Widget _buildPhoneIllustration() {
    return Container(
      width: 80, // Portrait shape (narrower than height)
      height: 160,
      decoration: BoxDecoration(
        border: .all(color: const Color.fromARGB(255, 0, 0, 0), width: 3),
        borderRadius: .circular(20),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Notch (optional, to suggest speaker/camera area)
          Container(
            width: 40,
            height: 6,
            margin: const .only(top: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 0, 0),
              borderRadius: .circular(3),
            ),
          ),
          const Spacer(),
          // You can add a blank screen or content here if desired
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDrivingLicenceIllustration() {
    return Container(
      width: 155,
      height: 90,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE0E6), Color(0xFFFFC1CC)],
          begin: .topLeft,
          end: .bottomRight,
        ),
        border: .all(color: Color(0xFFB48DA3), width: 1.2),
        borderRadius: .circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
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
            Row(
              children: [
                const SizedBox(width: 5),
                const Text(
                  "DRIVING LICENCE",
                  style: TextStyle(
                    color: Color(0xFF0046AD),
                    fontWeight: .bold,
                    fontSize: 9,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: .circular(3),
                    border: .all(color: Colors.grey[400]!),
                  ),
                  child: Icon(Icons.person, size: 10, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Middle section – main photo placeholder
            Expanded(
              child: Align(
                alignment: .centerLeft,
                child: Container(
                  width: 38,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: .circular(3),
                    border: .all(color: Colors.grey[400]!),
                  ),
                  child: Icon(Icons.person, size: 20, color: Colors.grey[600]),
                ),
              ),
            ),

            // MRZ line at the bottom (only text, no bar)
            const Center(
              child: Padding(
                padding: .only(top: 4),
                child: Text(
                  "D1NLD2X150949621115MZ26KC47X2W",
                  style: TextStyle(
                    fontFamily: "monospace",
                    fontWeight: .bold,
                    fontSize: 6,
                    color: Colors.black,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
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
            height: requestedHeight, // or use MediaQuery if dynamic height needed
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -25),
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
