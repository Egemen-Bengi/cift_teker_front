import 'package:cift_teker_front/screens/main_navigation.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;
  final double elevation;
  final Color backgroundColor;
  final Color titleColor;
  final String? profileImageUrl;
  final bool showBackButton;
  final VoidCallback? onBackButtonPressed;
  final bool showAvatar;

  const CustomAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
    this.elevation = 0.3,
    this.backgroundColor = Colors.white,
    this.titleColor = Colors.black87,
    this.profileImageUrl,
    this.showBackButton = false,
    this.onBackButtonPressed,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: onBackButtonPressed,
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: titleColor,
        ),
      ),
      actions: showAvatar
          ? [
              GestureDetector(
                onTap: () {
                  final mainNavState = context
                      .findAncestorStateOfType<MainNavigationState>();
                  mainNavState?.onItemTapped(2);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                    child: profileImageUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ]
          : [],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
