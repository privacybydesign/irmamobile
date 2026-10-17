import "dart:convert";

import "package:flutter_i18n/flutter_i18n_delegate.dart";
import "package:flutter_test/flutter_test.dart";
import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/theme/theme.dart";
import "package:yivi_core/src/widgets/credential_card/attribute_photo.dart";

import "helpers/test_translation_loader.dart";

// A valid 1x1 PNG.
final _png = base64Decode(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC",
);

Widget _app(Widget child) => IrmaTheme(
  builder: (_) => MaterialApp(
    localizationsDelegates: [
      FlutterI18nDelegate(
        translationLoader: TestTranslationLoader(
          basePath: "assets/locales",
          forcedLocale: const Locale("en", "US"),
        ),
      ),
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: Scaffold(body: Center(child: child)),
  ),
);

final _viewerClose = find.byKey(const Key("photo_viewer_close"));

void main() {
  testWidgets("a small picture with slightly rounded corners", (tester) async {
    await tester.pumpWidget(_app(AttributePhoto(bytes: _png, title: "Photo")));
    await tester.pumpAndSettle();

    final clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
    expect(clip.borderRadius, BorderRadius.circular(AttributePhoto.radius));
    final size = tester.getSize(find.byType(AttributePhoto));
    expect(size.width, lessThanOrEqualTo(AttributePhoto.thumbnail.width));
    expect(size.height, lessThanOrEqualTo(AttributePhoto.thumbnail.height));
  });

  testWidgets("opens full screen as a hero, with its name and a close button", (
    tester,
  ) async {
    await tester.pumpWidget(_app(AttributePhoto(bytes: _png, title: "Photo")));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AttributePhoto));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // In flight between the card and the viewer.
    expect(find.byType(Hero), findsNWidgets(2));
    await tester.pumpAndSettle();

    expect(find.text("Photo"), findsOneWidget);
    expect(_viewerClose, findsOneWidget);
    // As big as the screen allows, in its own shape.
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final viewerPhoto = tester.getSize(find.byType(Image).last);
    expect(
      viewerPhoto.width == screen.width || viewerPhoto.height == screen.height,
      isTrue,
    );

    await tester.tap(_viewerClose);
    await tester.pumpAndSettle();
    expect(_viewerClose, findsNothing);
  });

  testWidgets("a swipe down takes it away, a short one springs back", (
    tester,
  ) async {
    await tester.pumpWidget(_app(AttributePhoto(bytes: _png, title: "Photo")));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AttributePhoto));
    await tester.pumpAndSettle();

    final centre = tester.getCenter(find.byType(InteractiveViewer));
    await tester.timedDragFrom(
      centre,
      const Offset(0, 60),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(_viewerClose, findsOneWidget);

    await tester.timedDragFrom(
      centre,
      const Offset(0, 300),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(_viewerClose, findsNothing);
  });

  testWidgets("inside a card that is a hero itself, it only fades in", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Hero(
          tag: "card",
          child: AttributePhoto(bytes: _png, title: "Photo"),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AttributePhoto));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(_viewerClose, findsOneWidget);
  });
}
