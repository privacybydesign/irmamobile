import "package:rxdart/rxdart.dart";

class CombinedState2<A, B> {
  A a;
  B b;

  CombinedState2(this.a, this.b);
}

Stream<CombinedState2<A, B>> combine2<A, B>(
  Stream<A> streamA,
  Stream<B> streamB,
) {
  return Rx.combineLatest2(streamA, streamB, (A a, B b) {
    return CombinedState2<A, B>(a, b);
  });
}
