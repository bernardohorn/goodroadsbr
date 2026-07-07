import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/routing/app_routes.dart';
import '../../../../../core/widgets/empty_state.dart';
import '../../../../../core/widgets/skeleton_loader.dart';
import '../../../../../core/widgets/status_chip.dart';
import '../../../../map/domain/entities/bounding_box.dart';
import '../../../../map/domain/entities/occurrence_pin.dart';
import '../../../../map/presentation/controllers/map_providers.dart';
import '../../../../occurrences/presentation/controllers/my_occurrences_controller.dart';
import '../../../../occurrences/presentation/widgets/occurrence_card.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meu histórico'),
          bottom: const TabBar(tabs: [Tab(text: 'Minhas ocorrências'), Tab(text: 'Todas as ocorrências')]),
        ),
        body: const TabBarView(children: [_MyOccurrencesTab(), _AllOccurrencesTab()]),
      ),
    );
  }
}

class _MyOccurrencesTab extends ConsumerWidget {
  const _MyOccurrencesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myOccurrencesControllerProvider);
    final controller = ref.read(myOccurrencesControllerProvider.notifier);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: state.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(20),
          children: List.generate(5, (_) => const SkeletonListTile()),
        ),
        error: (error, _) => ListView(
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Não foi possível carregar suas ocorrências',
              message: error is Failure ? error.message : null,
            ),
          ],
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return ListView(
              children: const [
                EmptyState(
                  icon: Icons.inbox_outlined,
                  title: 'Você ainda não registrou nenhuma ocorrência',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: page.items.length + (page.hasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == page.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: OutlinedButton(onPressed: controller.loadMore, child: const Text('Carregar mais')),
                  ),
                );
              }
              return OccurrenceCard(occurrence: page.items[index]);
            },
          );
        },
      ),
    );
  }
}

class _AllOccurrencesTab extends ConsumerStatefulWidget {
  const _AllOccurrencesTab();

  @override
  ConsumerState<_AllOccurrencesTab> createState() => _AllOccurrencesTabState();
}

class _AllOccurrencesTabState extends ConsumerState<_AllOccurrencesTab> {
  bool _isLoading = true;
  Failure? _failure;
  List<OccurrencePin> _pins = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _failure = null;
    });

    try {
      final position = await ref.read(mapProviderContractProvider).currentPosition();
      final box = BoundingBox.aroundPoint(lat: position.latitude, lng: position.longitude, radiusKm: 25);
      final result = await ref.read(findOccurrencesInBoundingBoxUseCaseProvider)(box);
      if (!mounted) return;
      result.fold(
        (failure) => setState(() => _failure = failure),
        (pins) => setState(() => _pins = pins),
      );
    } catch (_) {
      if (mounted) setState(() => _failure = const UnknownFailure('Não foi possível obter sua localização.'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ListView(padding: const EdgeInsets.all(20), children: List.generate(5, (_) => const SkeletonListTile()));
    }
    if (_failure != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: [EmptyState(icon: Icons.error_outline, title: 'Não foi possível carregar', message: _failure!.message)]),
      );
    }
    if (_pins.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(children: const [EmptyState(icon: Icons.map_outlined, title: 'Nenhuma ocorrência próxima de você')]),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _pins.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final pin = _pins[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(pin.protocolNumber),
            trailing: StatusChip(status: pin.status),
            onTap: () => context.push(AppRoutes.occurrenceDetailsPath(pin.id)),
          );
        },
      ),
    );
  }
}
