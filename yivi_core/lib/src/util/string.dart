extension StringFormattingExtension on String {
  String toCapitalized() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toCapitalized()).join(' ');

  String replaceBreakingHyphens() {
    const breakingHyphen = '-';
    const nonBreakingHyphen = '\u2011';

    return replaceAll(breakingHyphen, nonBreakingHyphen);
  }
}
