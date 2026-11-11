import "package:material_ui/material_ui.dart";

import "../../../theme/yivi_palette.dart";
import "../../../widgets/irma_app_bar.dart";
import "../../../widgets/two_pane.dart";

/// A page the More tab opens (Instellingen, Veelgestelde vragen): in the
/// tab's detail pane ([embedded]) with its title on the page, else on a
/// page of its own under an app bar with the title. [children] scroll under
/// the floating app bar.
class MoreSubpage extends StatelessWidget {
  final bool embedded;
  final String titleKey;

  /// The room above [children] on a page of its own.
  final double top;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  /// On a page of its own, the scroll view fills the page's height.
  final bool fillHeight;
  final List<Widget> children;

  const MoreSubpage({
    super.key,
    required this.embedded,
    required this.titleKey,
    required this.top,
    this.controller,
    this.physics,
    this.fillHeight = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      controller: controller,
      physics: physics,
      padding: embedded
          ? PaneTitle.pagePadding(context)
          : EdgeInsets.fromLTRB(16, top, 16, 48),
      // Inside the scroll view, so the content starts below the floating
      // app bar and scrolls underneath it.
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [if (embedded) PaneTitle(titleKey), ...children],
        ),
      ),
    );
    if (embedded) return scroll;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: YiviPalette.of(context).background,
      appBar: IrmaAppBar(titleTranslationKey: titleKey),
      body: fillHeight
          ? SizedBox(height: double.infinity, child: scroll)
          : scroll,
    );
  }
}
