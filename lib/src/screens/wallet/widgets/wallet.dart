import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/card/card.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_button.dart';
import 'package:irmamobile/src/theme/theme.dart';

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
  final _walletAspectRatio = 87 / 360; // wallet.svg
  final _cardShrunkHeight = 10;
  final _cardUnshrunkHeight = 40;
  final _cardsMaxExtended = 5;
  final _scrollTipping = 50;

  // Might need tweaking depending on screen size
  final _screenTopOffset = 110;

  //  Credential currentCard;
  int drawnCardIndex = 0;

  AnimationController drawController;
  Animation<double> drawAnimation;

  WalletState cardInStackState = WalletState.halfway;
  WalletState oldState = WalletState.halfway;
  WalletState currentState = WalletState.minimal;
  double scroll = 0;

  final _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);

  @override
  void initState() {
    drawController = AnimationController(duration: Duration(milliseconds: _animationDuration), vsync: this);
    drawAnimation = CurvedAnimation(parent: drawController, curve: Curves.easeInOut)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          if (oldState == WalletState.halfway || oldState == WalletState.full) {
            cardInStackState = oldState;
          }
          oldState = currentState;
          drawController.reset();
          scroll = 0;
        }
      });
    super.initState();
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
      animation: drawAnimation,
      builder: (BuildContext buildContext, Widget child) {
        final size = MediaQuery.of(buildContext).size;
        final walletTop = size.height - (size.width - 2 * _padding) * _walletAspectRatio - _screenTopOffset;

        int index = 0;
        double cardTop;

        return Stack(children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: _padding * 2, horizontal: _padding * 2),
              child: ListView(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: _padding),
                    child: SvgPicture.asset(
                      'assets/wallet/wallet_illustration.svg',
                      width: size.width / 2,
                    ),
                  ),
                  Text(
                    FlutterI18n.translate(context, 'wallet.caption'),
                    textAlign: TextAlign.center,
                    style: IrmaTheme.of(context).textTheme.body1,
                  ),
                  GestureDetector(
                    onTap: widget.addCard,
                    child: Text(
                      FlutterI18n.translate(context, 'wallet.add_data'),
                      textAlign: TextAlign.center,
                      style: IrmaTheme.of(context).hyperlinkTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SvgPicture.asset(
              'assets/wallet/wallet_back.svg',
              width: size.width,
            ),
          ),
          ...widget.credentials != null
              ? widget.credentials.map((credential) {
                  final double walletShrinkInterpolation = _walletShrinkTween.evaluate(drawAnimation);

                  // TODO for performance: positions can be cached
                  final double oldTop = getCardPosition(
                      state: oldState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: scroll);

                  final double newTop = getCardPosition(
                      state: currentState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: 0);

                  cardTop = interpolate(oldTop, newTop, walletShrinkInterpolation);

                  final card = Positioned(
                    left: 0,
                    right: 0,
                    top: walletTop - cardTop,
                    child: GestureDetector(
                      onTap: (int _pos) {
                        return () {
                          cardTapped(_pos, credential, size);
                        };
                      }(index),
                      onVerticalDragStart: (int _index) {
                        return (DragStartDetails details) {
                          setState(() {
                            drawnCardIndex = _index;
                            scroll = details.localPosition.dy - _cardUnshrunkHeight / 2;
                          });
                        };
                      }(index),
                      onVerticalDragUpdate: (DragUpdateDetails details) {
                        setState(() {
                          scroll = details.localPosition.dy - _cardUnshrunkHeight / 2;
                        });
                      },
                      onVerticalDragEnd: (int _index) {
                        return (DragEndDetails details) {
                          if ((scroll < -_scrollTipping && currentState != WalletState.drawn) ||
                              (scroll > _scrollTipping && currentState == WalletState.drawn)) {
                            cardTapped(_index, credential, size);
                          } else if (scroll > _scrollTipping && currentState == WalletState.full) {
                            setNewState(WalletState.halfway);
                          } else {
                            drawController.forward();
                          }
                        };
                      }(index),
                      child: IrmaCard(attributes: credential, scrollOverflowCallback: scrollOverflow),
                    ),
                  );
                  index++;

                  return card;
                })
              : [Align(alignment: Alignment.center, child: Text(FlutterI18n.translate(context, 'ui.loading')))],
          Align(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: <Widget>[
                IgnorePointer(
                    ignoring: true,
                    child: SvgPicture.asset(
                      'assets/wallet/wallet_front.svg',
                      width: size.width,
                      height: size.width * _walletAspectRatio,
                    )),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: WalletButton(
                      svgFile: 'assets/wallet/btn_help.svg',
                      accessibleName: "wallet.help",
                      clickStreamSink: widget.helpCallback),
                ),
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: WalletButton(
                      svgFile: 'assets/wallet/btn_qrscan.svg',
                      accessibleName: "wallet.scan_qr_code",
                      clickStreamSink: widget.qrCallback),
                ),
              ],
            ),
          )
        ]);
      });

  void cardTapped(int index, Credential credential, Size size) {
    setState(() {
      if (currentState == WalletState.drawn) {
        setNewState(cardInStackState);
      } else {
        if (isStacked(currentState, index)) {
          setNewState(WalletState.full);
        } else {
          drawnCardIndex = index;
          setNewState(WalletState.drawn);
        }
      }
    });
  }

  bool isStacked(WalletState newState, int index) =>
      newState == WalletState.halfway && widget.credentials.length >= _cardsMaxExtended && index < 4;

  void scrollOverflow(double y) {
    if (y > 40 && currentState == WalletState.drawn) {
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

  double getCardPosition({WalletState state, Size size, int index, int drawnCardIndex, double scroll}) {
    double cardPosition;

    switch (state) {
      case WalletState.drawn:
        if (index == drawnCardIndex) {
          cardPosition = getWalletTop(size);
          cardPosition -= scroll;
        } else {
          cardPosition = -(index + 1) * _cardShrunkHeight.toDouble();
          if (cardPosition < -_cardUnshrunkHeight) {
            cardPosition = -_cardUnshrunkHeight.toDouble();
          }
        }
        break;

      case WalletState.minimal:
        cardPosition = -(index + 1) * _cardShrunkHeight.toDouble();
        if (cardPosition < -_cardUnshrunkHeight) {
          cardPosition = -_cardUnshrunkHeight.toDouble();
        }
        break;

      case WalletState.halfway:
        final double top = (widget.credentials.length - 1 - index).toDouble();

        // Many cards
        if (widget.credentials.length >= _cardsMaxExtended) {
          // Top small border cards
          if (index < _cardUnshrunkHeight / _cardShrunkHeight) {
            cardPosition = (_cardsMaxExtended - _cardUnshrunkHeight / _cardShrunkHeight + 2) * _cardUnshrunkHeight -
                index * _cardShrunkHeight;

            // Other cards
          } else {
            cardPosition = (_cardsMaxExtended + 1 - index) * _cardUnshrunkHeight.toDouble();
          }

          // Dragging top small border cards
          if (drawnCardIndex < _cardUnshrunkHeight / _cardShrunkHeight && index != drawnCardIndex) {
            cardPosition -= scroll;
          }

          // Few cards
        } else {
          cardPosition = top * _cardUnshrunkHeight.toDouble();
        }

        // Drag drawn card
        if (index == drawnCardIndex) {
          cardPosition -= scroll;
        }

        // Bottom cards are deeper in wallet
        if (cardPosition < 0) {
          cardPosition *= 2;
        }

        break;

      case WalletState.full:
        final top = min(getWalletTop(size), (widget.credentials.length - 1) * _cardUnshrunkHeight.toDouble());
        cardPosition = top - index * _cardUnshrunkHeight;
        // Active card
        if (index == drawnCardIndex) {
          cardPosition -= scroll;

          // Drag down
        } else if (scroll > _cardUnshrunkHeight - _cardShrunkHeight) {
          if (index > drawnCardIndex) {
            cardPosition -= scroll * (1 - (index - drawnCardIndex - 1) / (top / _cardUnshrunkHeight - drawnCardIndex)) -
                (_cardUnshrunkHeight - _cardShrunkHeight);
          } else {
            cardPosition -= scroll - (_cardUnshrunkHeight - _cardShrunkHeight);
          }
        }
        break;
    }

    return cardPosition;
  }

  double getWalletTop(Size size) => size.height - size.width * _walletAspectRatio - _screenTopOffset;

  double interpolate(double x1, double x2, double p) => x1 + p * (x2 - x1);
}

enum WalletState { drawn, halfway, full, minimal }
