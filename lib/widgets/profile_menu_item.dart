import 'package:flutter/material.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showDivider;
  final Widget? trailing;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle != null ? Text(subtitle!) : null,
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        ),
        if (showDivider) const Divider(),
      ],
    );
  }
}