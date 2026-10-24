import "dart:ui" show lerpDouble;

import "package:flutter/services.dart";
import "package:material_ui/material_ui.dart";

import "../../theme/yivi_palette.dart";
import "../irma_close_button.dart";
import "../pull_to_dismiss_physics.dart";

/// A photo in a credential's values: a small picture with slightly rounded
/// corners that opens full screen, as in WhatsApp. The photo flies there (and
/// back) as a hero, its corners squaring off on the way.
class AttributePhoto extends StatefulWidget {
  final Uint8List bytes;

  /// Its name, at the top of the full-screen view.
  final String title;

  const AttributePhoto({super.key, required this.bytes, required this.title});

  /// The largest the small picture gets.
  static const Size thumbnail = Size(66, 100);

  static const double radius = 8;

  @override
  State<AttributePhoto> createState() => _AttributePhotoState();
}

class _AttributePhotoState extends State<AttributePhoto> {
  // One per photo on screen, so two cards with the same photo fly apart.
  final _tag = Object();
  late MemoryImage _image = MemoryImage(widget.bytes);
  ImageStream? _stream;
  late final _listener = ImageStreamListener(_onImage, onError: _onError);

  /// Width over height once decoded; until then a passport photo's.
  double? _aspect;
  bool _broken = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(AttributePhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      _image = MemoryImage(widget.bytes);
      _aspect = null;
      _broken = false;
      _resolve();
    }
  }

  void _resolve() {
    final stream = _image.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  void _onImage(ImageInfo info, bool _) {
    final aspect = info.image.width / info.image.height;
    info.dispose();
    if (mounted && aspect != _aspect) setState(() => _aspect = aspect);
  }

  void _onError(Object _, StackTrace? _) {
    if (mounted) setState(() => _broken = true);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  /// A hero inside another hero (a card that flies itself, as in the Change
  /// sheet) is not allowed; there the view only fades in.
  bool get _canFly => context.findAncestorWidgetOfExactType<Hero>() == null;

  void _open() {
    final fly = _canFly;
    Navigator.of(context).push(
      _PhotoRoute(
        builder: (_) => _PhotoViewer(
          image: _image,
          title: widget.title,
          aspect: _aspect ?? _passport,
          heroTag: fly ? _tag : null,
        ),
      ),
    );
  }

  static const _passport = 35 / 45;

  @override
  Widget build(BuildContext context) {
    if (_broken) return const SizedBox.shrink();
    final picture = _Picture(image: _image, radius: AttributePhoto.radius);
    return Semantics(
      button: true,
      image: true,
      label: widget.title,
      child: GestureDetector(
        onTap: _open,
        child: ConstrainedBox(
          constraints: BoxConstraints.loose(AttributePhoto.thumbnail),
          child: AspectRatio(
            aspectRatio: _aspect ?? _passport,
            child: _canFly
                ? Hero(
                    tag: _tag,
                    createRectTween: _straight,
                    flightShuttleBuilder: _shuttle,
                    child: picture,
                  )
                : picture,
          ),
        ),
      ),
    );
  }

  /// The photo in flight: the corners go from rounded on the card to square
  /// full screen, and back.
  Widget _shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) => AnimatedBuilder(
    animation: animation,
    builder: (context, _) => _Picture(
      image: _image,
      // The animation runs 0 → 1 into the viewer and 1 → 0 back out.
      radius: lerpDouble(AttributePhoto.radius, 0, animation.value)!,
    ),
  );
}

/// A straight path for the photo in flight. The default curved one moves
/// the corners along arcs, which squeezes the photo out of its shape.
RectTween _straight(Rect? begin, Rect? end) =>
    RectTween(begin: begin, end: end);

class _Picture extends StatelessWidget {
  final ImageProvider image;
  final double radius;

  const _Picture({required this.image, required this.radius});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: Image(
      image: image,
      // The box has the photo's own shape, so nothing is cut off.
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

/// A see-through route, so the page under the photo shows while the black
/// fades in (and while it is swiped away).
class _PhotoRoute extends PageRoute<void> {
  final WidgetBuilder builder;

  _PhotoRoute({required this.builder});

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 320);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// The photo full screen, as in WhatsApp: on black, with its name and a close
/// button on top. A tap hides or shows the bar; pinch or double-tap zooms; a
/// swipe up or down, when not zoomed in, takes it away.
class _PhotoViewer extends StatefulWidget {
  final ImageProvider image;
  final String title;
  final double aspect;
  final Object? heroTag;

  const _PhotoViewer({
    required this.image,
    required this.title,
    required this.aspect,
    required this.heroTag,
  });

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer>
    with SingleTickerProviderStateMixin {
  final _zoom = TransformationController();
  bool _chrome = true;

  /// How far the photo is swiped away.
  double _drag = 0;
  bool _dragging = false;
  late final _springBack = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..addListener(() => setState(() => _drag = _dragFrom * (1 - _springT)));
  double _dragFrom = 0;
  double get _springT => Curves.easeOutCubic.transform(_springBack.value);

  Offset? _doubleTapAt;

  bool get _zoomedIn => _zoom.value.getMaxScaleOnAxis() > 1.01;

  @override
  void dispose() {
    _zoom.dispose();
    _springBack.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  void _onStart(ScaleStartDetails d) {
    _springBack.stop();
    _dragging = d.pointerCount == 1 && !_zoomedIn;
  }

  void _onUpdate(ScaleUpdateDetails d) {
    if (!_dragging || d.pointerCount > 1) {
      _dragging = false;
      return;
    }
    setState(() => _drag += d.focalPointDelta.dy);
  }

  void _onEnd(ScaleEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = d.velocity.pixelsPerSecond.dy;
    if (_drag.abs() > PullToDismissPhysics.dismissDistance ||
        velocity.abs() > PullToDismissPhysics.dismissVelocity) {
      // Flies back to the card from where it was let go.
      _close();
      return;
    }
    _dragFrom = _drag;
    _springBack.forward(from: 0);
  }

  void _toggleZoom() {
    if (_zoomedIn) {
      _zoom.value = Matrix4.identity();
      return;
    }
    final at = _doubleTapAt ?? Offset.zero;
    const scale = 2.5;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)!.animation!;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final photo = AspectRatio(
      aspectRatio: widget.aspect,
      child: Image(
        image: widget.image,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );

    // The status bar of the page under it: nothing else sets it back.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pageBar = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
    );
    const blackBar = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );

    // Text styles and ink for the bar: a route of its own has no Material.
    return Material(
      type: MaterialType.transparency,
      child: AnimatedBuilder(
        animation: route,
        builder: (context, _) {
          // The black fades in with the route and out with the swipe.
          final away = (_drag.abs() / (size.height / 2)).clamp(0.0, 1.0);
          final black = route.value * (1 - away);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            // White over the black; the page's own once it shows through
            // again, so closing leaves the right one behind.
            value: black > 0.5 ? blackBar : pageBar,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: black)),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _chrome = !_chrome),
                  onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                  onDoubleTap: _toggleZoom,
                  child: InteractiveViewer(
                    transformationController: _zoom,
                    maxScale: 5,
                    // Swiping, not panning, while not zoomed in.
                    panEnabled: _zoomedIn,
                    onInteractionStart: _onStart,
                    onInteractionUpdate: _onUpdate,
                    onInteractionEnd: _onEnd,
                    child: Transform.translate(
                      offset: Offset(0, _drag),
                      child: Center(
                        child: widget.heroTag == null
                            ? FadeTransition(opacity: route, child: photo)
                            : Hero(
                                tag: widget.heroTag!,
                                createRectTween: _straight,
                                // Square full screen; the shuttle rounds it on
                                // the way to the card.
                                child: photo,
                              ),
                      ),
                    ),
                  ),
                ),
                // The bar, over a dark gradient so the white reads on any photo.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: IgnorePointer(
                    ignoring: !_chrome,
                    child: AnimatedOpacity(
                      opacity: _chrome && !_dragging && _drag == 0
                          ? route.value
                          : 0,
                      duration: const Duration(milliseconds: 180),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x99000000), Color(0x00000000)],
                          ),
                        ),
                        child: Padding(
                          // At the height of the card details' close
                          // button, 16 under the safe area.
                          padding: EdgeInsets.fromLTRB(
                            16 + padding.left,
                            padding.top + 16,
                            16 + padding.right,
                            24,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: YiviPalette.of(
                                      context,
                                    ).display(17).copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                              // Room for the close button, drawn above the bar.
                              const SizedBox(width: 52),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // The app's close button, as on every other page. Above the
                // bar, not in it: the bar fades through an Opacity, which
                // would turn the glass dark (see GlassSurface.opacity).
                Positioned(
                  top: padding.top + 16,
                  right: 16 + padding.right,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      end: _chrome && !_dragging && _drag == 0
                          ? route.value
                          : 0,
                    ),
                    // Follows the route at once; eases when the bars hide.
                    duration: route.isAnimating
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    builder: (context, opacity, _) => IrmaCloseButton(
                      key: const Key("photo_viewer_close"),
                      onTap: _close,
                      opacity: opacity,
                      dark: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
