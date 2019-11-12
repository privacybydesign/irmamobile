import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class Wallet extends StatefulWidget {
  final List<Credential> credentials;
  final VoidCallback qrCallback;

  Wallet({this.credentials, this.qrCallback});

  @override
  _WalletState createState() => _WalletState();

  void updateCard() {
    print("update card");
  }

  void removeCard() {
    print("remove card");
  }
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  final padding = 15.0;
  final animationDuration = 250;
  final walletAspectRatio = 185 / 406; // wallet.svg
  final qrButtonSize = 94; // qr-button.svg
  final cardShrunkHeight = 10;
  final cardUnshrunkHeight = 40;
  final cardsMaxExtended = 5;
  final scrollTipping = 50;

  // Might need tweaking depending on screen size
  final screenTopOffset = 110;

//  Credential currentCard;
  int drawnCardIndex = 0;

  AnimationController drawController;
  Animation<double> drawAnimation;

  WalletState cardInStackState = WalletState.halfway;
  WalletState oldState = WalletState.halfway;
  WalletState currentState = WalletState.minimal;
  double scroll = 0;

  final Tween _walletShrinkTween = Tween<double>(begin: 0, end: 1);

  @override
  void initState() {
    drawController = AnimationController(duration: Duration(milliseconds: animationDuration), vsync: this);
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

  cardTapped(int index, Credential credential, Size size) {
    setState(() {
      if (currentState == WalletState.drawn) {
        setNewState(cardInStackState);
      } else {
        if (isStacked(currentState, index)) {
          setNewState(WalletState.full);
        } else {
          drawnCardIndex = index;
          setNewState(WalletState.drawn);
          openCurrentCard(size);
        }
      }
    });
  }

  isStacked(newState, index) {
    return newState == WalletState.halfway && widget.credentials.length >= cardsMaxExtended && index < 4;
  }

  openCurrentCard(Size size) {}

  scrollOverflow(y) {
    if (y > 20 && currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: drawAnimation,
      builder: (buildContext, child) {
        final size = MediaQuery.of(buildContext).size;
        final walletTop = size.height - (size.width - 2 * padding) * walletAspectRatio - screenTopOffset;

        List<Widget> cardWidgets = [];
        int index = 0;
        double cardTop;
        int bottomCardIndex;

        cardWidgets.addAll(widget.credentials.map((credential) {
          double walletShrinkTween = _walletShrinkTween.evaluate(drawAnimation);

          // TODO for performance: positions can be cached
          double oldTop = getCardPosition(
              state: oldState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: scroll);

          double newTop =
              getCardPosition(state: currentState, size: size, index: index, drawnCardIndex: drawnCardIndex, scroll: 0);

          cardTop = interpolate(oldTop, newTop, walletShrinkTween);

          Widget card = Positioned(
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
                      if ((scroll < -scrollTipping && currentState != WalletState.drawn) ||
                          (scroll > scrollTipping && currentState == WalletState.drawn)) {
                        cardTapped(_index, credential, size);
                      } else if (scroll > scrollTipping && currentState == WalletState.full) {
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
                    height: size.width * walletAspectRatio,
                  )),
              Positioned(
                  left: (size.width - qrButtonSize) / 2,
                  top: (size.width - 2 * padding) * walletAspectRatio * 0.18,
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

  setNewState(WalletState newState) {
    setState(() {
      oldState = currentState;
      currentState = newState;
      drawController.forward();
    });
  }

  getCardPosition({WalletState state, Size size, int index, int drawnCardIndex, double scroll}) {
    double cardPosition;

    switch (state) {
      case WalletState.drawn:
        if (index == drawnCardIndex) {
          cardPosition = getWalletTop(size);
          cardPosition -= scroll;
        } else {
          cardPosition = -1.0 * (index + 1) * cardShrunkHeight;
          if (cardPosition < -4.0 * cardShrunkHeight) {
            cardPosition = -4.0 * cardShrunkHeight;
          }
        }
        break;

      case WalletState.minimal:
        cardPosition = -1.0 * (index + 1) * cardShrunkHeight;
        if (cardPosition < -4.0 * cardShrunkHeight) {
          cardPosition = -4.0 * cardShrunkHeight;
        }
        break;

      case WalletState.halfway:
        double top = 1.0 * (widget.credentials.length - 1 - index);

        // Many cards
        if (widget.credentials.length >= cardsMaxExtended) {
          // Top small border cards
          if (index < cardUnshrunkHeight / cardShrunkHeight) {
            cardPosition = 1.0 * (cardsMaxExtended - cardUnshrunkHeight / cardShrunkHeight + 2) * cardUnshrunkHeight -
                index * cardShrunkHeight;

            // Other cards
          } else {
            cardPosition = 1.0 * (cardsMaxExtended + 1 - index) * cardUnshrunkHeight;
          }

          // Dragging top small border cards
          if (drawnCardIndex < 4 && index != drawnCardIndex) {
            cardPosition -= scroll;
          }

          // Few cards
        } else {
          cardPosition = 1.0 * top * cardUnshrunkHeight;
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
        cardPosition = getWalletTop(size) - index * cardUnshrunkHeight;
        // Active card
        if (index == drawnCardIndex) {
          cardPosition -= scroll;

          // Drag down
        } else if (scroll > cardUnshrunkHeight - cardShrunkHeight) {
          if (index > drawnCardIndex) {
            cardPosition -= scroll *
                    (1 - (index - drawnCardIndex - 1) / (getWalletTop(size) / cardUnshrunkHeight - drawnCardIndex)) -
                30;
          } else {
            cardPosition -= scroll - 30;
          }
        }
        break;
    }

    return cardPosition;
  }

  getWalletTop(Size size) {
    return size.height - size.width * walletAspectRatio - screenTopOffset;
  }

  interpolate(double x1, double x2, double p) {
    return x1 + p * (x2 - x1);
  }
}

enum WalletState { drawn, halfway, full, minimal }
