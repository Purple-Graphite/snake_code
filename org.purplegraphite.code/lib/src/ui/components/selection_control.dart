import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

const double _kHandleSize = 22.0;

// Minimal padding from all edges of the selection toolbar to all edges of the
// viewport.
const double _kToolbarScreenPadding = 8.0;
const double _kToolbarHeight = 50.0;
// Padding when positioning toolbar below selection.
const double _kToolbarContentDistanceBelow = _kHandleSize - 2.0;
const double _kToolbarContentDistance = 8.0;
const InteractiveInkFeatureFactory _splashFactory = InkRipple.splashFactory;
const Duration _animationDuration = const Duration(milliseconds: 200);
const BoxConstraints _overflowConstraints = const BoxConstraints(
  maxWidth: 250,
);
final BorderRadius _toolbarBorderRadius = BorderRadius.circular(12);
final BorderRadius _overflowOpenBorderRadius = BorderRadius.only(
  topRight: Radius.circular(12),
);

// Don't document this, for use only with selection controls
class _FlexWell extends StatelessWidget {
  const _FlexWell({
    Key key,
    this.onPressed,
    this.label,
    this.padding,
    this.color,
    this.icon,
    this.style,
    this.atEnd = false,
    this.tooltip,
  }) : super(key: key);
  final void Function() onPressed;
  final String label;
  final Icon icon;
  final EdgeInsetsGeometry padding;
  final Color color;
  final TextStyle style;
  final bool atEnd;
  final String tooltip;

  static String _toUpperCamelCase(String text) {
    return '${text[0].toUpperCase()}${text.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry _padding =
        padding ?? EdgeInsets.fromLTRB(14, 16, 14, 16);
    Widget child;

    if (label.toString() != null.toString()) {
      // text is not null or a String representation of null
      var _brightness = Theme.of(context).brightness;
      child = Text(
        '${_toUpperCamelCase(label)}',
        style: style ??
            TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: _brightness == Brightness.dark ? Colors.white : null,
            ),
      );
    } else {
      child = icon;
    }

    if (tooltip != null) {
      child = Tooltip(
        message: tooltip,
        child: child,
      );
    }

    child = Container(
      padding: _padding,
      color: color ?? Colors.transparent,
      child: child,
    );

    return InkWell(
      splashFactory: _splashFactory,
      child: child,
      onTap: onPressed,
    );
  }
}

/// Manages a copy/paste text selection toolbar.
class _TextSelectionToolbar extends StatefulWidget {
  const _TextSelectionToolbar({
    Key key,
    this.handleCut,
    this.handleCopy,
    this.handlePaste,
    this.handleSelectAll,
    this.isAbove,
  }) : super(key: key);

  final VoidCallback handleCut;
  final VoidCallback handleCopy;
  final VoidCallback handlePaste;
  final VoidCallback handleSelectAll;

  // When true, the toolbar fits above its anchor and will be positioned there.
  final bool isAbove;

  @override
  _TextSelectionToolbarState createState() => _TextSelectionToolbarState();
}

class _TextSelectionToolbarState extends State<_TextSelectionToolbar>
    with TickerProviderStateMixin {
  // Whether or not the overflow menu is open. When it is closed, the menu
  // items that don't overflow are shown. When it is open, only the overflowing
  // menu items are shown.
  bool _overflowOpen = false;
  // AnimationController _animationController;
  // The key for _TextSelectionToolbarContainer.
  UniqueKey _containerKey = UniqueKey();

  _FlexWell _getItem(VoidCallback onPressed, String label) {
    assert(onPressed != null);
    return _FlexWell(
      label: label,
      onPressed: onPressed,
    );
  }

  @override
  void initState() {
    super.initState();
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: _animationDuration,
    // );
  }

  @override
  void dispose() {
    super.dispose();
    // _animationController.dispose();
  }

  @override
  void didUpdateWidget(_TextSelectionToolbar oldWidget) {
    if (((widget.handleCut == null) != (oldWidget.handleCut == null)) ||
        ((widget.handleCopy == null) != (oldWidget.handleCopy == null)) ||
        ((widget.handlePaste == null) != (oldWidget.handlePaste == null)) ||
        ((widget.handleSelectAll == null) !=
            (oldWidget.handleSelectAll == null))) {
      // Change _TextSelectionToolbarContainer's key when the menu changes in
      // order to cause it to rebuild. This lets it recalculate its
      // saved width for the new set of children, and it prevents AnimatedSize
      // from animating the size change.
      _containerKey = UniqueKey();
      // If the menu items change, make sure the overflow menu is closed. This
      // prevents an empty overflow menu.
      _overflowOpen = false;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    final List<Widget> items = <Widget>[
      if (widget.handleCut != null)
        _getItem(widget.handleCut, localizations.cutButtonLabel),
      if (widget.handleCopy != null)
        _getItem(widget.handleCopy, localizations.copyButtonLabel),
      if (widget.handlePaste != null)
        _getItem(widget.handlePaste, localizations.pasteButtonLabel),
      if (widget.handleSelectAll != null)
        _getItem(widget.handleSelectAll, localizations.selectAllButtonLabel),
    ];

    // If there is no option available, build an empty widget.
    if (items.isEmpty) {
      return Container(width: 0.0, height: 0.0);
    }

    Color _toolbarColor, _iconColor, _iconButtonColor;
    final bool _isDark = Theme.of(context).brightness == Brightness.dark;
    _toolbarColor = _isDark ? Colors.grey[700] : Colors.grey[100];
    _iconButtonColor =
        _isDark ? Colors.grey[600].withAlpha(0x88) : Colors.grey[200];
    _iconColor = _isDark ? Colors.grey[800] : Colors.grey[400];

    return ConstrainedBox(
      constraints: _overflowConstraints,
      child: _TextSelectionToolbarContainer(
        key: _containerKey,
        overflowOpen: _overflowOpen,
        child: AnimatedSize(
          vsync: this,
          duration: _animationDuration,
          child: Material(
            elevation: 1,
            color: _toolbarColor,
            borderRadius: _toolbarBorderRadius,
            clipBehavior: Clip.hardEdge,
            child: _TextSelectionToolbarItems(
              isAbove: widget.isAbove,
              overflowOpen: _overflowOpen,
              children: <Widget>[
                // The navButton that shows and hides the overflow menu is the
                // first child.
                Material(
                  color: _iconButtonColor,
                  borderRadius: _overflowOpen
                      ? _overflowOpenBorderRadius
                      : _toolbarBorderRadius,
                  elevation: 0,
                  clipBehavior: Clip.hardEdge,
                  child: IconButton(
                    // TODO(justinmc): This should be an AnimatedIcon, but
                    // AnimatedIcons doesn't yet support arrow_back to more_vert.
                    // https://github.com/flutter/flutter/issues/51209
                    // icon: AnimatedIcon(
                    //   AnimatedIcons.more_vert_to_arrow_back,
                    // ),
                    icon: Icon(
                      _overflowOpen ? Icons.arrow_back : Icons.more_vert,
                      color: _iconColor,
                    ),
                    tooltip: _overflowOpen
                        ? localizations.backButtonTooltip
                        : localizations.moreButtonTooltip,
                    onPressed: () {
                      setState(() {
                        _overflowOpen = !_overflowOpen;
                      });
                      // _overflowOpen
                      //     ? _animationController.reverse()
                      //     : _animationController.forward();
                    },
                  ),
                ),
                ...items,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// When the overflow menu is open, it tries to align its right edge to the right
// edge of the closed menu. This widget handles this effect by measuring and
// maintaining the width of the closed menu and aligning the child to the right.
class _TextSelectionToolbarContainer extends SingleChildRenderObjectWidget {
  const _TextSelectionToolbarContainer({
    @required Widget child,
    @required this.overflowOpen,
    Key key,
  })  : assert(child != null),
        assert(overflowOpen != null),
        super(key: key, child: child);

  final bool overflowOpen;

  @override
  _TextSelectionToolbarContainerRenderBox createRenderObject(
      BuildContext context) {
    return _TextSelectionToolbarContainerRenderBox(overflowOpen: overflowOpen);
  }

  @override
  void updateRenderObject(BuildContext context,
      _TextSelectionToolbarContainerRenderBox renderObject) {
    renderObject.overflowOpen = overflowOpen;
  }
}

class _TextSelectionToolbarContainerRenderBox extends RenderProxyBox {
  _TextSelectionToolbarContainerRenderBox({
    @required bool overflowOpen,
  })  : assert(overflowOpen != null),
        _overflowOpen = overflowOpen,
        super();

  // The width of the menu when it was closed. This is used to achieve the
  // behavior where the open menu aligns its right edge to the closed menu's
  // right edge.
  double _closedWidth;

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    child.layout(constraints.loosen(), parentUsesSize: true);

    // Save the width when the menu is closed. If the menu changes, this width
    // is invalid, so it's important that this RenderBox be recreated in that
    // case. Currently, this is achieved by providing a new key to
    // _TextSelectionToolbarContainer.
    if (!overflowOpen && _closedWidth == null) {
      _closedWidth = child.size.width;
    }

    size = constraints.constrain(Size(
      // If the open menu is wider than the closed menu, just use its own width
      // and don't worry about aligning the right edges.
      // _closedWidth is used even when the menu is closed to allow it to
      // animate its size while keeping the same right alignment.
      _closedWidth == null || child.size.width > _closedWidth
          ? child.size.width
          : _closedWidth,
      child.size.height,
    ));

    final _ToolbarParentData childParentData =
        child.parentData as _ToolbarParentData;
    childParentData.offset = Offset(
      size.width - child.size.width,
      0.0,
    );
  }

  // Paint at the offset set in the parent data.
  @override
  void paint(PaintingContext context, Offset offset) {
    final _ToolbarParentData childParentData =
        child.parentData as _ToolbarParentData;
    context.paintChild(child, childParentData.offset + offset);
  }

  // Include the parent data offset in the hit test.
  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    final _ToolbarParentData childParentData =
        child.parentData as _ToolbarParentData;
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final _ToolbarParentData childParentData =
        child.parentData as _ToolbarParentData;
    transform.translate(childParentData.offset.dx, childParentData.offset.dy);
    super.applyPaintTransform(child, transform);
  }
}

// Renders the menu items in the correct positions in the menu and its overflow
// submenu based on calculating which item would first overflow.
class _TextSelectionToolbarItems extends MultiChildRenderObjectWidget {
  _TextSelectionToolbarItems({
    @required this.isAbove,
    @required this.overflowOpen,
    @required List<Widget> children,
    Key key,
  })  : assert(children != null),
        assert(isAbove != null),
        assert(overflowOpen != null),
        super(key: key, children: children);

  final bool isAbove;
  final bool overflowOpen;

  @override
  _TextSelectionToolbarItemsRenderBox createRenderObject(BuildContext context) {
    return _TextSelectionToolbarItemsRenderBox(
      isAbove: isAbove,
      overflowOpen: overflowOpen,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, _TextSelectionToolbarItemsRenderBox renderObject) {
    renderObject
      ..isAbove = isAbove
      ..overflowOpen = overflowOpen;
  }

  @override
  _TextSelectionToolbarItemsElement createElement() =>
      _TextSelectionToolbarItemsElement(this);
}

class _ToolbarParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether or not this child is painted.
  ///
  /// Children in the selection toolbar may be laid out for measurement purposes
  /// but not painted. This allows these children to be identified.
  bool shouldPaint;

  @override
  String toString() => '${super.toString()}; shouldPaint=$shouldPaint';
}

class _TextSelectionToolbarItemsElement extends MultiChildRenderObjectElement {
  _TextSelectionToolbarItemsElement(
    MultiChildRenderObjectWidget widget,
  ) : super(widget);

  static bool _shouldPaint(Element child) {
    return (child.renderObject.parentData as _ToolbarParentData).shouldPaint;
  }

  @override
  void debugVisitOnstageChildren(ElementVisitor visitor) {
    children.where(_shouldPaint).forEach(visitor);
  }
}

class _TextSelectionToolbarItemsRenderBox extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _ToolbarParentData> {
  _TextSelectionToolbarItemsRenderBox({
    @required bool isAbove,
    @required bool overflowOpen,
  })  : assert(overflowOpen != null),
        assert(isAbove != null),
        _isAbove = isAbove,
        _overflowOpen = overflowOpen,
        super();

  // The index of the last item that doesn't overflow.
  int _lastIndexThatFits = -1;

  bool _isAbove;
  bool get isAbove => _isAbove;
  set isAbove(bool value) {
    if (value == isAbove) {
      return;
    }
    _isAbove = value;
    markNeedsLayout();
  }

  bool _overflowOpen;
  bool get overflowOpen => _overflowOpen;
  set overflowOpen(bool value) {
    if (value == overflowOpen) {
      return;
    }
    _overflowOpen = value;
    markNeedsLayout();
  }

  // Layout the necessary children, and figure out where the children first
  // overflow, if at all.
  void _layoutChildren() {
    // When overflow is not open, the toolbar is always a specific height.
    final BoxConstraints sizedConstraints = _overflowOpen
        ? constraints
        : BoxConstraints.loose(Size(
            constraints.maxWidth,
            _kToolbarHeight,
          ));

    int i = -1;
    double width = 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      // No need to layout children inside the overflow menu when it's closed.
      // The opposite is not true. It is necessary to layout the children that
      // don't overflow when the overflow menu is open in order to calculate
      // _lastIndexThatFits.
      if (_lastIndexThatFits != -1 && !overflowOpen) {
        return;
      }

      final RenderBox child = (renderObjectChild as RenderBox)
        ..layout(sizedConstraints.loosen(), parentUsesSize: true);
      width += child.size.width;

      if (width > sizedConstraints.maxWidth && _lastIndexThatFits == -1) {
        _lastIndexThatFits = i - 1;
      }
    });

    // If the last child overflows, but only because of the width of the
    // overflow button, then just show it and hide the overflow button.
    final RenderBox navButton = firstChild;
    if (_lastIndexThatFits != -1 &&
        _lastIndexThatFits == childCount - 2 &&
        width - navButton.size.width <= sizedConstraints.maxWidth) {
      _lastIndexThatFits = -1;
    }
  }

  // Returns true when the child should be painted, false otherwise.
  bool _shouldPaintChild(RenderObject renderObjectChild, int index) {
    // Paint the navButton when there is overflow.
    if (renderObjectChild == firstChild) {
      return _lastIndexThatFits != -1;
    }

    // If there is no overflow, all children besides the navButton are painted.
    if (_lastIndexThatFits == -1) {
      return true;
    }

    // When there is overflow, paint if the child is in the part of the menu
    // that is currently open. Overflowing children are painted when the
    // overflow menu is open, and the children that fit are painted when the
    // overflow menu is closed.
    return (index > _lastIndexThatFits) == overflowOpen;
  }

  // Decide which children will be pained and set their shouldPaint, and set the
  // offset that painted children will be placed at.
  void _placeChildren() {
    int i = -1;
    Size nextSize = const Size(0.0, 0.0);
    double fitWidth = 0.0;
    final RenderBox navButton = firstChild;
    double overflowHeight =
        overflowOpen && !isAbove ? navButton.size.height : 0.0;
    visitChildren((RenderObject renderObjectChild) {
      i++;

      final RenderBox child = renderObjectChild as RenderBox;
      final _ToolbarParentData childParentData =
          child.parentData as _ToolbarParentData;

      // Handle placing the navigation button after iterating all children.
      if (renderObjectChild == navButton) {
        return;
      }

      // There is no need to place children that won't be painted.
      if (!_shouldPaintChild(renderObjectChild, i)) {
        childParentData.shouldPaint = false;
        return;
      }
      childParentData.shouldPaint = true;

      if (!overflowOpen) {
        childParentData.offset = Offset(fitWidth, 0.0);
        fitWidth += child.size.width;
        nextSize = Size(
          fitWidth,
          math.max(child.size.height, nextSize.height),
        );
      } else {
        childParentData.offset = Offset(0.0, overflowHeight);
        overflowHeight += child.size.height;
        nextSize = Size(
          math.max(child.size.width, nextSize.width),
          overflowHeight,
        );
      }
    });

    // Place the navigation button if needed.
    final _ToolbarParentData navButtonParentData =
        navButton.parentData as _ToolbarParentData;
    if (_shouldPaintChild(firstChild, 0)) {
      navButtonParentData.shouldPaint = true;
      if (overflowOpen) {
        navButtonParentData.offset =
            isAbove ? Offset(0.0, overflowHeight) : Offset.zero;
        nextSize = Size(
          nextSize.width,
          isAbove ? nextSize.height + navButton.size.height : nextSize.height,
        );
      } else {
        navButtonParentData.offset = Offset(fitWidth, 0.0);
        nextSize = Size(nextSize.width + navButton.size.width, nextSize.height);
      }
    } else {
      navButtonParentData.shouldPaint = false;
    }

    size = nextSize;
  }

  @override
  void performLayout() {
    _lastIndexThatFits = -1;
    if (firstChild == null) {
      performResize();
      return;
    }

    _layoutChildren();
    _placeChildren();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    visitChildren((RenderObject renderObjectChild) {
      final RenderBox child = renderObjectChild as RenderBox;
      final _ToolbarParentData childParentData =
          child.parentData as _ToolbarParentData;
      if (!childParentData.shouldPaint) {
        return;
      }

      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ToolbarParentData) {
      child.parentData = _ToolbarParentData();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {Offset position}) {
    // The x, y parameters have the top left of the node's box as the origin.
    RenderBox child = lastChild;
    while (child != null) {
      final _ToolbarParentData childParentData =
          child.parentData as _ToolbarParentData;

      // Don't hit test children aren't shown.
      if (!childParentData.shouldPaint) {
        child = childParentData.previousSibling;
        continue;
      }

      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}

/// Centers the toolbar around the given anchor, ensuring that it remains on
/// screen.
class _TextSelectionToolbarLayout extends SingleChildLayoutDelegate {
  _TextSelectionToolbarLayout(this.anchor, this.upperBounds, this.fitsAbove);

  /// Anchor position of the toolbar in global coordinates.
  final Offset anchor;

  /// The upper-most valid y value for the anchor.
  final double upperBounds;

  /// Whether the closed toolbar fits above the anchor position.
  ///
  /// If the closed toolbar doesn't fit, then the menu is rendered below the
  /// anchor position. It should never happen that the toolbar extends below the
  /// padded bottom of the screen.
  ///
  /// If the closed toolbar does fit but it doesn't fit when the overflow menu
  /// is open, then the toolbar is still rendered above the anchor position. It
  /// then grows downward, overlapping the selection.
  final bool fitsAbove;

  // Return the value that centers width as closely as possible to position
  // while fitting inside of min and max.
  static double _centerOn(
      double position, double width, double min, double max) {
    // If it overflows on the left, put it as far left as possible.
    if (position - width / 2.0 < min) {
      return min;
    }

    // If it overflows on the right, put it as far right as possible.
    if (position + width / 2.0 > max) {
      return max - width;
    }

    // Otherwise it fits while perfectly centered.
    return position - width / 2.0;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(
      _centerOn(
        anchor.dx,
        childSize.width,
        _kToolbarScreenPadding,
        size.width - _kToolbarScreenPadding,
      ),
      fitsAbove
          ? math.max(upperBounds, anchor.dy - childSize.height)
          : anchor.dy,
    );
  }

  @override
  bool shouldRelayout(_TextSelectionToolbarLayout oldDelegate) {
    return anchor != oldDelegate.anchor;
  }
}

/// Draws a single text selection handle which points up and to the left.
class _TextSelectionHandlePainter extends CustomPainter {
  _TextSelectionHandlePainter({this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double radius = size.width / 2.0;
    final Rect circle =
        Rect.fromCircle(center: Offset(radius, radius), radius: radius);
    final Rect point = Rect.fromLTWH(0.0, 0.0, radius, radius);
    final Path path = Path()
      ..addOval(circle)
      ..addRect(point);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TextSelectionHandlePainter oldPainter) {
    return color != oldPainter.color;
  }
}

class _CodeTextSelectionControls extends TextSelectionControls {
  /// Returns the size of the Material handle.
  @override
  Size getHandleSize(double textLineHeight) =>
      const Size(_kHandleSize, _kHandleSize);

  /// Builder for material-style copy/paste text selection toolbar.
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
  ) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));

    // The toolbar should appear below the TextField when there is not enough
    // space above the TextField to show it.
    final TextSelectionPoint startTextSelectionPoint = endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        endpoints.length > 1 ? endpoints[1] : endpoints[0];
    const double closedToolbarHeightNeeded =
        _kToolbarScreenPadding + _kToolbarHeight + _kToolbarContentDistance;
    final double paddingTop = MediaQuery.of(context).padding.top;
    final double availableHeight = globalEditableRegion.top +
        startTextSelectionPoint.point.dy -
        textLineHeight -
        paddingTop;
    final bool fitsAbove = closedToolbarHeightNeeded <= availableHeight;
    final Offset anchor = Offset(
      globalEditableRegion.left + selectionMidpoint.dx,
      fitsAbove
          ? globalEditableRegion.top +
              startTextSelectionPoint.point.dy -
              textLineHeight -
              _kToolbarContentDistance
          : globalEditableRegion.top +
              endTextSelectionPoint.point.dy +
              _kToolbarContentDistanceBelow,
    );

    return Stack(
      children: <Widget>[
        CustomSingleChildLayout(
          delegate: _TextSelectionToolbarLayout(
            anchor,
            _kToolbarScreenPadding + paddingTop,
            fitsAbove,
          ),
          child: _TextSelectionToolbar(
            handleCut: canCut(delegate) ? () => handleCut(delegate) : null,
            handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
            handlePaste:
                canPaste(delegate) ? () => handlePaste(delegate) : null,
            handleSelectAll:
                canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
            isAbove: fitsAbove,
          ),
        ),
      ],
    );
  }

  /// Builder for material-style text selection handles.
  @override
  Widget buildHandle(
      BuildContext context, TextSelectionHandleType type, double textHeight) {
    final Widget handle = SizedBox(
      width: _kHandleSize,
      height: _kHandleSize,
      child: CustomPaint(
        painter: _TextSelectionHandlePainter(
          color: Theme.of(context).textSelectionHandleColor,
        ),
      ),
    );

    // [handle] is a circle, with a rectangle in the top left quadrant of that
    // circle (an onion pointing to 10:30). We rotate [handle] to point
    // straight up or up-right depending on the handle type.
    switch (type) {
      case TextSelectionHandleType.left: // points up-right
        return Transform.rotate(
          angle: math.pi / 2.0,
          child: handle,
        );
      case TextSelectionHandleType.right: // points up-left
        return handle;
      case TextSelectionHandleType.collapsed: // points up
        return Transform.rotate(
          angle: math.pi / 4.0,
          child: handle,
        );
    }
    assert(type != null);
    return null;
  }

  /// Gets anchor for material-style text selection handles.
  ///
  /// See [TextSelectionControls.getHandleAnchor].
  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    switch (type) {
      case TextSelectionHandleType.left:
        return const Offset(_kHandleSize, 0);
      case TextSelectionHandleType.right:
        return Offset.zero;
      default:
        return const Offset(_kHandleSize / 2, -4);
    }
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // Android allows SelectAll when selection is not collapsed, unless
    // everything has already been selected.
    final TextEditingValue value = delegate.textEditingValue;
    return delegate.selectAllEnabled &&
        value.text.isNotEmpty &&
        !(value.selection.start == 0 &&
            value.selection.end == value.text.length);
  }
}

/// Text selection controls for Codemorphic widgets.
/// Follows design of Android's Native selection controls.
///
/// In the future it may support extendable addtional controls &
/// magnification of text when moving cursor by touch.
final TextSelectionControls codeSelectionControls =
    _CodeTextSelectionControls();