import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../controllers/categories_providers.dart';
import '../widgets/category_form_dialog.dart';

/// Tela 6/10 do desktop: CRUD de categorias de ocorrencia — desenhada como
/// tela propria a pedido explicito do cliente (ver docs/DECISOES.md,
/// entrada "Escopo do app Desktop expandido").
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Categorias',
              subtitle: 'Tipos de problema disponíveis para o cidadão classificar uma ocorrência.',
              action: FilledButton.icon(
                onPressed: () => CategoryFormDialog.show(context),
                icon: const Icon(Icons.add),
                label: const Text('Nova categoria'),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Column(children: [SkeletonRow(), SkeletonRow(), SkeletonRow()]),
                error: (error, _) => Center(child: Text('Não foi possível carregar as categorias: $error')),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const EmptyState(icon: Icons.category_outlined, title: 'Nenhuma categoria cadastrada');
                  }
                  return Card(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final color = _parseColor(category.color) ?? Theme.of(context).colorScheme.primary;
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color, radius: 10),
                          title: Text(category.name),
                          subtitle: Text(category.active ? 'Ativa' : 'Inativa'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => CategoryFormDialog.show(context, category: category),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (value == null) return null;
    return Color(0xFF000000 | value);
  }
}
