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

Stream<CombinedState2<A, B>> combine2<A, B>(
  Stream<A> streamA,
  Stream<B> streamB,
) {
  return Observable.combineLatest2(streamA, streamB, (A a, B b) {
    return CombinedState2<A, B>(a, b);
  });
}

Stream<CombinedState3<A, B, C>> combine3<A, B, C>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
) {
  return Observable.combineLatest3(streamA, streamB, streamC, (A a, B b, C c) {
    return CombinedState3<A, B, C>(a, b, c);
  });
}
