import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/version_information.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

void startDevExperiment3(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: IrmaAppBar(
            title: const Text('Update available voorbeeld'),
          ),
          body: StreamBuilder<VersionInformation>(
            stream: IrmaRepository.get().getVersionInformation(),
            builder: (context, snapshot) {
              switch (snapshot.data?.updateAvailable()) {
                case false:
                  return Center(
                    child: Container(
                      color: IrmaTheme.of(context).interactionInformation,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No update available"),
                      ),
                    ),
                  );
                case true:
                  return Center(
                    child: Container(
                      color: IrmaTheme.of(context).interactionAlert,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("Update available"),
                      ),
                    ),
                  );
              }
              return Container();
            },
          ),
        );
      },
    ),
  );
}
