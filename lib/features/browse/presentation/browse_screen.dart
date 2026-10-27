import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../deck/domain/flashcard.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../deck/presentation/flashcard_view.dart';
import '../../review/domain/scheduler.dart';
import '../../review/presentation/progress_controller.dart';
import 'browse_controller.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(browseResultsProvider)) {
      AsyncValue(:final value?) => _BrowseView(results: value),
      AsyncValue(hasError: true) => ErrorView(
        onRetry: () => ref
          ..invalidate(deckProvider)
          ..invalidate(progressControllerProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _BrowseView extends ConsumerWidget {
  const _BrowseView({required this.results});

  final BrowseResults results;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(browseFilterProvider);
    final items = results.items;
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = contentPadding(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: padding.copyWith(top: 8),
              sliver: SliverToBoxAdapter(
                child: _Filters(chapters: results.chapters, filter: filter),
              ),
            ),
            SliverPadding(
              padding: padding.copyWith(top: 8, bottom: 4),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.resultCount(items.length),
                        key: const Key('result-count'),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    if (!filter.isEmpty)
                      TextButton(
                        onPressed: ref
                            .read(browseFilterProvider.notifier)
                            .clear,
                        child: Text(l10n.clearFilters),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: padding.copyWith(bottom: 24),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _CardTile(
                  key: ValueKey(items[index].card.id),
                  item: items[index],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Filters extends ConsumerStatefulWidget {
  const _Filters({required this.chapters, required this.filter});

  final List<Chapter> chapters;
  final BrowseFilter filter;

  @override
  ConsumerState<_Filters> createState() => _FiltersState();
}

class _FiltersState extends ConsumerState<_Filters> {
  late final _search = TextEditingController(text: widget.filter.query);

  @override
  void didUpdateWidget(_Filters oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when "Clear filters" empties the query.
    if (widget.filter.query != _search.text) {
      _search.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(browseFilterProvider.notifier);
    final filter = widget.filter;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('search'),
          controller: _search,
          onChanged: controller.setQuery,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: filter.query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.clearSearch,
                    icon: const Icon(Icons.close),
                    onPressed: () => controller.setQuery(''),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownMenu<String?>(
              key: ValueKey('chapter-${filter.chapterId}'),
              initialSelection: filter.chapterId,
              label: Text(l10n.chapter),
              onSelected: controller.setChapter,
              dropdownMenuEntries: [
                DropdownMenuEntry(value: null, label: l10n.allChapters),
                for (final chapter in widget.chapters)
                  DropdownMenuEntry(
                    value: chapter.id,
                    label: l10n.chapterLabel(chapter.number, chapter.title),
                  ),
              ],
            ),
            for (final level in Level.values)
              FilterChip(
                label: Text(levelName(context, level)),
                selected: filter.levels.contains(level),
                onSelected: (_) => controller.toggleLevel(level),
              ),
          ],
        ),
      ],
    );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({required this.item, super.key});

  final BrowseItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/card/${item.card.id}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Code spans read fine without their backticks here.
                      item.card.question.replaceAll('`', ''),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        LevelChip(level: item.card.level),
                        Text(
                          l10n.chapterLabel(
                            item.chapter.number,
                            item.chapter.title,
                          ),
                          style: muted,
                        ),
                        Text(statusName(context, item.status), style: muted),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

String statusName(BuildContext context, CardStatus status) {
  final l10n = AppLocalizations.of(context);
  return switch (status) {
    CardStatus.fresh => l10n.statusNew,
    CardStatus.learning => l10n.statusLearning,
    CardStatus.mastered => l10n.statusMastered,
  };
}
