import 'package:flutter/foundation.dart';

/// Where the web app is published.
final siteUrl = Uri.parse(
  'https://chandrachaan.github.io/flutter-interview-cards/',
);

final sourceCodeUrl = Uri.parse(
  'https://github.com/ChandraChaan/flutter-interview-cards',
);

final handbookUrl = Uri.parse(
  'https://github.com/ChandraChaan/flutter-architect-handbook',
);

/// A link that opens [cardId] in the app. On the web it points at the site
/// you're on, so links also work from a local build or a fork.
Uri cardShareUrl(String cardId, {Uri? base}) {
  final site = base ?? (kIsWeb ? Uri.base : siteUrl);
  return Uri(
    scheme: site.scheme,
    host: site.host,
    port: site.hasPort ? site.port : null,
    path: site.path,
    fragment: '/card/$cardId',
  );
}
