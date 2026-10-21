import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme.dart';

class NavPageItem {
  final int index;
  final String title;
  final String subtitle;
  final IconData icon;

  const NavPageItem({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.items,
    this.isCollapsed = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<NavPageItem> items;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCollapsed ? 96 : 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [brandBlueDeep, brandBlue, brandBlueStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(
            color: brandYellow.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(8, 0),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 180;
          return SingleChildScrollView(
            padding: compact
                ? const EdgeInsets.fromLTRB(12, 24, 12, 20)
                : const EdgeInsets.fromLTRB(22, 24, 22, 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 44,
              ),
              child: Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: compact
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      if (!compact)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: brandYellow.withValues(alpha: 0.72),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: brandYellow.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              const BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 18,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/branding/logo.png',
                            height: 44,
                            width: 44,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.local_shipping_rounded,
                              size: 40,
                              color: brandBlue,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: brandYellow.withValues(alpha: 0.68),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: brandYellow.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/branding/logo.png',
                            height: 24,
                            width: 24,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.local_shipping_rounded,
                              size: 24,
                              color: brandBlue,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'GARUDASHIELD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'TRANSPORTER',
                      style: TextStyle(
                        color: brandYellow,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ...items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SidebarButton(
                        item: item,
                        selected: selectedIndex == item.index,
                        onTap: () => onSelect(item.index),
                        isCollapsed: compact,
                      ),
                    );
                  }),
                  const SizedBox(height: 32),
                  if (!compact)
                    Opacity(
                      opacity: 0.72,
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: brandYellow.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: brandYellow,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'v1.0.0-transporter',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Opacity(
                      opacity: 0.72,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: brandYellow.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: brandYellow,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SidebarButton extends StatelessWidget {
  const SidebarButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    required this.isCollapsed,
  });

  final NavPageItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? brandYellow.withValues(alpha: 0.52)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: brandYellow.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: isCollapsed
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFFD7E5FF),
                    size: 20,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SidebarBreathingLabel(
                      text: item.title,
                      active: selected,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarBreathingLabel extends StatelessWidget {
  const _SidebarBreathingLabel({
    required this.text,
    required this.active,
  });

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      style: TextStyle(
        color: active ? Colors.white : const Color(0xFFF4F8FF),
        fontSize: 14,
        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
      ),
    );

    if (!active) {
      return label;
    }

    return label
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .tint(
          color: brandYellow.withValues(alpha: 0.62),
          duration: 1350.ms,
        );
  }
}
