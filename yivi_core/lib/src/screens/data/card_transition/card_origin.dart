import "card_slots.dart";

/// Where a card opens from: what fades around it, whether a + turns into
/// the details' ✕, and where it goes back to.
enum CardOrigin {
  /// A card of the stack: the cards above sink, the cards below fall.
  stack,

  /// A list row: its thumbnail grows; the tab around it fades.
  listRow,

  /// A grid cell: its card grows; the tab around it fades.
  gridCell,

  /// A search result (a list row): opens on the found field, and the
  /// keyboard comes back on close.
  searchResult,

  /// A notification's picture: as a list row; no + in a bar.
  notification;

  bool get isStack => this == stack;

  /// The bar's + turns into the details' ✕ (Data tab only).
  bool get plusTurnsIntoClose => this != notification;

  /// The view its card is shown in, where closing measures it.
  CardSlotView get view => switch (this) {
    stack => CardSlotView.stack,
    listRow || searchResult => CardSlotView.list,
    gridCell => CardSlotView.grid,
    notification => CardSlotView.notifications,
  };
}
