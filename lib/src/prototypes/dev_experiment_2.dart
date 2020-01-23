import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/widgets/irma_app_bar.dart';

class MyEvent {}

class MyState {
  final Credential credential;
  MyState({this.credential});
}

class MyBloc extends Bloc<MyEvent, MyState> {
  MyBloc();

  @override
  MyState get initialState => MyState();

  @override
  Stream<MyState> mapEventToState(MyEvent event) {
    return IrmaRepository.get().getCredential("mySchemeManager.myIssuer.myCredentialFoo").map<MyState>((credential) {
      return MyState(credential: credential);
    });
  }
}

void startDevExperiment2(BuildContext context) {
  final myBloc = MyBloc();
  myBloc.dispatch(MyEvent());

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: IrmaAppBar(
            title: const Text('IrmaRepository BLoC voorbeeld'),
          ),
          body: BlocBuilder<MyBloc, MyState>(
            bloc: myBloc,
            builder: (context, state) {
              if (state.credential == null) {
                return Center(child: const Text("Loading..."));
              }
              return Center(
                child: ListView.builder(
                  itemCount: state.credential.attributes.length,
                  itemBuilder: (BuildContext context, int index) {
                    final AttributeType key = state.credential.attributes.keys.elementAt(index);
                    return Row(children: [
                      Text(key.name['nl']), // TODO: use TranslatedValue
                      const Text(" = "),
                      Text(state.credential.attributes[key].translate('nl')),
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
