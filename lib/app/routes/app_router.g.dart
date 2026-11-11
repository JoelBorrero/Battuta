// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the singleton [GoRouter] instance to the widget tree.
///
/// Inject via `ref.watch(appRouterProvider)` in your top-level
/// [MaterialApp.router].

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Provides the singleton [GoRouter] instance to the widget tree.
///
/// Inject via `ref.watch(appRouterProvider)` in your top-level
/// [MaterialApp.router].

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Provides the singleton [GoRouter] instance to the widget tree.
  ///
  /// Inject via `ref.watch(appRouterProvider)` in your top-level
  /// [MaterialApp.router].
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'40140e9329f89de6cfe675a04a3c4bb9c717057f';
