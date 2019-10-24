import 'package:flutter/material.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';

void startDevExperiment1(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('IrmaRepository voorbeeld'),
          ),
          // We're going to obtain a credential from the repository. We don't
          // know if this is mock data or the real stuff, this widget doesn't
          // care.
          //
          // In A BLoC scenario, the repository is used by the Bloc class, not
          // by the widget. See Dev Experiment 2 for an example.
          body: StreamBuilder<Credential>(
            // get a Future<Credential> from the repository
            stream: IrmaRepository.get().getCredential("mySchemeManager.myIssuer.myCredentialFoo"),

            // build a UI based on the credential
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                // We're waiting for the Future to resolve, show a loading screen.
                return Center(child: Text("Loading..."));
              }

              if (snapshot.error != null) {
                throw snapshot.error;
              }

              // When the Future has resolved, show a list of key/values
              return Center(
                child: ListView.builder(
                  itemCount: snapshot.data.attributes.length,
                  itemBuilder: (BuildContext context, int index) {
                    AttributeType key = snapshot.data.attributes.keys.elementAt(index);
                    return Row(children: [
                      Text(key.name['nl']), // TODO: use TranslatedValue
                      Text(" = "),
                      Text(snapshot.data.attributes[key].translate('nl')),
                    ]);
                  },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
