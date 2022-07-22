part of pin;

// Because ClipOval, becomes an oval when the item
// to clip is not in a square with equal edges
class _PerfectCircleClip extends CustomClipper<Path> {
  double radiusDelta = 5;

  @override
  Path getClip(Size size) {
    final path = Path();

    path.addOval(Rect.fromCircle(
      center: Offset(size.width / 2.0, size.height / 2.0),
      radius: size.shortestSide / 2.0 - radiusDelta,
    ));

    return path..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
