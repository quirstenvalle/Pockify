import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpInputRow extends StatefulWidget {
  const OtpInputRow({
    super.key,
    required this.length,
    required this.onChanged,
    this.enabled = true,
    this.autoFocus = true,
  });

  final int length;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool autoFocus;

  @override
  State<OtpInputRow> createState() => OtpInputRowState();
}

class OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _nodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _value => _controllers.map((c) => c.text).join();

  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    widget.onChanged('');
    if (_nodes.isNotEmpty) {
      _nodes.first.requestFocus();
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final focusIndex = digits.length.clamp(0, widget.length - 1);
      _nodes[focusIndex].requestFocus();
      widget.onChanged(_value);
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    widget.onChanged(_value);
  }

  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      widget.onChanged(_value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final boxSize = width < 380 ? 42.0 : 48.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < widget.length; i++)
          SizedBox(
            width: boxSize,
            height: boxSize + 4,
            child: KeyboardListener(
              focusNode: FocusNode(skipTraversal: true),
              onKeyEvent: (event) => _onKey(i, event),
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                enabled: widget.enabled,
                autofocus: widget.autoFocus && i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 1,
                style: const TextStyle(
                  fontFamily: 'NotoSans',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  height: 1.2,
                  leadingDistribution: TextLeadingDistribution.even,
                ),
                textAlignVertical: TextAlignVertical.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF0EEE9),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD8D3CB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF7F20),
                      width: 1.5,
                    ),
                  ),
                ),
                onChanged: (value) => _onChanged(i, value),
              ),
            ),
          ),
      ],
    );
  }
}
