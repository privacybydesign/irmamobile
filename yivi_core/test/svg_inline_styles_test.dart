import "package:flutter_test/flutter_test.dart";
import "package:yivi_core/src/util/svg_inline_styles.dart";

// Bank logos come as SVGs that colour their shapes with CSS classes, which
// flutter_svg ignores: without inlining, every shape is drawn in black.

void main() {
  test("moves class styles onto the elements", () {
    const svg = """
<svg viewBox="0 0 10 10" style="enable-background:new 0 0 10 10;">
<style type="text/css">
	.st0{fill:#009286;}
	.st1{fill-rule:evenodd;clip-rule:evenodd;fill:#F3C000;}
</style>
<g transform="translate(1 1)">
	<path class="st0" d="M1,1"/>
	<path class="st1" d="M2,2"/>
</g>
</svg>""";
    final inlined = inlineSvgStyles(svg);

    expect(inlined, isNot(contains("<style")));
    expect(inlined, isNot(contains("class=")));
    expect(inlined, contains('<path d="M1,1" style="fill:#009286"/>'));
    expect(
      inlined,
      contains(
        '<path d="M2,2" style="fill-rule:evenodd;clip-rule:evenodd;fill:#F3C000"/>',
      ),
    );
    // what is not about classes stays as it is
    expect(inlined, contains('style="enable-background:new 0 0 10 10;"'));
    expect(inlined, contains('<g transform="translate(1 1)">'));
  });

  test("combines classes, shared rules and the element's own style", () {
    const svg = """
<svg><style>.a,.b{fill:red}.b{stroke:blue}</style>
<rect class="a b" style="opacity:0.5" width="1"></rect>
<rect class="unknown" width="2"/></svg>""";
    final inlined = inlineSvgStyles(svg);

    expect(
      inlined,
      contains(
        '<rect width="1" style="fill:red;fill:red;stroke:blue;opacity:0.5">',
      ),
    );
    // a class without a rule is left alone; the element's own style wins by
    // coming last
    expect(inlined, contains('<rect class="unknown" width="2"/>'));
  });

  test("leaves an SVG without class styles untouched", () {
    const svg = '<svg><path fill="#fff" d="M0,0"/></svg>';
    expect(inlineSvgStyles(svg), svg);
  });
}
