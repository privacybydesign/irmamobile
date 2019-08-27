import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class PinField extends StatefulWidget {
  final bool autofocus;
  final int maxLength;
  final int minLength;
  final ValueChanged<String> onSubmit;

  PinField({
    this.minLength = 5,
    this.maxLength = 16,
    this.autofocus = true,
    this.onSubmit,
  });

  @override
  _PinFieldState createState() => _PinFieldState();
}

class _PinFieldState extends State<PinField> {
  final controller = TextEditingController();

  bool obscureText;
  String value;
  FocusNode focusNode;

  @override
  void initState() {
    value = '';
    obscureText = true;
    focusNode = FocusNode();
    super.initState();
    controller.addListener(_updateLength);
  }

  _updateLength() {
    setState(() {
      value = controller.text;

      if (value.length == widget.maxLength) {
        widget.onSubmit(value);
      }
    });
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int len =
        min(widget.maxLength, max(value.length + 1, widget.minLength));
    final boxes = List<Widget>(len);

    for (int i = 0; i < len; i++) {
      String char = i < value.length ? value[i] : '';

      if (obscureText && char != '') {
        char = '*';
      }

      boxes[i] = Container(
        margin: const EdgeInsets.all(5.0),
        padding: const EdgeInsets.all(5.0),
        width: 30,
        alignment: Alignment.center,
        decoration: new BoxDecoration(
          border: new Border.all(color: Colors.black),
          borderRadius: BorderRadius.all(Radius.circular(5)),
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
          onFieldSubmitted: widget.onSubmit,
          inputFormatters: [
            WhitelistingTextInputFormatter(RegExp('[0-9]')),
          ],
          autofocus: true,
          keyboardType:
              TextInputType.numberWithOptions(signed: false, decimal: false),
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
                Future.delayed(Duration(milliseconds: 100), () {
                  FocusScope.of(context).requestFocus(focusNode);
                });
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 80),
                child: Wrap(children: boxes),
              ),
            ),
            IconButton(
              iconSize: 20,
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
