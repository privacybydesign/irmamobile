import 'package:flutter/material.dart';
import 'package:irmamobile/src/theme/irma-icons.dart';
import 'package:irmamobile/src/theme/theme.dart';

void startDesignFields(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) {
      return DesignFields();
    }),
  );
}

class DesignFields extends StatefulWidget {
  @override
  _DesignFieldsState createState() => _DesignFieldsState();
}

class _DesignFieldsState extends State<DesignFields> {
  final enabledWithValueTextEditingController = TextEditingController.fromValue(
    TextEditingValue(text: "Value"),
  );
  final disabledWithValueTextEditingController = TextEditingController.fromValue(
    TextEditingValue(text: "Value"),
  );

  final validTextEditingController = TextEditingController(
    text: "valid value",
  );
  final warningTextEditingController = TextEditingController(
    text: "valid value (but warning)",
  );
  final invalidTextEditingController = TextEditingController(
    text: "invalid value",
  );

  final multilineTextEditingController = TextEditingController.fromValue(
    TextEditingValue(
      text:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean scelerisque vulputate ipsum, ac euismod libero ultricies vitae. Duis vel lorem congue, imperdiet orci eget, egestas eros.",
    ),
  );

  var selectedValue = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Fields"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Text("TextField", style: IrmaTheme.of(context).textTheme.display3),
              Text("Enabled", style: Theme.of(context).textTheme.display2),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "enabled empty",
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                    ),
                  ),
                  _buildTextFieldExample(
                    context,
                    "enabled with hint on focus",
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: "hint text",
                        labelText: "Label",
                      ),
                    ),
                  ),
                  _buildTextFieldExample(
                    context,
                    "enabled with value",
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      controller: enabledWithValueTextEditingController,
                    ),
                  ),
                ],
              ),
              Text("Disabled", style: Theme.of(context).textTheme.display2),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "disabled empty",
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      enabled: false,
                    ),
                  ),
                  _buildTextFieldExample(
                    context,
                    "disabled with value",
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      enabled: false,
                      controller: disabledWithValueTextEditingController,
                    ),
                  ),
                ],
              ),
              Text("Validated", style: Theme.of(context).textTheme.display2),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "valid",
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                        suffixIcon: Icon(IrmaIcons.valid, color: IrmaTheme.of(context).primaryDark),
                      ),
                      controller: validTextEditingController,
                    ),
                  ),
                  _buildTextFieldExample(
                    context,
                    "warning",
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                        suffixIcon: Icon(IrmaIcons.warning, color: IrmaTheme.of(context).interactionAlert),
                      ),
                      controller: warningTextEditingController,
                    ),
                  ),
                  _buildTextFieldExample(
                    context,
                    "invalid",
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                        suffixIcon: Icon(IrmaIcons.invalid, color: IrmaTheme.of(context).interactionInvalid),
                        errorText: "This is an error message",
                      ),
                      controller: invalidTextEditingController,
                    ),
                  ),
                ],
              ),
              Text("Multi-line", style: Theme.of(context).textTheme.display2),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "multi-line",
                    TextField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      controller: multilineTextEditingController,
                      maxLines: 4,
                    ),
                  ),
                ],
              ),
              Text("Dropdown", style: IrmaTheme.of(context).textTheme.display3),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "enabled",
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      hint: Text("Label"),
                      value: selectedValue,
                      onChanged: (value) {
                        setState(() {
                          selectedValue = value;
                        });
                        print(value);
                      },
                      items: [
                        DropdownMenuItem(child: Text("Maak een keuze"), value: -1),
                        DropdownMenuItem(child: Text("Eerste optie"), value: 0),
                        DropdownMenuItem(child: Text("Tweede optie"), value: 1),
                        DropdownMenuItem(child: Text("Derde optie"), value: 2),
                        DropdownMenuItem(child: Text("Vierde optie"), value: 3),
                        DropdownMenuItem(child: Text("Laatste optie"), value: 4),
                      ],
                    ),
                  ),
                ],
              ),
              Wrap(
                children: <Widget>[
                  _buildTextFieldExample(
                    context,
                    "disabled",
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      value: -1,
                      // Currently, only way to disable DropdownButtonFormField is to set items to null.
                      // https://github.com/flutter/flutter/issues/27009
                      onChanged: null,
                      items: null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFieldExample(BuildContext context, String name, Widget textField) {
    return Padding(
      padding: EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          textField,
          SizedBox(height: 8.0),
          Text(name, style: IrmaTheme.of(context).textTheme.caption.copyWith(color: IrmaTheme.of(context).grayscale80)),
        ],
      ),
    );
  }
}
