// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_i18n/flutter_i18n.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// import '../../../sentry/sentry.dart';
// import '../../../theme/irma_icons.dart';
// import '../../../theme/theme.dart';
// import '../../../widgets/heading.dart';
// import '../../../widgets/irma_button.dart';
// import '../../../widgets/irma_repository_provider.dart';
// import '../../../widgets/link.dart';
// import 'choose_pin.dart';

// class Introduction extends StatefulWidget {
//   static const String routeName = 'introduction';

//   @override
//   _IntroductionState createState() => _IntroductionState();
// }

// class _IntroductionState extends State<Introduction> {
//   int currentIndexPage = 0;
//   int pageLength = 3;

//   final _controller = PageController(
//     initialPage: 0,
//   );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // Prevent overflow when returning from pin input
//       resizeToAvoidBottomInset: false,
//       body: Container(
//         padding: EdgeInsets.only(top: IrmaTheme.of(context).largeSpacing),
//         child: PageView(
//           controller: _controller,
//           scrollDirection: Axis.vertical,
//           onPageChanged: (value) {
//             setState(() => currentIndexPage = value);
//           },
//           children: [
//             Walkthrough(
//               image: SvgPicture.asset('assets/enrollment/introduction_screen1.svg',
//                   excludeFromSemantics: true, width: 280, height: 245),
//               titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen1.title'),
//               textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen1.text'),
//               key: const Key('enrollment_p1'),
//               onNextScreen: () => _controller.nextPage(curve: Curves.ease, duration: const Duration(milliseconds: 800)),
//             ),
//             Walkthrough(
//               image: SvgPicture.asset('assets/enrollment/introduction_screen2.svg',
//                   excludeFromSemantics: true, width: 280, height: 231),
//               titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen2.title'),
//               textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen2.text'),
//               key: const Key('enrollment_p2'),
//               onNextScreen: () => _controller.nextPage(curve: Curves.ease, duration: const Duration(milliseconds: 800)),
//             ),
//             Walkthrough(
//               image: SvgPicture.asset('assets/enrollment/introduction_screen3.svg',
//                   excludeFromSemantics: true, width: 341, height: 247),
//               titleContent: FlutterI18n.translate(context, 'enrollment.introduction.screen3.title'),
//               textContent: FlutterI18n.translate(context, 'enrollment.introduction.screen3.text'),
//               linkText: 'enrollment.introduction.screen3.privacy.text',
//               linkUrl: 'enrollment.introduction.screen3.privacy.url',
//               key: const Key('enrollment_p3'),
//               onNextScreen: () => {},
//               onPressButton: () => Navigator.of(context).pushNamed(ChoosePin.routeName),
//               finalScreen: true,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class Walkthrough extends StatelessWidget {
//   final String titleContent;
//   final String textContent;
//   final String? linkText;
//   final String? linkUrl;
//   final SvgPicture image;
//   final bool finalScreen;
//   final void Function() onNextScreen;
//   final void Function()? onPressButton;

//   const Walkthrough({
//     Key? key,
//     required this.titleContent,
//     required this.textContent,
//     required this.image,
//     required this.onNextScreen,
//     this.linkText,
//     this.linkUrl,
//     this.onPressButton,
//     this.finalScreen = false,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final theme = IrmaTheme.of(context);

//     return Semantics(
//       explicitChildNodes: true,
//       child: Column(
//         children: [
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 image,
//                 Container(
//                   padding: const EdgeInsets.only(top: 30.0),
//                   alignment: Alignment.center,
//                   constraints: const BoxConstraints(maxWidth: 288.0),
//                   child: Heading(
//                     titleContent,
//                     style: theme.textTheme.headline3,
//                     textAlign: TextAlign.center,
//                     key: const Key('intro_heading'),
//                   ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.only(top: theme.defaultSpacing),
//                   alignment: Alignment.center,
//                   constraints: const BoxConstraints(maxWidth: 288.0),
//                   child: Text(
//                     textContent,
//                     style: theme.textTheme.bodyText2,
//                     textAlign: TextAlign.center,
//                     key: const Key('intro_body'),
//                   ),
//                 ),
//                 if (linkText != null)
//                   Container(
//                     padding: EdgeInsets.only(top: theme.defaultSpacing),
//                     alignment: Alignment.center,
//                     constraints: const BoxConstraints(maxWidth: 288.0),
//                     key: const Key('intro_body_link'),
//                     child: Link(
//                       label: FlutterI18n.translate(context, linkText!),
//                       onTap: () {
//                         try {
//                           IrmaRepositoryProvider.of(context).openURL(FlutterI18n.translate(context, linkUrl!));
//                         } on PlatformException catch (e, stacktrace) {
//                           reportError(e,
//                               stacktrace); //TODO: reconsider whether this should be handled this way, or is better of with an error screens
//                         }
//                       },
//                     ),
//                   ),
//               ],
//             ),
//           ),
//           Container(
//             width: MediaQuery.of(context).size.width,
//             padding: EdgeInsets.symmetric(
//               vertical: theme.mediumSpacing,
//               horizontal: theme.defaultSpacing,
//             ),
//             color: finalScreen ? theme.background : null,
//             child: finalScreen
//                 ? IrmaButton(
//                     key: const Key('next'),
//                     label: 'enrollment.introduction.button_text',
//                     onPressed: onPressButton,
//                   )
//                 : IconButton(
//                     key: const Key('next'),
//                     onPressed: onNextScreen,
//                     icon: Icon(IrmaIcons.chevronDown,
//                         semanticLabel: FlutterI18n.translate(context, 'accessibility.next'), color: Colors.grey),
//                     iconSize: 32,
//                     alignment: Alignment.center,
//                   ),
//           ),
//         ],
//       ),
//     );
//   }
// }
