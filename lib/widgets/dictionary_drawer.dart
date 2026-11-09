import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app/themes/app_colors.dart';
import '../features/settings/settings_dialog.dart';

class DictionaryDrawer extends StatelessWidget {
  const DictionaryDrawer({super.key, required this.onRouteSelected});

  final Function(int) onRouteSelected;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.parchment,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/logo1.svg', // Path to your SVG file
                    width: 70,
                    height: 70,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Dictionary',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Activities'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: const Text('Saves'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(6);
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text('Rewards'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Growth'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_stories_outlined),
            title: const Text('Mga Kabanata'),
            onTap: () {
              Navigator.pop(context);
              onRouteSelected(5);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              showDialog<void>(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            },
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
