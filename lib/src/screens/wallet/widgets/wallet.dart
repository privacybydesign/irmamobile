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
import 'package:irmamobile/src/screens/pin/pin_screen.dart';
import 'package:irmamobile/src/screens/wallet/widgets/get_cards_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/irma_pilot_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_button.dart';
import 'package:irmamobile/src/screens/webview/webview_screen.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
import 'package:irmamobile/src/util/language.dart';
import 'package:irmamobile/src/widgets/card/card.dart';
import 'package:irmamobile/src/widgets/credential_nudge.dart';

///  Show Wallet widget API
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
  final VoidCallback onQRScannerPressed;
  final VoidCallback onHelpPressed;
  final VoidCallback onAddCardsPressed;
  final VoidCallback onNewCardAnimationShown;

  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> with TickerProviderStateMixin {
  final _cardAnimationDuration = 250;
  final _loginAnimationDuration = 400;
  final _walletAspectRatio = 87 / 360; // wallet.svg 360x87 px
  final _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);
  final _containerKey = GlobalKey();

  // Visible height of tightly folded cards
  final _cardTopBorderHeight = 10;

  // Visible height of cards with visible title
  final _cardTopHeight = 40;

  // Number of cards with visible title
  final _cardsMaxExtended = 5;

  // Number of cards with visible title that are shown in a tightly folded wallet
  final _cardsTopVisible = 3;

  // Movements below this distance are not handled as swipes
  final _dragTipping = 50;

  // Scrolling below this distance are not handled as swipes
  final _scrollOverflowTipping = 50;

  // Height of qr/help buttons
  final _walletIconHeight = 60;

  // How much cards are dragged down [state==folded]
  final _dragDownFactor = 1.5;

  // Offset of cards relative to wallet
  final _heightOffset = -35.0;

  // Add a margin to the screen height to deal with different phones
  final _screenHeightMargin = 100;

  // Time to show new cards before being added to wallet
  final _cardVisibleDelay = 3250;

  // Time between opening the wallet and showing the cards
  final _walletShowCardsDelay = 200;

  // Offset of minimized cards
  final _minimizedCardOffset = -20;

  // Height of interactive bottom to toggle wallet state between tightlyfolded and folded
  final _walletBottomInteractive = 0.7;

  AnimationController _cardAnimationController;
  AnimationController _loginLogoutAnimationController;
  Animation<double> _drawAnimation;

  WalletState _cardInStackState = WalletState.tightlyfolded;
  WalletState _oldState = WalletState.minimal;
  WalletState _currentState = WalletState.minimal;

  // Index of drawn (visible) card
  int _drawnCardIndex = 0;

  // Variables for good dragging UX
  double _dragOffsetSave = 0;
  double _dragOffset = 0;
  double _cardDragOffset = 0;
  bool _nudgeVisible = true;
  bool _showCards = false;

  final _closedWalletOffset = 50;
  final IrmaRepository _irmaClient = IrmaRepository.get();

  get type => null;

  @override
  void initState() {
    super.initState();

    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: _cardAnimationDuration),
      vsync: this,
    );
    _loginLogoutAnimationController = AnimationController(
      duration: Duration(milliseconds: _loginAnimationDuration),
      vsync: this,
    );

    if (widget.hasLoginLogoutAnimation && widget.isOpen) {
      startLoginAnimation();
    }

    _drawAnimation = CurvedAnimation(parent: _cardAnimationController, curve: Curves.easeInOut)
      ..addStatusListener(
        (state) {
          if (state == AnimationStatus.completed) {
            setState(
              () {
                if (_oldState == WalletState.tightlyfolded || _oldState == WalletState.folded) {
                  _cardInStackState = _oldState;
                }

                if (_currentState == WalletState.tightlyfolded && widget.showNewCardAnimation == true) {
                  widget.onNewCardAnimationShown();
                }
                _oldState = _currentState;
                _cardAnimationController.reset();
                _dragOffset = 0;
              },
            );
          }
        },
      );
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _loginLogoutAnimationController.dispose();
    super.dispose();
  }

  @mustCallSuper
  @protected
  @override
  void didUpdateWidget(Wallet oldWidget) {
    if (widget.showNewCardAnimation == true) {
      setState(() {
        _drawnCardIndex = widget.newCardIndex;
        _currentState = WalletState.drawn;
        _nudgeVisible = false;
        _cardAnimationController.forward(from: _cardAnimationDuration.toDouble());
      });

      Future.delayed(Duration(milliseconds: _cardVisibleDelay)).then((_) {
        setNewState(_cardInStackState);
      });
    }

    if (widget.hasLoginLogoutAnimation && !oldWidget.isOpen && widget.isOpen) {
      startLoginAnimation();
    }

    if (widget.hasLoginLogoutAnimation && oldWidget.isOpen && !widget.isOpen) {
      _loginLogoutAnimationController.reverse().then((_) {
        _irmaClient.lock();
        Navigator.of(context).pushNamed(PinScreen.routeName);
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_drawAnimation, _loginLogoutAnimationController]),
        builder: (BuildContext buildContext, Widget child) {
          final mq = MediaQuery.of(buildContext);
          final screenWidth = mq.size.width;
          final screenHeight = mq.size.height;
          final walletTop = screenHeight - screenWidth * _walletAspectRatio + _heightOffset - _screenHeightMargin;

          return Stack(
            key: _containerKey,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: IrmaTheme.of(context).defaultSpacing,
                  horizontal: IrmaTheme.of(context).smallSpacing,
                ),
                child: AnimatedOpacity(
                  // If the widget is visible, animate to 0.0 (invisible).
                  // If the widget is hidden, animate to 1.0 (fully visible).
                  opacity: _nudgeVisible ? 1.0 : 0.0,
                  duration: Duration(milliseconds: _cardAnimationDuration),
                  child: _buildNudge(context),
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                height: screenHeight,
                width: screenWidth,
                child: Stack(
                  overflow: Overflow.visible,
                  fit: StackFit.expand,
                  children: [
                    /// Wallet background
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset(
                        'assets/wallet/wallet_back.svg',
                        excludeFromSemantics: true,
                        width: screenWidth,
                      ),
                    ),

                    /// All cards
                    if (_showCards)
                      _buildCardStack(walletTop, screenHeight),

                    /// Wallet foreground with help and qr buttons
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        children: <Widget>[
                          IgnorePointer(
                            ignoring: true,
                            child: SvgPicture.asset(
                              'assets/wallet/wallet_front.svg',
                              width: screenWidth,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            height: screenWidth * _walletAspectRatio * _walletBottomInteractive,
                            width: screenWidth,
                            child: Semantics(
                              button: true,
                              label: FlutterI18n.translate(context, 'wallet.toggle'),
                              child: GestureDetector(
                                onTap: () {
                                  switch (_currentState) {
                                    case WalletState.tightlyfolded:
                                      setNewState(WalletState.folded);
                                      break;
                                    case WalletState.folded:
                                      setNewState(WalletState.tightlyfolded);
                                      break;
                                    default:
                                      setNewState(_cardInStackState);
                                      break;
                                  }
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            left: 16,
                            bottom: (screenWidth * _walletAspectRatio - _walletIconHeight) / 2,
                            child: WalletButton(
                              svgFile: 'assets/wallet/btn_help.svg',
                              accessibleName: "wallet.help",
                              clickStreamSink: widget.onHelpPressed,
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: (screenWidth * _walletAspectRatio - _walletIconHeight) / 2,
                            child: WalletButton(
                              svgFile: 'assets/wallet/btn_qrscan.svg',
                              accessibleName: "wallet.scan_qr_code",
                              clickStreamSink: widget.onQRScannerPressed,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: _walletShrinkTween.evaluate(_loginLogoutAnimationController) * screenHeight -
                          _closedWalletOffset,
                      child: SvgPicture.asset(
                        'assets/wallet/wallet_high.svg',
                        width: screenWidth,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  void startLoginAnimation() {
    _loginLogoutAnimationController.forward().then((_) {
      setState(() {
        _showCards = true;
      });
      return Future.delayed(Duration(milliseconds: _walletShowCardsDelay));
    }).then((_) {
      setNewState(WalletState.tightlyfolded);
    });
  }

  Widget _buildCardStack(double walletTop, double screenHeight) {
    if (widget.credentials == null) {
      return Container();
    }

    /// Compensate _screenHeightMargin for bottom bar
    final stackHeightFolded = _screenHeightMargin + widget.credentials.length.toDouble() * _cardTopHeight;
    final walletHeight = screenHeight - _screenHeightMargin;

    final scrollingEnabled = _currentState == WalletState.folded && stackHeightFolded > walletHeight;

    /// Render all credential cards
    final rendered = widget.credentials.asMap().entries.map<Widget>(
      (credential) {
        final cardTop = getCardPosition(credential.key, walletTop);
        return Positioned(
          left: 0,
          right: 0,
          top: walletTop - cardTop,
          child: getCard(
            index: credential.key,
            count: widget.credentials.length,
            credential: credential.value,
            walletTop: walletTop,
            enableGestures: !scrollingEnabled,
          ),
        );
      },
    ).toList();

    /// Display chevron to help users expanding their tightly folded wallet.
    /// Button needs to be inserted in the stack at the right place.
    if (_currentState == WalletState.tightlyfolded && widget.credentials.length > _cardsTopVisible + 1) {
      rendered.insert(
        widget.credentials.length - _cardsTopVisible - 1,
        _buildWalletExpandButton(walletTop, widget.credentials.length - _cardsTopVisible - 2),
      );
    }

    /// Wallet may only be scrollable when being in a folded state.
    /// Scrollview is not transparent to gestures, so use container if scrollview is not needed.
    if (scrollingEnabled) {
      return SingleChildScrollView(
        padding: EdgeInsets.only(top: IrmaTheme.of(context).smallSpacing),
        child: Stack(
          overflow: Overflow.visible,
          children: [
            /// Fixed size element must be in stack to prevent the scroll view from growing to infinite sizes.
            Container(
              constraints: BoxConstraints(
                maxHeight: stackHeightFolded,
              ),
            ),
            ...rendered,
          ],
        ),
      );
    } else {
      return Container(
        /// The container size must always be at least the wallet height to make all animations visible.
        constraints: BoxConstraints(
          maxHeight: walletHeight,
        ),
        child: Stack(
          overflow: Overflow.visible,
          children: rendered,
        ),
      );
    }
  }

  Widget _buildWalletExpandButton(double walletTop, int firstTightlyFoldedCardIndex) {
    return Positioned(
      left: 0,
      right: 0,
      top: walletTop - getCardPosition(firstTightlyFoldedCardIndex, walletTop) - _cardTopHeight + _cardTopBorderHeight,
      child: Align(
        alignment: Alignment.center,

        /// Add similar gestures as the cards have to make sure the animations keep working
        child: GestureDetector(
          onTap: () => setNewState(WalletState.folded),
          onVerticalDragDown: (DragDownDetails details) {
            setState(
              () {
                _cardDragOffset = _cardTopHeight / 2;
                _drawnCardIndex = 0;
                _dragOffsetSave = details.localPosition.dy - _cardDragOffset;
              },
            );
          },
          onVerticalDragStart: (DragStartDetails details) {
            setState(() {
              _dragOffset = _dragOffsetSave;
            });
          },
          onVerticalDragUpdate: (DragUpdateDetails details) {
            setState(() {
              _dragOffset = details.localPosition.dy - _cardDragOffset;
            });
          },
          onVerticalDragEnd: (DragEndDetails details) {
            if ((_dragOffset < -_dragTipping && _currentState != WalletState.drawn) ||
                (_dragOffset > _dragTipping && _currentState == WalletState.drawn)) {
              setNewState(WalletState.folded);
            } else {
              _cardAnimationController.forward();
            }
          },
          child: ClipOval(
            child: Container(
              color: IrmaTheme.of(context).grayscale60,
              padding: EdgeInsets.all(IrmaTheme.of(context).smallSpacing),
              child: Icon(
                IrmaIcons.chevronUp,
                color: IrmaTheme.of(context).backgroundBlue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// IrmaCard with gestures attached
  /// Most of this code deals with having a good dragging UX
  Widget getCard({int index, int count, Credential credential, double walletTop, bool enableGestures}) =>
      GestureDetector(
        onTap: () {
          cardTapped(index, credential);
        },
        onVerticalDragDown: enableGestures
            ? (DragDownDetails details) {
                setState(
                  () {
                    if (_currentState == WalletState.drawn) {
                      _cardDragOffset = details.localPosition.dy -
                          calculateCardPosition(
                              state: _currentState,
                              walletTop: walletTop,
                              index: count,
                              drawnCardIndex: _drawnCardIndex,
                              dragOffset: 0);
                      if (_drawnCardIndex == index) {
                        _dragOffsetSave = details.localPosition.dy - _cardDragOffset;
                      }
                    } else {
                      _cardDragOffset = _cardTopHeight / 2;
                      _drawnCardIndex = index;
                      _dragOffsetSave = details.localPosition.dy - _cardDragOffset;
                    }
                  },
                );
              }
            : null,
        onVerticalDragStart: enableGestures
            ? (DragStartDetails details) {
                setState(() {
                  _dragOffset = _dragOffsetSave;
                });
              }
            : null,
        onVerticalDragUpdate: enableGestures
            ? (DragUpdateDetails details) {
                setState(() {
                  if (_drawnCardIndex == index) {
                    _dragOffset = details.localPosition.dy - _cardDragOffset;
                  }
                });
              }
            : null,
        onVerticalDragEnd: enableGestures
            ? (DragEndDetails details) {
                if ((_dragOffset < -_dragTipping && _currentState != WalletState.drawn) ||
                    (_dragOffset > _dragTipping && _currentState == WalletState.drawn)) {
                  cardTapped(index, credential);
                } else if (_dragOffset > _dragTipping && _currentState == WalletState.folded) {
                  setNewState(WalletState.tightlyfolded);
                } else {
                  _cardAnimationController.forward();
                }
              }
            : null,
        child: IrmaCard.fromCredential(
          credential: credential,
          scrollBeyondBoundsCallback: scrollBeyondBound,
          onRefreshCredential: _createOnRefreshCredential(credential),
          onDeleteCredential: _createOnDeleteCredential(index, credential),
        ),
      );

  /// Animate each card between old and new state
  double getCardPosition(int index, double walletTop) {
    final double oldTop = calculateCardPosition(
      state: _oldState,
      walletTop: walletTop,
      index: index,
      drawnCardIndex: _drawnCardIndex,
      dragOffset: _dragOffset,
    );

    final double newTop = calculateCardPosition(
      state: _currentState,
      walletTop: walletTop,
      index: index,
      drawnCardIndex: _drawnCardIndex,
      dragOffset: 0,
    );

    return interpolate(oldTop, newTop, _walletShrinkTween.evaluate(_drawAnimation));
  }

  /// onTap handler
  void cardTapped(int index, Credential credential) {
    if (_currentState == WalletState.drawn) {
      setNewState(_cardInStackState);
    } else {
      if (isTightlyFolded(_currentState, index)) {
        setNewState(WalletState.folded);
      } else {
        _drawnCardIndex = index;
        setNewState(WalletState.drawn, nudgeIsVisible: false);
      }
    }
  }

  Widget _buildNudge(BuildContext context) => StreamBuilder(
        stream: _irmaClient.irmaConfigurationSubject,
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            final irmaConfiguration = snapshot.data as IrmaConfiguration;
            final credentialNudge = CredentialNudgeProvider.of(context).credentialNudge;

            if (credentialNudge == null || _hasCredential(credentialNudge.fullCredentialTypeId)) {
              if (widget.credentials.length >= 4) {
                return Container();
              } else {
                return GetCardsNudge(
                  credentials: widget.credentials,
                  size: MediaQuery.of(context).size,
                  onAddCardsPressed: widget.onAddCardsPressed,
                );
              }
            } else {
              final credentialType = irmaConfiguration.credentialTypes[credentialNudge.fullCredentialTypeId];
              final issuer = irmaConfiguration.issuers[credentialType.fullIssuerId];

              return IrmaPilotNudge(
                credentialType: credentialType,
                issuer: issuer,
                irmaConfigurationPath: irmaConfiguration.path,
                showLaunchFailDialog: credentialNudge.showLaunchFailDialog,
              );
            }
          }

          return Container(height: 0);
        },
      );

  bool _hasCredential(String credentialTypeId) {
    return (widget.credentials ?? []).any(
      (credential) => credential.info.credentialType.fullId == credentialTypeId,
    );
  }

  /// Is the card in the area where cards are tightly folded
  bool isTightlyFolded(WalletState newState, int index) =>
      newState == WalletState.tightlyfolded &&
      widget.credentials.length >= _cardsMaxExtended &&
      index < widget.credentials.length - _cardTopHeight / _cardTopBorderHeight;

  /// When there are many attributes, the contents will scroll. When scrolled beyond the bottom bound,
  /// a drag down will be triggered.
  void scrollBeyondBound(double y) {
    if (y > _scrollOverflowTipping && _currentState == WalletState.drawn) {
      setNewState(_cardInStackState);
    }
  }

  /// Set a new state of the wallet and start the animation
  void setNewState(WalletState newState, {bool nudgeIsVisible = true}) {
    setState(
      () {
        _nudgeVisible = nudgeIsVisible;
        _oldState = _currentState;
        _currentState = newState;
        _cardAnimationController.forward();
      },
    );
  }

  /// Calculate the position of a card, depending on the state of the wallet
  double calculateCardPosition({
    WalletState state,
    double walletTop,
    int index,
    int drawnCardIndex,
    double dragOffset,
  }) {
    double cardPosition;

    switch (state) {
      case WalletState.drawn:
        cardPosition = getCardDrawnPosition(index, drawnCardIndex, dragOffset, walletTop);
        break;

      case WalletState.minimal:
        cardPosition = getCardMinimizedPosition(index);
        break;

      case WalletState.tightlyfolded:
        cardPosition = getCardTightlyFoldedPosition(index);
        break;

      case WalletState.folded:
        cardPosition = getCardFoldedPosition(index, walletTop);
        break;
    }

    return cardPosition;
  }

  /// Position of a card when a card is shown
  double getCardDrawnPosition(int index, int drawnCardIndex, double dragOffset, double walletTop) {
    double cardPosition;

    if (index == drawnCardIndex) {
      cardPosition = walletTop - IrmaTheme.of(context).mediumSpacing - dragOffset;
    } else {
      cardPosition = (1 - index) * _cardTopBorderHeight.toDouble() + 2 + _minimizedCardOffset;
      if (cardPosition < -_cardTopHeight) {
        cardPosition = -_cardTopHeight.toDouble() + _cardTopBorderHeight.toDouble() + 2;
      }
      if (index > drawnCardIndex) {
        cardPosition += _cardTopBorderHeight;
      }
    }

    return cardPosition;
  }

  /// Position of a card when minimized to the bottom
  double getCardMinimizedPosition(int index) {
    double cardPosition;

    cardPosition = -(index + 1) * _cardTopBorderHeight.toDouble();
    if (cardPosition < -_cardTopHeight) {
      cardPosition = -_cardTopHeight.toDouble();
    }

    return cardPosition;
  }

  /// Position of a card folded in wallet. With many cards, the top cards are folded tighter
  double getCardTightlyFoldedPosition(int index) {
    double cardPosition;

    if (widget.credentials.length >= _cardsMaxExtended) {
      // Hidden cards

      if (index <= widget.credentials.length - 1 - _cardsTopVisible - _cardTopHeight / _cardTopBorderHeight) {
        cardPosition = (_cardsTopVisible + 1) * _cardTopHeight.toDouble();

        // Top small border cards
      } else if (index <= widget.credentials.length - 1 - _cardsTopVisible) {
        cardPosition = _cardsTopVisible * _cardTopHeight.toDouble() -
            (index - (widget.credentials.length - _cardsTopVisible - 1)) * _cardTopBorderHeight.toDouble();

        // Other cards
      } else {
        cardPosition = (widget.credentials.length - 1 - index) * _cardTopHeight.toDouble();
      }

      // Dragging top small border cards
      if (_drawnCardIndex < widget.credentials.length - _cardTopHeight / _cardTopBorderHeight &&
          index != _drawnCardIndex) {
        cardPosition -= _dragOffset;
      }

      // Few cards
    } else {
      cardPosition = (widget.credentials.length - 1 - index).toDouble() * _cardTopHeight.toDouble();
    }

    // Drag drawn card
    if (index == _drawnCardIndex) {
      cardPosition -= _dragOffset;
    }

    return cardPosition;
  }

  /// Position of a card folded in wallet. With many cards, all cards are visible, including the titles
  double getCardFoldedPosition(int index, double walletTop) {
    double cardPosition;

    cardPosition = min(walletTop, (widget.credentials.length - 1) * _cardTopHeight.toDouble()) - index * _cardTopHeight;

    if (index == _drawnCardIndex) {
      cardPosition -= _dragOffset;
    } else if (_dragOffset > _cardTopHeight - _cardTopBorderHeight) {
      if (index >= _drawnCardIndex) {
        cardPosition -= _dragOffset *
                ((_drawnCardIndex - index) *
                        (1 / _dragDownFactor - 1) /
                        (_drawnCardIndex - (widget.credentials.length - 1)) +
                    1 / _dragDownFactor) *
                _dragDownFactor -
            _cardTopHeight / 2;
      } else {
        cardPosition -= _dragOffset - (_cardTopHeight - _cardTopBorderHeight);
      }
    }

    return cardPosition;
  }

  /// Simple interpolation function between values x1 and x2. 0 <= p <=1
  double interpolate(double x1, double x2, double p) => x1 + p * (x2 - x1);

  /// Handler for refresh in ... menu
  Function() _createOnRefreshCredential(Credential credential) {
    if (credential.info.credentialType.issueUrl == null) {
      return null;
    }

    return () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WebviewScreen(getTranslation(context, credential.info.credentialType.issueUrl));
        }),
      );
    };
  }

  /// Handler for delete in ... menu
  Function() _createOnDeleteCredential(int index, Credential credential) {
    if (credential.info.credentialType.disallowDelete) {
      return null;
    }

    return () {
      IrmaRepository.get().bridgedDispatch(
        DeleteCredentialEvent(hash: credential.hash),
      );
      if (_drawnCardIndex == index && _currentState == WalletState.drawn) {
        setNewState(_cardInStackState);
      } else if (_drawnCardIndex > index && _currentState == WalletState.drawn) {
        // Compensate for removed card.
        _drawnCardIndex--;
      }
    };
  }
}

/// Wallet can have four states
enum WalletState {
  drawn, // A card is shown
  tightlyfolded, // Cards a folded tightly
  folded, // Cards a folded, titles are visible
  minimal, // Cards are minimized at bottom of wallet
}
