import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

  bool obscureText;
  String value;
  FocusNode focusNode;
  int lastLength;

  @override
  void initState() {
    value = '';
    lastLength = 0;
    obscureText = true;

    focusNode = FocusNode();
    super.initState();
    controller.addListener(_updateLength);
  }

  _updateLength() {
    final val = controller.text;
    final len = val.length;

    if (len != lastLength && len == widget.maxLength) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (widget.onFull != null) {
          widget.onFull(val);
        }

        if (widget.onSubmit != null && widget.autosubmit) {
          widget.onSubmit(val);
        }

        if (widget.autoclear) {
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
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int len = min(widget.maxLength, max(value.length + 1, widget.minLength));
    final boxes = List<Widget>(len);

    for (int i = 0; i < len; i++) {
      String char = i < value.length ? value[i] : '';

      if (obscureText && char != '') {
        char = ' ';
      }

      boxes[i] = Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        width: 40.0,
        height: 40.0,
        alignment: Alignment.center,
        decoration: new BoxDecoration(
          border: new Border.all(color: Colors.black),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          color: char == ' ' ? Colors.black : Colors.white,
        ),
        child: new Text(char, style: TextStyle(fontSize: 20)),
      );
    }

    var transparentBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.transparent,
        width: 0.0,
      ),
    );

    return Stack(children: [
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
      Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 48, height: 48),
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
            child: Wrap(children: boxes),
          ),
        ),
        IconButton(
          iconSize: 20,
          padding: EdgeInsets.all(5.0),
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
            color: Theme.of(context).primaryColorDark,
          ),
          onPressed: () {
            setState(() {
              obscureText = !obscureText;
            });
          },
        ),
      ]),
    ]);
  }
}
