// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repertoire_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the current repertoire list and exposes mutation methods.
///
/// Usage in a widget:
/// ```dart
/// final repertoire = ref.watch(repertoireProvider);
/// repertoire.when(
///   data: (songs) => SongListView(songs: songs),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => ErrorMessage(e),
/// );
/// ```

@ProviderFor(Repertoire)
final repertoireProvider = RepertoireProvider._();

/// Provides the current repertoire list and exposes mutation methods.
///
/// Usage in a widget:
/// ```dart
/// final repertoire = ref.watch(repertoireProvider);
/// repertoire.when(
///   data: (songs) => SongListView(songs: songs),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => ErrorMessage(e),
/// );
/// ```
final class RepertoireProvider
    extends $AsyncNotifierProvider<Repertoire, List<Song>> {
  /// Provides the current repertoire list and exposes mutation methods.
  ///
  /// Usage in a widget:
  /// ```dart
  /// final repertoire = ref.watch(repertoireProvider);
  /// repertoire.when(
  ///   data: (songs) => SongListView(songs: songs),
  ///   loading: () => const CircularProgressIndicator(),
  ///   error: (e, st) => ErrorMessage(e),
  /// );
  /// ```
  RepertoireProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repertoireProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repertoireHash();

  @$internal
  @override
  Repertoire create() => Repertoire();
}

String _$repertoireHash() => r'6adf2225a608b2a178d3b01a9fddab24b8222478';

/// Provides the current repertoire list and exposes mutation methods.
///
/// Usage in a widget:
/// ```dart
/// final repertoire = ref.watch(repertoireProvider);
/// repertoire.when(
///   data: (songs) => SongListView(songs: songs),
///   loading: () => const CircularProgressIndicator(),
///   error: (e, st) => ErrorMessage(e),
/// );
/// ```

abstract class _$Repertoire extends $AsyncNotifier<List<Song>> {
  FutureOr<List<Song>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Song>>, List<Song>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Song>>, List<Song>>,
              AsyncValue<List<Song>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
