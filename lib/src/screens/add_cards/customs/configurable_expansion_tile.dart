// configurable_expansion_tile
// From: https://github.com/matthewstyler/configurable_expansion_tile/blob/master/lib/configurable_expansion_tile.dart
//
//Copyright 2018 Tyler Matthews. All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are
//met:
//
//* Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//* Redistributions in binary form must reproduce the above
//copyright notice, this list of conditions and the following
//disclaimer in the documentation and/or other materials provided
//with the distribution.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// Slightly adapted to remove an animation (fade to white when header color remains the same)

library configurable_expansion_tile;

import 'package:flutter/material.dart';

/// A configurable Expansion Tile edited from the flutter material implementation
/// that allows for customization of most of the behaviour. Includes providing colours,
/// replacement widgets on expansion, and  animating preceding/following widgets.
///
/// See:
/// [ExpansionTile]
class ConfigurableExpansionTile extends StatefulWidget {
  /// Creates a a [Widget] with an optional [animatedWidgetPrecedingHeader] and/or
  /// [animatedWidgetFollowingHeader]. Optionally, the header can change on the
  /// expanded state by proving a [Widget] in [headerExpanded]. Colors can also
  /// be specified for the animated transitions/states. [children] are revealed
  /// when the expansion tile is expanded.
  const ConfigurableExpansionTile(
      {Key key,
      this.headerBackgroundColorStart = Colors.transparent,
      this.onExpansionChanged,
      this.children = const <Widget>[],
      this.initiallyExpanded = false,
      @required this.header,
      this.animatedWidgetFollowingHeader,
      this.animatedWidgetPrecedingHeader,
      this.expandedBackgroundColor,
      this.borderColorStart = Colors.transparent,
      this.borderColorEnd = Colors.transparent,
      this.topBorderOn = true,
      this.bottomBorderOn = true,
      this.kExpand = const Duration(milliseconds: 200),
      this.headerBackgroundColorEnd,
      this.headerExpanded,
      this.headerAnimationTween,
      this.borderAnimationTween,
      this.animatedWidgetTurnTween,
      this.animatedWidgetTween})
      : assert(initiallyExpanded != null),
        super(key: key);

  /// Called when the tile expands or collapses.
  ///
  /// When the tile starts expanding, this function is called with the value
  /// true. When the tile starts collapsing, this function is called with
  /// the value false.
  final ValueChanged<bool> onExpansionChanged;

  /// The widgets that are displayed when the tile expands.
  ///
  /// Typically [ListTile] widgets.
  final List<Widget> children;

  /// The color of the header, useful to set if your animating widgets are
  /// larger than the header widget, or you want an animating color, in which
  /// case your header widget should be transparent
  final Color headerBackgroundColorStart;

  /// The [Color] the header will transition to on expand
  final Color headerBackgroundColorEnd;

  /// The [Color] of the background of the [children] when expanded
  final Color expandedBackgroundColor;

  /// Specifies if the list tile is initially expanded (true) or collapsed (false, the default).
  final bool initiallyExpanded;

  /// The header for the expansion tile
  final Widget header;

  /// An optional widget to replace [header] with if the list is expanded
  final Widget headerExpanded;

  /// A widget to rotate following the [header] (ie an arrow)
  final Widget animatedWidgetFollowingHeader;

  /// A widget to rotate preceding the [header] (ie an arrow)
  final Widget animatedWidgetPrecedingHeader;

  /// The duration of the animations
  final Duration kExpand;

  /// The color the border start, before the list is expanded
  final Color borderColorStart;

  /// The color of the border at the end of animation, after the list is expanded
  final Color borderColorEnd;

  /// Turns the top border of the list is on/off
  final bool topBorderOn;

  /// Turns the bottom border of the list on/off
  final bool bottomBorderOn;

  /// Header transition tween
  final Animatable<double> headerAnimationTween;

  /// Border animation tween
  final Animatable<double> borderAnimationTween;

  /// Tween for turning [animatedWidgetFollowingHeader] and [animatedWidgetPrecedingHeader]
  final Animatable<double> animatedWidgetTurnTween;

  ///  [animatedWidgetFollowingHeader] and [animatedWidgetPrecedingHeader] transition tween
  final Animatable<double> animatedWidgetTween;

  static final Animatable<double> _easeInTween = CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween = Tween<double>(begin: 0.0, end: 0.5);

  static final Animatable<double> _easeOutTween = CurveTween(curve: Curves.easeOut);
  @override
  _ConfigurableExpansionTileState createState() => _ConfigurableExpansionTileState();
}

class _ConfigurableExpansionTileState extends State<ConfigurableExpansionTile> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _iconTurns;
  Animation<double> _heightFactor;

  Animation<Color> _borderColor;
  Animation<Color> _headerColor;

  final ColorTween _borderColorTween = ColorTween();
  final ColorTween _headerColorTween = ColorTween();

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.kExpand, vsync: this);
    _heightFactor = _controller.drive(ConfigurableExpansionTile._easeInTween);
    _iconTurns = _controller.drive((widget.animatedWidgetTurnTween ?? ConfigurableExpansionTile._halfTween)
        .chain(widget.animatedWidgetTween ?? ConfigurableExpansionTile._easeInTween));

    _borderColor = _controller
        .drive(_borderColorTween.chain(widget.borderAnimationTween ?? ConfigurableExpansionTile._easeOutTween));
    _borderColorTween.end = widget.borderColorEnd;

    _headerColor = _controller
        .drive(_headerColorTween.chain(widget.headerAnimationTween ?? ConfigurableExpansionTile._easeInTween));
    _headerColorTween.end = widget.headerBackgroundColorEnd ?? widget.headerBackgroundColorStart;
    _isExpanded = PageStorage.of(context)?.readState(context) ?? widget.initiallyExpanded;
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    if (widget.onExpansionChanged != null) widget.onExpansionChanged(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget child) {
    final Color borderSideColor = _borderColor.value ?? widget.borderColorStart;
    // final Color headerColor =
    //     _headerColor?.value ?? widget.headerBackgroundColorStart;
    final Color headerColor = widget.headerBackgroundColorStart;

    return Container(
      decoration: BoxDecoration(
          border: Border(
        top: BorderSide(color: widget.topBorderOn ? borderSideColor : Colors.transparent),
        bottom: BorderSide(color: widget.bottomBorderOn ? borderSideColor : Colors.transparent),
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GestureDetector(
              onTap: _handleTap,
              child: Container(
                  color: headerColor,
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RotationTransition(
                        turns: _iconTurns,
                        child: widget.animatedWidgetPrecedingHeader ?? Container(),
                      ),
                      _getHeader(),
                      RotationTransition(
                        turns: _iconTurns,
                        child: widget.animatedWidgetFollowingHeader ?? Container(),
                      )
                    ],
                  ))),
          ClipRect(
            child: Align(
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  /// Retrieves the header to display for the tile, derived from [_isExpanded] state
  Widget _getHeader() {
    if (!_isExpanded) {
      return widget.header;
    } else {
      return widget.headerExpanded ?? widget.header;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool closed = !_isExpanded && _controller.isDismissed;
    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed
          ? null
          : Container(
              color: widget.expandedBackgroundColor ?? Colors.transparent, child: Column(children: widget.children)),
    );
  }
}
