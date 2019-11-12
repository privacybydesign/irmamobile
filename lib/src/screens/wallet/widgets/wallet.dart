import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _scrollTipping = 100;

  // Might need tweaking depending on screen size
  final _screenTopOffset = 110;

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
    drawController = AnimationController(duration: Duration(milliseconds: _animationDuration), vsync: this);
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

  void cardTapped(int position, Credential credential, Size size) {
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

  bool isStacked(WalletState newState, int position) {
    return (newState == WalletState.halfway) && (widget.credentials.length >= _cardsMaxExtended) && (position < 4);
  }

  void openCurrentCard(Size size) {}

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: drawAnimation,
      builder: (buildContext, child) {
        final size = MediaQuery.of(buildContext).size;
        final walletTop = size.height - (size.width - 2 * _padding) * _walletAspectRatio - _screenTopOffset;

        final List<Widget> cardWidgets = [];
        int index = 0;
        double cardTop;
        int bottomCardIndex;

        cardWidgets.addAll(widget.credentials.map((credential) {
          // TODO for performance: positions can be cached
          final double oldTop = getCardPosition(
            position: oldState,
            size: size,
            index: index,
            isDrawnCard: credential == currentCard,
            scroll: scroll,
          );
          final double newTop = getCardPosition(
            position: newState,
            size: size,
            index: index,
            isDrawnCard: credential == currentCard,
            scroll: 0,
          );

          cardTop = interpolate(
            oldTop,
            newTop,
            _walletShrinkTween.evaluate(drawAnimation) as double,
          );

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
//                    debugPrint("onVerticalDragStart");
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragEnd: (int _pos) {
                    return (DragEndDetails details) {
//                      debugPrint("onVerticalDragEnd");
                      if ((scroll < -_scrollTipping && newState != WalletState.drawn) ||
                          (scroll > _scrollTipping && newState == WalletState.drawn)) {
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
//                    debugPrint("onVerticalDragUpdate");
                    setState(() {
                      scroll = details.localPosition.dy;
                    });
                  },
                  onVerticalDragCancel: () {
//                    debugPrint("onVerticalDragCancel");
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

  double getCardPosition({WalletState position, Size size, int index, bool isDrawnCard, double scroll}) {
    double cardPosition;
    switch (position) {
      case WalletState.drawn:
        if (isDrawnCard) {
          cardPosition = getWalletTop(size);
          cardPosition -= scroll;
        } else {
          cardPosition = -1.0 * (index + 1) * _cardShrunkHeight;
          if (cardPosition < -4.0 * _cardShrunkHeight) {
            cardPosition = -4.0 * _cardShrunkHeight;
          }
        }
        break;

      case WalletState.halfway:
        final double top = 1.0 * (widget.credentials.length - 1 - index);
        if (widget.credentials.length >= _cardsMaxExtended) {
          if (index < _cardUnshrunkHeight / _cardShrunkHeight) {
            cardPosition =
                1.0 * (_cardsMaxExtended - _cardUnshrunkHeight / _cardShrunkHeight + 2) * _cardUnshrunkHeight -
                    index * _cardShrunkHeight;
          } else {
            cardPosition = 1.0 * (_cardsMaxExtended + 1 - index) * _cardUnshrunkHeight;
          }
        } else {
          cardPosition = 1.0 * top * _cardUnshrunkHeight;
        }
        if (isDrawnCard) {
          cardPosition -= scroll;
        }
        if (cardPosition < 0) {
          cardPosition = 0;
        }
        break;

      case WalletState.full:
        cardPosition = getWalletTop(size) - index * _cardUnshrunkHeight;
        if (isDrawnCard) {
          cardPosition -= scroll;
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

enum WalletState { drawn, halfway, full }
