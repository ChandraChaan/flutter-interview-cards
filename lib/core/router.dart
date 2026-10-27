import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browse/presentation/browse_screen.dart';
import '../features/card/presentation/card_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/review/presentation/study_screen.dart';
import '../features/shell/presentation/app_shell.dart';

/// Card IDs are lower-case words joined by `-`; anything else in a shared
/// link is rejected before it reaches a screen.
final _cardId = RegExp(r'^[a-z0-9_-]{1,120}$');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // On the web the default hash strategy gives links like
    // https://.../flutter-interview-cards/#/card/<id>.
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StudyScreen()),
          ),
          GoRoute(
            path: '/browse',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: BrowseScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProgressScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/card/:id',
        redirect: (context, state) =>
            _cardId.hasMatch(state.pathParameters['id']!) ? null : '/browse',
        builder: (context, state) =>
            CardScreen(cardId: state.pathParameters['id']!),
      ),
    ],
    // Unknown paths go home rather than to a dead end.
    onException: (context, state, router) => router.go('/'),
  );
  ref.onDispose(router.dispose);
  return router;
});
