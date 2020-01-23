import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/card_suggestion.dart';
import 'package:irmamobile/src/widgets/card_suggestion_group.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

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
  final _enabledWithValueTextEditingController = TextEditingController.fromValue(
    TextEditingValue(text: "Value"),
  );
  final _disabledWithValueTextEditingController = TextEditingController.fromValue(
    TextEditingValue(text: "Value"),
  );

  final _validTextEditingController = TextEditingController(
    text: "valid value",
  );
  final _warningTextEditingController = TextEditingController(
    text: "valid value (but warning)",
  );
  final _invalidTextEditingController = TextEditingController(
    text: "invalid value",
  );

  final _multilineTextEditingController = TextEditingController.fromValue(
    TextEditingValue(
      text:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean scelerisque vulputate ipsum, ac euismod libero ultricies vitae. Duis vel lorem congue, imperdiet orci eget, egestas eros.",
    ),
  );

  var _selectedValue = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: IrmaAppBar(
        title: const Text("Fields"),
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
                      controller: _enabledWithValueTextEditingController,
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
                      controller: _disabledWithValueTextEditingController,
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
                      controller: _validTextEditingController,
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
                      controller: _warningTextEditingController,
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
                      controller: _invalidTextEditingController,
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
                      controller: _multilineTextEditingController,
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
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: "Label",
                      ),
                      hint: const Text("Label"),
                      value: _selectedValue,
                      onChanged: (value) {
                        setState(() {
                          _selectedValue = value;
                        });
                        debugPrint(value.toString());
                      },
                      items: const [
                        DropdownMenuItem(value: -1, child: Text("Maak een keuze")),
                        DropdownMenuItem(value: 0, child: Text("Eerste optie")),
                        DropdownMenuItem(value: 1, child: Text("Tweede optie")),
                        DropdownMenuItem(value: 2, child: Text("Derde optie")),
                        DropdownMenuItem(value: 3, child: Text("Vierde optie")),
                        DropdownMenuItem(value: 4, child: Text("Laatste optie")),
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
              Text("Card Group", style: IrmaTheme.of(context).textTheme.display3),
              CardSuggestionGroup(
                title: FlutterI18n.translate(context, 'card_store.personal_data'),
                credentials: <CardSuggestion>[
                  CardSuggestion(
                    icon: Image.asset("assets/non-free/irmalogo.png"),
                    title: "Persoonsgegevens",
                    subTitle: "Gemeente(BRP)",
                    obtained: false,
                    onTap: () {
                      debugPrint("clicked");
                    },
                  ),
                  CardSuggestion(
                    icon: Image.asset("assets/non-free/irmalogo.png"),
                    title: "Persoonsgegevens",
                    subTitle: "Gemeente(BRP)",
                    obtained: false,
                    onTap: () {
                      debugPrint("clicked");
                    },
                  ),
                  CardSuggestion(
                    icon: Image.asset("assets/non-free/irmalogo.png"),
                    title: "Persoonsgegevens",
                    subTitle: "Gemeente(BRP)",
                    obtained: true,
                    onTap: () {
                      debugPrint("clicked");
                    },
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
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: <Widget>[
          textField,
          const SizedBox(height: 8.0),
          Text(name, style: IrmaTheme.of(context).textTheme.caption.copyWith(color: IrmaTheme.of(context).grayscale80)),
        ],
      ),
    );
  }
}
