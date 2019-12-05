import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/card/card.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_button.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/widgets/loading_indicator.dart';

class Wallet extends StatefulWidget {
  final List<Credential> credentials; // null when pending
  final VoidCallback qrCallback;
  final VoidCallback helpCallback;

  const Wallet({this.credentials, this.qrCallback, this.helpCallback});

  @override
  _WalletState createState() => _WalletState();

  void updateCard() {
    debugPrint("update card");
  }

  void removeCard() {
    debugPrint("remove card");
  }

  void addCard() {
    debugPrint("add card");
  }
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  final _padding = 15.0;
  final _animationDuration = 250;
  final _loginDuration = 500;
  final _walletAspectRatio = 87 / 360; // wallet.svg | 360 / 620, 620 - 87 = 533
  final _walletFullWidth = 360;
  final _walletFullHeight = 620;
  final _cardTopBorderHeight = 10;
  final _cardTopHeight = 40;
  final _cardsMaxExtended = 5;
  final _dragTipping = 50;
  final _scrollOverflowTipping = 50;
  final _screenTopOffset = 110; // Might need tweaking depending on screen size
  final _walletOffset = -20; // Might need tweaking depending on screen size
  final _walletBackOffset = 8; // Might need tweaking depending on screen size
  final _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);
  final _walletIconHeight = 60;
  final _dragDownFactor = 1.5;

  int drawnCardIndex = 0;
  AnimationController drawController;
  AnimationController loginLogoutController;
  Animation<double> drawAnimation;

  WalletState cardInStackState = WalletState.halfway;
  WalletState oldState = WalletState.minimal;
  WalletState currentState = WalletState.minimal;

  double dragOffset = 0;
  double cardDragOffset = 0;
  int showCardsCounter = 0;

  @override
  void initState() {
    drawController = AnimationController(duration: Duration(milliseconds: _animationDuration), vsync: this);
    loginLogoutController = AnimationController(duration: Duration(milliseconds: _loginDuration), vsync: this);

    drawAnimation = CurvedAnimation(parent: drawController, curve: Curves.easeInOut)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          if (oldState == WalletState.halfway || oldState == WalletState.full) {
            cardInStackState = oldState;
          }
          oldState = currentState;
          drawController.reset();
          dragOffset = 0;
        }
      });
    loginLogoutController.forward();

    super.initState();
  }

  @override
  void dispose() {
    drawController.dispose();
    super.dispose();
  }

  @mustCallSuper
  @protected
  @override
  void didUpdateWidget(Wallet oldWidget) {
    if (oldWidget.credentials == null && widget.credentials != null) {
      setNewState(WalletState.halfway);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([drawAnimation, loginLogoutController]),
      builder: (BuildContext buildContext, Widget child) {
        final size = MediaQuery.of(buildContext).size;
        final walletTop = size.height - size.width * _walletAspectRatio - _screenTopOffset;

        int index = 0;
        double cardTop;

        return Stack(children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: _padding * 2, horizontal: _padding * 2),
              child: ListView(
                children: <Widget>[
                  SvgPicture.asset(
                    'assets/wallet/wallet_illustration.svg',
                    width: size.width / 2,
                  ),
                  Padding(
                    padding: EdgeInsets.all(_padding),
                    child: Text(
                      FlutterI18n.translate(context, 'wallet.caption'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).textTheme.body1,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.addCard,
                    child: Text(
                      FlutterI18n.translate(context, 'wallet.add_data'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).hyperlinkTextStyle,
                    ),
                  ),
                  if (widget.credentials == null) Align(alignment: Alignment.center, child: LoadingIndicator()),
                ],
              ),
            ),
          ),
          Positioned(
            top: size.width * _walletFullHeight / _walletFullWidth -
                size.width * _walletAspectRatio +
                _walletOffset -
                _walletBackOffset,
            child: SvgPicture.asset(
              'assets/wallet/wallet_back.svg',
              width: size.width,
            ),
          ),
          if (widget.credentials != null)
            ...widget.credentials.map((credential) {
              final double walletShrinkInterpolation = _walletShrinkTween.evaluate(drawAnimation);

              // TODO for performance: positions can be cached
              final double oldTop = calculateCardPosition(
                  state: oldState,
                  walletTop: walletTop,
                  index: index,
                  drawnCardIndex: drawnCardIndex,
                  dragOffset: dragOffset);

              final double newTop = calculateCardPosition(
                  state: currentState,
                  walletTop: walletTop,
                  index: index,
                  drawnCardIndex: drawnCardIndex,
                  dragOffset: 0);

              cardTop = interpolate(oldTop, newTop, walletShrinkInterpolation);

              return (int _index) {
                return Positioned(
                  left: 0,
                  right: 0,
                  top: walletTop - cardTop,
                  child: GestureDetector(
                    onTap: () {
                      cardTapped(_index, credential, size);
                    },
                    onVerticalDragStart: (DragStartDetails details) {
                      setState(() {
                        if (currentState == WalletState.drawn) {
                          cardDragOffset = details.localPosition.dy -
                              calculateCardPosition(
                                  state: currentState,
                                  walletTop: walletTop,
                                  index: index,
                                  drawnCardIndex: drawnCardIndex,
                                  dragOffset: 0);
                        } else {
                          cardDragOffset = _cardTopHeight / 2;
                        }
                        drawnCardIndex = _index;
                        dragOffset = details.localPosition.dy - cardDragOffset;
                      });
                    },
                    onVerticalDragUpdate: (DragUpdateDetails details) {
                      setState(() {
                        dragOffset = details.localPosition.dy - cardDragOffset;
                      });
                    },
                    onVerticalDragEnd: (DragEndDetails details) {
                      if ((dragOffset < -_dragTipping && currentState != WalletState.drawn) ||
                          (dragOffset > _dragTipping && currentState == WalletState.drawn)) {
                        cardTapped(_index, credential, size);
                      } else if (dragOffset > _dragTipping && currentState == WalletState.full) {
                        setNewState(WalletState.halfway);
                      } else {
                        drawController.forward();
                      }
                    },
                    child: IrmaCard(attributes: credential, scrollBeyondBoundsCallback: scrollBeyondBound),
                  ),
                );
              }(index++);
            }),
          Positioned(
            top: loginLogoutController.value * size.width * _walletFullHeight / _walletFullWidth -
                size.width * _walletAspectRatio +
                _walletOffset,
            child: IgnorePointer(
              ignoring: true,
              child: SvgPicture.asset(
                'assets/wallet/wallet_front.svg',
                width: size.width,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: (size.width * _walletAspectRatio - _walletIconHeight) / 2,
            child: WalletButton(
                svgFile: 'assets/wallet/btn_help.svg',
                accessibleName: "wallet.help",
                clickStreamSink: widget.helpCallback),
          ),
          Positioned(
            right: 16,
            bottom: (size.width * _walletAspectRatio - _walletIconHeight) / 2,
            child: WalletButton(
                svgFile: 'assets/wallet/btn_qrscan.svg',
                accessibleName: "wallet.scan_qr_code",
                clickStreamSink: widget.qrCallback),
          ),
        ]);
      });

  void cardTapped(int index, Credential credential, Size size) {
    if (currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    } else {
      if (isStackedClosely(currentState, index)) {
        setNewState(WalletState.full);
      } else {
        drawnCardIndex = index;
        setNewState(WalletState.drawn);
      }
    }
  }

  // Is the card in the area where cards are stacked closely together
  bool isStackedClosely(WalletState newState, int index) =>
      newState == WalletState.halfway &&
      widget.credentials.length >= _cardsMaxExtended &&
      index < _cardTopHeight / _cardTopBorderHeight;

  // When there are many attributes, the contents will scroll. When scrolled beyond the bottom bound,
  // a drag down will be triggered.
  void scrollBeyondBound(double y) {
    if (y > _scrollOverflowTipping && currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    }
  }

  void setNewState(WalletState newState) {
    setState(() {
      oldState = currentState;
      currentState = newState;
      drawController.forward();
    });
  }

  double calculateCardPosition(
      {WalletState state, double walletTop, int index, int drawnCardIndex, double dragOffset}) {
    double cardPosition;

    switch (state) {
      case WalletState.drawn:
        if (index == drawnCardIndex) {
          cardPosition = walletTop;
          cardPosition -= dragOffset;
        } else {
          cardPosition = -(index + 1) * _cardTopBorderHeight.toDouble();
          if (cardPosition < -_cardTopHeight) {
            cardPosition = -_cardTopHeight.toDouble();
          }
          if (index > drawnCardIndex) {
            cardPosition += _cardTopBorderHeight;
          }
        }
        break;

      case WalletState.minimal:
        cardPosition = -(index + 1) * _cardTopBorderHeight.toDouble();
        if (cardPosition < -_cardTopHeight) {
          cardPosition = -_cardTopHeight.toDouble();
        }
        break;

      case WalletState.halfway:
        final double top = (widget.credentials.length - 1 - index).toDouble();

        // Many cards
        if (widget.credentials.length >= _cardsMaxExtended) {
          // Top small border cards
          if (index < _cardTopHeight / _cardTopBorderHeight) {
            cardPosition = (_cardsMaxExtended - _cardTopHeight / _cardTopBorderHeight + 2) * _cardTopHeight -
                index * _cardTopBorderHeight;

            // Other cards
          } else {
            cardPosition = (_cardsMaxExtended + 1 - index) * _cardTopHeight.toDouble();
          }

          // Dragging top small border cards
          if (drawnCardIndex < _cardTopHeight / _cardTopBorderHeight && index != drawnCardIndex) {
            cardPosition -= dragOffset;
          }

          // Few cards
        } else {
          cardPosition = top * _cardTopHeight.toDouble();
        }

        // Drag drawn card
        if (index == drawnCardIndex) {
          cardPosition -= dragOffset;
        }

        // Bottom cards are deeper in wallet
        if (cardPosition < 0) {
          cardPosition *= 2;
        }

        break;

      case WalletState.full:
        cardPosition =
            min(walletTop, (widget.credentials.length - 1) * _cardTopHeight.toDouble()) - index * _cardTopHeight;

        if (dragOffset > _cardTopHeight - _cardTopBorderHeight) {
          if (index >= drawnCardIndex) {
            cardPosition -= dragOffset *
                    ((drawnCardIndex - index) *
                            (1 / _dragDownFactor - 1) /
                            (drawnCardIndex - (widget.credentials.length - 1)) +
                        1 / _dragDownFactor) *
                    _dragDownFactor -
                _cardTopHeight / 2;
          } else {
            cardPosition -= dragOffset - (_cardTopHeight - _cardTopBorderHeight);
          }
        } else if (index == drawnCardIndex) {
          cardPosition -= dragOffset;
        }
        break;
    }

    return cardPosition;
  }

  double interpolate(double x1, double x2, double p) => x1 + p * (x2 - x1);
}

enum WalletState { drawn, halfway, full, minimal }
