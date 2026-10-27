import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/links.dart';
import '../../../core/widgets/status_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../deck/presentation/deck_providers.dart';
import '../../review/domain/scheduler.dart';
import '../../review/presentation/progress_controller.dart';
import 'progress_summary.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(progressSummaryProvider)) {
      AsyncValue(:final value?) => _ProgressView(summary: value),
      AsyncValue(hasError: true) => ErrorView(
        onRetry: () => ref
          ..invalidate(deckProvider)
          ..invalidate(progressControllerProvider),
      ),
      _ => const LoadingView(),
    };
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: contentPadding(
          constraints.maxWidth,
        ).copyWith(top: 8, bottom: 32),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatTile(
                icon: Icons.local_fire_department_outlined,
                value: '${summary.streak}',
                label: l10n.statStreak,
              ),
              _StatTile(
                icon: Icons.done_all,
                value: '${summary.reviewedToday}',
                label: l10n.statReviewedToday,
              ),
              _StatTile(
                icon: Icons.schedule,
                value: '${summary.dueToday}',
                label: l10n.statDueToday,
              ),
              _StatTile(
                icon: Icons.workspace_premium_outlined,
                value: l10n.ofTotal(
                  summary.overall.mastered,
                  summary.overall.total,
                ),
                label: l10n.statMastered,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(l10n.masteryTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.masteryExplainer(Scheduler.masteredAfterDays),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          for (final item in summary.chapters)
            Padding(
              key: ValueKey(item.chapter.id),
              padding: const EdgeInsets.only(bottom: 16),
              child: _ChapterRow(item: item),
            ),
          const SizedBox(height: 16),
          const _AboutCard(),
          const SizedBox(height: 24),
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: _ResetButton(),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 150),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineMedium),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.item});

  final ChapterMastery item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mastery = item.mastery;
    final breakdown = l10n.masteryBreakdown(
      mastery.mastered,
      mastery.learning,
      mastery.fresh,
    );
    return Semantics(
      label:
          '${l10n.chapterLabel(item.chapter.number, item.chapter.title)}, '
          '$breakdown',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.chapterLabel(item.chapter.number, item.chapter.title),
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          MasteryBar(mastery: mastery),
          const SizedBox(height: 4),
          Text(
            breakdown,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mastered cards, then cards being learned, as one bar. The counts are
/// always written next to it too.
class MasteryBar extends StatelessWidget {
  const MasteryBar({required this.mastery, super.key});

  final Mastery mastery;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (mastery.mastered > 0)
                Expanded(
                  flex: mastery.mastered,
                  child: ColoredBox(
                    key: const Key('mastered-segment'),
                    color: scheme.primary,
                  ),
                ),
              if (mastery.learning > 0)
                Expanded(
                  flex: mastery.learning,
                  child: ColoredBox(
                    key: const Key('learning-segment'),
                    color: scheme.primary.withAlpha(110),
                  ),
                ),
              if (mastery.fresh > 0)
                Expanded(flex: mastery.fresh, child: const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aboutTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.aboutBody),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrl(handbookUrl),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(l10n.theHandbook),
                ),
                TextButton.icon(
                  onPressed: () => launchUrl(sourceCodeUrl),
                  icon: const Icon(Icons.code),
                  label: Text(l10n.sourceCode),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ResetButton extends ConsumerWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      key: const Key('reset-progress'),
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.error,
        side: BorderSide(color: scheme.error),
      ),
      icon: const Icon(Icons.restart_alt),
      label: Text(l10n.resetProgress),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.resetTitle),
            content: Text(l10n.resetBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('confirm-reset'),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.reset),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        await ref.read(progressControllerProvider.notifier).reset();
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetDone)));
      },
    );
  }
}
