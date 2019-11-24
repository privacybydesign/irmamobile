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
  final int maxLength;
  final int minLength;
  final ValueChanged<String> onChange;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onFull;

  const PinField({
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

    focusNode = FocusNode();
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
  void dispose() {
    _textEditingController.dispose();
    focusNode.dispose();
    _isDisposed = true;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    if (widget.maxLength > 5) {
      return Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: MediaQuery.of(context).size.width - theme.spacing * 4,
          child: Row(
            children: <Widget>[
              Flexible(
                child: TextFormField(
                  controller: _textEditingController,
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

    for (int i = 0; i < len; i++) {
      String char = i < value.length ? value[i] : '';
      final bool filled = char != '';

      if (obscureText && filled) {
        char = '●';
      }

      boxes[i] = Container(
        margin: EdgeInsets.only(right: i == len - 1 ? 0 : theme.spacing * 0.5),
        width: theme.spacing * 1.5,
        height: theme.spacing * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(theme.spacing * 0.25)),
          border: Border.all(color: theme.primaryDark),
          color: theme.grayscaleWhite,
        ),
        child: Text(
          char,
          style: Theme.of(context).textTheme.body2.copyWith(
                color: complete ? theme.primaryBlue : theme.primaryDark,
              ),
        ),
      );
    }

    final transparentBorder = OutlineInputBorder(
      borderSide: const BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
    );

    return Stack(
      children: [
        Container(
          width: 0.1,
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
            obscureText: true,
            style: const TextStyle(
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
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: theme.spacing * 2, height: theme.spacing * 2),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(const Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(focusNode);
                });
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 80),
                child: Wrap(children: boxes),
              ),
            ),
            SizedBox(
              width: theme.spacing * 2,
              height: theme.spacing * 2,
              child: IconButton(
                iconSize: theme.spacing * 0.75,
                icon: Icon(
                  // TODO: add irma icon
                  obscureText ? IrmaIcons.view : Icons.visibility_off,
                  color: theme.grayscale40,
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
