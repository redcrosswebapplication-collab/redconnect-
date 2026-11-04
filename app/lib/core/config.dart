class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rndykhrrautjdpnszgcv.supabase.co',
  );
  static const String supabasePublishableKey =
      String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_IZmBKZkxuDihWIF9srFPFg_u8d485ne',
  );

  static void validateSupabaseConfig({
    String? url,
    String? publishableKey,
  }) {
    final configuredUrl = url ?? supabaseUrl;
    final configuredKey = publishableKey ?? supabasePublishableKey;
    if (configuredUrl.isEmpty || configuredKey.isEmpty) {
      throw StateError(
        'Configure SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define.',
      );
    }
    final uri = Uri.tryParse(configuredUrl);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw StateError('SUPABASE_URL must be a valid URL.');
    }
  }
}
