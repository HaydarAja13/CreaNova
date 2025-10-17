import 'package:flutter/material.dart';

class NavBar extends StatelessWidget {
  const NavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.white = const Color(0xCCFAFAFA),
    this.activeColor = Colors.white,
    this.inactiveColor = const Color(0xFF777777),
    this.gradient,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color white, activeColor, inactiveColor;

  /// Gradient untuk ikon aktif (default sesuai spesifikasi kamu)
  final Gradient? gradient;

  Gradient get _defaultGrad => const LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0xFF85A947), // 0%
      Color(0xFF3E7B27), // 51%
      Color(0xFF123524), // 100%
    ],
    stops: [0.0, 0.51, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? _defaultGrad;

    return Container(
      decoration: BoxDecoration(
        color: white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home', // MODIFIED: Menambahkan label
                index: 0,
                currentIndex: currentIndex,
                inactiveColor: inactiveColor,
                onTap: onTap,
                gradient: grad,
              ),
              _NavItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: 'TukarIn', // MODIFIED: Menambahkan label
                index: 1,
                currentIndex: currentIndex,
                inactiveColor: inactiveColor,
                onTap: onTap,
                gradient: grad,
              ),
              const SizedBox(width: 56),
              _NavItem(
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'History', // MODIFIED: Menambahkan label
                index: 2,
                currentIndex: currentIndex,
                inactiveColor: inactiveColor,
                onTap: onTap,
                gradient: grad,
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile', // MODIFIED: Menambahkan label
                index: 3,
                currentIndex: currentIndex,
                inactiveColor: inactiveColor,
                onTap: onTap,
                gradient: grad,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label, // MODIFIED: Menambahkan properti label
    required this.index,
    required this.currentIndex,
    required this.inactiveColor,
    required this.onTap,
    required this.gradient,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label; // MODIFIED: Menambahkan properti label
  final int index;
  final int currentIndex;
  final Color inactiveColor;
  final ValueChanged<int> onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    Widget iconWidget = Icon(
      selected ? selectedIcon : icon,
      size: 26,
      color: selected ? Colors.white : inactiveColor,
    );
    if (selected) {
      iconWidget = ShaderMask(
        shaderCallback: (Rect rect) => gradient.createShader(rect),
        blendMode: BlendMode.srcIn,
        child: iconWidget,
      );
    }

    Widget textWidget = Text(
      label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: selected ? Colors.white : inactiveColor,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (selected) {
      textWidget = ShaderMask(
        shaderCallback: (Rect rect) => gradient.createShader(rect),
        blendMode: BlendMode.srcIn,
        child: textWidget,
      );
    }

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
        const SizedBox(height: 2),
        textWidget,
      ],
    );

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        customBorder: const CircleBorder(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: SizedBox(
                key: ValueKey(selected),
                width: double.infinity,
                child: content
            ),
          ),
        ),
      ),
    );
  }
}