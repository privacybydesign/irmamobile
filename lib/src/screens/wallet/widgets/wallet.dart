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
  final scrollTipping = 100;

  // Might need tweaking depending on screen size
  final screenTopOffset = 110;

  Credential currentCard;

  AnimationController drawController;
  Animation<double> drawAnimation;

  WalletState expiredState = WalletState.halfway;
  WalletState oldState = WalletState.halfway;
  WalletState newState = WalletState.halfway;
  double scroll = 0;

  final Tween _walletShrinkTween = Tween<double>(begin: 0, end: 1);

  @override
  void initState() {
    drawController = AnimationController(duration: Duration(milliseconds: animationDuration), vsync: this);
    drawAnimation = CurvedAnimation(parent: drawController, curve: Curves.easeInOut)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          expiredState = oldState;
          oldState = newState;
          drawController.reset();
          scroll = 0;
        }
      });

    super.initState();
  }

  cardTapped(int position, Credential credential, Size size) {
    setState(() {
      oldState = newState;

      if (newState != WalletState.drawn) {
        if (isStacked(newState, position)) {
          newState = WalletState.full;
          drawController.forward();
        } else {
          currentCard = credential;
          newState = WalletState.drawn;
          drawController.forward();
          openCurrentCard(size);
        }
      } else {
        newState = expiredState;
        drawController.forward();
      }
    });
  }

  isStacked(newState, position) {
    return newState == WalletState.halfway && widget.credentials.length >= cardsMaxExtended && position < 4;
  }

  openCurrentCard(Size size) {}

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
          // TODO for performance: positions can be cached
          double oldTop = getCardPosition(
              position: oldState, size: size, index: index, isDrawnCard: credential == currentCard, scroll: scroll);
          double newTop = getCardPosition(
              position: newState, size: size, index: index, isDrawnCard: credential == currentCard, scroll: 0);

          cardTop = interpolate(oldTop, newTop, _walletShrinkTween.evaluate(drawAnimation));

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
//                    print("onVerticalDragStart");
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragEnd: (int _pos) {
                    return (DragEndDetails details) {
//                      print("onVerticalDragEnd");
                      if ((scroll < -scrollTipping && newState != WalletState.drawn) ||
                          (scroll > scrollTipping && newState == WalletState.drawn)) {
                        cardTapped(_pos, credential, size);
                      } else {
                        drawController.forward();
                      }
                    };
                  }(index),
                  onVerticalDragDown: (DragDownDetails details) {
                    setState(() {
                      currentCard = credential;
                      scroll = 0;
                    });
                  },
                  onVerticalDragUpdate: (DragUpdateDetails details) {
//                    print("onVerticalDragUpdate");
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragCancel: () {
//                    print("onVerticalDragCancel");
                  },
                  child: IrmaCard(
                      attributes: credential,
                      isOpen: currentCard == credential,
                      updateCallback: widget.updateCard,
                      removeCallback: widget.removeCard)));

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
                        oldState = newState;
                        newState = WalletState.halfway;
                        drawController.reset();
                        drawController.forward();
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

  getCardPosition({WalletState position, Size size, int index, bool isDrawnCard, double scroll}) {
    double cardPosition;
    switch (position) {
      case WalletState.drawn:
        if (isDrawnCard) {
          cardPosition = getWalletTop(size);
          cardPosition -= scroll;
        } else {
          cardPosition = -1.0 * (index + 1) * cardShrunkHeight;
          if (cardPosition < -4.0 * cardShrunkHeight) {
            cardPosition = -4.0 * cardShrunkHeight;
          }
        }
        break;

      case WalletState.halfway:
        double top = 1.0 * (widget.credentials.length - 1 - index);
        if (widget.credentials.length >= cardsMaxExtended) {
          if (index < cardUnshrunkHeight / cardShrunkHeight) {
            cardPosition = 1.0 * (cardsMaxExtended - cardUnshrunkHeight / cardShrunkHeight + 2) * cardUnshrunkHeight -
                index * cardShrunkHeight;
          } else {
            cardPosition = 1.0 * (cardsMaxExtended + 1 - index) * cardUnshrunkHeight;
          }
        } else {
          cardPosition = 1.0 * top * cardUnshrunkHeight;
        }
        if (isDrawnCard) {
          cardPosition -= scroll;
        }
        if (cardPosition < 0) {
          cardPosition = 0;
        }
        break;

      case WalletState.full:
        cardPosition = getWalletTop(size) - index * cardUnshrunkHeight;
        if (isDrawnCard) {
          cardPosition -= scroll;
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

enum WalletState { drawn, halfway, full }
