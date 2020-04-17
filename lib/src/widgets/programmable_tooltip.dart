// Based on flutter source of their tooltip.
// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ProgrammableTooltip extends StatefulWidget {
  const ProgrammableTooltip({
    Key key,
    @required this.message,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.verticalOffset,
    this.preferBelow,
    this.excludeFromSemantics,
    this.decoration,
    this.textStyle,
    this.show,
    this.child,
  })  : assert(message != null),
        super(key: key);

  final String message;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double verticalOffset;
  final bool preferBelow;
  final bool excludeFromSemantics;
  final Widget child;
  final Decoration decoration;
  final TextStyle textStyle;
  final bool show;

  @override
  _TooltipState createState() => _TooltipState();
}

class _TooltipState extends State<ProgrammableTooltip> with WidgetsBindingObserver {
  static const double _defaultTooltipHeight = 32.0;
  static const double _defaultTooltipWidth = 192.0;
  static const double _defaultVerticalOffset = 24.0;
  static const bool _defaultPreferBelow = true;
  static const bool _defaultShow = false;
  static const EdgeInsetsGeometry _defaultPadding = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsetsGeometry _defaultMargin = EdgeInsets.all(0.0);
  static const Duration _fadeDuration = Duration(milliseconds: 100);
  static const bool _defaultExcludeFromSemantics = false;

  double height;
  double width;
  EdgeInsetsGeometry padding;
  EdgeInsetsGeometry margin;
  Decoration decoration;
  TextStyle textStyle;
  double verticalOffset;
  bool preferBelow;
  bool excludeFromSemantics;
  OverlayEntry _entry;

  bool _opened;

  @override
  void initState() {
    super.initState();
    _opened = false;
    if (widget.show) {
      _show();
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    // We would want to re render the overlay if any metrics
    // ever change.
    if (widget.show) {
      _show();
    } else {
      _hide();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We would want to re render the overlay if any of the dependencies
    // ever change.
    if (widget.show) {
      _show();
    } else {
      _hide();
    }
  }

  @override
  void didUpdateWidget(ProgrammableTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show) {
      _show();
    } else {
      _hide();
    }
  }

  @override
  void dispose() {
    if (widget.show) {
      _hide();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _show() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 280));
      if (_opened == true) {
        _entry.remove();
      }
      _entry = _buildOverlayEntry();
      if (_entry != null) {
        Overlay.of(context).insert(_entry);
        SemanticsService.tooltip(widget.message);
        _opened = true;
      }
    });
  }

  void _hide() {
    if (_opened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _entry.remove();
        _opened = false;
      });
    }
  }

  OverlayEntry _buildOverlayEntry() {
    if (context == null) {
      return null;
    }
    final RenderBox box = context.findRenderObject() as RenderBox;
    if (box.attached == false) {
      return null;
    }
    final Offset target = box.localToGlobal(box.size.center(Offset.zero));

    final ThemeData theme = Theme.of(context);
    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);
    TextStyle defaultTextStyle;
    BoxDecoration defaultDecoration;
    if (theme.brightness == Brightness.dark) {
      defaultTextStyle = theme.textTheme.body1.copyWith(
        color: Colors.black,
      );
      defaultDecoration = BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    } else {
      defaultTextStyle = theme.textTheme.body1.copyWith(
        color: Colors.white,
      );
      defaultDecoration = BoxDecoration(
        color: Colors.grey[700].withOpacity(0.9),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      );
    }

    return OverlayEntry(
        builder: (context) => Directionality(
            textDirection: Directionality.of(context),
            child: _TooltipOverlay(
              message: widget.message,
              width: widget.width ?? _defaultTooltipWidth,
              height: widget.height ?? tooltipTheme.height ?? _defaultTooltipHeight,
              padding: widget.padding ?? tooltipTheme.padding ?? _defaultPadding,
              margin: widget.margin ?? tooltipTheme.margin ?? _defaultMargin,
              decoration: widget.decoration ?? tooltipTheme.decoration ?? defaultDecoration,
              textStyle: widget.textStyle ?? tooltipTheme.textStyle ?? defaultTextStyle,
              target: target,
              verticalOffset: widget.verticalOffset ?? tooltipTheme.verticalOffset ?? _defaultVerticalOffset,
              preferBelow: widget.preferBelow ?? tooltipTheme.preferBelow ?? _defaultPreferBelow,
              show: widget.show ?? _defaultShow,
              fadeDuration: _fadeDuration,
            )));
  }

  @override
  Widget build(BuildContext context) {
    assert(Overlay.of(context) != null);
    // Listen to changes in media query such as when a device orientation changes
    // or when the keyboard is toggled.
    MediaQuery.of(context);

    final TooltipThemeData tooltipTheme = TooltipTheme.of(context);

    final excludeFromSemantics =
        widget.excludeFromSemantics ?? tooltipTheme.excludeFromSemantics ?? _defaultExcludeFromSemantics;

    return Semantics(
      label: excludeFromSemantics ? null : widget.message,
      child: widget.child,
    );
  }
}

/// A delegate for computing the layout of a tooltip to be displayed above or
/// bellow a target specified in the global coordinate system.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  /// Creates a delegate for computing the layout of a tooltip.
  ///
  /// The arguments must not be null.
  _TooltipPositionDelegate({
    @required this.target,
    @required this.verticalOffset,
    @required this.preferBelow,
  })  : assert(target != null),
        assert(verticalOffset != null),
        assert(preferBelow != null);

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
    );
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        verticalOffset != oldDelegate.verticalOffset ||
        preferBelow != oldDelegate.preferBelow;
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    Key key,
    this.message,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.decoration,
    this.textStyle,
    this.animation,
    this.target,
    this.verticalOffset,
    this.preferBelow,
    this.fadeDuration,
    this.show,
  }) : super(key: key);

  final String message;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Decoration decoration;
  final TextStyle textStyle;
  final Animation<double> animation;
  final Offset target;
  final double verticalOffset;
  final bool preferBelow;
  final Duration fadeDuration;
  final bool show;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomSingleChildLayout(
          delegate: _TooltipPositionDelegate(
            target: target,
            verticalOffset: verticalOffset,
            preferBelow: preferBelow,
          ),
          child: AnimatedOpacity(
            opacity: show ? 1.0 : 0.0,
            duration: fadeDuration,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height, maxWidth: width),
              child: DefaultTextStyle(
                style: Theme.of(context).textTheme.body1,
                child: Container(
                  decoration: decoration,
                  padding: padding,
                  margin: margin,
                  child: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: Text(
                      message,
                      style: textStyle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
