import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class Wallet extends StatefulWidget {
  final List<Credential> credentials;
  final VoidCallback qrCallback;

  const Wallet({this.credentials, this.qrCallback});

  @override
  _WalletState createState() => _WalletState();

  void updateCard() {
    debugPrint("update card");
  }

  void removeCard() {
    debugPrint("remove card");
  }
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  final _padding = 15.0;
  final _animationDuration = 250;
  final _walletAspectRatio = 185 / 406; // wallet.svg
  final _qrButtonSize = 94; // qr-button.svg
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

  final Tween _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);

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

    setNewState(WalletState.halfway);

    super.initState();
  }

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

  bool isStacked(WalletState newState, int index) {
    return newState == WalletState.halfway && widget.credentials.length >= _cardsMaxExtended && index < 4;
  }

  void scrollOverflow(double y) {
    if (y > 40 && currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: drawAnimation,
    builder: (BuildContext buildContext, Widget child) {
      final size = MediaQuery.of(buildContext).size;
      final walletTop = size.height - (size.width - 2 * _padding) * _walletAspectRatio - _screenTopOffset;

      final List<Widget> cardWidgets = [];
      int index = 0;
      double cardTop;
      int bottomCardIndex;

      cardWidgets.addAll(widget.credentials.map((credential) {
        final double walletShrinkInterpolation = _walletShrinkTween.evaluate(drawAnimation) as double;

        // TODO for performance: positions can be cached
        final double oldTop = getCardPosition(
          state: oldState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: scroll);

        final double newTop =
        getCardPosition(state: currentState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: 0);

        cardTop = interpolate(oldTop, newTop, walletShrinkInterpolation);

        final Widget card = Positioned(
          left: 0,
          right: 0,
          top: walletTop - cardTop,
          child: GestureDetector(
            onTap: (int _pos) {
              return () {
                cardTapped(_pos, credential, size);
              };
            }(index),
            onVerticalDragStart: (DragStartDetails details) {
              setState(() {
                scroll = details.localPosition.dy;
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
            onVerticalDragDown: (int _index) {
              return (DragDownDetails details) {
                setState(() {
                  drawnCardIndex = _index;
                  scroll = 0;
                });
              };
            }(index),
            onVerticalDragUpdate: (DragUpdateDetails details) {
              setState(() {
                scroll = details.localPosition.dy;
              });
            },
            child: IrmaCard(
              attributes: credential,
              isOpen: drawnCardIndex == index,
              updateCallback: widget.updateCard,
              removeCallback: widget.removeCard,
              scrollOverflowCallback: scrollOverflow)));

        if (cardTop >= 0) {
          bottomCardIndex = index;
        }

        index++;
        return card;
      }));

      cardWidgets.add(Align(
        alignment: Alignment.bottomCenter,
        child: Stack(
          children: <Widget>[
            GestureDetector(
              onTapUp: (TapUpDetails details) {
                if (details.localPosition.dy < 30) {
                  // Tap on top of wallet simulates tap on bottom card
                  cardTapped(bottomCardIndex, widget.credentials[bottomCardIndex], size);
                } else {
                  setState(() {
                    setNewState(WalletState.halfway);
                  });
                }
              },
              child: SvgPicture.asset(
                'assets/wallet/wallet.svg',
                width: size.width,
                height: size.width * _walletAspectRatio,
              )),
            Positioned(
              left: (size.width - _qrButtonSize) / 2,
              top: (size.width - 2 * _padding) * _walletAspectRatio * 0.18,
              child: GestureDetector(
                onTap: () {
                  widget.qrCallback();
                },
                child: Semantics(
                  button: true,
                  label: FlutterI18n.translate(context, 'wallet.scan_qr_code'),
                  child: SvgPicture.asset(
                    'assets/wallet/qr-button.svg',
                  ))))
          ],
        ),
      ));

      return Stack(children: cardWidgets);
    });

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
          cardPosition = -1.0 * (index + 1) * _cardShrunkHeight;
          if (cardPosition < -4.0 * _cardShrunkHeight) {
            cardPosition = -4.0 * _cardShrunkHeight;
          }
        }
        break;

      case WalletState.minimal:
        cardPosition = -1.0 * (index + 1) * _cardShrunkHeight;
        if (cardPosition < -4.0 * _cardShrunkHeight) {
          cardPosition = -4.0 * _cardShrunkHeight;
        }
        break;

      case WalletState.halfway:
        final double top = 1.0 * (widget.credentials.length - 1 - index);

        // Many cards
        if (widget.credentials.length >= _cardsMaxExtended) {
          // Top small border cards
          if (index < _cardUnshrunkHeight / _cardShrunkHeight) {
            cardPosition = 1.0 * (_cardsMaxExtended - _cardUnshrunkHeight / _cardShrunkHeight + 2) * _cardUnshrunkHeight -
              index * _cardShrunkHeight;

            // Other cards
          } else {
            cardPosition = 1.0 * (_cardsMaxExtended + 1 - index) * _cardUnshrunkHeight;
          }

          // Dragging top small border cards
          if (drawnCardIndex < 4 && index != drawnCardIndex) {
            cardPosition -= scroll;
          }

          // Few cards
        } else {
          cardPosition = 1.0 * top * _cardUnshrunkHeight;
        }

        // Drag drawn card
        if (index == drawnCardIndex) {
          cardPosition -= scroll;
        }

        // No cards lower than wallet
        if (cardPosition < 0) {
          cardPosition = 0;
        }
        break;

      case WalletState.full:
        cardPosition = getWalletTop(size) - index * _cardUnshrunkHeight;
        // Active card
        if (index == drawnCardIndex) {
          cardPosition -= scroll;

          // Drag down
        } else if (scroll > _cardUnshrunkHeight - _cardShrunkHeight) {
          if (index > drawnCardIndex) {
            cardPosition -= scroll *
              (1 - (index - drawnCardIndex - 1) / (getWalletTop(size) / _cardUnshrunkHeight - drawnCardIndex)) -
              30;
          } else {
            cardPosition -= scroll - 30;
          }
        }
        break;
    }

    return cardPosition;
  }

  double getWalletTop(Size size) {
    return size.height - size.width * _walletAspectRatio - _screenTopOffset;
  }

  double interpolate(double x1, double x2, double p) {
    return x1 + p * (x2 - x1);
  }
}

enum WalletState { drawn, halfway, full, minimal }
