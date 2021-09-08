// This file is not null safe yet.
// @dart=2.11

import 'package:flutter/material.dart';

// Can be removed once https://github.com/flutter/flutter/pull/61662 arrives in stable.
HeroController createHeroController() =>
    HeroController(createRectTween: (Rect begin, Rect end) => MaterialRectArcTween(begin: begin, end: end));
