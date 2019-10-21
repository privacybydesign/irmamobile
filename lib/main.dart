import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/src/store/app_bloc_delegate.dart';
import 'package:irmamobile/src/store/irma_client/irma_client_bloc.dart';

void main() {
  // Register the app bloc delegate and register app-wide blocs to it that intercept all events
  AppBlocDelegate appBlocDelegate = AppBlocDelegate();
  BlocSupervisor.delegate = appBlocDelegate;

  List<BlocProvider> appBlocProviders = [
    BlocProvider<IrmaClientBloc>.value(value: appBlocDelegate.registerBloc(IrmaClientBloc())),
  ];

  // Run the application
  runApp(App(appBlocProviders));
}
