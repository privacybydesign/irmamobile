import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

import 'irma_button.dart';

class PinField extends StatefulWidget {
  final bool autofocus;
  final bool autosubmit;
  final bool autoclear;
  final bool enabled;
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
    this.enabled = true,
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

  @override
  void initState() {
    super.initState();
    value = '';
    obscureText = true;

    focusNode = widget.focusNode ?? FocusNode();
    _textEditingController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(PinField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear the input when we switch from short to long or vice versa
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

  void _onTextChanged() {
    final changedValue = _textEditingController.text;

    if (changedValue.length != value.length && changedValue.length == widget.maxLength && !widget.longPin) {
      _onFull(changedValue);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isDisposed) {
          return;
        }

        if (widget.autosubmit) {
          _onSubmit(changedValue);
        }
      });
    }

    setState(() {
      value = changedValue;
    });

    if (widget.onChange != null) {
      widget.onChange(changedValue);
    }
  }

  void _onSubmit(String value) {
    if (widget.onSubmit != null) {
      widget.onSubmit(value);
    }
    if (widget.autoclear) {
      _textEditingController.clear();
    }
  }

  void _onFull(String value) {
    if (widget.onFull != null) {
      widget.onFull(value);
    }
  }

  void _onEditingCompleteOrSubmit() {
    final val = _textEditingController.text;

    if (val.length >= widget.minLength && val.length <= widget.maxLength) {
      _onSubmit(val);
    }
  }

  // Make the text transparent for short PINs
  TextStyle _formFieldStyle() {
    if (widget.longPin) {
      return null;
    }

    return const TextStyle(
      height: 0.1,
      color: Colors.transparent,
    );
  }

  // Hide the form field with transparancy for short PINs
  InputDecoration _formFieldDecoration() {
    if (widget.longPin) {
      return const InputDecoration();
    }

    const transparentBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
    );

    return InputDecoration(
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
    );
  }

  // PIN boxes for short pins
  Widget _buildPinBoxes() {
    final theme = IrmaTheme.of(context);
    final bool complete = value.length == widget.maxLength;

    final boxes = List<Widget>.generate(widget.maxLength, (i) {
      String char = i < value.length ? value[i] : '';
      final bool filled = char != '';

      final hasBorder = i > value.length || !widget.enabled;
      if (obscureText && filled) {
        char = '●';
      }

      Color setBorderColor() {
        if (hasBorder) {
          // empty boxes that are not in focus
          return theme.grayscale60;
        } else if (hasBorder || filled) {
          return theme.grayscale40; // filled boxes
        } else {
          // the box that is currently in focus
          return theme.primaryBlue;
        }
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: i == widget.maxLength - 1 ? 0 : theme.smallSpacing),
        width: 30.0,
        height: 40.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(theme.tinySpacing)),
            border: Border.all(
              color: setBorderColor(),
              width: filled || hasBorder ? 1 : 2,
            ),
            color: widget.enabled ? theme.grayscaleWhite : theme.disabled),
        child: Text(
          char,
          style: Theme.of(context).textTheme.display2.copyWith(
                height: 22.0 / 18.0,
                color: complete ? theme.primaryBlue : theme.grayscale40,
              ),
        ),
      );
    });

    return Row(
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
    );
  }

  // Submit buttons for longs PINs
  Widget _buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.all(
        IrmaTheme.of(context).defaultSpacing,
      ),
      child: IrmaButton(
        label: FlutterI18n.translate(context, "pin_common.done"),
        onPressed: widget.enabled ? _onEditingCompleteOrSubmit : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(milliseconds: widget.longPin ? 200 : 0),
              width: widget.longPin ? MediaQuery.of(context).size.width - 2 * theme.hugeSpacing : 0.1,
              child: TextField(
                controller: _textEditingController,
                enabled: widget.enabled,
                focusNode: focusNode,
                onEditingComplete: _onEditingCompleteOrSubmit,
                autofocus: widget.autofocus,
                obscureText: obscureText,
                cursorColor: Colors.transparent,
                maxLength: widget.maxLength,
                enableInteractiveSelection: false,

                // Only allow numeric input, without signs or decimal points
                keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false),
                inputFormatters: [
                  WhitelistingTextInputFormatter(RegExp('[0-9]')),
                ],

                // Set the style (dependent on if the input is for long PINs)
                style: _formFieldStyle(),
                decoration: _formFieldDecoration(),
              ),
            ),
            if (!widget.longPin) ...[
              _buildPinBoxes(),
            ],
            SizedBox(
              width: theme.largeSpacing,
              height: theme.largeSpacing,
              child: IconButton(
                iconSize: theme.defaultSpacing,
                icon: Icon(
                  obscureText ? IrmaIcons.view : IrmaIcons.hide,
                  semanticLabel: FlutterI18n.translate(context, obscureText ? "pin_common.view" : "pin_common.hide"),
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
        ),
        if (widget.longPin) ...[
          _buildSubmitButton(),
        ],
      ],
    );
  }
}
