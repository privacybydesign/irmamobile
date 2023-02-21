class CardExpiryDate {
  final DateTime? dateTime;

  CardExpiryDate(this.dateTime);

  bool get expired => dateTime?.isBefore(DateTime.now()) ?? false;

  int get validDays => dateTime?.difference(DateTime.now()).inDays ?? 8;

  bool get expiresSoon => validDays <= 7;
}
