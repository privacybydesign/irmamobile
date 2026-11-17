import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:material_ui/material_ui.dart";
import "package:vcmrtd/vcmrtd.dart";

import "../../../models/mrz.dart";
import "document_translation_keys.dart";

/// One chip read: what was scanned or typed, and how often this document
/// went back to its chip screen to read again.
typedef ChipRead = ({ScannedMrz mrz, int attempt});

/// A screen of adding a document in the sheet. The chip and the loader
/// after the face check share one page: they swap in place.
sealed class DocumentStep {
  const DocumentStep();

  /// In the sheet's numbering: the details are 1, adding it is last.
  int get number;

  /// The sheet bar's title.
  String titleKey(DocumentType type);

  /// The navigator page this step is shown on.
  LocalKey get pageKey;
}

/// How to hold the document.
final class InstructionStep extends DocumentStep {
  const InstructionStep();
  @override
  int get number => 2;
  @override
  String titleKey(DocumentType type) => type.scanTitleKey;
  @override
  LocalKey get pageKey => const ValueKey("instruction");
}

/// The camera, or typing it in ([manual]).
final class CaptureStep extends DocumentStep {
  const CaptureStep({required this.manual});
  final bool manual;
  @override
  int get number => 3;
  @override
  String titleKey(DocumentType type) => type.scanTitleKey;
  @override
  LocalKey get pageKey => ValueKey(manual ? "manual" : "camera");
}

/// Reading the chip.
final class ChipStep extends DocumentStep {
  const ChipStep(this.read, {this.instant = false});
  final ChipRead read;

  /// In place at once, without a slide (read again, back from adding it).
  final bool instant;
  @override
  int get number => 4;
  @override
  String titleKey(DocumentType type) => type.nfcTitleKey;
  @override
  LocalKey get pageKey => ValueKey(("chip", read.attempt));
}

/// After the face check, the data being fetched: on the chip's page, and
/// counted as the chip's step.
final class PreparingStep extends DocumentStep {
  const PreparingStep(this.read);
  final ChipRead read;
  @override
  int get number => 4;
  @override
  String titleKey(DocumentType type) => "face_verification.preparing_title";
  @override
  LocalKey get pageKey => ValueKey(("chip", read.attempt));
}

/// The face check's intro, when the issuer asks for one.
final class FaceIntroStep extends DocumentStep {
  const FaceIntroStep(this.read);
  final ChipRead read;
  @override
  int get number => 5;
  @override
  String titleKey(DocumentType type) => "face_verification.title";
  @override
  LocalKey get pageKey => const ValueKey("face");
}

@immutable
final class DocumentFlowState {
  const DocumentFlowState(
    this.type, {
    this.stack = const [InstructionStep()],
    this.faceCheck = false,
    this.attempts = 0,
  });

  final DocumentType type;

  /// The screens, bottom first; the last is on top. Never empty.
  final List<DocumentStep> stack;

  /// The issuer asked for a face check: one step more.
  final bool faceCheck;

  /// Chip reads started, so a new one has a page of its own.
  final int attempts;

  DocumentStep get top => stack.last;
  int get step => top.number;
  int get total => faceCheck ? 6 : 5;
  String get titleKey => top.titleKey(type);

  DocumentFlowState copyWith({
    List<DocumentStep>? stack,
    bool? faceCheck,
    int? attempts,
  }) => DocumentFlowState(
    type,
    stack: stack ?? this.stack,
    faceCheck: faceCheck ?? this.faceCheck,
    attempts: attempts ?? this.attempts,
  );
}

final documentFlowProvider = NotifierProvider.autoDispose
    .family<DocumentFlow, DocumentFlowState, DocumentType>(DocumentFlow.new);

/// Adding a document in the sheet: which of its screens is up, for the
/// sheet's navigator, title and progress.
class DocumentFlow extends Notifier<DocumentFlowState> {
  DocumentFlow(this.type);

  final DocumentType type;

  /// The face intro's answer, while it is up.
  Completer<bool>? _face;

  @override
  DocumentFlowState build() {
    ref.onDispose(() {
      final face = _face;
      if (face != null && !face.isCompleted) face.complete(false);
    });
    return DocumentFlowState(type);
  }

  void _push(DocumentStep step) =>
      state = state.copyWith(stack: [...state.stack, step]);

  /// Start on the instruction: the camera, or typing it in on a device
  /// without one.
  void capture({required bool hasCamera}) =>
      _push(CaptureStep(manual: !hasCamera));

  /// "Enter manually" on the camera.
  void typeIn() => _push(const CaptureStep(manual: true));

  /// The details are read: the chip. Ignored while a chip page is up (the
  /// camera reports a read more than once).
  void read(ScannedMrz mrz) {
    if (state.stack.any((s) => s is ChipStep || s is PreparingStep)) return;
    final attempt = state.attempts;
    state = state.copyWith(
      stack: [...state.stack, ChipStep((mrz: mrz, attempt: attempt))],
      attempts: attempt + 1,
    );
  }

  /// Back in the bar, system back: the screen on top goes. False on the
  /// instruction: the sheet goes back to the details then.
  bool back() {
    final top = state.top;
    if (top is InstructionStep) return false;
    if (top is FaceIntroStep) {
      answerFace(false);
      return true;
    }
    removePage(top.pageKey);
    return true;
  }

  /// The page with [key] went (a finished swipe): its steps go with it.
  void removePage(LocalKey key) {
    if (key == const ValueKey("face")) {
      final face = _face;
      _face = null;
      if (face != null && !face.isCompleted) face.complete(false);
    }
    final stack = [...state.stack];
    while (stack.length > 1 && stack.last.pageKey == key) {
      stack.removeLast();
    }
    state = state.copyWith(stack: stack);
  }

  /// Back from adding it: to the chip, which starts over, without a slide.
  /// The issuer asks for a face check again if it wants one.
  void readAgain() {
    final i = state.stack.indexWhere(
      (s) => s is ChipStep || s is PreparingStep,
    );
    if (i < 0) return;
    final mrz = switch (state.stack[i]) {
      ChipStep(:final read) || PreparingStep(:final read) => read.mrz,
      _ => throw StateError("not a chip step"),
    };
    final face = _face;
    _face = null;
    if (face != null && !face.isCompleted) face.complete(false);
    final attempt = state.attempts;
    state = state.copyWith(
      stack: [...state.stack.take(i), ChipStep((mrz: mrz, attempt: attempt))],
      faceCheck: false,
      attempts: attempt + 1,
    );
  }

  /// The chip's screen shows the loader after the face check ([preparing])
  /// or the read again.
  void preparing(bool preparing) {
    final stack = [...state.stack];
    final i = stack.lastIndexWhere((s) => s is ChipStep || s is PreparingStep);
    if (i < 0) return;
    final read = switch (stack[i]) {
      ChipStep(:final read) || PreparingStep(:final read) => read,
      _ => throw StateError("not a chip step"),
    };
    final next = preparing ? PreparingStep(read) : ChipStep(read);
    if (stack[i].runtimeType == next.runtimeType) return;
    stack[i] = next;
    state = state.copyWith(stack: stack);
  }

  /// The issuer asks for a face check: its intro goes over the chip's
  /// screen; true on Start, false on back.
  Future<bool> askFace() {
    final chip = state.stack.lastWhere(
      (s) => s is ChipStep || s is PreparingStep,
    );
    final read = switch (chip) {
      ChipStep(:final read) || PreparingStep(:final read) => read,
      _ => throw StateError("not a chip step"),
    };
    final face = _face = Completer<bool>();
    state = state.copyWith(
      stack: [...state.stack, FaceIntroStep(read)],
      faceCheck: true,
    );
    return face.future;
  }

  /// The intro's Start ([start]), or back.
  void answerFace(bool start) {
    final face = _face;
    _face = null;
    if (state.top is FaceIntroStep) {
      state = state.copyWith(
        stack: state.stack.sublist(0, state.stack.length - 1),
      );
    }
    if (face != null && !face.isCompleted) face.complete(start);
  }
}
