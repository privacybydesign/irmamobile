import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:irmamobile/src/models/credential.dart';
import 'package:irmamobile/src/widgets/card/card.dart';

class Wallet extends StatefulWidget {
  final StreamController<void> qrClickStreamSink = StreamController();
  final StreamController<String> eventStream = StreamController();

  final List<Credential> credentials;

  Wallet(this.credentials);

  @protected
  @mustCallSuper
  void dispose() {
    qrClickStreamSink.close();
    eventStream.close();
  }

  @override
  _WalletState createState() => _WalletState();
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
  List<IrmaCard> irmaCards;

  AnimationController drawController;
  Animation<double> drawAnimation;

  CardPosition expiredPosition = CardPosition.halfway;
  CardPosition oldPosition = CardPosition.halfway;
  CardPosition newPosition = CardPosition.halfway;
  double scroll = 0;

  final Tween _walletShrinkTween = Tween<double>(begin: 0, end: 1);

  @override
  void initState() {
    drawController = AnimationController(duration: Duration(milliseconds: animationDuration), vsync: this);
    drawAnimation = CurvedAnimation(parent: drawController, curve: Curves.easeInOut)
      ..addStatusListener((state) {
        if (state == AnimationStatus.completed) {
          expiredPosition = oldPosition;
          oldPosition = newPosition;
          drawController.reset();
          scroll = 0;
        }
      });

    widget.eventStream.sink.add('Started');
    widget.qrClickStreamSink.stream.listen((_) {
      print('QR clicked');
    });
    super.initState();
  }

  cardTapped(int position, Credential credential, Size size) {
    setState(() {
      oldPosition = newPosition;

      if (newPosition != CardPosition.drawn) {
        if (newPosition == CardPosition.halfway && widget.credentials.length >= cardsMaxExtended && position < 4) {
          newPosition = CardPosition.full;
          drawController.forward();
        } else {
          currentCard = credential;
          newPosition = CardPosition.drawn;
          drawController.forward();
          openCurrentCard(size);
        }
      } else {
        newPosition = expiredPosition;
        drawController.forward();
      }
    });
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

        irmaCards = [];
        cardWidgets.addAll(widget.credentials.map((credential) {
          irmaCards.add(IrmaCard(credential, currentCard == credential));

          // TODO for performance: positions can be cached
          double oldTop = getCardPosition(
              position: oldPosition, size: size, index: index, isDrawnCard: credential == currentCard, scroll: scroll);
          double newTop = getCardPosition(
              position: newPosition, size: size, index: index, isDrawnCard: credential == currentCard, scroll: 0);

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
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragEnd: (int _pos) {
                    return (DragEndDetails details) {
                      print("onVerticalDragEnd");
                      if ((scroll < -scrollTipping && newPosition != CardPosition.drawn) ||
                          (scroll > scrollTipping && newPosition == CardPosition.drawn)) {
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
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragCancel: () {
                    print("onVerticalDragCancel");
                  },
                  child: irmaCards[index]));

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
                        oldPosition = newPosition;
                        newPosition = CardPosition.halfway;
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
                        widget.qrClickStreamSink.add(true);
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

  getCardPosition({CardPosition position, Size size, int index, bool isDrawnCard, double scroll}) {
    double cardPosition;
    switch (position) {
      case CardPosition.drawn:
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

      case CardPosition.halfway:
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

      case CardPosition.full:
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

enum CardPosition { drawn, halfway, full }
