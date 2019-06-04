import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'base_painter.dart';
import 'slider_painter.dart';
import 'utils.dart';

enum CircularSliderMode { singleHandler, doubleHandler }

class CircularSliderPaint extends StatefulWidget {
  final CircularSliderMode mode;
  final int init;
  final int end;
  final int divisions;
  final int primarySectors;
  final int secondarySectors;
  final Function onSelectionChange;
  final Color baseColor;
  final Color selectionColor;
  final Color handlerColor;
  final double handlerOuterRadius;
  final Widget child;
  final bool showRoundedCapInSelection;
  final bool showHandlerOuter;

  CircularSliderPaint({
    @required this.mode,
    @required this.divisions,
    @required this.init,
    @required this.end,
    this.child,
    @required this.primarySectors,
    @required this.secondarySectors,
    @required this.onSelectionChange,
    @required this.baseColor,
    @required this.selectionColor,
    @required this.handlerColor,
    @required this.handlerOuterRadius,
    @required this.showRoundedCapInSelection,
    @required this.showHandlerOuter,
  });

  @override
  _CircularSliderState createState() => _CircularSliderState();
}

class _CircularSliderState extends State<CircularSliderPaint> {
  bool _isInitHandlerSelected = false;
  bool _isEndHandlerSelected = false;
  double _sliderRadius;

  SliderPainter _painter;

  /// start angle in radians where we need to locate the init handler
  double _startAngle;

  /// end angle in radians where we need to locate the end handler
  double _endAngle;

  /// the absolute angle in radians representing the selection
  double _sweepAngle;

  bool get isDoubleHandler => widget.mode == CircularSliderMode.doubleHandler;
  bool get isSingleHandler => widget.mode == CircularSliderMode.singleHandler;

  @override
  void initState() {
    super.initState();
    _calculatePaintData();
  }

  // we need to update this widget both with gesture detector but
  // also when the parent widget rebuilds itself
  @override
  void didUpdateWidget(CircularSliderPaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.init != widget.init || oldWidget.end != widget.end) {
      _calculatePaintData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        CustomPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
          () => CustomPanGestureRecognizer(
              onPanDown: _onPanDown,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd),
          (CustomPanGestureRecognizer instance) {},
        ),
      },
      child: CustomPaint(
        painter: BasePainter(
            baseColor: widget.baseColor,
            selectionColor: widget.selectionColor,
            primarySectors: widget.primarySectors,
            secondarySectors: widget.secondarySectors,
            onCalculatedRadius: (double radius) => _sliderRadius = radius),
        foregroundPainter: _painter,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: widget.child,
        ),
      ),
    );
  }

  void _calculatePaintData() {
    var initPercent = isDoubleHandler
        ? valueToPercentage(widget.init, widget.divisions)
        : 0.0;
    var endPercent = valueToPercentage(widget.end, widget.divisions);
    var sweep = getSweepAngle(initPercent, endPercent);

    _startAngle = isDoubleHandler ? percentageToRadians(initPercent) : 0.0;
    _endAngle = percentageToRadians(endPercent);
    _sweepAngle = percentageToRadians(sweep.abs());

    _painter = SliderPainter(
      mode: widget.mode,
      startAngle: _startAngle,
      endAngle: _endAngle,
      sweepAngle: _sweepAngle,
      selectionColor: widget.selectionColor,
      handlerColor: widget.handlerColor,
      handlerOuterRadius: widget.handlerOuterRadius,
      showRoundedCapInSelection: widget.showRoundedCapInSelection,
      showHandlerOuter: widget.showHandlerOuter,
    );
  }

  void _onPanUpdate(Offset details) {
    if (!_isInitHandlerSelected && !_isEndHandlerSelected) {
      return;
    }
    if (_painter.center == null) {
      return;
    }
    RenderBox renderBox = context.findRenderObject();
    var position = renderBox.globalToLocal(details);

    var angle = coordinatesToRadians(_painter.center, position);
    var percentage = radiansToPercentage(angle);
    var newValue = percentageToValue(percentage, widget.divisions);

    if (isDoubleHandler && _isInitHandlerSelected) {
      widget.onSelectionChange(newValue, widget.end);
    } else {
      widget.onSelectionChange(widget.init, newValue);
    }
  }

  void _onPanEnd(_) {
    _isInitHandlerSelected = false;
    _isEndHandlerSelected = false;
  }

  bool _onPanDown(Offset details) {
    if (_painter == null) {
      return false;
    }
    RenderBox renderBox = context.findRenderObject();
    var position = renderBox.globalToLocal(details);
    if (position != null) {
      if (isSingleHandler) {

        _isEndHandlerSelected = isPointInsideCircle(
            position, _painter.endHandler, widget.handlerOuterRadius);

        if(_isEndHandlerSelected) {
            _onPanUpdate(details);
        }

        //if (isPointAlongCircle(position, _sliderRadius)) {
        //  _isEndHandlerSelected = true;
        //  _onPanUpdate(details);
        //}
      } else {
        _isInitHandlerSelected = isPointInsideCircle(
            position, _painter.initHandler, widget.handlerOuterRadius);

        if (!_isInitHandlerSelected) {
          _isEndHandlerSelected = isPointInsideCircle(
              position, _painter.endHandler, widget.handlerOuterRadius);
        }
      }
    }
    return _isInitHandlerSelected || _isEndHandlerSelected;
  }
}

class CustomPanGestureRecognizer extends OneSequenceGestureRecognizer {
  final Function onPanDown;
  final Function onPanUpdate;
  final Function onPanEnd;

  CustomPanGestureRecognizer(
      {@required this.onPanDown,
      @required this.onPanUpdate,
      @required this.onPanEnd});

  @override
  void addPointer(PointerEvent event) {
    if (onPanDown(event.position)) {
      startTrackingPointer(event.pointer);
      resolve(GestureDisposition.accepted);
    } else {
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      onPanUpdate(event.position);
    }
    if (event is PointerUpEvent) {
      onPanEnd(event.position);
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
