extension StringFormattingExtension on String {
  String replaceBreakingHyphens() {
    const breakingHyphen = "-";
    const nonBreakingHyphen = "\u2011";

    return replaceAll(breakingHyphen, nonBreakingHyphen);
  }

  /// A host name as people say it: without "www.".
  String withoutWww() => startsWith("www.") ? substring(4) : this;
}
