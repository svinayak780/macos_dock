import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MacosDock<IconData>(
          items: const [
            Icons.person,
            Icons.message,
            Icons.call,
            Icons.camera,
            Icons.photo,
          ]
              .map<MacosDockItem<IconData>>((icon) => MacosDockItem(
                    icon: icon,
                    onTap: () {
                      // Handle tap event.
                      // debug stub
                      if (kDebugMode) {
                        print('tapped $icon');
                      }
                    },
                  ))
              .toList(),
          itemSpacing: 16,
          itemExtent: 52,
          direction: Axis.horizontal,
          builder: (icon) => AppIcon(
            icon: icon,
            size: 52,
          ),
        ),
      ),
    );
  }
}

/// [Widget] displaying the [icon] in a colored container.
class AppIcon extends StatelessWidget {
  /// [IconData] to be displayed.
  final IconData icon;

  /// Size of the [icon] container.
  final double size;

  const AppIcon({super.key, required this.icon, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: size),
      height: size,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.primaries[icon.hashCode % Colors.primaries.length],
      ),
      child: Center(
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

/// [MacosDockItem] stores the [icon], [onTap], and [tooltip] fields.
class MacosDockItem<T> {
  /// [Icon] to be displayed.
  final T icon;

  /// Callback when item is tapped.
  final Function onTap;

  const MacosDockItem({
    required this.icon,
    required this.onTap,
  });
}

/// [DataModel] used to store the [icon], [offset], and [animationDuration].
class DataModel<T> {
  /// [IconData] to be displayed.
  final T icon;

  /// [Offset] of the [icon].
  Offset offset;

  /// [Opacity] of the [icon].
  double opacity;

  /// Duration of the snapping animation.
  int animationDuration = 500;

  DataModel({
    required this.icon,
    required this.offset,
    required this.animationDuration,
    this.opacity = 1.0,
  });
}

/// Stores data as per pan initiation time frame
class PanTracker<T> {
  /// [IconData] to be displayed.
  final MacosDockItem<T>? icon;

  /// [Offset] of the [icon].
  final Offset offset;

  /// [Opacity] of the [icon].
  final int index;

  const PanTracker({
    required this.icon,
    required this.offset,
    required this.index,
  });
}

/// [Widget] building the [Dock].
class MacosDock<T> extends StatefulWidget {
  /// Size of individual [T] items.
  final double itemExtent;

  /// Spacing between [T] items.
  final double itemSpacing;

  /// [T] items to be displayed, wrapped as [MacosDockItem].
  final List<MacosDockItem<T>> items;

  /// Primary axis of the [dock].
  final Axis direction;

  /// Duration of the snapping animation.
  final int animationDuration;

  /// Padding of the [dock].
  final double padding;

  /// Builder building the provided [T] item.
  final Widget Function(T) builder;

  const MacosDock({
    super.key,
    this.direction = Axis.horizontal,
    this.itemExtent = 48,
    this.itemSpacing = 8,
    this.animationDuration = 500,
    this.padding = 4.0,
    required this.items,
    required this.builder,
  });

  @override
  State<MacosDock<T>> createState() => _MacosDockState<T>();
}

/// State of the [MacosDock] used to manipulate the [_items].
class _MacosDockState<T> extends State<MacosDock<T>> {
  /// [T] items being manipulated as [DataModel].
  late List<DataModel> _items;

  /// Width of the [Dock].
  double width = 0.0;

  /// Height of the [Dock].
  double height = 0.0;

  @override
  void initState() {
    super.initState();
    // Generates the [DataModel] list from the provided [items] with initial offsets.
    _items = widget.items
        .map(
          (e) => DataModel(
            icon: e,
            offset: Offset(
              widget.direction == Axis.horizontal
                  ? (widget.items.indexOf(e) *
                      (widget.itemExtent + widget.itemSpacing))
                  : 0,
              widget.direction == Axis.vertical
                  ? (widget.items.indexOf(e) *
                      (widget.itemExtent + widget.itemSpacing))
                  : 0,
            ),
            animationDuration: 0,
          ),
        )
        .toList();
    // Calculates the height of the [Dock] based on the [items] and [direction].
    height = widget.direction == Axis.horizontal
        ? widget.itemExtent + 16 + widget.padding * 2
        : (_items.length * (widget.itemSpacing + widget.itemExtent) -
                widget.itemSpacing) +
            16 +
            widget.padding * 2;
    // Calculates the width of the [Dock] based on the [items] and [direction].
    width = widget.direction == Axis.vertical
        ? widget.itemExtent + 16 + widget.padding * 2
        : (_items.length * (widget.itemSpacing + widget.itemExtent) -
                widget.itemSpacing) +
            16 +
            widget.padding * 2;
  }

  /// [DataModel] currently being panned.
  DataModel? overlay;

  /// Stores the initiation of a pan event.
  PanTracker panTracker = const PanTracker(
    icon: null,
    offset: Offset(0, 0),
    index: 0,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Calculates the top position of the [Dock] based on the [constraints].
      final dockTop = constraints.maxHeight / 2 - height / 2;
      // Calculates the left position of the [Dock] based on the [constraints].
      final dockLeft = constraints.maxWidth / 2 - width / 2;

      // Demarcates the total draggable area for [overlay].
      return Stack(
        fit: StackFit.expand,
        children: [
          // Stock background image. (non-functional)
          Image.network(
            'https://picsum.photos/seed/macosdockclone/${constraints.maxWidth.toInt()}/${constraints.maxHeight.toInt()}',
            fit: BoxFit.contain,
          ),
          // Implicitly animates the position of the [Dock].
          AnimatedPositioned(
            duration: Duration(milliseconds: widget.animationDuration),
            // Centers the [Dock] in the available area.
            top: dockTop,
            left: dockLeft,
            // Blur effect for the [Dock].
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                // Implicitly animates the size of the [Dock].
                child: AnimatedContainer(
                  duration: Duration(milliseconds: widget.animationDuration),
                  height: height,
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Theme.of(context).dividerColor, width: 1.0),
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                  ),
                  padding: EdgeInsets.all(widget.padding),
                  child: Stack(
                    children: List.generate(_items.length, (index) {
                      // Individual [Dock] items.
                      return AnimatedPositioned(
                        top: _items[index].offset.dy,
                        left: _items[index].offset.dx,
                        duration: Duration(
                            milliseconds: _items[index].animationDuration),
                        child: Tooltip(
                          preferBelow: false,
                          message: _items[index].icon.icon.toString(),
                          child: GestureDetector(
                            onTap: () {
                              // Calls the [onTap] function of the [MacosDockIcon].
                              _items[index].icon.onTap();
                            },
                            onPanStart: (details) {
                              // Initiates the [panTracker] to track the initiation offset of [overlay].
                              panTracker = PanTracker(
                                icon: MacosDockItem(
                                  icon: _items[index].icon,
                                  onTap: () {},
                                ),
                                offset: Offset(
                                  widget.direction == Axis.horizontal
                                      ? index *
                                          (widget.itemSpacing +
                                              widget.itemExtent)
                                      : 0,
                                  widget.direction == Axis.vertical
                                      ? index *
                                          (widget.itemSpacing +
                                              widget.itemExtent)
                                      : 0,
                                ),
                                index: index,
                              );
                              // Initializes [overlay].
                              setState(() {
                                if (overlay == null ||
                                    overlay?.icon != panTracker.icon!) {
                                  overlay = DataModel(
                                    icon: panTracker.icon!,
                                    offset: panTracker.offset,
                                    animationDuration: 0,
                                  );
                                } else {
                                  overlay!.offset = details.globalPosition -
                                      details.localPosition;
                                  overlay!.animationDuration = 0;
                                }
                                _items[index].opacity = 0;
                              });
                            },
                            onPanUpdate: (details) {
                              // Updates the [overlay] offset based on the drag.
                              setState(() {
                                if (overlay == null ||
                                    overlay?.icon != panTracker.icon) {
                                  overlay = DataModel(
                                    icon: panTracker.icon!,
                                    offset: panTracker.offset,
                                    animationDuration: 0,
                                  );
                                } else {
                                  overlay!.offset =
                                      overlay!.offset + details.delta;
                                  overlay!.animationDuration = 0;
                                }
                              });
                              // Horizontal Axis Movement
                              if (widget.direction == Axis.horizontal) {
                                // Checks if the [overlay] is moved to the right by at least one [item].
                                // Checks if the [overlay] moves within Y axis constraints.
                                // Checks if the [overlay] is moved within the bounds of the dock on X axis.
                                if (overlay!.offset.dx >
                                        (panTracker.offset.dx) +
                                            (widget.itemExtent +
                                                widget.itemSpacing) &&
                                    overlay!.offset.dy.abs() <
                                        (widget.itemExtent +
                                            widget.itemSpacing) &&
                                    overlay!.offset.dx <
                                        width - widget.padding) {
                                  // Looks up the index of the item to be swapped.
                                  int newIndex = _items.indexWhere((e) =>
                                      e.offset.dx ==
                                      (panTracker.offset.dx +
                                          widget.itemSpacing +
                                          widget.itemExtent));
                                  if (newIndex == -1) {
                                    return;
                                  }
                                  setState(() {
                                    // Animates the swap movement
                                    _items[newIndex].animationDuration =
                                        widget.animationDuration;
                                    _items[newIndex].offset =
                                        _items[newIndex].offset -
                                            Offset(
                                                (widget.itemExtent +
                                                    widget.itemSpacing),
                                                0);
                                    // Updates the [item] at [panTracker] index.
                                    _items[panTracker.index].animationDuration =
                                        0;
                                    _items[panTracker.index].offset =
                                        _items[panTracker.index].offset +
                                            Offset(
                                                (widget.itemExtent +
                                                    widget.itemSpacing),
                                                0);
                                    // Updates [panTracker].
                                    panTracker = PanTracker(
                                      icon: panTracker.icon,
                                      offset: panTracker.offset +
                                          Offset(
                                              widget.itemExtent +
                                                  widget.itemSpacing,
                                              0),
                                      index: panTracker.index,
                                    );
                                  });
                                }
                                // Checks if the [overlay] is moved to the left by at least one [item].
                                // Checks if the [item] is moved within Y axis constraints.
                                // Checks if the [item] is moved within the bounds of the dock on X axis.
                                else if (overlay!.offset.dx <
                                        (panTracker.offset.dx) -
                                            (widget.itemExtent +
                                                widget.itemSpacing) &&
                                    overlay!.offset.dy.abs() <
                                        (widget.itemExtent +
                                            widget.itemSpacing) &&
                                    overlay!.offset.dx >
                                        (-1 * widget.padding)) {
                                  // Looks up the index of the item to be swapped.
                                  int newIndex = _items.indexWhere((e) =>
                                      e.offset.dx ==
                                      (panTracker.offset.dx -
                                          widget.itemSpacing -
                                          widget.itemExtent));
                                  if (newIndex == -1) {
                                    return;
                                  }
                                  setState(() {
                                    // Animates the swap movement
                                    _items[newIndex].animationDuration =
                                        widget.animationDuration;
                                    _items[newIndex].offset =
                                        _items[newIndex].offset +
                                            Offset(
                                                (widget.itemExtent +
                                                    widget.itemSpacing),
                                                0);
                                    // Updates the [item] at [panTracker] index.
                                    _items[panTracker.index].animationDuration =
                                        0;
                                    _items[panTracker.index].offset =
                                        _items[panTracker.index].offset -
                                            Offset(
                                                (widget.itemExtent +
                                                    widget.itemSpacing),
                                                0);
                                    // Updates [panTracker].
                                    panTracker = PanTracker(
                                      icon: panTracker.icon,
                                      offset: panTracker.offset -
                                          Offset(
                                              widget.itemExtent +
                                                  widget.itemSpacing,
                                              0),
                                      index: panTracker.index,
                                    );
                                  });
                                }
                              }
                              // Vertical Axis Movement
                              else {
                                // Checks if the [overlay] is moved to the bottom by at least one [item].
                                // Checks if the [overlay] moves within X axis constraints.
                                // Checks if the [overlay] is moved within the bounds of the dock on Y axis.
                                if (overlay!.offset.dy >
                                        (panTracker.offset.dy) +
                                            (widget.itemExtent +
                                                widget.itemSpacing) &&
                                    overlay!.offset.dx.abs() <
                                        (widget.itemExtent +
                                            widget.itemSpacing) &&
                                    overlay!.offset.dy <
                                        height - widget.padding) {
                                  // Looks up the index of the item to be swapped.
                                  int newIndex = _items.indexWhere((e) =>
                                      e.offset.dy ==
                                      (panTracker.offset.dy +
                                          widget.itemSpacing +
                                          widget.itemExtent));
                                  if (newIndex == -1) {
                                    return;
                                  }
                                  setState(() {
                                    // Animates the swap movement
                                    _items[newIndex].animationDuration =
                                        widget.animationDuration;
                                    _items[newIndex].offset =
                                        _items[newIndex].offset -
                                            Offset(
                                              0,
                                              (widget.itemExtent +
                                                  widget.itemSpacing),
                                            );
                                    // Updates the [item] at [panTracker] index.
                                    _items[panTracker.index].animationDuration =
                                        0;
                                    _items[panTracker.index].offset =
                                        _items[panTracker.index].offset +
                                            Offset(
                                              0,
                                              (widget.itemExtent +
                                                  widget.itemSpacing),
                                            );
                                    // Updates [panTracker].
                                    panTracker = PanTracker(
                                      icon: panTracker.icon,
                                      offset: panTracker.offset +
                                          Offset(
                                            0,
                                            widget.itemExtent +
                                                widget.itemSpacing,
                                          ),
                                      index: panTracker.index,
                                    );
                                  });
                                }
                                // Checks if the [overlay] is moved to the top by at least one [item].
                                // Checks if the [item] is moved within X axis constraints.
                                // Checks if the [item] is moved within the bounds of the dock on Y axis.
                                else if (overlay!.offset.dy <
                                        (panTracker.offset.dy) -
                                            (widget.itemExtent +
                                                widget.itemSpacing) &&
                                    overlay!.offset.dx.abs() <
                                        (widget.itemExtent +
                                            widget.itemSpacing) &&
                                    overlay!.offset.dy >
                                        (-1 * widget.padding)) {
                                  // Looks up the index of the item to be swapped.
                                  int newIndex = _items.indexWhere((e) =>
                                      e.offset.dy ==
                                      (panTracker.offset.dy -
                                          widget.itemSpacing -
                                          widget.itemExtent));
                                  if (newIndex == -1) {
                                    return;
                                  }
                                  setState(() {
                                    // Animates the swap movement
                                    _items[newIndex].animationDuration =
                                        widget.animationDuration;
                                    _items[newIndex].offset =
                                        _items[newIndex].offset +
                                            Offset(
                                              0,
                                              (widget.itemExtent +
                                                  widget.itemSpacing),
                                            );
                                    // Updates the [item] at [panTracker] index.
                                    _items[panTracker.index].animationDuration =
                                        0;
                                    _items[panTracker.index].offset =
                                        _items[panTracker.index].offset -
                                            Offset(
                                              0,
                                              (widget.itemExtent +
                                                  widget.itemSpacing),
                                            );
                                    // Updates [panTracker].
                                    panTracker = PanTracker(
                                      icon: panTracker.icon,
                                      offset: panTracker.offset -
                                          Offset(
                                            0,
                                            widget.itemExtent +
                                                widget.itemSpacing,
                                          ),
                                      index: panTracker.index,
                                    );
                                  });
                                }
                              }
                            },
                            onPanEnd: (details) {
                              // Checks if the [overlay] is moved outside the bounds of the dock.
                              if (details.globalPosition.dx < dockLeft ||
                                  details.globalPosition.dy < dockTop ||
                                  details.globalPosition.dx >
                                      dockLeft + width ||
                                  details.globalPosition.dy >
                                      dockTop + height) {
                                setState(() {
                                  // Resets overlay.
                                  overlay = null;
                                  // Animates all the other items into place.
                                  for (int i = panTracker.index;
                                      i < _items.length;
                                      i++) {
                                    _items[i].animationDuration =
                                        widget.animationDuration;
                                    _items[i].offset = Offset(
                                      widget.direction == Axis.horizontal
                                          ? _items[i].offset.dx -
                                              (widget.itemExtent +
                                                  widget.itemSpacing)
                                          : 0,
                                      widget.direction == Axis.vertical
                                          ? _items[i].offset.dy -
                                              (widget.itemExtent +
                                                  widget.itemSpacing)
                                          : 0,
                                    );
                                  }
                                  // Animates dock size
                                  if (widget.direction == Axis.horizontal) {
                                    width = width -
                                        (widget.itemExtent +
                                            widget.itemSpacing);
                                  } else {
                                    height = height -
                                        (widget.itemExtent +
                                            widget.itemSpacing);
                                  }
                                });
                                // Removes the item from the list after the animation completes.
                                Future.delayed(
                                  Duration(
                                      milliseconds: widget.animationDuration),
                                  () {
                                    for (int i = 0; i < _items.length; i++) {
                                      _items[i].animationDuration = 0;
                                    }
                                    setState(() {
                                      _items.removeAt(panTracker.index);
                                    });
                                  },
                                );
                                return;
                              }
                              // Snaps the [overlay] back to the initial position as a default case.
                              setState(() {
                                overlay!.animationDuration =
                                    widget.animationDuration;
                                overlay!.offset = panTracker.offset;
                              });
                              // Resets the [overlay] after animation completes.
                              Future.delayed(
                                Duration(
                                    milliseconds: widget.animationDuration),
                                () {
                                  setState(() {
                                    overlay = null;
                                    for (int i = 0; i < _items.length; i++) {
                                      _items[i].opacity = 1;
                                      _items[i].animationDuration = 0;
                                    }
                                    if (widget.direction == Axis.horizontal) {
                                      _items.sort((a, b) =>
                                          a.offset.dx.compareTo(b.offset.dx));
                                    } else {
                                      _items.sort((a, b) =>
                                          a.offset.dy.compareTo(b.offset.dy));
                                    }
                                  });
                                },
                              );
                            },
                            child: Opacity(
                              opacity: _items[index].opacity,
                              child: widget.builder(_items[index].icon.icon),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
          // Displays the [overlay].
          // Necessary to display the item being dragged above all other items while animating.
          if (overlay != null)
            AnimatedPositioned(
              top: dockTop + widget.padding + overlay!.offset.dy,
              left: dockLeft + widget.padding + overlay!.offset.dx,
              duration: Duration(milliseconds: overlay!.animationDuration),
              child: widget.builder(overlay!.icon.icon.icon),
            ),
        ],
      );
    });
  }
}
