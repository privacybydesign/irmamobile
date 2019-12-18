import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/src/screens/enrollment/enrollment_screen.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/src/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/src/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/src/widgets/pin_field.dart';

import 'testing_app.dart';

void main() {
  setUp(() {
    WidgetsBinding.instance.renderView.configuration = TestViewConfiguration(size: const Size(1200.0, 1980.0));
  });

  testWidgets('Enrollment basic flow test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(TestingApp(builder: (_) => EnrollmentScreen()));
    await tester.pumpAndSettle();

    // expect a choose pin button
    expect(find.text('Kies je pincode'), findsOneWidget);

    // tap the choose pin button
    await tester.tap(find.text('Kies je pincode'));
    await tester.pump();

    // expect the choose pin screen to appear
    expect(find.text('Voer je pincode in'), findsOneWidget);
    await tester.enterText(find.byType(PinField), "87129");
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    expect(find.text('Pincode kiezen'), findsOneWidget);

    await tester.enterText(find.byType(PinField), "87129");
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    expect(
        find.text(
            'Vul nu je e-mailadres in, dan kun je bij verlies of diefstal van je telefoon, IRMA op je telefoon blokkeren.'),
        findsOneWidget);
  });

  testWidgets('Enrollment error flow test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(TestingApp(builder: (_) => EnrollmentScreen()));
    await tester.pumpAndSettle();

    // expect a choose pin button
    expect(find.text('Kies je pincode'), findsOneWidget);

    // tap the choose pin button
    await tester.tap(find.text('Kies je pincode'));
    await tester.pump();

    // expect the choose pin screen to appear
    expect(find.text('Kies een pincode van 5 cijfers'), findsOneWidget);
    await tester.enterText(find.byType(PinField), "87129");
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));

    expect(find.text('Pincode kiezen'), findsOneWidget);

    await tester.enterText(find.byType(PinField), "97684");
    await tester.pumpAndSettle(const Duration(milliseconds: 1000));
    expect(find.text('De pincodes kwamen niet overeen, probeer het nog eens.'), findsOneWidget);
  });

  testWidgets('Show a failed email validation message', (WidgetTester tester) async {
    await tester.pumpWidget(TestingApp(
        builder: (_) => BlocProvider<EnrollmentBloc>(
            builder: (_) => EnrollmentBloc.test(EnrollmentState()
                .copyWith(pin: '1234', pinConfirmed: true, emailValid: false, showEmailValidation: true)),
            child:
                ProvideEmail(submitEmail: () => {}, skipEmail: () => {}, changeEmail: (_) => {}, cancel: () => {}))));
    await tester.pumpAndSettle();

    expect(find.text('Dit is geen geldig e-mailadres'), findsOneWidget);
  });

  testWidgets('Email input shows no warning when requesting email', (WidgetTester tester) async {
    await tester.pumpWidget(TestingApp(
        builder: (_) => BlocProvider<EnrollmentBloc>(
            builder: (_) => EnrollmentBloc.test(EnrollmentState().copyWith(emailValid: true)),
            child:
                ProvideEmail(submitEmail: () => {}, skipEmail: () => {}, changeEmail: (_) => {}, cancel: () => {}))));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Vul nu je e-mailadres in, dan kun je bij verlies of diefstal van je telefoon, IRMA op je telefoon blokkeren.'),
        findsOneWidget);
    expect(find.text('Dit is geen geldig e-mailadres'), findsNothing);
  });

  testWidgets('Show a failed email validation message', (WidgetTester tester) async {
    await tester.pumpWidget(TestingApp(
        builder: (_) => BlocProvider<EnrollmentBloc>(
            builder: (_) => EnrollmentBloc.test(EnrollmentState()
                .copyWith(pin: '1234', pinConfirmed: true, emailValid: false, showEmailValidation: true)),
            child:
                ProvideEmail(submitEmail: () => {}, skipEmail: () => {}, changeEmail: (_) => {}, cancel: () => {}))));
    await tester.pumpAndSettle();

    expect(find.text('Dit is geen geldig e-mailadres'), findsOneWidget);
  });
}
