import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/printer_data.dart';
import '../providers/serial_provider.dart';

class DirectionalPad extends ConsumerStatefulWidget {
  const DirectionalPad({super.key});

  @override
  ConsumerState<DirectionalPad> createState() => _DirectionalPadState();
}

class _DirectionalPadState extends ConsumerState<DirectionalPad> {
  double _xyStep = 1;
  double _zStep = 1;

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(serialConnectionProvider.select(
      (d) => d.connectionState == PrinterConnectionState.connected,
    ));
    final notifier = ref.read(serialConnectionProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HomeColumn(enabled: isConnected, onHome: (gcode) => notifier.sendGcode(gcode)),
            const SizedBox(width: 12),
            _XYRadialPad(
              step: _xyStep,
              enabled: isConnected,
              onXyStepChanged: (v) => setState(() => _xyStep = v),
              onMove: (axis, distance) => notifier.move(axis, distance),
              onHome: (gcode) => notifier.sendGcode(gcode),
              onCenterAction: () => notifier.sendGcode('M84'),
            ),
            const SizedBox(width: 12),
            _ZAxisPanel(
              step: _zStep,
              enabled: isConnected,
              onZStepChanged: (v) => setState(() => _zStep = v),
              onZMove: (axis, distance) => notifier.move(axis, distance),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  XY Radial Pad
// ──────────────────────────────────────────────────────────────────

class _XYRadialPad extends StatelessWidget {
  final double step;
  final bool enabled;
  final ValueChanged<double> onXyStepChanged;
  final void Function(PrinterAxis axis, double distance) onMove;
  final void Function(String gcode) onHome;
  final VoidCallback onCenterAction;

  const _XYRadialPad({
    required this.step,
    required this.enabled,
    required this.onXyStepChanged,
    required this.onMove,
    required this.onHome,
    required this.onCenterAction,
  });

  @override
  Widget build(BuildContext context) {
    const double containerSize = 360;
    const double circlePadding = 24;
    const double buttonSize = 56;
    const double halfBtn = buttonSize / 2;
    const double center = containerSize / 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: containerSize,
      height: containerSize,
      child: Stack(
        children: [
          // Circle background
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(circlePadding),
              child: CustomPaint(
                painter: _RadialPadPainter(isDark: isDark),
                size: const Size.fromRadius(center - circlePadding),
              ),
            ),
          ),

          // XY step buttons along 45° diagonal from center (180,180)
          // at 24%/46%/68%/88% of radius (156) — 28px circles
          Positioned(top: 140, left: 192,
            child: _IncButton('0.1', step == 0.1, enabled, () => onXyStepChanged(0.1))),
          Positioned(top: 115, left: 217,
            child: _IncButton('1', step == 1, enabled, () => onXyStepChanged(1))),
          Positioned(top: 91, left: 241,
            child: _IncButton('10', step == 10, enabled, () => onXyStepChanged(10))),
          Positioned(top: 69, left: 263,
            child: _IncButton('100', step == 100, enabled, () => onXyStepChanged(100))),

          // Directional chevron icons centered on cardinal axes
          Positioned(top: circlePadding - 4, left: center - halfBtn,
            child: _DirBtn(
              icon: FontAwesomeIcons.chevronUp,
              color: const Color(0xFF5B7DB4), enabled: enabled,
              onPressed: () => onMove(PrinterAxis.y, step),
              size: buttonSize,
            )),
          Positioned(top: containerSize - circlePadding - buttonSize + 4, left: center - halfBtn,
            child: _DirBtn(
              icon: FontAwesomeIcons.chevronDown,
              color: const Color(0xFF5B7DB4), enabled: enabled,
              onPressed: () => onMove(PrinterAxis.y, -step),
              size: buttonSize,
            )),
          Positioned(top: center - halfBtn, left: circlePadding - 4,
            child: _DirBtn(
              icon: FontAwesomeIcons.chevronLeft,
              color: const Color(0xFFFFA726), enabled: enabled,
              onPressed: () => onMove(PrinterAxis.x, -step),
              size: buttonSize,
            )),
          Positioned(top: center - halfBtn, left: containerSize - circlePadding - buttonSize + 4,
            child: _DirBtn(
              icon: FontAwesomeIcons.chevronRight,
              color: const Color(0xFFFFA726), enabled: enabled,
              onPressed: () => onMove(PrinterAxis.x, step),
              size: buttonSize,
            )),

          // Axis labels on outside perimeter
          Positioned(top: 3, left: center - 9,
            child: Text('Y+', style: _labelStyle(enabled, const Color(0xFF5B7DB4)))),
          Positioned(bottom: 3, left: center - 9,
            child: Text('Y\u2011', style: _labelStyle(enabled, const Color(0xFF5B7DB4)))),
          Positioned(left: 4, top: center - 8,
            child: Text('X\u2011', style: _labelStyle(enabled, const Color(0xFFFFA726)))),
          Positioned(right: 4, top: center - 8,
            child: Text('X+', style: _labelStyle(enabled, const Color(0xFFFFA726)))),

          // Center button
          Positioned(top: center - 16, left: center - 16,
            child: _CenterBtn(enabled: enabled, onPressed: onCenterAction)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Z Axis Panel
// ──────────────────────────────────────────────────────────────────

class _ZAxisPanel extends StatelessWidget {
  final double step;
  final bool enabled;
  final ValueChanged<double> onZStepChanged;
  final void Function(PrinterAxis axis, double distance) onZMove;

  const _ZAxisPanel({
    required this.step,
    required this.enabled,
    required this.onZStepChanged,
    required this.onZMove,
  });

  @override
  Widget build(BuildContext context) {
    const double panelWidth = 72;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black;

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DirBtn(
              icon: FontAwesomeIcons.chevronUp,
              color: const Color(0xFF4CAF50), enabled: enabled,
              onPressed: () => onZMove(PrinterAxis.z, step),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('Z Step', style: TextStyle(color: labelColor, fontSize: 9)),
            const SizedBox(height: 8),
            _ZIncBtn('0.1', step == 0.1, enabled, () => onZStepChanged(0.1)),
            const SizedBox(height: 6),
            _ZIncBtn('1', step == 1, enabled, () => onZStepChanged(1)),
            const SizedBox(height: 6),
            _ZIncBtn('10', step == 10, enabled, () => onZStepChanged(10)),
            const SizedBox(height: 12),
            _DirBtn(
              icon: FontAwesomeIcons.chevronDown,
              color: const Color(0xFF4CAF50), enabled: enabled,
              onPressed: () => onZMove(PrinterAxis.z, -step),
              size: 48,
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Custom Painter for Radial Background
// ──────────────────────────────────────────────────────────────────

class _RadialPadPainter extends CustomPainter {
  final bool isDark;

  const _RadialPadPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final shadowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8)
      ..color = Colors.black.withAlpha(40);
    canvas.drawCircle(center, radius, shadowPaint);

    final bgColors = isDark
        ? const [Color(0xFF3A3A3A), Color(0xFF2A2A2A), Color(0xFF1E1E1E)]
        : const [Color(0xFFE6E6E6), Color(0xFFD6D6D6), Color(0xFFC8C8C8)];
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: bgColors,
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius - 4, bgPaint);

    final ringColors = isDark
        ? const [Color(0xFF444444), Color(0xFF383838), Color(0xFF4A4A4A)]
        : const [Color(0xFFD0D0D0), Color(0xFFC4C4C4), Color(0xFFD8D8D8)];
    for (int i = 0; i < ringColors.length; i++) {
      final ringRadius = radius * (0.25 + i * 0.2);
      final ringPaint = Paint()
        ..color = ringColors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(center, ringRadius, ringPaint);
    }

    final linePaint = Paint()
      ..color = isDark ? const Color(0xFF555555) : const Color(0xFFB0B0B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final diagRadius = radius * 0.85;
    canvas.drawLine(
      Offset(center.dx + diagRadius * 0.707, center.dy - diagRadius * 0.707),
      Offset(center.dx - diagRadius * 0.707, center.dy + diagRadius * 0.707),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - diagRadius * 0.707, center.dy - diagRadius * 0.707),
      Offset(center.dx + diagRadius * 0.707, center.dy + diagRadius * 0.707),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialPadPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

// ──────────────────────────────────────────────────────────────────
//  Directional Button (Font Awesome chevron icon)
// ──────────────────────────────────────────────────────────────────

class _DirBtn extends StatefulWidget {
  final FaIconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;
  final double size;

  const _DirBtn({
    required this.icon,
    required this.color,
    required this.enabled,
    this.onPressed,
    this.size = 56,
  });

  @override
  State<_DirBtn> createState() => _DirBtnState();
}

class _DirBtnState extends State<_DirBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final iconColor = enabled
        ? (_pressed ? widget.color.withAlpha(200) : widget.color)
        : widget.color.withAlpha(80);

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(
            child: FaIcon(widget.icon, size: widget.size * 0.85, color: iconColor),
          ),
        ),
      ),
    );
  }
}

TextStyle _labelStyle(bool enabled, Color color) => TextStyle(
  color: enabled ? color : color.withAlpha(80),
  fontSize: 13,
  fontWeight: FontWeight.bold,
  shadows: const [
    Shadow(color: Colors.black54, blurRadius: 2),
    Shadow(color: Colors.black38, blurRadius: 1),
  ],
);

// ──────────────────────────────────────────────────────────────────
//  Increment Button (circular, for XY diagonal)
// ──────────────────────────────────────────────────────────────────

class _IncButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  const _IncButton(this.label, this.selected, this.enabled, this.onPressed);

  @override
  Widget build(BuildContext context) {
    const double size = 28;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFFFF6B6B) : const Color(0xFF444444),
          border: Border.all(
            color: selected ? const Color(0xFFFF6B6B) : const Color(0xFF666666),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFFFF6B6B).withAlpha(80)
                  : Colors.black.withAlpha(40),
              blurRadius: selected ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade300,
            fontSize: 10, fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Center Button (crosshair)
// ──────────────────────────────────────────────────────────────────

class _CenterBtn extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;

  const _CenterBtn({required this.enabled, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? const Color(0xFF555555) : const Color(0xFF555555).withAlpha(100),
          border: Border.all(color: Colors.white24, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _CrosshairPainter(
            color: enabled ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  final Color color;

  _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const arm = 7.0;
    const gap = 2.5;

    canvas.drawLine(Offset(cx - arm, cy - arm), Offset(cx - gap, cy - gap), paint);
    canvas.drawLine(Offset(cx + gap, cy + gap), Offset(cx + arm, cy + arm), paint);
    canvas.drawLine(Offset(cx + arm, cy - arm), Offset(cx + gap, cy - gap), paint);
    canvas.drawLine(Offset(cx - gap, cy + gap), Offset(cx - arm, cy + arm), paint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(Offset(cx, cy), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ──────────────────────────────────────────────────────────────────
//  Home Column (left side of D-pad)
// ──────────────────────────────────────────────────────────────────

class _HomeColumn extends StatelessWidget {
  final bool enabled;
  final void Function(String gcode) onHome;

  const _HomeColumn({required this.enabled, required this.onHome});

  @override
  Widget build(BuildContext context) {
    const double panelWidth = 72;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0);

    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 6,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Home', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.black, fontSize: 9)),
            const SizedBox(height: 10),
            _HomeBtn('All', Icons.home, Colors.black87, enabled, () => onHome('G28')),
            const SizedBox(height: 10),
            _HomeBtn('X', Icons.home, const Color(0xFFFFA726), enabled, () => onHome('G28 X')),
            const SizedBox(height: 10),
            _HomeBtn('Y', Icons.home, const Color(0xFF5B7DB4), enabled, () => onHome('G28 Y')),
            const SizedBox(height: 10),
            _HomeBtn('Z', Icons.home, const Color(0xFF4CAF50), enabled, () => onHome('G28 Z')),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _HomeBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  const _HomeBtn(this.label, this.icon, this.color, this.enabled, this.onPressed);

  @override
  State<_HomeBtn> createState() => _HomeBtnState();
}

class _HomeBtnState extends State<_HomeBtn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = enabled
        ? (_pressed ? widget.color.withAlpha(180) : widget.color)
        : widget.color.withAlpha(80);
    final fgColor = enabled
        ? (_pressed ? Colors.white70 : Colors.white)
        : Colors.white38;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 52,
          height: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_pressed ? 20 : 40),
                blurRadius: _pressed ? 1 : 3,
                offset: Offset(0, _pressed ? 1 : 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: fgColor),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Z Increment Button
// ──────────────────────────────────────────────────────────────────

class _ZIncBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onPressed;

  const _ZIncBtn(this.label, this.selected, this.enabled, this.onPressed);

  @override
  Widget build(BuildContext context) {
    const double size = 28;
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? const Color(0xFFFF6B6B) : const Color(0xFF444444),
          border: Border.all(
            color: selected ? const Color(0xFFFF6B6B) : const Color(0xFF666666),
            width: selected ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0xFFFF6B6B).withAlpha(80)
                  : Colors.black.withAlpha(40),
              blurRadius: selected ? 6 : 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade300,
            fontSize: 10, fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  Generic Control Button (E- / E+)
// ──────────────────────────────────────────────────────────────────

class _ControlButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const _ControlButton(this.label, this.onPressed, this.color);

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 52, height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? (_pressed ? widget.color.withAlpha(180) : widget.color)
                : widget.color.withAlpha(80),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(_pressed ? 30 : 50),
                blurRadius: _pressed ? 2 : 4,
                offset: Offset(0, _pressed ? 1 : 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              color: enabled
                  ? (_pressed ? Colors.black54 : Colors.black87)
                  : Colors.black38,
              fontSize: 12, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
