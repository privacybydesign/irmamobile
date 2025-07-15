import 'package:rxdart/rxdart.dart';

class CombinedState2<A, B> {
  A a;
  B b;

  CombinedState2(this.a, this.b);
}

class CombinedState3<A, B, C> {
  A a;
  B b;
  C c;

  CombinedState3(this.a, this.b, this.c);
}

class CombinedState4<A, B, C, D> {
  A a;
  B b;
  C c;
  D d;

  CombinedState4(this.a, this.b, this.c, this.d);
}

Stream<CombinedState2<A, B>> combine2<A, B>(Stream<A> streamA, Stream<B> streamB) {
  return Rx.combineLatest2(streamA, streamB, (A a, B b) {
    return CombinedState2<A, B>(a, b);
  });
}

Stream<CombinedState3<A, B, C>> combine3<A, B, C>(Stream<A> streamA, Stream<B> streamB, Stream<C> streamC) {
  return Rx.combineLatest3(streamA, streamB, streamC, (A a, B b, C c) {
    return CombinedState3<A, B, C>(a, b, c);
  });
}

Stream<CombinedState4<A, B, C, D>> combine4<A, B, C, D>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  Stream<D> streamD,
) {
  return Rx.combineLatest4(streamA, streamB, streamC, streamD, (A a, B b, C c, D d) {
    return CombinedState4<A, B, C, D>(a, b, c, d);
  });
}
