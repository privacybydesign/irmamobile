/// Rewrites an SVG that styles its shapes with CSS classes in a `<style>`
/// block, as design tools export it, to one that carries those styles on the
/// elements themselves. flutter_svg ignores `<style>` blocks, and would draw
/// such an image in black.
///
/// Only class selectors (`.name`, also several separated by commas) are
/// understood, which is what these exports use. Anything else is left alone.
String inlineSvgStyles(String svg) {
  final rules = <String, String>{};
  final withoutStyleBlocks = svg.replaceAllMapped(_styleBlock, (block) {
    final css = block.group(1)!.replaceAll(_cssComment, "");
    for (final rule in _cssRule.allMatches(css)) {
      final declarations = rule.group(2)!.trim();
      for (final selector in rule.group(1)!.split(",")) {
        final name = _classSelector.firstMatch(selector.trim())?.group(1);
        if (name == null) continue;
        rules[name] = _join(rules[name], declarations);
      }
    }
    return "";
  });
  if (rules.isEmpty) return svg;

  return withoutStyleBlocks.replaceAllMapped(_tagWithClass, (tag) {
    var declarations = "";
    for (final name in tag.group(2)!.trim().split(_whitespace)) {
      declarations = _join(declarations, rules[name]);
    }
    if (declarations.isEmpty) return tag.group(0)!;

    // styles of the element itself come last, so they keep winning
    var rest = "${tag.group(1)}${tag.group(3)}";
    final own = _styleAttribute.firstMatch(rest);
    if (own != null) {
      declarations = _join(declarations, own.group(1));
      rest = rest.replaceFirst(_styleAttribute, "");
    }
    rest = rest.trimRight();
    final selfClosing = rest.endsWith("/");
    if (selfClosing) {
      rest = rest.substring(0, rest.length - 1).trimRight();
    }
    return '<$rest style="$declarations"${selfClosing ? "/" : ""}>';
  });
}

String _join(String? a, String? b) {
  final parts = [
    for (final part in [a, b])
      if (part != null && part.trim().isNotEmpty)
        part.trim().replaceFirst(RegExp(r";$"), ""),
  ];
  return parts.join(";");
}

final _styleBlock = RegExp(
  r"<style[^>]*>(.*?)</style>",
  dotAll: true,
  caseSensitive: false,
);
final _cssComment = RegExp(r"/\*.*?\*/|<!\[CDATA\[|\]\]>", dotAll: true);
final _cssRule = RegExp(r"([^{}]+)\{([^{}]*)\}");
final _classSelector = RegExp(r"^\.([A-Za-z_][\w-]*)$");
final _whitespace = RegExp(r"\s+");
// an opening tag with a class attribute: what is before and after it
final _tagWithClass = RegExp(
  r'''<([A-Za-z][^<>]*?)\sclass\s*=\s*["']([^"']*)["']([^<>]*)>''',
  dotAll: true,
);
final _styleAttribute = RegExp(r'''\sstyle\s*=\s*["']([^"']*)["']''');
