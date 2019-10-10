import 'package:flutter/material.dart';
import 'package:irmamobile/src/screens/add_cards/widgets/credential.dart';
import 'package:irmamobile/src/theme/theme.dart';

class CredentialGroup extends StatelessWidget {
  final List<Credential> credentials;
  final String title;
  const CredentialGroup({Key key, this.title, this.credentials}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: credentials.length + 1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(
              top: 8.0,
              bottom: 8.0,
            ),
            child: Text(
              title,
              style: IrmaTheme.of(context).textTheme.title,
            ),
          );
        }

        return credentials[index - 1];
      },
      separatorBuilder: (context, index) {
        return Divider(
          color: Colors.grey,
          height: 5,
        );
      },
    );
  }
}
