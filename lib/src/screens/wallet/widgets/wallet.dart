// This code is not null safe yet.
// @dart=2.11

import 'dart:async';
import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:irmamobile/src/data/irma_repository.dart';
import 'package:irmamobile/src/models/credential_events.dart';
import 'package:irmamobile/src/models/credentials.dart';
import 'package:irmamobile/src/models/irma_configuration.dart';
import 'package:irmamobile/src/models/native_events.dart';
import 'package:irmamobile/src/screens/wallet/widgets/get_cards_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/irma_pilot_nudge.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_button.dart';
import 'package:irmamobile/src/screens/wallet/widgets/wallet_icon_button.dart';
import 'package:irmamobile/src/theme/irma_icons.dart';
import 'package:irmamobile/src/theme/theme.dart';
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
    Key key,
    @required this.credentials,
    this.hasLoginLogoutAnimation = false,
    this.isOpen = false,
    this.newCardIndex,
    this.showNewCardAnimation,
    this.onQRScannerPressed,
    this.onHelpPressed,
    this.onAddCardsPressed,
    @required this.onNewCardAnimationShown,
  }) : super(key: key);

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
  WalletState createState() => WalletState();
}

class WalletState extends State<Wallet> with TickerProviderStateMixin {
  final _cardAnimationDuration = 250;
  final _loginAnimationDuration = 400;
  final _walletAspectRatio = 87 / 360; // wallet.svg 360x87 px
  final _walletShrinkTween = Tween<double>(begin: 0.0, end: 1.0);
  final _containerKey = GlobalKey();

  // Width of the wallet is only known after the first render.
  double _walletWidth;

  // Distance between bottom of app and top of wallet; is only known after the first render.
  double _walletHeight;

  // Distance between the top of the bottom bar and top of wallet; is only known after the first render.
  double get _cardStackHeight => _walletHeight - _walletAspectRatio * _walletWidth;

  // Visible height of tightly folded cards
  final _cardTopBorderHeight = 10;

  // Visible height of cards with visible title
  final _cardTopHeight = 36;

  // Max number of cards allowed without needing a switch between folded and tightly folded wallet
  final _cardsMaxExtended = 5;

  // Number of cards with visible title that are shown in a tightly folded wallet
  final _cardsTopVisible = 3;

  // Number of cards with visible title in a tightly folded wallet that can be used as overlap
  // for wallet expand button.
  final _cardsTopVisibleOverlap = 1;

  // Number of cards with only a visible border that are shown in a tightly folded wallet
  final _cardsTopBorderVisible = 4;

  // Movements below this distance are not handled as swipes
  final _dragTipping = 50;

  // Scrolling below this distance are not handled as swipes
  final _scrollOverflowTipping = 50;

  // Height of qr/help buttons
  final _walletIconHeight = 60;

  // How much cards are dragged down [layout==folded]
  final _dragDownFactor = 1.5;

  // Time to show new cards before being added to wallet
  final _cardVisibleDelay = 3250;

  // Time between opening the wallet and showing the cards
  final _walletShowCardsDelay = 200;

  // Offset of minimized cards
  final _minimizedCardOffset = 16;

  // Height of interactive bottom to toggle wallet layout between tightlyfolded and folded
  final _walletBottomInteractive = 0.7;

  // Is the fixed offset a card moves to show a user that it can move
  final double _cardGestureNudgingOffset = 20;

  AnimationController _cardAnimationController;
  AnimationController _loginLogoutAnimationController;
  Animation<double> _drawAnimation;

  WalletLayout _cardInStackLayout = WalletLayout.tightlyfolded;
  WalletLayout _oldLayout = WalletLayout.minimal;
  WalletLayout _currentLayout = WalletLayout.minimal;

  // Index of drawn (visible) card
  int _drawnCardIndex = 0;

  // Variables for good dragging UX
  double _dragOffsetSave = 0;
  double _dragOffset = 0;
  double _cardDragOffset = 0;
  bool _cardTappedSave = false;
  bool _nudgeVisible = true;
  bool _showCards = false;

  final IrmaRepository _irmaClient = IrmaRepository.get();

  Type get type => null;

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
                if (_oldLayout == WalletLayout.tightlyfolded || _oldLayout == WalletLayout.folded) {
                  _cardInStackLayout = _oldLayout;
                }

                if (_currentLayout == WalletLayout.tightlyfolded && widget.showNewCardAnimation == true) {
                  widget.onNewCardAnimationShown();
                }
                _oldLayout = _currentLayout;
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
        _currentLayout = WalletLayout.drawn;
        _nudgeVisible = false;
        _cardAnimationController.forward(from: _cardAnimationDuration.toDouble());
      });

      Future.delayed(Duration(milliseconds: _cardVisibleDelay)).then((_) {
        if (mounted) {
          setNewLayout(_cardInStackLayout);
        }
      });
    } else if (_drawnCardIndex < (oldWidget.credentials?.length ?? 0) && widget.credentials != null) {
      // Check whether drawn card still exists in the new state. Index might have changed due to removal.
      final newIndex = widget.credentials.indexWhere((c) => c.hash == oldWidget.credentials[_drawnCardIndex].hash);
      if (newIndex >= 0) {
        // Credential is still there; update the drawn card index.
        _drawnCardIndex = newIndex;
      } else {
        // Drawn card does not exist anymore, so assign a non-existing index.
        _drawnCardIndex = widget.credentials.length;
      }
    }

    // If drawn card does not exist anymore, make sure the currentState is not WalletLayout.drawn.
    if (_drawnCardIndex >= (widget.credentials?.length ?? 0) && _currentLayout == WalletLayout.drawn) {
      setNewLayout(_cardInStackLayout);
    }

    if (widget.hasLoginLogoutAnimation && !oldWidget.isOpen && widget.isOpen) {
      startLoginAnimation();
    }

    if (widget.hasLoginLogoutAnimation && oldWidget.isOpen && !widget.isOpen) {
      _loginLogoutAnimationController.reverse().then((_) {
        _irmaClient.lock();
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  void _calculateSizes() {
    // Height is only known after the first render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newWalletHeight = context.size.height;
      if (newWalletHeight != _walletHeight) {
        setState(() {
          _walletWidth = context.size.width; // Width never changes.
          _walletHeight = newWalletHeight;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_drawAnimation, _loginLogoutAnimationController]),
        builder: (BuildContext buildContext, Widget child) {
          // We can only render the wallet when the sizes are known.
          _calculateSizes();
          if (_walletHeight == null) {
            return Container();
          }

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
                key: const Key('wallet_present'),
                alignment: Alignment.bottomCenter,
                height: _walletHeight,
                width: _walletWidth,
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
                        width: _walletWidth,
                      ),
                    ),

                    /// All cards
                    if (_showCards) _buildCardStack(),

                    /// Wallet foreground with help and qr buttons
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        children: <Widget>[
                          IgnorePointer(
                            ignoring: true,
                            child: SvgPicture.asset(
                              'assets/wallet/wallet_front.svg',
                              width: _walletWidth,
                            ),
                          ),

                          /// Element to prevent wallet foreground to be tappable without harming other gestures
                          Positioned(
                            bottom: 0,
                            height: _walletWidth * _walletAspectRatio * _walletBottomInteractive,
                            width: _walletWidth,
                            child: GestureDetector(
                              onTap: () {},
                            ),
                          ),

                          Positioned(
                            left: 16,
                            bottom: (_walletWidth * _walletAspectRatio - _walletIconHeight) / 2,
                            child: WalletButton(
                              key: const Key('wallet_button_help'),
                              svgFile: 'assets/wallet/btn_help.svg',
                              accessibleName: "wallet.help",
                              clickStreamSink: widget.onHelpPressed,
                            ),
                          ),
                          Positioned(
                            right: 16,
                            bottom: (_walletWidth * _walletAspectRatio - _walletIconHeight) / 2,
                            child: WalletButton(
                              key: const Key('wallet_button_scanqr'),
                              svgFile: 'assets/wallet/btn_qrscan.svg',
                              accessibleName: "wallet.scan_qr_code",
                              clickStreamSink: widget.onQRScannerPressed,
                            ),
                          ),

                          /// Show button to minimize wallet only if wallet is in a layout that it can be minimized
                          if (_currentLayout == WalletLayout.drawn ||
                              _currentLayout == WalletLayout.folded && widget.credentials.length > _cardsMaxExtended)
                            Positioned(
                              bottom: (_walletWidth * _walletAspectRatio - _walletIconHeight) / 2,
                              width: _walletWidth,
                              child: Align(
                                alignment: Alignment.center,
                                child: WalletIconButton(
                                  iconData: IrmaIcons.chevronDown,
                                  onTap: () {
                                    switch (_currentLayout) {
                                      case WalletLayout.tightlyfolded:
                                        setNewLayout(WalletLayout.folded);
                                        break;
                                      case WalletLayout.folded:
                                        setNewLayout(WalletLayout.tightlyfolded);
                                        break;
                                      default:
                                        setNewLayout(_cardInStackLayout);
                                        break;
                                    }
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Positioned(
                      right: 0,
                      top: _walletShrinkTween.evaluate(_loginLogoutAnimationController) * _walletHeight,
                      child: SvgPicture.asset(
                        'assets/wallet/wallet_high.svg',
                        width: _walletWidth,
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
      if (mounted) {
        setNewLayout(WalletLayout.tightlyfolded);
      }
    });
  }

  Widget _buildCardStack() {
    if (widget.credentials == null) {
      return Container();
    }

    /// Compensate _screenHeightMargin for bottom bar
    final stackHeightFolded = widget.credentials.length.toDouble() * _cardTopHeight;

    final scrollingEnabled = _currentLayout == WalletLayout.folded && stackHeightFolded > _cardStackHeight;

    /// Render all credential cards
    final rendered = widget.credentials.asMap().entries.map<Widget>(
      (credential) {
        final cardTop = getCardPosition(credential.key);
        return Positioned(
          left: 0,
          right: 0,
          top: _cardStackHeight - cardTop,
          child: getCard(
            index: credential.key,
            count: widget.credentials.length,
            credential: credential.value,
            gesturesLongPressOnly: scrollingEnabled,
          ),
        );
      },
    ).toList();

    /// Display chevron to help users expanding their tightly folded wallet.
    /// Button needs to be inserted in the stack at the right place.
    final index = widget.credentials.length < _cardsTopVisible + _cardsTopVisibleOverlap + _cardsTopBorderVisible
        ? widget.credentials.length - _cardsTopVisible
        : widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap;
    if (_currentLayout == WalletLayout.tightlyfolded && widget.credentials.length > _cardsMaxExtended) {
      rendered.insert(
        index,
        _buildWalletExpandButton(),
      );
    }

    /// Wallet may only be scrollable when being in a folded layout.
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
                maxHeight: stackHeightFolded + _walletAspectRatio * _walletWidth,
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
          maxHeight: _walletHeight,
        ),
        child: Stack(
          overflow: Overflow.visible,
          children: rendered,
        ),
      );
    }
  }

  Widget _buildWalletExpandButton() {
    int topCardIndex = widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap - _cardsTopBorderVisible;
    // If there are not enough cards, the first one is the highest one.
    if (topCardIndex < 0) {
      topCardIndex = 0;
    }
    return Positioned(
      left: 0,
      right: 0,
      top: _cardStackHeight - getCardPosition(topCardIndex),
      child: Align(
        alignment: Alignment.center,

        /// Add similar gestures as the cards have to make sure the animations keep working
        child: WalletIconButton(
          iconData: IrmaIcons.chevronUp,
          onTap: () => setNewLayout(WalletLayout.folded),
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
            if ((_dragOffset < -_dragTipping && _currentLayout != WalletLayout.drawn) ||
                (_dragOffset > _dragTipping && _currentLayout == WalletLayout.drawn)) {
              setNewLayout(WalletLayout.folded);
            } else {
              _cardAnimationController.forward();
            }
          },
        ),
      ),
    );
  }

  /// IrmaCard with gestures attached
  /// Most of this code deals with having a good dragging UX
  Widget getCard({int index, int count, Credential credential, bool gesturesLongPressOnly}) => GestureDetector(
        onTap: () {
          cardTapped(index, credential);
        },
        onLongPressStart: _currentLayout == WalletLayout.drawn
            ? null
            : (LongPressStartDetails details) {
                HapticFeedback.vibrate();
                setState(() {
                  cardGestureInit(index, count, details.localPosition, longPressed: true);
                  cardGestureFixedUpdate();
                });
              },
        onLongPressMoveUpdate: _currentLayout == WalletLayout.drawn
            ? null
            : (LongPressMoveUpdateDetails details) {
                setState(() {
                  cardGestureUpdate(index, details.localPosition);
                });
              },
        onLongPressEnd: _currentLayout == WalletLayout.drawn
            ? null
            : (LongPressEndDetails details) {
                cardGestureEnd(index, credential);
              },
        onVerticalDragDown: !gesturesLongPressOnly
            ? (DragDownDetails details) {
                setState(() {
                  cardGestureInit(index, count, details.localPosition, longPressed: false);
                });
              }
            : null,
        onVerticalDragStart: !gesturesLongPressOnly
            ? (DragStartDetails details) {
                setState(() {
                  cardGestureFixedUpdate();
                });
              }
            : null,
        onVerticalDragUpdate: !gesturesLongPressOnly
            ? (DragUpdateDetails details) {
                setState(() {
                  cardGestureUpdate(index, details.localPosition);
                });
              }
            : null,
        onVerticalDragEnd: !gesturesLongPressOnly
            ? (DragEndDetails details) {
                cardGestureEnd(index, credential);
              }
            : null,
        child: IrmaCard.fromCredential(
          key: Key('wallet_card_$index'),
          credential: credential,
          scrollBeyondBoundsCallback: scrollBeyondBound,
          onRefreshCredential: _createOnRefreshCredential(credential),
          onDeleteCredential: _createOnDeleteCredential(index, credential),
        ),
      );

  void cardGestureInit(int index, int count, Offset localPosition, {bool longPressed}) {
    // Correct all drags with the starting localPosition of the gesture to assure a smooth animation.
    _cardDragOffset = localPosition.dy;

    if (_currentLayout != WalletLayout.drawn) {
      _drawnCardIndex = index;
      if (longPressed) {
        // Make a fixed nudge card drag to show users the card can move now
        _cardDragOffset += _cardGestureNudgingOffset;
      }
    }

    if (_drawnCardIndex == index) {
      _dragOffsetSave = localPosition.dy - _cardDragOffset;
    }
    _cardTappedSave = longPressed;
  }

  void cardGestureFixedUpdate() {
    _dragOffset = _dragOffsetSave;
  }

  void cardGestureUpdate(int index, Offset localPosition) {
    if (_drawnCardIndex == index) {
      _dragOffset = localPosition.dy - _cardDragOffset;
    }
    if (_cardTappedSave && (_dragOffset < _dragOffsetSave - 2 || _dragOffset > _dragOffsetSave + 2)) {
      // When card has been substantially moved, see card gesture as a drag and not as a tap.
      _cardTappedSave = false;
    }
  }

  void cardGestureEnd(int index, Credential credential) {
    if (_cardTappedSave ||
        (_dragOffset < -_dragTipping && _currentLayout != WalletLayout.drawn) ||
        (_dragOffset > _dragTipping && _currentLayout == WalletLayout.drawn)) {
      cardTapped(index, credential);
    } else if (_dragOffset > _dragTipping && _currentLayout == WalletLayout.folded) {
      setNewLayout(WalletLayout.tightlyfolded);
    } else {
      _cardAnimationController.forward();
    }
  }

  /// Animate each card between old and new layout
  double getCardPosition(int index) {
    final double oldTop = calculateCardPosition(
      layout: _oldLayout,
      index: index,
      drawnCardIndex: _drawnCardIndex,
      dragOffset: _dragOffset,
    );

    final double newTop = calculateCardPosition(
      layout: _currentLayout,
      index: index,
      drawnCardIndex: _drawnCardIndex,
      dragOffset: 0,
    );

    return interpolate(oldTop, newTop, _walletShrinkTween.evaluate(_drawAnimation));
  }

  /// onTap handler
  void cardTapped(int index, Credential credential) {
    if (_currentLayout == WalletLayout.drawn) {
      setNewLayout(_cardInStackLayout);
    } else {
      if (isTightlyFolded(_currentLayout, index)) {
        setNewLayout(WalletLayout.folded);
      } else {
        _drawnCardIndex = index;
        setNewLayout(WalletLayout.drawn);
      }
    }
  }

  Widget _buildNudge(BuildContext context) => StreamBuilder(
        stream: _irmaClient.getIrmaConfiguration(),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            final irmaConfiguration = snapshot.data as IrmaConfiguration;
            final credentialNudge = CredentialNudgeProvider.of(context).credentialNudge;

            if (credentialNudge == null || _hasCredential(credentialNudge.fullCredentialTypeId)) {
              return GetCardsNudge(
                key: const Key('add_cards_button'),
                credentials: widget.credentials,
                size: MediaQuery.of(context).size,
                onAddCardsPressed: widget.onAddCardsPressed,
                showButton: (widget?.credentials?.length ?? 0) <= _cardsTopVisible,
              );
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
  bool isTightlyFolded(WalletLayout newLayout, int index) {
    if (newLayout != WalletLayout.tightlyfolded || widget.credentials.length <= _cardsMaxExtended) {
      return false;
    }
    if (widget.credentials.length < _cardsTopVisible + _cardsTopVisibleOverlap + _cardsTopBorderVisible) {
      return index < widget.credentials.length - _cardsTopVisible;
    } else {
      return index < widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap;
    }
  }

  /// When there are many attributes, the contents will scroll. When scrolled beyond the bottom bound,
  /// a drag down will be triggered.
  void scrollBeyondBound(double y) {
    if (y > _scrollOverflowTipping && _currentLayout == WalletLayout.drawn) {
      setNewLayout(_cardInStackLayout);
    }
  }

  /// Set a new layout of the wallet and start the animation
  void setNewLayout(WalletLayout newLayout) {
    setState(
      () {
        _nudgeVisible = nudgeVisible(newLayout);
        _oldLayout = _currentLayout;
        _currentLayout = newLayout;
        _cardAnimationController.forward();
      },
    );
  }

  /// Set the layout to the cards-in-stack layout
  void androidBackPressed() {
    if (_currentLayout == WalletLayout.drawn) {
      setNewLayout(_cardInStackLayout);
    } else {
      _irmaClient.bridgedDispatch(AndroidSendToBackgroundEvent());
    }
  }

  bool nudgeVisible(WalletLayout layout) {
    switch (layout) {
      case WalletLayout.drawn:
        return false;
      case WalletLayout.folded:
        final screenHeight = MediaQuery.of(context).size.height;
        // Make nudge invisible if cards occupy more than half of the screen
        return _cardTopHeight * (widget.credentials?.length ?? 0) < screenHeight / 2;
      default:
        return true;
    }
  }

  /// Calculate the position of a card, depending on the layout of the wallet
  double calculateCardPosition({
    WalletLayout layout,
    int index,
    int drawnCardIndex,
    double dragOffset,
  }) {
    double cardPosition;

    switch (layout) {
      case WalletLayout.drawn:
        cardPosition = getCardDrawnPosition(index, drawnCardIndex, dragOffset);
        break;

      case WalletLayout.minimal:
        cardPosition = getCardMinimizedPosition(index);
        break;

      case WalletLayout.tightlyfolded:
        cardPosition = getCardTightlyFoldedPosition(index);
        break;

      case WalletLayout.folded:
        cardPosition = getCardFoldedPosition(index);
        break;
    }

    return cardPosition;
  }

  /// Position of a card when a card is shown
  double getCardDrawnPosition(int index, int drawnCardIndex, double dragOffset) {
    double cardPosition;

    if (index == drawnCardIndex) {
      cardPosition = _cardStackHeight - IrmaTheme.of(context).mediumSpacing - dragOffset;
    } else {
      cardPosition = -index * _cardTopBorderHeight.toDouble() + _minimizedCardOffset;
      // Correct for the drawn card creating a gap in the minimized wallet
      if (index > drawnCardIndex) {
        cardPosition += _cardTopBorderHeight;
      }
    }

    return cardPosition;
  }

  /// Position of a card when minimized to the bottom
  double getCardMinimizedPosition(int index) {
    double cardPosition;

    cardPosition = -index * _cardTopBorderHeight.toDouble() + _minimizedCardOffset;
    if (cardPosition < -_cardTopHeight) {
      cardPosition = -_cardTopHeight.toDouble();
    }

    return cardPosition;
  }

  /// Position of a card folded in wallet. With many cards, the top cards are folded tighter
  double getCardTightlyFoldedPosition(int index) {
    double cardPosition;

    if (widget.credentials.length > _cardsMaxExtended) {
      // Hidden cards
      if (index < widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap - _cardsTopBorderVisible) {
        cardPosition = _cardsTopVisible * _cardTopHeight.toDouble();

        // Top small border cards
      } else if (index < widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap) {
        cardPosition = (_cardsTopVisible + _cardsTopVisibleOverlap) * _cardTopHeight.toDouble() +
            (widget.credentials.length - _cardsTopVisible - _cardsTopVisibleOverlap - index) * _cardTopBorderHeight;

        // Other cards
      } else {
        cardPosition = (widget.credentials.length - index) * _cardTopHeight.toDouble();
      }

      // Dragging top small border cards
      // Check whether overlap card is needed for wallet expand button. Otherwise the card can move individually.
      final individuallyMovingCards =
          widget.credentials.length < _cardsTopVisible + _cardsTopVisibleOverlap + _cardsTopBorderVisible
              ? _cardsTopVisible
              : _cardsTopVisible + _cardsTopVisibleOverlap;
      if (_drawnCardIndex < widget.credentials.length - individuallyMovingCards && index != _drawnCardIndex) {
        cardPosition -= _dragOffset;
      }

      // Few cards
    } else {
      cardPosition = (widget.credentials.length - index).toDouble() * _cardTopHeight.toDouble();
    }

    // Drag drawn card
    if (index == _drawnCardIndex) {
      cardPosition -= _dragOffset;
    }

    return cardPosition;
  }

  /// Position of a card folded in wallet. With many cards, all cards are visible, including the titles
  double getCardFoldedPosition(int index) {
    double cardPosition;

    cardPosition =
        min(_cardStackHeight, widget.credentials.length * _cardTopHeight.toDouble()) - index * _cardTopHeight;

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
    if (credential.info.credentialType.issueUrl.isEmpty) {
      return null;
    }

    return () {
      _irmaClient.openIssueURL(context, credential.info.fullId);
    };
  }

  /// Handler for delete in ... menu
  Function() _createOnDeleteCredential(int index, Credential credential) {
    if (credential.info.credentialType.disallowDelete) {
      return null;
    }

    return () => _irmaClient.bridgedDispatch(DeleteCredentialEvent(hash: credential.hash));
  }
}

// Wallet can have four layouts
enum WalletLayout {
  drawn, // A card is shown
  tightlyfolded, // Cards a folded tightly
  folded, // Cards a folded, titles are visible
  minimal, // Cards are minimized at bottom of wallet
}
