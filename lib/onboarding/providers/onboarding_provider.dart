import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const onboardingCompletedKey = 'onboarding_completed';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at startup.');
});

final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(
          onboardingCompletedKey,
        ) ??
        false;
  }

  Future<void> complete() async {
    await ref.read(sharedPreferencesProvider).setBool(
          onboardingCompletedKey,
          true,
        );
    state = true;
  }
}
