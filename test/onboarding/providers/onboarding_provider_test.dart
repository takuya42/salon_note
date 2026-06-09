import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salon_note/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('初期状態ではオンボーディング未完了になる', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(onboardingCompletedProvider), isFalse);
  });

  test('完了状態をSharedPreferencesへ永続化する', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    await container.read(onboardingCompletedProvider.notifier).complete();

    expect(container.read(onboardingCompletedProvider), isTrue);
    expect(preferences.getBool(onboardingCompletedKey), isTrue);
  });

  test('保存済み状態を再起動相当のProviderContainerで復元する', () async {
    SharedPreferences.setMockInitialValues({onboardingCompletedKey: true});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(onboardingCompletedProvider), isTrue);
  });
}
