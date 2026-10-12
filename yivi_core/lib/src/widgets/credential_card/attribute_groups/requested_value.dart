import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter_i18n/flutter_i18n.dart";
import "package:material_ui/material_ui.dart";

import "../../../models/schemaless/schemaless_events.dart" as schemaless;
import "../../../theme/theme.dart";
import "attribute_comparison.dart";
import "attribute_value_formatting.dart";

/// What a chip next to a value the verifier asked for says.
enum RequestedValueKind {
  /// The value is what was asked for ("Satisfies").
  satisfied,

  /// A card to obtain: the value it must have ("Required").
  required,

  /// The value is not what was asked for ("Required: yes").
  mismatch,
}

/// Marks the cards below it as templates of a credential still to obtain, so
/// their requested values read "Required" rather than "Satisfies".
class RequestedValueScope extends InheritedWidget {
  final bool template;

  const RequestedValueScope({
    super.key,
    required this.template,
    required super.child,
  });

  static bool isTemplate(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<RequestedValueScope>()
          ?.template ??
      false;

  @override
  bool updateShouldNotify(RequestedValueScope oldWidget) =>
      template != oldWidget.template;
}

/// Whether the verifier asked for a specific value of [attribute].
bool hasRequestedValue(schemaless.Attribute attribute) =>
    attribute.requestedValue?.hasConcreteValue ?? false;

/// The chip for [attributes] together (one displayed value built from them),
/// or null when none has a requested value. Any mismatch wins.
RequestedValueKind? requestedValueKind(
  Iterable<schemaless.Attribute> attributes, {
  required bool template,
}) {
  final requested = attributes.where(hasRequestedValue).toList();
  if (requested.isEmpty) return null;
  if (template) return RequestedValueKind.required;
  return requested.every((a) => sameAttributeValue(a.value, a.requestedValue))
      ? RequestedValueKind.satisfied
      : RequestedValueKind.mismatch;
}

/// [attributes] with the requested values of [requested] (same claim path)
/// filled in, for comparing an obtained credential with what was asked.
List<schemaless.Attribute> withRequestedValues(
  List<schemaless.Attribute> attributes,
  List<schemaless.Attribute> requested,
) => [
  for (final a in attributes)
    switch (requested.firstWhereOrNull(
      (r) => listEquals(r.claimPath, a.claimPath) && hasRequestedValue(r),
    )) {
      null => a,
      final r => schemaless.Attribute(
        claimPath: a.claimPath,
        displayName: a.displayName,
        description: a.description,
        value: a.value,
        requestedValue: r.requestedValue,
        intentToRetain: a.intentToRetain,
      ),
    },
];

/// A small chip on the right of a value the verifier asked for: green
/// "Satisfies", blue "Required" on a card to obtain, or red "Required: yes"
/// when the value is not what was asked.
class RequestedValueChip extends StatelessWidget {
  final List<schemaless.Attribute> attributes;

  const RequestedValueChip(this.attributes, {super.key});

  /// The chip for [attributes], or null when nothing was requested of them.
  static Widget? maybe(
    BuildContext context,
    List<schemaless.Attribute> attributes,
  ) =>
      requestedValueKind(
            attributes,
            template: RequestedValueScope.isTemplate(context),
          ) ==
          null
      ? null
      : RequestedValueChip(attributes);

  static const _prefix = "credential.requested_value";

  @override
  Widget build(BuildContext context) {
    final theme = IrmaTheme.of(context);
    final kind = requestedValueKind(
      attributes,
      template: RequestedValueScope.isTemplate(context),
    );
    if (kind == null) return const SizedBox.shrink();

    final (text, background, foreground) = switch (kind) {
      RequestedValueKind.satisfied => (
        FlutterI18n.translate(context, "$_prefix.satisfied"),
        theme.successSurface,
        theme.onSuccessSurface,
      ),
      RequestedValueKind.required => (
        FlutterI18n.translate(context, "$_prefix.required"),
        theme.backgroundTertiary,
        theme.link,
      ),
      RequestedValueKind.mismatch => (
        FlutterI18n.translate(
          context,
          "$_prefix.required_value",
          translationParams: {"value": _requestedText(context)},
        ),
        theme.errorSurface,
        theme.error,
      ),
    };

    return Container(
      key: Key("requested_value_${kind.name}"),
      padding: EdgeInsets.symmetric(
        horizontal: theme.smallSpacing,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: theme.borderRadius,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: theme.secondaryFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  /// The first mismatching requested value, yes / no translated.
  String _requestedText(BuildContext context) {
    final a = attributes.firstWhere(
      (a) =>
          hasRequestedValue(a) &&
          !sameAttributeValue(a.value, a.requestedValue),
    );
    return switch (comparableAttributeValue(a.requestedValue)) {
      final bool b => formatAttributeBool(context, b),
      final v => "$v",
    };
  }
}

/// [value] with the requested-value chip of [attributes] on its right, if
/// any.
class WithRequestedValueChip extends StatelessWidget {
  final List<schemaless.Attribute> attributes;
  final Widget child;

  const WithRequestedValueChip({
    super.key,
    required this.attributes,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final chip = RequestedValueChip.maybe(context, attributes);
    if (chip == null) return child;
    return Row(
      crossAxisAlignment: .center,
      spacing: IrmaTheme.of(context).smallSpacing,
      children: [
        Expanded(child: child),
        chip,
      ],
    );
  }
}
