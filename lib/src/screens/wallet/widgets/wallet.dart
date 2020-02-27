import 'dart:async';
import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/screens/wallet/widgets/digid_proef_helper.dart';
import 'package:irmamobile/src/screens/wallet/widgets/get_cards_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/irma_pilot_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_button.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/card.dart';
import 'package:irmamobile/src/widgets/nudge_state.dart';

///  Show Wallet widget
///
///  credentials: List of credentials (cards)
///  hasLoginLogoutAnimation: Show wallet opening or closing animation
///  isOpen: is wallet open or closed (see hasLoginLogoutAnimation)
///  newCardIndex: index of credentials[] of card to be added
///  onQRScannerPressed: callback for QR button tapped
///  onHelpPressed: callback for Help button tapped
///  onAddCardsPressed: callback for add button tapped
class Wallet extends StatefulWidget {
  const Wallet({
    @required this.credentials,
    this.hasLoginLogoutAnimation = false,
    this.isOpen = false,
    this.newCardIndex,
    this.newWallet,
    this.onNewWalletClosed,
    this.showNewCardAnimation,
    this.onQRScannerPressed,
    this.onHelpPressed,
    this.onAddCardsPressed,
    @required this.onNewCardAnimationShown,
  });

  final List<Credential> credentials; // null when pending
  final bool hasLoginLogoutAnimation;
  final bool isOpen;
  final int newCardIndex;
  final bool showNewCardAnimation;
  final bool newWallet;
  final VoidCallback onNewWalletClosed;
  final VoidCallback onQRScannerPressed;
  final VoidCallback onHelpPressed;
  final VoidCallback onAddCardsPressed;
  final VoidCallback onNewCardAnimationShown;

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin, WidgetsBindingObserver {
  final _animationDuration = 250;
  final _loginDuration = 500;
  final _walletAspectRatio = 87 / 360; // wallet.svg | 360 / 620, 620 - 87 = 533
  final _walletYPos = 25;
  final _cardTopBorderHeight = 10;
  final _cardTopHeight = 40;
  final _cardsMaxExtended = 5;
  final _walletBottomInteractive = 0.7;
  final _dragTipping = 50;
  final _scrollOverflowTipping = 50;
  final _walletBoxHeight = 120;
  final _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);
  final _walletIconHeight = 60;
  final _dragDownFactor = 1.5;
  final _heightOffset = 94.0;
  final _containerKey = GlobalKey();
  final _cardVisibleDelay = 2000;

  double renderBoxHeight = 0;
  int drawnCardIndex = 0;
  AnimationController drawController;
  AnimationController loginLogoutController;
  Animation<double> drawAnimation;

  WalletState cardInStackState = WalletState.halfway;
  WalletState oldState = WalletState.minimal;
  WalletState currentState = WalletState.minimal;

  double dragOffsetSave = 0;
  double dragOffset = 0;
  double cardDragOffset = 0;
  int showCardsCounter = 0;
  bool _nudgeVisible = true;

  final irmaClient = IrmaRepository.get();

  get type => null;

  @override
  void initState() {
    super.initState();
    drawController = AnimationController(duration: Duration(milliseconds: _animationDuration), vsync: this);
    loginLogoutController = AnimationController(duration: Duration(milliseconds: _loginDuration), vsync: this);

    drawAnimation = CurvedAnimation(parent: drawController, curve: Curves.easeInOut)
      ..addStatusListener(
        (state) {
          if (state == AnimationStatus.completed) {
            setState(
              () {
                if (oldState == WalletState.halfway || oldState == WalletState.full) {
                  cardInStackState = oldState;
                }

                if (currentState == WalletState.halfway && widget.showNewCardAnimation == true) {
                  widget.onNewCardAnimationShown();
                }
                oldState = currentState;
                drawController.reset();
                dragOffset = 0;
              },
            );
          }
        },
      );

    WidgetsBinding.instance.addPostFrameCallback(
      (Duration dur) {
        recalculateHeight();
      },
    );

    WidgetsBinding.instance.addObserver(this);

    if (widget.hasLoginLogoutAnimation && widget.showNewCardAnimation == false) {
      loginLogoutController.forward();
    }
  }

  @override
  void didChangeMetrics() {
    recalculateHeight();
  }

  @override
  void dispose() {
    drawController.dispose();
    loginLogoutController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @mustCallSuper
  @protected
  @override
  void didUpdateWidget(Wallet oldWidget) {
    if (widget.showNewCardAnimation == true) {
      drawnCardIndex = widget.newCardIndex;
      setState(() {
        currentState = WalletState.drawn;
        _nudgeVisible = false;
        drawController.forward(from: _animationDuration.toDouble());
      });

      Future.delayed(Duration(milliseconds: _cardVisibleDelay)).then((_) {
        setNewState(cardInStackState);
      });
    } else {
      setNewState(WalletState.halfway);
    }

    if (widget.hasLoginLogoutAnimation && widget.showNewCardAnimation == true) {
      loginLogoutController.forward();
    }

    if (oldWidget.isOpen && !widget.isOpen) {
      loginLogoutController.reverse();
    }

    super.didUpdateWidget(oldWidget);
  }

  Widget _buildDigidProefNudge(BuildContext context, IrmaConfiguration irmaConfiguration) {
    final credentialType = irmaConfiguration.credentialTypes["irma-demo.digidproef.basicPersonalData"];
    final issuer = irmaConfiguration.issuers[credentialType.fullIssuerId];

    return IrmaPilotNudge(
      credentialType: credentialType,
      issuer: issuer,
      irmaConfigurationPath: irmaConfiguration.path,
      launchFailAction: launchFailActionDigiDProef,
    );
  }

  Widget _buildGemeenteNudge(BuildContext context, IrmaConfiguration irmaConfiguration) {
    final credentialType = irmaConfiguration.credentialTypes["pbdf.gemeente.personalData"];
    final issuer = irmaConfiguration.issuers[credentialType.fullIssuerId];

    return IrmaPilotNudge(
      credentialType: credentialType,
      issuer: issuer,
      launchFailAction: (context) {},
    );
  }

  Widget _buildDefaultNudge(BuildContext context) {
    return GetCardsNudge(
      credentials: widget.credentials,
      size: MediaQuery.of(context).size,
      onAddCardsPressed: widget.onAddCardsPressed,
    );
  }

  Widget _buildNudge(BuildContext context) {
    return StreamBuilder(
      stream: irmaClient.irmaConfigurationSubject,
      builder: (context, snapshot) {
        if (snapshot.data != null) {
          final irmaConfiguration = snapshot.data as IrmaConfiguration;
          final nudgeState = Nudge.of(context).nudgeState;

          switch (nudgeState) {
            case NudgeState.addCards:
              return _buildDefaultNudge(context);

            case NudgeState.digidProef:
              if (_hasCredential("irma-demo.digidproef.basicPersonalData")) {
                return _buildDefaultNudge(context);
              }

              return _buildDigidProefNudge(context, irmaConfiguration);

            case NudgeState.gemeente:
              if (_hasCredential("pbdf.gemeente.personalData")) {
                return _buildDefaultNudge(context);
              }
              return _buildGemeenteNudge(context, irmaConfiguration);
          }
        }

        return Container();
      },
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([drawAnimation, loginLogoutController]),
        builder: (BuildContext buildContext, Widget child) {
          final size = MediaQuery.of(buildContext).size;
          final double screenTopOffset = renderBoxHeight == 0 ? 0 : size.height - renderBoxHeight - _heightOffset;
          final walletTop = size.height - _walletBoxHeight - size.width * _walletAspectRatio - screenTopOffset;

          int index = 0;
          double cardTop;

          return Stack(
            key: _containerKey,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: IrmaTheme.of(context).defaultSpacing, horizontal: IrmaTheme.of(context).smallSpacing),
                child: AnimatedOpacity(
                  // If the widget is visible, animate to 0.0 (invisible).
                  // If the widget is hidden, animate to 1.0 (fully visible).
                  opacity: _nudgeVisible ? 1.0 : 0.0,
                  duration: Duration(milliseconds: _animationDuration),
                  child: _buildNudge(context),
                ),
              ),
              if (widget.newWallet ?? true) ...[
                Container(
                  height: 60,
                  color: IrmaTheme.of(context).interactionValid,
                  child: Row(
                    children: <Widget>[
                      SizedBox(width: IrmaTheme.of(context).defaultSpacing),
                      Icon(IrmaIcons.valid, color: Colors.white),
                      SizedBox(width: IrmaTheme.of(context).smallSpacing),
                      Text(
                        FlutterI18n.translate(context, "wallet.new_wallet"),
                        style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
                      ),
                      Expanded(child: Container()),
                      IconButton(
                        icon: Icon(IrmaIcons.close),
                        color: Colors.white,
                        onPressed: widget.onNewWalletClosed,
                      ),
                      SizedBox(width: IrmaTheme.of(context).defaultSpacing),
                    ],
                  ),
                )
              ],
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  child: Stack(
                    children: [
                      Positioned(
                        top: walletTop + _walletYPos - IrmaTheme.of(context).smallSpacing,
                        child: SvgPicture.asset(
                          'assets/wallet/wallet_back.svg',
                          excludeFromSemantics: true,
                          width: size.width,
                        ),
                      ),
                      if (widget.credentials != null)
                        ...widget.credentials.map(
                          (credential) {
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
                                  onVerticalDragDown: (DragDownDetails details) {
                                    setState(
                                      () {
                                        if (currentState == WalletState.drawn) {
                                          cardDragOffset = details.localPosition.dy -
                                              calculateCardPosition(
                                                  state: currentState,
                                                  walletTop: walletTop,
                                                  index: index,
                                                  drawnCardIndex: drawnCardIndex,
                                                  dragOffset: 0);
                                          if (drawnCardIndex == _index) {
                                            dragOffsetSave = details.localPosition.dy - cardDragOffset;
                                          }
                                        } else {
                                          cardDragOffset = _cardTopHeight / 2;
                                          drawnCardIndex = _index;
                                          dragOffsetSave = details.localPosition.dy - cardDragOffset;
                                        }
                                      },
                                    );
                                  },
                                  onVerticalDragStart: (DragStartDetails details) {
                                    dragOffset = dragOffsetSave;
                                  },
                                  onVerticalDragUpdate: (DragUpdateDetails details) {
                                    setState(() {
                                      if (drawnCardIndex == _index) {
                                        dragOffset = details.localPosition.dy - cardDragOffset;
                                      }
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
                                  child: IrmaCard(
                                    credential: credential,
                                    scrollBeyondBoundsCallback: scrollBeyondBound,
                                    onRefreshCredential: _createOnRefreshCredential(credential),
                                    onDeleteCredential: _createOnDeleteCredential(credential),
                                  ),
                                ),
                              );
                            }(index++);
                          },
                        ),
                      Positioned(
                        top: (widget.hasLoginLogoutAnimation ? loginLogoutController.value : 1.0) *
                            (walletTop + _walletYPos),
                        child: IgnorePointer(
                          ignoring: true,
                          child: SvgPicture.asset(
                            'assets/wallet/wallet_front.svg',
                            excludeFromSemantics: true,
                            width: size.width,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        height: size.width * _walletAspectRatio * _walletBottomInteractive,
                        width: size.width,
                        child: Semantics(
                          button: true,
                          label: FlutterI18n.translate(context, 'wallet.toggle'),
                          child: GestureDetector(
                            onTap: () {
                              switch (currentState) {
                                case WalletState.halfway:
                                  setNewState(WalletState.full);
                                  break;
                                case WalletState.full:
                                  setNewState(WalletState.halfway);
                                  break;
                                default:
                                  setNewState(cardInStackState);
                                  break;
                              }
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: (size.width * _walletAspectRatio - _walletIconHeight) / 2,
                        child: WalletButton(
                          svgFile: 'assets/wallet/btn_help.svg',
                          accessibleName: "wallet.help",
                          clickStreamSink: widget.onHelpPressed,
                        ),
                      ),
                      Positioned(
                        right: 16,
                        bottom: (size.width * _walletAspectRatio - _walletIconHeight) / 2,
                        child: WalletButton(
                          svgFile: 'assets/wallet/btn_qrscan.svg',
                          accessibleName: "wallet.scan_qr_code",
                          clickStreamSink: widget.onQRScannerPressed,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      );

  bool _hasCredential(String credentialTypeId) {
    return (widget.credentials ?? []).any(
      (c) => c.credentialType.fullId == credentialTypeId,
    );
  }

  void recalculateHeight() {
    final BuildContext currentContext = _containerKey.currentContext;

    if (currentContext != null && currentContext.size.height > renderBoxHeight) {
      setState(
        () {
          renderBoxHeight = currentContext.size.height;
        },
      );
    }
  }

  void cardTapped(int index, Credential credential, Size size) {
    if (currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    } else {
      if (isStackedClosely(currentState, index)) {
        setNewState(WalletState.full);
      } else {
        drawnCardIndex = index;
        setNewState(WalletState.drawn, nudgeIsVisible: false);
      }
    }
  }

  // Is the card in the area where cards are stacked closely together
  bool isStackedClosely(WalletState newState, int index) =>
      newState == WalletState.halfway &&
      widget.credentials.length >= _cardsMaxExtended &&
      index < widget.credentials.length - _cardTopHeight / _cardTopBorderHeight;

  // When there are many attributes, the contents will scroll. When scrolled beyond the bottom bound,
  // a drag down will be triggered.
  void scrollBeyondBound(double y) {
    if (y > _scrollOverflowTipping && currentState == WalletState.drawn) {
      setNewState(cardInStackState);
    }
  }

  void setNewState(WalletState newState, {bool nudgeIsVisible = true}) {
    setState(
      () {
        _nudgeVisible = nudgeIsVisible;
        oldState = currentState;
        currentState = newState;
        drawController.forward();
      },
    );
  }

  double calculateCardPosition(
      {WalletState state, double walletTop, int index, int drawnCardIndex, double dragOffset}) {
    const cardsHalfway = 3;
    double cardPosition;

    switch (state) {
      case WalletState.drawn:
        if (index == drawnCardIndex) {
          cardPosition = walletTop - IrmaTheme.of(context).mediumSpacing;
          cardPosition -= dragOffset;
        } else {
          cardPosition = -(index - 1) * _cardTopBorderHeight.toDouble() + 2;
          if (cardPosition < -_cardTopHeight) {
            cardPosition = -_cardTopHeight.toDouble() + _cardTopBorderHeight.toDouble() + 2;
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
        // Many cards
        if (widget.credentials.length >= _cardsMaxExtended) {
          // Hidden cards

          if (index <= widget.credentials.length - 1 - cardsHalfway - _cardTopHeight / _cardTopBorderHeight) {
            cardPosition = (cardsHalfway + 1) * _cardTopHeight.toDouble();

            // Top small border cards
          } else if (index <= widget.credentials.length - 1 - cardsHalfway) {
            cardPosition = cardsHalfway * _cardTopHeight.toDouble() -
                (index - (widget.credentials.length - cardsHalfway - 1)) * _cardTopBorderHeight.toDouble();

            // Other cards
          } else {
            cardPosition = (widget.credentials.length - 1 - index) * _cardTopHeight.toDouble();
          }

          // Dragging top small border cards
          if (drawnCardIndex < widget.credentials.length - _cardTopHeight / _cardTopBorderHeight &&
              index != drawnCardIndex) {
            cardPosition -= dragOffset;
          }

          // Few cards
        } else {
          cardPosition = (widget.credentials.length - 1 - index).toDouble() * _cardTopHeight.toDouble();
        }

        // Drag drawn card
        if (index == drawnCardIndex) {
          cardPosition -= dragOffset;
        }

        break;

      case WalletState.full:
        cardPosition =
            min(walletTop, (widget.credentials.length - 1) * _cardTopHeight.toDouble()) - index * _cardTopHeight;

        if (index == drawnCardIndex) {
          cardPosition -= dragOffset;
        } else if (dragOffset > _cardTopHeight - _cardTopBorderHeight) {
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
        }
        break;
    }

    return cardPosition;
  }

  double interpolate(double x1, double x2, double p) => x1 + p * (x2 - x1);

  Function() _createOnRefreshCredential(Credential credential) {
    if (credential.credentialType.issueUrl == null) {
      return null;
    }

    return () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WebviewScreen(getTranslation(credential.credentialType.issueUrl));
        }),
      );
    };
  }

  Function() _createOnDeleteCredential(Credential credential) {
    if (credential.credentialType.disallowDelete) {
      return null;
    }

    return () {
      IrmaRepository.get().bridgedDispatch(
        DeleteCredentialEvent(hash: credential.hash),
      );
    };
  }
}

enum WalletState { drawn, halfway, full, minimal }
