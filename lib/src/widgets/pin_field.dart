import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

class PinField extends StatefulWidget {
  final bool autofocus;
  final bool autosubmit;
  final bool autoclear;
  final FocusNode focusNode;
  final bool longPin;
  final ValueChanged<String> onChange;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFull;

  int get maxLength {
    return longPin ? 16 : 5;
  }

  int get minLength {
    return 5;
  }

  const PinField({
    this.longPin = false,
    this.autofocus = true,
    this.autosubmit = true,
    this.autoclear = true,
    this.focusNode,
    this.onChange,
    this.onSubmit,
    this.onFull,
  });

  @override
  _PinFieldState createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  final _textEditingController = TextEditingController();
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

    focusNode = widget.focusNode ?? FocusNode();
    _textEditingController.addListener(_updateLength);
  }

  void _updateLength() {
    final val = _textEditingController.text;
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
          _textEditingController.clear();
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
  void didUpdateWidget(PinField oldWidget) {
    super.didUpdateWidget(oldWidget);
    focusNode = widget.focusNode ?? focusNode;
    if (widget.longPin != oldWidget.longPin) {
      _textEditingController.clear();
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _isDisposed = true;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final int len = min(widget.maxLength, max(value.length + 1, widget.minLength));
    final boxes = List<Widget>(len);
    final bool complete = value.length == widget.maxLength;

    if (!widget.longPin) {
      for (int i = 0; i < len; i++) {
        String char = i < value.length ? value[i] : '';
        final bool filled = char != '';

        if (obscureText && filled) {
          char = '●';
        }

        boxes[i] = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: EdgeInsets.only(right: i == len - 1 ? 0 : theme.smallSpacing),
          width: 30.0,
          height: 40.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(theme.tinySpacing)),
            border: Border.all(color: i > value.length ? Colors.transparent : theme.grayscale40),
            color: theme.grayscaleWhite,
          ),
          child: Text(
            char,
            style: Theme.of(context).textTheme.display2.copyWith(
                  height: 22.0 / 18.0,
                  color: complete ? theme.primaryBlue : theme.grayscale40,
                ),
          ),
        );
      }
    }

    const transparentBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedContainer(
          duration: Duration(milliseconds: widget.longPin ? 200 : 0),
          width: widget.longPin ? MediaQuery.of(context).size.width - theme.hugeSpacing : 0.1,
          child: TextFormField(
            controller: _textEditingController,
            focusNode: focusNode,
            onEditingComplete: () {
              final val = _textEditingController.text;
              if (val.length >= widget.minLength && val.length <= widget.maxLength && widget.onSubmit != null) {
                widget.onSubmit(val);
              }
            },
            inputFormatters: [
              WhitelistingTextInputFormatter(RegExp('[0-9]')),
            ],
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
            obscureText: obscureText,
            style: widget.longPin
                ? null
                : const TextStyle(
                    height: 0.1,
                    color: Colors.transparent,
                  ),
            decoration: widget.longPin
                ? const InputDecoration()
                : InputDecoration(
                    focusedErrorBorder: transparentBorder,
                    errorBorder: transparentBorder,
                    disabledBorder: transparentBorder,
                    enabledBorder: transparentBorder,
                    focusedBorder: transparentBorder,
                    counterText: null,
                    counterStyle: null,
                    helperStyle: const TextStyle(
                      height: 0.0,
                      color: Colors.transparent,
                    ),
                    labelStyle: const TextStyle(height: 0.1),
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                  ),
            cursorColor: Colors.transparent,
            maxLength: widget.maxLength,
          ),
        ),
        if (!widget.longPin)
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: theme.largeSpacing, height: theme.largeSpacing),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  Future.delayed(const Duration(milliseconds: 100), () {
                    FocusScope.of(context).requestFocus(focusNode);
                  });
                },
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 64),
                  child: Wrap(children: boxes),
                ),
              ),
            ],
          ),
        SizedBox(
          width: theme.largeSpacing,
          height: theme.largeSpacing,
          child: IconButton(
            iconSize: obscureText ? theme.defaultSpacing : theme.mediumSpacing,
            icon: Icon(
              obscureText ? IrmaIcons.view : IrmaIcons.hide,
              color: theme.grayscale40,
            ),
            onPressed: () {
              setState(() {
                obscureText = !obscureText;
              });
            },
          ),
        ),
      ],
    );
  }
}
