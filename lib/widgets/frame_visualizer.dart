import 'package:flutter/material.dart';
import '../theme/robee_theme.dart';

/// Frame type enum for color coding
enum SlotContent {
  brood,    // orange
  pollen,   // purple
  cappedHoney, // yellow
  empty,    // grey
  feeder,   // grey + water icon
  // Honey box specific
  honeyFull,   // golden amber
  honeyUncapped, // light yellow
}

class FrameVisualizer extends StatelessWidget {
  final int? selectedBroodFrame;
  final int? selectedHoneyFrame;
  final ValueChanged<int>? onBroodFrameSelect;
  final ValueChanged<int>? onHoneyFrameSelect;
  final int? activeBroodFrame;
  final int? activeHoneyFrame;

  const FrameVisualizer({
    super.key,
    this.selectedBroodFrame,
    this.selectedHoneyFrame,
    this.onBroodFrameSelect,
    this.onHoneyFrameSelect,
    this.activeBroodFrame,
    this.activeHoneyFrame,
  });

  // Mock brood contents: 10 slots
  static const _broodContents = [
    SlotContent.empty,
    SlotContent.pollen,
    SlotContent.brood,
    SlotContent.brood,
    SlotContent.brood,
    SlotContent.brood,
    SlotContent.cappedHoney,
    SlotContent.pollen,
    SlotContent.empty,
    SlotContent.feeder, // slot 9 (index 9) = feeder
  ];

  // Mock honey contents: 7 slots
  static const _honeyContents = [
    SlotContent.honeyUncapped,
    SlotContent.honeyFull,
    SlotContent.honeyFull,
    SlotContent.honeyFull,
    SlotContent.honeyFull,
    SlotContent.honeyUncapped,
    SlotContent.empty,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Honey box (top) — 7 slots, wider
        _BoxRow(
          label: 'HONEY BOX',
          contents: _honeyContents,
          slotWidth: 44.0,
          slotHeight: 52.0,
          selectedFrame: selectedHoneyFrame,
          activeFrame: activeHoneyFrame,
          onFrameSelect: onHoneyFrameSelect,
        ),
        const SizedBox(height: 10),
        // Brood box (bottom) — 10 slots, narrower
        _BoxRow(
          label: 'BROOD BOX',
          contents: _broodContents,
          slotWidth: 30.0,
          slotHeight: 44.0,
          selectedFrame: selectedBroodFrame,
          activeFrame: activeBroodFrame,
          onFrameSelect: onBroodFrameSelect,
        ),
      ],
    );
  }
}

Color _slotColor(SlotContent content) {
  switch (content) {
    case SlotContent.brood:
      return const Color(0xFFE8834E); // orange
    case SlotContent.pollen:
      return const Color(0xFFA855F7); // purple
    case SlotContent.cappedHoney:
      return const Color(0xFFF59E0B); // yellow
    case SlotContent.empty:
      return const Color(0xFF2A2520); // dark grey
    case SlotContent.feeder:
      return const Color(0xFF1F1C1A); // darker grey
    case SlotContent.honeyFull:
      return const Color(0xFFD98639); // golden amber
    case SlotContent.honeyUncapped:
      return const Color(0xFFEBD08A); // light yellow
  }
}

class _BoxRow extends StatelessWidget {
  final String label;
  final List<SlotContent> contents;
  final double slotWidth;
  final double slotHeight;
  final int? selectedFrame;
  final int? activeFrame;
  final ValueChanged<int>? onFrameSelect;

  const _BoxRow({
    required this.label,
    required this.contents,
    required this.slotWidth,
    required this.slotHeight,
    this.selectedFrame,
    this.activeFrame,
    this.onFrameSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(label, style: RoBeeTheme.labelSmall),
              const SizedBox(width: 8),
              // Legend
              _LegendDot(color: _slotColor(SlotContent.brood), label: 'Brood'),
              const SizedBox(width: 8),
              _LegendDot(
                  color: _slotColor(SlotContent.pollen), label: 'Pollen'),
              const SizedBox(width: 8),
              _LegendDot(
                  color: _slotColor(SlotContent.cappedHoney),
                  label: 'Capped'),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(contents.length, (i) {
              final content = contents[i];
              final isFeeder = content == SlotContent.feeder;
              final isSelected = !isFeeder &&
                  selectedFrame != null &&
                  selectedFrame == i;
              final isActive = !isFeeder &&
                  activeFrame != null &&
                  activeFrame == i;

              return _FrameSlot(
                index: i,
                content: content,
                isFeeder: isFeeder,
                isSelected: isSelected,
                isActive: isActive,
                slotWidth: slotWidth,
                slotHeight: slotHeight,
                onTap: isFeeder || onFrameSelect == null
                    ? null
                    : () => onFrameSelect!(i),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _FrameSlot extends StatefulWidget {
  final int index;
  final SlotContent content;
  final bool isFeeder;
  final bool isSelected;
  final bool isActive;
  final double slotWidth;
  final double slotHeight;
  final VoidCallback? onTap;

  const _FrameSlot({
    required this.index,
    required this.content,
    required this.isFeeder,
    required this.isSelected,
    required this.isActive,
    required this.slotWidth,
    required this.slotHeight,
    this.onTap,
  });

  @override
  State<_FrameSlot> createState() => _FrameSlotState();
}

class _FrameSlotState extends State<_FrameSlot>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    if (widget.isActive) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_FrameSlot old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isActive && _pulseCtrl.isAnimating) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _slotColor(widget.content);

    final slotWidget = GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isSelected ? widget.slotWidth - 1 : widget.slotWidth - 3,
        height:
            widget.isSelected ? widget.slotHeight + 4 : widget.slotHeight,
        margin: const EdgeInsets.only(right: 3),
        decoration: BoxDecoration(
          color: widget.isFeeder
              ? const Color(0xFF1F1C1A)
              : widget.isSelected
                  ? baseColor.withOpacity(0.9)
                  : baseColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: widget.isFeeder
                ? RoBeeTheme.border
                : widget.isSelected
                    ? RoBeeTheme.amber
                    : widget.isActive
                        ? RoBeeTheme.amber.withOpacity(0.7)
                        : baseColor.withOpacity(0.5),
            width: widget.isSelected ? 1.5 : 1,
          ),
          // Active frame only gets amber glow (functional state indicator)
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: RoBeeTheme.amber.withOpacity(0.45),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: widget.isFeeder
            ? const Center(
                child: Icon(
                  Icons.water_drop_rounded,
                  color: RoBeeTheme.glassWhite60,
                  size: 14,
                ),
              )
            : Center(
                child: Text(
                  '${widget.index + 1}',
                  style: RoBeeTheme.monoSmall.copyWith(
                    color: widget.isSelected
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                    fontSize: 9,
                  ),
                ),
              ),
      ),
    );

    if (!widget.isActive) return slotWidget;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (ctx, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.slotWidth + 4 * _pulse.value,
              height: widget.slotHeight + 4 * _pulse.value,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: RoBeeTheme.amber.withOpacity(_pulse.value * 0.4),
                  width: 1,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      child: slotWidget,
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: RoBeeTheme.labelSmall.copyWith(fontSize: 8)),
      ],
    );
  }
}
