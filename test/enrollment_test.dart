import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irmamobile/app.dart';
import 'package:irmamobile/screens/enrollment/enrollment.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_bloc.dart';
import 'package:irmamobile/screens/enrollment/models/enrollment_state.dart';
import 'package:irmamobile/screens/enrollment/widgets/provide_email.dart';
import 'package:irmamobile/widgets/pin_field.dart';

void main() {
  setUp(() {});

  testWidgets('Enrollment basic flow test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(App.test((_) => Enrollment()));
    await tester.pumpAndSettle();

    // expect a choose pin button
    expect(find.text('Kies je pincode'), findsOneWidget);

    // tap the choose pin button
    await tester.tap(find.text('Kies je pincode'));
    await tester.pump();

    // expect the choose pin screen to appear
    expect(
        find.text('Kies een pincode van minimaal 5 cijfers'), findsOneWidget);
    await tester.enterText(find.byType(PinField), "87129");
    await tester.pumpAndSettle();
    expect(find.text('Volgende'), findsOneWidget);

    await tester.tap(find.text('Volgende'));
    await tester.pumpAndSettle();
    expect(find.text('Herhaal je pincode'), findsOneWidget);

    await tester.enterText(find.byType(PinField), "87129");
    await tester.pumpAndSettle();
    expect(
        find.text(
            'Geef een e-mailadres op. Dan kun je bij verlies of diefstal van je telefoon, zorgen dat niemand jouw persoonlijke gegevens kan zien.'),
        findsOneWidget);
  });

  testWidgets('Email input shows no warning when requesting email',
      (WidgetTester tester) async {
    await tester.pumpWidget(App.test((_) => ProvideEmail(), [
      BlocProvider<EnrollmentBloc>(
          builder: (_) => EnrollmentBloc.test(EnrollmentState().copyWith(
                emailValidated: true,
              )))
    ]));
    await tester.pumpAndSettle();

    expect(
        find.text(
            'Geef een e-mailadres op. Dan kun je bij verlies of diefstal van je telefoon, zorgen dat niemand jouw persoonlijke gegevens kan zien.'),
        findsOneWidget);
    expect(
        find.text('Het ingevulde e-mailadres is niet geldig.'), findsNothing);
  });

  testWidgets('Show a failed email validation message',
      (WidgetTester tester) async {
    await tester.pumpWidget(App.test((_) => ProvideEmail(), [
      BlocProvider<EnrollmentBloc>(
          builder: (_) => EnrollmentBloc.test(EnrollmentState().copyWith(
                pin: '1234',
                pinConfirmed: true,
                emailValidated: false,
              )))
    ]));
    await tester.pumpAndSettle();

    expect(
        find.text('Het ingevulde e-mailadres is niet geldig.'), findsOneWidget);
  });
}
