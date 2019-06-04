import 'package:flutter/material.dart';

import 'circular_slider_paint.dart';

/// Returns a widget which displays a circle to be used as a slider.
///
/// Required arguments are init and end to set the initial selection.
/// onSelectionChange is a callback function which returns new values as the user
/// changes the interval.
/// The rest of the params are used to change the look and feel.
///
///     DoubleCircularSlider(5, 10, onSelectionChange: () => {});
class DoubleCircularSlider extends StatefulWidget {
  /// the selection will be values between 0..divisions; max value is 300
  final int divisions;

  /// the initial value in the selection
  final int init;

  /// the end value in the selection
  final int end;

  /// the number of primary sectors to be painted
  /// will be painted using selectionColor
  final int primarySectors;

  /// the number of secondary sectors to be painted
  /// will be painted using baseColor
  final int secondarySectors;

  /// an optional widget that would be mounted inside the circle
  final Widget child;

  /// height of the canvas, default at 220
  final double height;

  /// width of the canvas, default at 220
  final double width;

  /// color of the base circle and sections
  final Color baseColor;

  /// color of the selection
  final Color selectionColor;

  /// color of the handlers
  final Color handlerColor;

  /// callback function when init and end change
  /// (int init, int end) => void
  final Function onSelectionChange;

  /// outer radius for the handlers
  final double handlerOuterRadius;

  /// if true an extra handler ring will be displayed in the handler
  final bool showHandlerOuter;

  DoubleCircularSlider(
    this.divisions,
    this.init,
    this.end, {
    this.height,
    this.width,
    this.child,
    this.primarySectors,
    this.secondarySectors,
    this.baseColor,
    this.selectionColor,
    this.handlerColor,
    this.onSelectionChange,
    this.handlerOuterRadius,
    this.showHandlerOuter,
  })  : assert(init >= 0 && init <= divisions,
            'init has to be > 0 and < divisions value'),
        assert(end >= 0 && end <= divisions,
            'end has to be > 0 and < divisions value'),
        assert(divisions >= 0 && divisions <= 300,
            'divisions has to be > 0 and <= 300');

  @override
  _DoubleCircularSliderState createState() => _DoubleCircularSliderState();
}

class _DoubleCircularSliderState extends State<DoubleCircularSlider> {
  int _init;
  int _end;

  @override
  void initState() {
    super.initState();
    _init = widget.init;
    _end = widget.end;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: widget.height ?? 220,
        width: widget.width ?? 220,
        child: CircularSliderPaint(
          mode: CircularSliderMode.doubleHandler,
          init: _init,
          end: _end,
          divisions: widget.divisions,
          primarySectors: widget.primarySectors ?? 0,
          secondarySectors: widget.secondarySectors ?? 0,
          child: widget.child,
          onSelectionChange: (newInit, newEnd) {
            if (widget.onSelectionChange != null) {
              widget.onSelectionChange(newInit, newEnd);
            }
            setState(() {
              _init = newInit;
              _end = newEnd;
            });
          },
          baseColor: widget.baseColor ?? Color.fromRGBO(255, 255, 255, 0.1),
          selectionColor:
              widget.selectionColor ?? Color.fromRGBO(255, 255, 255, 0.3),
          handlerColor: widget.handlerColor ?? Colors.white,
          handlerOuterRadius: widget.handlerOuterRadius ?? 12.0,
          showRoundedCapInSelection: false,
          showHandlerOuter: widget.showHandlerOuter ?? true,
        ));
  }
}
