import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final double? elevation;
  final Color backgroundColor;
  final Color titleColor;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final bool showAvatar;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.elevation,
    this.backgroundColor = Colors.white,
    this.titleColor = const Color(0xFF2D3436),
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.showAvatar = true,
    this.bottom,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: backgroundColor,
      shadowColor: Colors.black.withOpacity(0.1),
      elevation: elevation ?? 2.0,
      scrolledUnderElevation: 4.0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leadingWidth: 70,
      leading: showBackButton
          ? Center(
              child: InkWell(
                onTap: onBackButtonPressed,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.black87,
                    size: 22,
                  ),
                ),
              ),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: titleColor,
          letterSpacing: -0.5,
          fontFamily: 'Arial',
        ),
      ),
      actions: [
        if (actions != null) ...actions!,

        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                final mainNavState = context
                    .findAncestorStateOfType<MainNavigationState>();
                mainNavState?.onItemTapped(5);
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  child: Icon(Icons.person, color: Colors.grey.shade500),
                ),
              ),
            ),
          ),
      ],
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
