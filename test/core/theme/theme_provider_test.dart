import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('themeProvider initializes correctly', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': true});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final themeMode = container.read(themeProvider);
    expect(themeMode, ThemeMode.dark);
  });

  test('themeProvider toggles correctly', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': false});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );

    final themeMode = container.read(themeProvider);
    expect(themeMode, ThemeMode.light);

    await container.read(themeProvider.notifier).toggleTheme();
    
    expect(container.read(themeProvider), ThemeMode.dark);
    expect(prefs.getBool('theme_mode'), true);
  });
}
