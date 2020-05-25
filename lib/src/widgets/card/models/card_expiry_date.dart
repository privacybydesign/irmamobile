class CardExpiryDate {
  final DateTime dateTime;

  CardExpiryDate(this.dateTime);

  bool get expired => dateTime.isBefore(DateTime.now());

  int get validDays => dateTime.difference(DateTime.now()).inDays;

  bool get expiresSoon => validDays <= 7;
}
