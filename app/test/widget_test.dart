import 'package:flutter_test/flutter_test.dart';
import 'package:redcross_connect/core/config.dart';

void main() {
  test('requires a Supabase URL and publishable key', () {
    expect(
      () => AppConfig.validateSupabaseConfig(url: '', publishableKey: ''),
      throwsA(isA<StateError>()),
    );
  });

  test('accepts a configured Supabase project', () {
    expect(
      () => AppConfig.validateSupabaseConfig(
        url: 'https://project.supabase.co',
        publishableKey: 'sb_publishable_test',
      ),
      returnsNormally,
    );
  });
}
