import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current time. Tests override this with a fixed clock.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
