import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:medical_records/styles/app_colors.dart';

class ToggleNavigationItem {
  final IconData icon;
  final IconData? selectedIcon; // 선택 시 사용할 아이콘 (filled 버전)
  final String label;
  final VoidCallback? onTap;

  const ToggleNavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.onTap,
  });
}

class CustomToggleNavigation extends StatefulWidget {
  final List<ToggleNavigationItem> items;
  final int currentIndex;
  final Function(int)? onTap;
  final EdgeInsetsGeometry? margin;
  final double height;
  final Color backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final double iconSize;
  final double fontSize;
  final bool showLabels;

  const CustomToggleNavigation({
    Key? key,
    required this.items,
    required this.currentIndex,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 24),
    this.height = 48,
    this.backgroundColor = Colors.white,
    this.selectedColor,
    this.unselectedColor,
    this.borderRadius = 24,
    this.boxShadow,
    this.iconSize = 16,
    this.fontSize = 8,
    this.showLabels = true,
  }) : super(key: key);

  @override
  State<CustomToggleNavigation> createState() => _CustomToggleNavigationState();
}

class _CustomToggleNavigationState extends State<CustomToggleNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _animationControllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _animationControllers = List.generate(
      widget.items.length,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 150),
        vsync: this,
      ),
    );
    _scaleAnimations =
        _animationControllers
            .map(
              (controller) => Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(parent: controller, curve: Curves.easeInOut),
              ),
            )
            .toList();
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _animateIcon(int index) async {
    await _animationControllers[index].forward();
    await _animationControllers[index].reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor =
        widget.selectedColor ?? AppColors.textPrimary;
    final effectiveUnselectedColor =
        widget.unselectedColor ?? AppColors.textSecondary;
    final effectiveBoxShadow =
        widget.boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ];

    return Container(
      margin: widget.margin,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: effectiveBoxShadow,
      ),
      child: Row(
        children:
            widget.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = widget.currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    _animateIcon(index);
                    widget.onTap?.call(index);
                    item.onTap?.call();
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _scaleAnimations[index],
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimations[index].value,
                            child: Icon(
                              isSelected && item.selectedIcon != null
                                  ? item.selectedIcon!
                                  : item.icon,
                              size: widget.iconSize,
                              color:
                                  isSelected
                                      ? effectiveSelectedColor
                                      : effectiveUnselectedColor,
                            ),
                          );
                        },
                      ),
                      if (widget.showLabels) ...[
                        SizedBox(height: 2),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: widget.fontSize,
                            color:
                                isSelected
                                    ? effectiveSelectedColor
                                    : effectiveUnselectedColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
