import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/theme.dart';

class PinField extends StatefulWidget {
  final bool autofocus;
  final bool autosubmit;
  final bool autoclear;
  final int maxLength;
  final int minLength;
  final ValueChanged<String> onChange;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFull;

  PinField({
    this.minLength = 5,
    this.maxLength = 16,
    this.autofocus = true,
    this.autosubmit = true,
    this.autoclear = true,
    this.onChange,
    this.onSubmit,
    this.onFull,
  });

  @override
  _PinFieldState createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  final controller = TextEditingController();
  bool _isDisposed = false;

  bool obscureText;
  String value;
  FocusNode focusNode;
  int lastLength;

  @override
  void initState() {
    super.initState();
    value = '';
    lastLength = 0;
    obscureText = true;

    focusNode = FocusNode();
    controller.addListener(_updateLength);
  }

  _updateLength() {
    final val = controller.text;
    final len = val.length;

    if (len != lastLength && len == widget.maxLength) {
      if (widget.onFull != null) {
        widget.onFull(val);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed && widget.onSubmit != null && widget.autosubmit) {
          widget.onSubmit(val);
        }
        if (!_isDisposed && widget.autoclear) {
          controller.clear();
        }
      });
    }

    setState(() {
      value = val;
      lastLength = len;
    });

    if (widget.onChange != null) {
      widget.onChange(val);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _isDisposed = true;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (widget.maxLength > 5) {
      return Center(
        child: Container(
          width: (MediaQuery.of(context).size.width - theme.spacing * 4),
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextFormField(
                  controller: controller,
                  onEditingComplete: () {
                    final val = controller.text;
                    if (val.length >= widget.minLength && val.length <= widget.maxLength && widget.onSubmit != null) {
                      widget.onSubmit(val);
                    }
                  },
                  inputFormatters: [
                    WhitelistingTextInputFormatter(RegExp('[0-9]')),
                  ],
                  autofocus: true,
                  keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
                  obscureText: obscureText,
                  maxLength: widget.maxLength,
                ),
              ),
              IconButton(
                iconSize: theme.spacing,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () {
                  setState(
                    () {
                      obscureText = !obscureText;
                    },
                  );
                },
              )
            ],
          ),
        ),
      );
    }

    final int len = min(widget.maxLength, max(value.length + 1, widget.minLength));
    final boxes = List<Widget>(len);
    final bool complete = value.length == widget.maxLength;

    final filler = AnimatedOpacity(
      opacity: value.length == 0 ? 0.0 : 1.0,
      duration: Duration(milliseconds: 150),
      child: AnimatedContainer(
        width: (theme.spacing * 2.5 * max(value.length, 1)) - (theme.spacing * 0.5),
        height: theme.spacing * 2,
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOutExpo,
        decoration: new BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(theme.spacing)),
          color: obscureText ? theme.primaryBlue : theme.grayscale90,
        ),
      ),
    );

    for (int i = 0; i < len; i++) {
      String char = i < value.length ? value[i] : '';
      bool filled = char != '';
      var grey = obscureText ? theme.grayscale80 : theme.grayscale90;

      if (obscureText && filled) {
        char = ' ';
      }

      boxes[i] = Container(
        margin: EdgeInsets.only(right: i == len - 1 ? 0 : theme.spacing * 0.5),
        width: theme.spacing * 2,
        height: theme.spacing * 2,
        alignment: Alignment.center,
        decoration: new BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(theme.spacing)),
          color: grey,
        ),
        child: new Text(
          char,
          style: Theme.of(context).textTheme.body2.copyWith(
                fontSize: theme.spacing * 1.5,
                color: complete ? theme.primaryBlue : theme.primaryDark,
              ),
        ),
      );
    }

    var transparentBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
    );

    return Stack(
      children: [
        Container(
          width: 0.1,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: () {
              final val = controller.text;
              if (val.length >= widget.minLength && val.length <= widget.maxLength && widget.onSubmit != null) {
                widget.onSubmit(val);
              }
            },
            inputFormatters: [
              WhitelistingTextInputFormatter(RegExp('[0-9]')),
            ],
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(signed: false, decimal: false),
            obscureText: true,
            style: TextStyle(
              height: 0.1,
              color: Colors.transparent,
            ),
            decoration: InputDecoration(
              focusedErrorBorder: transparentBorder,
              errorBorder: transparentBorder,
              disabledBorder: transparentBorder,
              enabledBorder: transparentBorder,
              focusedBorder: transparentBorder,
              counterText: null,
              counterStyle: null,
              helperStyle: TextStyle(
                height: 0.0,
                color: Colors.transparent,
              ),
              labelStyle: TextStyle(height: 0.1),
              fillColor: Colors.transparent,
              border: InputBorder.none,
            ),
            cursorColor: Colors.transparent,
            maxLength: widget.maxLength,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: theme.spacing * 2, height: theme.spacing * 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(focusNode);
                });
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                child: Stack(
                  children: [
                    if (!obscureText) ...[filler],
                    Wrap(children: boxes),
                    if (obscureText) ...[filler],
                  ],
                ),
              ),
            ),
            SizedBox(
              width: theme.spacing * 2,
              height: theme.spacing * 2,
              child: IconButton(
                iconSize: theme.spacing,
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () {
                  setState(
                    () {
                      obscureText = !obscureText;
                    },
                  );
                },
              ),
            )
          ],
        ),
      ],
    );
  }
}
