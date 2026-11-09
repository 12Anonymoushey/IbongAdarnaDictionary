import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '/app/themes/app_colors.dart';
import '/app/themes/adarna_loading.dart';
//curved SHane
import '/app/themes/curved_bottom_shape.dart';
import '/features/search/search_screen.dart';
import '/features/pilak/pilak_service.dart';
import '/features/settings/settings_dialog.dart';
import '/services/app_feedback.dart';
import '/widgets/step_by_step_tutorial.dart';

import 'package:flutter_svg/flutter_svg.dart';

class DictionaryBar extends StatefulWidget implements PreferredSizeWidget {
  const DictionaryBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  State<DictionaryBar> createState() => _DictionaryBarState();
}

class _DictionaryBarState extends State<DictionaryBar> {
  @override
  void initState() {
    super.initState();
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.notifications)),
              title: const Text('Daily challenge available!'),
              subtitle: const Text('Complete today\'s word quest.'),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.star)),
              title: const Text('You earned a new reward'),
              subtitle: const Text('Check your Growth tab.'),
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdarnaMode() async {
    final service = PilakService.instance;
    try {
      await service.initialize();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load Adarna Mode: $error')),
      );
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => ListenableBuilder(
        listenable: service,
        builder: (context, _) => LayoutBuilder(
          builder: (context, constraints) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: constraints.maxHeight,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 132,
                      height: 132,
                      child: AdarnaLoadingScreen(),
                    ),
                    Text(
                      'Adarna Mode',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Double quiz Pilak. Searching words uses a heart; earn one back by scoring at least 75% on a quiz’s first attempt.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text('Adarna Mode'),
                      value: service.adarnaModeEnabled,
                      onChanged: (enabled) async {
                        try {
                          await service.setAdarnaModeEnabled(enabled);
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not update Adarna Mode: $error',
                                ),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    if (service.adarnaModeEnabled)
                      Text(
                        '${service.adarnaHearts} of 3 hearts remaining',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _modifyPilak() async {
    final service = PilakService.instance;
    try {
      await service.initialize();
      if (!mounted) return;
      final controller = TextEditingController(text: '${service.balance}');
      String? errorText;
      final balance = await showDialog<int>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Modify Pilak (developer testing)'),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Pilak balance',
                helperText: 'Enter a whole number of 0 or more.',
                errorText: errorText,
              ),
              onSubmitted: (value) {
                final parsed = int.tryParse(value.trim());
                if (parsed == null || parsed < 0) {
                  setDialogState(
                    () => errorText = 'Enter a valid non-negative number.',
                  );
                } else {
                  Navigator.of(dialogContext).pop(parsed);
                }
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final parsed = int.tryParse(controller.text.trim());
                  if (parsed == null || parsed < 0) {
                    setDialogState(
                      () => errorText = 'Enter a valid non-negative number.',
                    );
                  } else {
                    Navigator.of(dialogContext).pop(parsed);
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      );
      controller.dispose();
      if (balance != null) await service.setBalanceForTesting(balance);
    } catch (error) {
      if (mounted) AppFeedback.show('Could not modify Pilak: $error');
    }
  }

  Future<void> _showAdarnaTutorial() => showStepByStepTutorial(
    context: context,
    title: 'Adarna Mode tutorial',
    steps: const [
      TutorialStep(
        title: 'Open Adarna Mode',
        description: 'Tap the bird logo in the center of the top bar to open the Adarna Mode controls.',
        icon: Icons.flutter_dash,
      ),
      TutorialStep(
        title: 'Turn the mode on',
        description: 'Switch Adarna Mode on to double Pilak from quizzes. The heart counter appears on the screen.',
        icon: Icons.toggle_on,
      ),
      TutorialStep(
        title: 'Hearts protect searching',
        description: 'In Adarna Mode, submitting a search or opening a word from Search or Mga Kabanata uses one heart. The app warns you before entering those screens.',
        icon: Icons.favorite,
      ),
      TutorialStep(
        title: 'Earn hearts back',
        description: 'Score at least 75% on a quiz attempt to earn a heart. Hearts are capped at three; the developer menu can restore them for testing.',
        icon: Icons.quiz_outlined,
      ),
    ],
  );

  Future<void> _showPilakTutorial() => showStepByStepTutorial(
    context: context,
    title: 'Pamilihan & Pilak tutorial',
    steps: const [
      TutorialStep(
        title: 'Open Pamilihan',
        description: 'Choose Rewards in the bottom navigation, then tap Pamilihan to browse themes, features, and materials.',
        icon: Icons.storefront_outlined,
      ),
      TutorialStep(
        title: 'Check the cost first',
        description: 'Each product shows its Pilak price. Purchases succeed only when your balance is sufficient; owned products are marked in the list.',
        icon: Icons.sell_outlined,
      ),
      TutorialStep(
        title: 'Earn Pilak from quizzes',
        description: 'Complete quizzes to earn score-based Pilak. Repeated attempts within 24 hours reduce the reward; Adarna Mode doubles quiz Pilak.',
        icon: Icons.quiz_outlined,
      ),
      TutorialStep(
        title: 'Keep your daily streak',
        description: 'Open the app on consecutive days to earn the daily streak reward. Active reading rewards are available when the app records reading minutes.',
        icon: Icons.local_fire_department_outlined,
      ),
      TutorialStep(
        title: 'Buy and use rewards',
        description: 'Purchase a product to unlock it. Themes apply immediately; unlocked features are available in their corresponding app flows.',
        icon: Icons.redeem_outlined,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 65,
      elevation: 3,
      shadowColor: Colors.black45,
      shape: CurvedBottomShape(), // Applies your custom bezier curve
      flexibleSpace: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: const Offset(0, 10),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Semantics(
                  button: true,
                  label: 'Open Adarna Mode',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _showAdarnaMode,
                    child: SvgPicture.asset(
                      'assets/images/logo1.svg',
                      width: 42,
                      height: 42,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Search words',
          icon: const Icon(Icons.search),
          onPressed: () => Navigator.push<void>(
            context,
            MaterialPageRoute<void>(builder: (context) => const SearchScreen()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () => _showNotificationPanel(context),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'settings') {
              showDialog<void>(
                context: context,
                builder: (context) => const SettingsDialog(),
              );
            } else if (value == 'share') {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'Learn Filipino words with the Ibong Adarna Dictionary.',
                ),
              );
            } else if (value == 'restore_hearts') {
              PilakService.instance.restoreAdarnaHeartsForTesting().catchError((
                Object error,
              ) {
                AppFeedback.show('Could not restore hearts: $error');
              });
            } else if (value == 'modify_pilak') {
              _modifyPilak();
            } else if (value == 'tutorial_adarna') {
              _showAdarnaTutorial();
            } else if (value == 'tutorial_pilak') {
              _showPilakTutorial();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20, color: AppColors.sapphire),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 20, color: AppColors.sapphire),
                  SizedBox(width: 8),
                  Text('Share mode'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'restore_hearts',
              child: Row(
                children: [
                  Icon(Icons.favorite, size: 20, color: AppColors.crimson),
                  SizedBox(width: 8),
                  Text('Restore hearts (testing)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'modify_pilak',
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 20,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 8),
                  Text('Modify Pilak (testing)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'tutorial_adarna',
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: AppColors.sapphire,
                  ),
                  SizedBox(width: 8),
                  Text('Tutorial: Adarna Mode'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'tutorial_pilak',
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 20,
                    color: AppColors.sapphire,
                  ),
                  SizedBox(width: 8),
                  Text('Tutorial: Pamilihan & Pilak'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
