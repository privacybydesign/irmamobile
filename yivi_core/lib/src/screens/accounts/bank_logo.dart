import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:http/http.dart" as http;
import "package:material_ui/material_ui.dart";

import "../../models/bank_account.dart";
import "../../theme/theme.dart";
import "../../util/svg_inline_styles.dart";

/// The SVG logo at a URL, made fit to draw (see [inlineSvgStyles]) and kept
/// for as long as the app runs: the same few logos are shown again and again.
final bankLogoSvgProvider = FutureProvider.family<String, String>((
  ref,
  url,
) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception("logo $url answered ${response.statusCode}");
  }
  return inlineSvgStyles(response.body);
});

/// The logo of a bank in a round badge, or the first letter of the bank's
/// name when there is no logo (or it can't be loaded).
class BankLogo extends ConsumerWidget {
  const BankLogo({
    super.key,
    required this.name,
    required this.logoUrl,
    this.size = 52,
  });

  BankLogo.of(BankConnection connection, {super.key, this.size = 52})
    : name = connection.bankDisplayName,
      logoUrl = connection.bankLogoUrl;

  final String name;
  final String logoUrl;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = IrmaTheme.of(context);
    final url = logoUrl;

    final Widget fallback = Center(
      child: name.isEmpty
          ? Icon(
              Icons.account_balance_outlined,
              size: size * 0.5,
              color: theme.neutralDark,
            )
          : Text(
              name[0].toUpperCase(),
              style: theme.themeData.textTheme.headlineMedium!.copyWith(
                fontSize: size * 0.4,
                height: 1,
                fontWeight: FontWeight.w700,
                color: theme.neutralDark,
              ),
            ),
    );

    Widget logo = fallback;
    if (url.startsWith("https://")) {
      if (Uri.parse(url).path.toLowerCase().endsWith(".svg")) {
        logo = switch (ref.watch(bankLogoSvgProvider(url))) {
          AsyncData(:final value) => SvgPicture.string(
            value,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          ),
          // nothing while loading, so the letter does not flash by
          AsyncLoading() => const SizedBox.shrink(),
          _ => fallback,
        };
      } else {
        logo = Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallback,
        );
      }
    }

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: theme.light,
          shape: BoxShape.circle,
          border: Border.all(color: theme.tertiary),
        ),
        clipBehavior: Clip.antiAlias,
        // keep the logo clear of the round edge
        padding: EdgeInsets.all(size * 0.2),
        child: logo,
      ),
    );
  }
}
