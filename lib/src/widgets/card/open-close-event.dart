class OpenCloseEvent {
  OpenCloseStatus name;
  double height;

  OpenCloseEvent(this.name, this.height);
}

enum OpenCloseStatus {
  open,
  close,
}
