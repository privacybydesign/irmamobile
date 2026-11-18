import "package:material_ui/material_ui.dart";
import "package:yivi_core/src/widgets/sheet/glass_sheet.dart";

/// A document screen as the sheet's document step shows it, for tests of
/// one screen: as `home`, it opens a glass sheet with [screen] on a page
/// that fills it, the buttons in the page's bottom bar upright (in the
/// sheet's bar or left column sideways), and [title] in the sheet's bar.
class DocumentScreenHost extends StatefulWidget {
  const DocumentScreenHost(this.screen, {super.key, this.title = ""});

  final Widget screen;
  final String title;

  @override
  State<DocumentScreenHost> createState() => _DocumentScreenHostState();
}

class _DocumentScreenHostState extends State<DocumentScreenHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGlassSheet<void>(
        context: context,
        builder: (_) => GlassSheetPages(
          onBack: () {},
          pages: [
            GlassSheetPage.fill(
              title: SheetTitle(widget.title),
              exits: const SheetExits(close: SheetClose.none),
              bottomInBar: true,
              slotBottom: true,
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: widget.screen,
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox());
}
