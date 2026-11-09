import 'package:flutter/material.dart';

import '../../app/themes/app_colors.dart';
import 'pilak_product.dart';
import 'pilak_service.dart';

class PilakMarketplaceScreen extends StatefulWidget {
  const PilakMarketplaceScreen({super.key});

  @override
  State<PilakMarketplaceScreen> createState() => _PilakMarketplaceScreenState();
}

class _PilakMarketplaceScreenState extends State<PilakMarketplaceScreen> {
  PilakProductCategory? _category;
  bool _isWorking = false;
  String? _message;

  Future<void> _purchase(PilakProduct product) async {
    setState(() {
      _isWorking = true;
      _message = null;
    });
    try {
      final purchased = await PilakService.instance.purchase(product.id);
      if (!mounted) return;
      setState(() {
        _message = purchased
            ? null
            : PilakService.instance.owns(product.id)
            ? 'Nabili mo na ang produktong ito.'
            : 'Kulang ang iyong Pilak.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Hindi natuloy ang pagbili: $error');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _activateTheme(PilakProduct product) async {
    try {
      await PilakService.instance.activateTheme(product.id);
      if (mounted) {
        setState(() => _message = 'Inilapat ang temang ${product.name}.');
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Hindi mailapat ang tema: $error');
    }
  }

  Future<void> _export(PilakProduct product) async {
    try {
      final file = await PilakService.instance.exportMaterial(product.id);
      if (mounted) {
        setState(() => _message = 'Nai-save ang file sa ${file.path}');
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _message =
              'Hindi pa available ang materyal na ito. Walang bundled asset para sa ${product.name}. ($error)',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: PilakService.instance.initialize(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Hindi ma-load ang Pilak account: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = pilakProducts
            .where(
              (product) => _category == null || product.category == _category,
            )
            .toList();
        final colorScheme = Theme.of(context).colorScheme;
        return Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.gold,
                  child: Icon(Icons.monetization_on, color: AppColors.sapphire),
                ),
                title: const Text(
                  'Iyong balanse',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: Text(
                  '${PilakService.instance.balance} Pilak',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ).copyWith(color: colorScheme.primary),
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _filterChip('Lahat', null),
                  _filterChip('Mga Tema', PilakProductCategory.theme),
                  _filterChip('Mga Tampok', PilakProductCategory.feature),
                  _filterChip('Materyales', PilakProductCategory.material),
                ],
              ),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Text(
                  _message!,
                  style: TextStyle(
                    color:
                        _message!.startsWith('Hindi') ||
                            _message!.startsWith('Kulang')
                        ? colorScheme.error
                        : colorScheme.primary,
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                itemCount: products.length,
                itemBuilder: (context, index) => _productCard(products[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, PilakProductCategory? category) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: _category == category,
        onSelected: (_) => setState(() => _category = category),
      ),
    );
  }

  Widget _productCard(PilakProduct product) {
    final service = PilakService.instance;
    final colorScheme = Theme.of(context).colorScheme;
    final owned = service.owns(product.id);
    final activeTheme =
        product.themeId != null && product.themeId == service.activeThemeId;
    final icon = switch (product.category) {
      PilakProductCategory.theme => Icons.palette_outlined,
      PilakProductCategory.feature => Icons.lock_open_outlined,
      PilakProductCategory.material => Icons.inventory_2_outlined,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)
                        .copyWith(color: colorScheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(product.description),
                  const SizedBox(height: 8),
                  Text(
                    '${product.price} Pilak',
                    style: const TextStyle(fontWeight: FontWeight.bold)
                        .copyWith(color: colorScheme.secondary),
                  ),
                  const SizedBox(height: 8),
                  if (product.category == PilakProductCategory.material &&
                      owned)
                    OutlinedButton.icon(
                      onPressed: _isWorking ? null : () => _export(product),
                      icon: const Icon(Icons.download_outlined),
                      label: const Text('I-export'),
                    )
                  else if (activeTheme)
                    const Chip(
                      avatar: Icon(Icons.check, size: 18),
                      label: Text('Kasalukuyang tema'),
                    )
                  else if (product.category == PilakProductCategory.theme &&
                      owned)
                    OutlinedButton(
                      onPressed: () => _activateTheme(product),
                      child: const Text('Ilapat ang tema'),
                    )
                  else if (owned &&
                      product.id != 'streak_freeze' &&
                      product.id != 'quiz_decay_reset')
                    const Chip(
                      avatar: Icon(Icons.check, size: 18),
                      label: Text('Nabili na'),
                    )
                  else
                    FilledButton(
                      onPressed: _isWorking ? null : () => _purchase(product),
                      child: Text(owned ? 'Bilhin ulit' : 'Bilhin'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
