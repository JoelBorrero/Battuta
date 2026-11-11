// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SongsTable extends Songs with TableInfo<$SongsTable, SongEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SongsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<int> tempo = GeneratedColumn<int>(
    'tempo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeSignatureBeatsMeta =
      const VerificationMeta('timeSignatureBeats');
  @override
  late final GeneratedColumn<int> timeSignatureBeats = GeneratedColumn<int>(
    'time_signature_beats',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _timeSignatureBeatValueMeta =
      const VerificationMeta('timeSignatureBeatValue');
  @override
  late final GeneratedColumn<int> timeSignatureBeatValue = GeneratedColumn<int>(
    'time_signature_beat_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _sectionsJsonMeta = const VerificationMeta(
    'sectionsJson',
  );
  @override
  late final GeneratedColumn<String> sectionsJson = GeneratedColumn<String>(
    'sections_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _coverImagePathMeta = const VerificationMeta(
    'coverImagePath',
  );
  @override
  late final GeneratedColumn<String> coverImagePath = GeneratedColumn<String>(
    'cover_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _songWorkIdMeta = const VerificationMeta(
    'songWorkId',
  );
  @override
  late final GeneratedColumn<String> songWorkId = GeneratedColumn<String>(
    'song_work_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Original'),
  );
  static const VerificationMeta _visibilityMeta = const VerificationMeta(
    'visibility',
  );
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
    'visibility',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('private'),
  );
  static const VerificationMeta _forkedFromVersionIdMeta =
      const VerificationMeta('forkedFromVersionId');
  @override
  late final GeneratedColumn<String> forkedFromVersionId =
      GeneratedColumn<String>(
        'forked_from_version_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sharedOrganizationIdsJsonMeta =
      const VerificationMeta('sharedOrganizationIdsJson');
  @override
  late final GeneratedColumn<String> sharedOrganizationIdsJson =
      GeneratedColumn<String>(
        'shared_organization_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMsMeta = const VerificationMeta(
    'editedAtMs',
  );
  @override
  late final GeneratedColumn<int> editedAtMs = GeneratedColumn<int>(
    'edited_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sharingDirtyMeta = const VerificationMeta(
    'sharingDirty',
  );
  @override
  late final GeneratedColumn<bool> sharingDirty = GeneratedColumn<bool>(
    'sharing_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("sharing_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _songCreatorIdMeta = const VerificationMeta(
    'songCreatorId',
  );
  @override
  late final GeneratedColumn<String> songCreatorId = GeneratedColumn<String>(
    'song_creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    artist,
    key,
    tempo,
    timeSignatureBeats,
    timeSignatureBeatValue,
    sectionsJson,
    tagsJson,
    coverImagePath,
    notes,
    createdAt,
    updatedAt,
    songWorkId,
    ownerId,
    label,
    visibility,
    forkedFromVersionId,
    sharedOrganizationIdsJson,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    accountId,
    editedAtMs,
    sharingDirty,
    songCreatorId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'songs';
  @override
  VerificationContext validateIntegrity(
    Insertable<SongEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    } else if (isInserting) {
      context.missing(_artistMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('tempo')) {
      context.handle(
        _tempoMeta,
        tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta),
      );
    } else if (isInserting) {
      context.missing(_tempoMeta);
    }
    if (data.containsKey('time_signature_beats')) {
      context.handle(
        _timeSignatureBeatsMeta,
        timeSignatureBeats.isAcceptableOrUnknown(
          data['time_signature_beats']!,
          _timeSignatureBeatsMeta,
        ),
      );
    }
    if (data.containsKey('time_signature_beat_value')) {
      context.handle(
        _timeSignatureBeatValueMeta,
        timeSignatureBeatValue.isAcceptableOrUnknown(
          data['time_signature_beat_value']!,
          _timeSignatureBeatValueMeta,
        ),
      );
    }
    if (data.containsKey('sections_json')) {
      context.handle(
        _sectionsJsonMeta,
        sectionsJson.isAcceptableOrUnknown(
          data['sections_json']!,
          _sectionsJsonMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('cover_image_path')) {
      context.handle(
        _coverImagePathMeta,
        coverImagePath.isAcceptableOrUnknown(
          data['cover_image_path']!,
          _coverImagePathMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('song_work_id')) {
      context.handle(
        _songWorkIdMeta,
        songWorkId.isAcceptableOrUnknown(
          data['song_work_id']!,
          _songWorkIdMeta,
        ),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('visibility')) {
      context.handle(
        _visibilityMeta,
        visibility.isAcceptableOrUnknown(data['visibility']!, _visibilityMeta),
      );
    }
    if (data.containsKey('forked_from_version_id')) {
      context.handle(
        _forkedFromVersionIdMeta,
        forkedFromVersionId.isAcceptableOrUnknown(
          data['forked_from_version_id']!,
          _forkedFromVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('shared_organization_ids_json')) {
      context.handle(
        _sharedOrganizationIdsJsonMeta,
        sharedOrganizationIdsJson.isAcceptableOrUnknown(
          data['shared_organization_ids_json']!,
          _sharedOrganizationIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('edited_at_ms')) {
      context.handle(
        _editedAtMsMeta,
        editedAtMs.isAcceptableOrUnknown(
          data['edited_at_ms']!,
          _editedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('sharing_dirty')) {
      context.handle(
        _sharingDirtyMeta,
        sharingDirty.isAcceptableOrUnknown(
          data['sharing_dirty']!,
          _sharingDirtyMeta,
        ),
      );
    }
    if (data.containsKey('song_creator_id')) {
      context.handle(
        _songCreatorIdMeta,
        songCreatorId.isAcceptableOrUnknown(
          data['song_creator_id']!,
          _songCreatorIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SongEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SongEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      tempo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tempo'],
      )!,
      timeSignatureBeats: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_signature_beats'],
      )!,
      timeSignatureBeatValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_signature_beat_value'],
      )!,
      sectionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sections_json'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      coverImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_path'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      songWorkId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_work_id'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      visibility: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visibility'],
      )!,
      forkedFromVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}forked_from_version_id'],
      ),
      sharedOrganizationIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_organization_ids_json'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_at'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      editedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at_ms'],
      )!,
      sharingDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}sharing_dirty'],
      )!,
      songCreatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_creator_id'],
      ),
    );
  }

  @override
  $SongsTable createAlias(String alias) {
    return $SongsTable(attachedDatabase, alias);
  }
}

class SongEntry extends DataClass implements Insertable<SongEntry> {
  final String id;
  final String title;
  final String artist;
  final String key;
  final int tempo;
  final int timeSignatureBeats;
  final int timeSignatureBeatValue;
  final String sectionsJson;
  final String tagsJson;
  final String? coverImagePath;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? songWorkId;
  final String? ownerId;
  final String label;
  final String visibility;
  final String? forkedFromVersionId;
  final String sharedOrganizationIdsJson;
  final bool isDirty;

  /// Local tombstone: set when a synced version is deleted, until the delete
  /// has been pushed.
  final DateTime? deletedAt;

  /// `updated_at` of the backend row this copy was last synced with, as the
  /// exact ISO-8601 text the backend sent (Drift's `DateTime` would drop the
  /// sub-second part and make unchanged rows look changed).
  final String? remoteUpdatedAt;
  final String? accountId;

  /// When the user last edited the version, in milliseconds since the epoch.
  /// Strictly increasing per row, so two saves never share a value; it is what
  /// devices compare to decide whose edit is newer, and what tells a push that
  /// the row was edited again while it was in flight.
  final int editedAtMs;

  /// Label, visibility or shares changed locally and are not pushed yet.
  final bool sharingDirty;

  /// v4: account that created the work (`songs.created_by`); null if unknown.
  final String? songCreatorId;
  const SongEntry({
    required this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.tempo,
    required this.timeSignatureBeats,
    required this.timeSignatureBeatValue,
    required this.sectionsJson,
    required this.tagsJson,
    this.coverImagePath,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.songWorkId,
    this.ownerId,
    required this.label,
    required this.visibility,
    this.forkedFromVersionId,
    required this.sharedOrganizationIdsJson,
    required this.isDirty,
    this.deletedAt,
    this.remoteUpdatedAt,
    this.accountId,
    required this.editedAtMs,
    required this.sharingDirty,
    this.songCreatorId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['artist'] = Variable<String>(artist);
    map['key'] = Variable<String>(key);
    map['tempo'] = Variable<int>(tempo);
    map['time_signature_beats'] = Variable<int>(timeSignatureBeats);
    map['time_signature_beat_value'] = Variable<int>(timeSignatureBeatValue);
    map['sections_json'] = Variable<String>(sectionsJson);
    map['tags_json'] = Variable<String>(tagsJson);
    if (!nullToAbsent || coverImagePath != null) {
      map['cover_image_path'] = Variable<String>(coverImagePath);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || songWorkId != null) {
      map['song_work_id'] = Variable<String>(songWorkId);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['label'] = Variable<String>(label);
    map['visibility'] = Variable<String>(visibility);
    if (!nullToAbsent || forkedFromVersionId != null) {
      map['forked_from_version_id'] = Variable<String>(forkedFromVersionId);
    }
    map['shared_organization_ids_json'] = Variable<String>(
      sharedOrganizationIdsJson,
    );
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['edited_at_ms'] = Variable<int>(editedAtMs);
    map['sharing_dirty'] = Variable<bool>(sharingDirty);
    if (!nullToAbsent || songCreatorId != null) {
      map['song_creator_id'] = Variable<String>(songCreatorId);
    }
    return map;
  }

  SongsCompanion toCompanion(bool nullToAbsent) {
    return SongsCompanion(
      id: Value(id),
      title: Value(title),
      artist: Value(artist),
      key: Value(key),
      tempo: Value(tempo),
      timeSignatureBeats: Value(timeSignatureBeats),
      timeSignatureBeatValue: Value(timeSignatureBeatValue),
      sectionsJson: Value(sectionsJson),
      tagsJson: Value(tagsJson),
      coverImagePath: coverImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImagePath),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      songWorkId: songWorkId == null && nullToAbsent
          ? const Value.absent()
          : Value(songWorkId),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      label: Value(label),
      visibility: Value(visibility),
      forkedFromVersionId: forkedFromVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(forkedFromVersionId),
      sharedOrganizationIdsJson: Value(sharedOrganizationIdsJson),
      isDirty: Value(isDirty),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      editedAtMs: Value(editedAtMs),
      sharingDirty: Value(sharingDirty),
      songCreatorId: songCreatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(songCreatorId),
    );
  }

  factory SongEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SongEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String>(json['artist']),
      key: serializer.fromJson<String>(json['key']),
      tempo: serializer.fromJson<int>(json['tempo']),
      timeSignatureBeats: serializer.fromJson<int>(json['timeSignatureBeats']),
      timeSignatureBeatValue: serializer.fromJson<int>(
        json['timeSignatureBeatValue'],
      ),
      sectionsJson: serializer.fromJson<String>(json['sectionsJson']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      coverImagePath: serializer.fromJson<String?>(json['coverImagePath']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      songWorkId: serializer.fromJson<String?>(json['songWorkId']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      label: serializer.fromJson<String>(json['label']),
      visibility: serializer.fromJson<String>(json['visibility']),
      forkedFromVersionId: serializer.fromJson<String?>(
        json['forkedFromVersionId'],
      ),
      sharedOrganizationIdsJson: serializer.fromJson<String>(
        json['sharedOrganizationIdsJson'],
      ),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      editedAtMs: serializer.fromJson<int>(json['editedAtMs']),
      sharingDirty: serializer.fromJson<bool>(json['sharingDirty']),
      songCreatorId: serializer.fromJson<String?>(json['songCreatorId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String>(artist),
      'key': serializer.toJson<String>(key),
      'tempo': serializer.toJson<int>(tempo),
      'timeSignatureBeats': serializer.toJson<int>(timeSignatureBeats),
      'timeSignatureBeatValue': serializer.toJson<int>(timeSignatureBeatValue),
      'sectionsJson': serializer.toJson<String>(sectionsJson),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'coverImagePath': serializer.toJson<String?>(coverImagePath),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'songWorkId': serializer.toJson<String?>(songWorkId),
      'ownerId': serializer.toJson<String?>(ownerId),
      'label': serializer.toJson<String>(label),
      'visibility': serializer.toJson<String>(visibility),
      'forkedFromVersionId': serializer.toJson<String?>(forkedFromVersionId),
      'sharedOrganizationIdsJson': serializer.toJson<String>(
        sharedOrganizationIdsJson,
      ),
      'isDirty': serializer.toJson<bool>(isDirty),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'accountId': serializer.toJson<String?>(accountId),
      'editedAtMs': serializer.toJson<int>(editedAtMs),
      'sharingDirty': serializer.toJson<bool>(sharingDirty),
      'songCreatorId': serializer.toJson<String?>(songCreatorId),
    };
  }

  SongEntry copyWith({
    String? id,
    String? title,
    String? artist,
    String? key,
    int? tempo,
    int? timeSignatureBeats,
    int? timeSignatureBeatValue,
    String? sectionsJson,
    String? tagsJson,
    Value<String?> coverImagePath = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> songWorkId = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    String? label,
    String? visibility,
    Value<String?> forkedFromVersionId = const Value.absent(),
    String? sharedOrganizationIdsJson,
    bool? isDirty,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> remoteUpdatedAt = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    int? editedAtMs,
    bool? sharingDirty,
    Value<String?> songCreatorId = const Value.absent(),
  }) => SongEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    key: key ?? this.key,
    tempo: tempo ?? this.tempo,
    timeSignatureBeats: timeSignatureBeats ?? this.timeSignatureBeats,
    timeSignatureBeatValue:
        timeSignatureBeatValue ?? this.timeSignatureBeatValue,
    sectionsJson: sectionsJson ?? this.sectionsJson,
    tagsJson: tagsJson ?? this.tagsJson,
    coverImagePath: coverImagePath.present
        ? coverImagePath.value
        : this.coverImagePath,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    songWorkId: songWorkId.present ? songWorkId.value : this.songWorkId,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    label: label ?? this.label,
    visibility: visibility ?? this.visibility,
    forkedFromVersionId: forkedFromVersionId.present
        ? forkedFromVersionId.value
        : this.forkedFromVersionId,
    sharedOrganizationIdsJson:
        sharedOrganizationIdsJson ?? this.sharedOrganizationIdsJson,
    isDirty: isDirty ?? this.isDirty,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    accountId: accountId.present ? accountId.value : this.accountId,
    editedAtMs: editedAtMs ?? this.editedAtMs,
    sharingDirty: sharingDirty ?? this.sharingDirty,
    songCreatorId: songCreatorId.present
        ? songCreatorId.value
        : this.songCreatorId,
  );
  SongEntry copyWithCompanion(SongsCompanion data) {
    return SongEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      key: data.key.present ? data.key.value : this.key,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      timeSignatureBeats: data.timeSignatureBeats.present
          ? data.timeSignatureBeats.value
          : this.timeSignatureBeats,
      timeSignatureBeatValue: data.timeSignatureBeatValue.present
          ? data.timeSignatureBeatValue.value
          : this.timeSignatureBeatValue,
      sectionsJson: data.sectionsJson.present
          ? data.sectionsJson.value
          : this.sectionsJson,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      coverImagePath: data.coverImagePath.present
          ? data.coverImagePath.value
          : this.coverImagePath,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      songWorkId: data.songWorkId.present
          ? data.songWorkId.value
          : this.songWorkId,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      label: data.label.present ? data.label.value : this.label,
      visibility: data.visibility.present
          ? data.visibility.value
          : this.visibility,
      forkedFromVersionId: data.forkedFromVersionId.present
          ? data.forkedFromVersionId.value
          : this.forkedFromVersionId,
      sharedOrganizationIdsJson: data.sharedOrganizationIdsJson.present
          ? data.sharedOrganizationIdsJson.value
          : this.sharedOrganizationIdsJson,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      editedAtMs: data.editedAtMs.present
          ? data.editedAtMs.value
          : this.editedAtMs,
      sharingDirty: data.sharingDirty.present
          ? data.sharingDirty.value
          : this.sharingDirty,
      songCreatorId: data.songCreatorId.present
          ? data.songCreatorId.value
          : this.songCreatorId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SongEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('key: $key, ')
          ..write('tempo: $tempo, ')
          ..write('timeSignatureBeats: $timeSignatureBeats, ')
          ..write('timeSignatureBeatValue: $timeSignatureBeatValue, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('songWorkId: $songWorkId, ')
          ..write('ownerId: $ownerId, ')
          ..write('label: $label, ')
          ..write('visibility: $visibility, ')
          ..write('forkedFromVersionId: $forkedFromVersionId, ')
          ..write('sharedOrganizationIdsJson: $sharedOrganizationIdsJson, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('editedAtMs: $editedAtMs, ')
          ..write('sharingDirty: $sharingDirty, ')
          ..write('songCreatorId: $songCreatorId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    artist,
    key,
    tempo,
    timeSignatureBeats,
    timeSignatureBeatValue,
    sectionsJson,
    tagsJson,
    coverImagePath,
    notes,
    createdAt,
    updatedAt,
    songWorkId,
    ownerId,
    label,
    visibility,
    forkedFromVersionId,
    sharedOrganizationIdsJson,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    accountId,
    editedAtMs,
    sharingDirty,
    songCreatorId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SongEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.key == this.key &&
          other.tempo == this.tempo &&
          other.timeSignatureBeats == this.timeSignatureBeats &&
          other.timeSignatureBeatValue == this.timeSignatureBeatValue &&
          other.sectionsJson == this.sectionsJson &&
          other.tagsJson == this.tagsJson &&
          other.coverImagePath == this.coverImagePath &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.songWorkId == this.songWorkId &&
          other.ownerId == this.ownerId &&
          other.label == this.label &&
          other.visibility == this.visibility &&
          other.forkedFromVersionId == this.forkedFromVersionId &&
          other.sharedOrganizationIdsJson == this.sharedOrganizationIdsJson &&
          other.isDirty == this.isDirty &&
          other.deletedAt == this.deletedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.accountId == this.accountId &&
          other.editedAtMs == this.editedAtMs &&
          other.sharingDirty == this.sharingDirty &&
          other.songCreatorId == this.songCreatorId);
}

class SongsCompanion extends UpdateCompanion<SongEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> artist;
  final Value<String> key;
  final Value<int> tempo;
  final Value<int> timeSignatureBeats;
  final Value<int> timeSignatureBeatValue;
  final Value<String> sectionsJson;
  final Value<String> tagsJson;
  final Value<String?> coverImagePath;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> songWorkId;
  final Value<String?> ownerId;
  final Value<String> label;
  final Value<String> visibility;
  final Value<String?> forkedFromVersionId;
  final Value<String> sharedOrganizationIdsJson;
  final Value<bool> isDirty;
  final Value<DateTime?> deletedAt;
  final Value<String?> remoteUpdatedAt;
  final Value<String?> accountId;
  final Value<int> editedAtMs;
  final Value<bool> sharingDirty;
  final Value<String?> songCreatorId;
  final Value<int> rowid;
  const SongsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.key = const Value.absent(),
    this.tempo = const Value.absent(),
    this.timeSignatureBeats = const Value.absent(),
    this.timeSignatureBeatValue = const Value.absent(),
    this.sectionsJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.songWorkId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.label = const Value.absent(),
    this.visibility = const Value.absent(),
    this.forkedFromVersionId = const Value.absent(),
    this.sharedOrganizationIdsJson = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.sharingDirty = const Value.absent(),
    this.songCreatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SongsCompanion.insert({
    required String id,
    required String title,
    required String artist,
    required String key,
    required int tempo,
    this.timeSignatureBeats = const Value.absent(),
    this.timeSignatureBeatValue = const Value.absent(),
    this.sectionsJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.coverImagePath = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.songWorkId = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.label = const Value.absent(),
    this.visibility = const Value.absent(),
    this.forkedFromVersionId = const Value.absent(),
    this.sharedOrganizationIdsJson = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.sharingDirty = const Value.absent(),
    this.songCreatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       artist = Value(artist),
       key = Value(key),
       tempo = Value(tempo),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SongEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? key,
    Expression<int>? tempo,
    Expression<int>? timeSignatureBeats,
    Expression<int>? timeSignatureBeatValue,
    Expression<String>? sectionsJson,
    Expression<String>? tagsJson,
    Expression<String>? coverImagePath,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? songWorkId,
    Expression<String>? ownerId,
    Expression<String>? label,
    Expression<String>? visibility,
    Expression<String>? forkedFromVersionId,
    Expression<String>? sharedOrganizationIdsJson,
    Expression<bool>? isDirty,
    Expression<DateTime>? deletedAt,
    Expression<String>? remoteUpdatedAt,
    Expression<String>? accountId,
    Expression<int>? editedAtMs,
    Expression<bool>? sharingDirty,
    Expression<String>? songCreatorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (key != null) 'key': key,
      if (tempo != null) 'tempo': tempo,
      if (timeSignatureBeats != null)
        'time_signature_beats': timeSignatureBeats,
      if (timeSignatureBeatValue != null)
        'time_signature_beat_value': timeSignatureBeatValue,
      if (sectionsJson != null) 'sections_json': sectionsJson,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (coverImagePath != null) 'cover_image_path': coverImagePath,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (songWorkId != null) 'song_work_id': songWorkId,
      if (ownerId != null) 'owner_id': ownerId,
      if (label != null) 'label': label,
      if (visibility != null) 'visibility': visibility,
      if (forkedFromVersionId != null)
        'forked_from_version_id': forkedFromVersionId,
      if (sharedOrganizationIdsJson != null)
        'shared_organization_ids_json': sharedOrganizationIdsJson,
      if (isDirty != null) 'is_dirty': isDirty,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (accountId != null) 'account_id': accountId,
      if (editedAtMs != null) 'edited_at_ms': editedAtMs,
      if (sharingDirty != null) 'sharing_dirty': sharingDirty,
      if (songCreatorId != null) 'song_creator_id': songCreatorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SongsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? artist,
    Value<String>? key,
    Value<int>? tempo,
    Value<int>? timeSignatureBeats,
    Value<int>? timeSignatureBeatValue,
    Value<String>? sectionsJson,
    Value<String>? tagsJson,
    Value<String?>? coverImagePath,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? songWorkId,
    Value<String?>? ownerId,
    Value<String>? label,
    Value<String>? visibility,
    Value<String?>? forkedFromVersionId,
    Value<String>? sharedOrganizationIdsJson,
    Value<bool>? isDirty,
    Value<DateTime?>? deletedAt,
    Value<String?>? remoteUpdatedAt,
    Value<String?>? accountId,
    Value<int>? editedAtMs,
    Value<bool>? sharingDirty,
    Value<String?>? songCreatorId,
    Value<int>? rowid,
  }) {
    return SongsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      tempo: tempo ?? this.tempo,
      timeSignatureBeats: timeSignatureBeats ?? this.timeSignatureBeats,
      timeSignatureBeatValue:
          timeSignatureBeatValue ?? this.timeSignatureBeatValue,
      sectionsJson: sectionsJson ?? this.sectionsJson,
      tagsJson: tagsJson ?? this.tagsJson,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songWorkId: songWorkId ?? this.songWorkId,
      ownerId: ownerId ?? this.ownerId,
      label: label ?? this.label,
      visibility: visibility ?? this.visibility,
      forkedFromVersionId: forkedFromVersionId ?? this.forkedFromVersionId,
      sharedOrganizationIdsJson:
          sharedOrganizationIdsJson ?? this.sharedOrganizationIdsJson,
      isDirty: isDirty ?? this.isDirty,
      deletedAt: deletedAt ?? this.deletedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      accountId: accountId ?? this.accountId,
      editedAtMs: editedAtMs ?? this.editedAtMs,
      sharingDirty: sharingDirty ?? this.sharingDirty,
      songCreatorId: songCreatorId ?? this.songCreatorId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<int>(tempo.value);
    }
    if (timeSignatureBeats.present) {
      map['time_signature_beats'] = Variable<int>(timeSignatureBeats.value);
    }
    if (timeSignatureBeatValue.present) {
      map['time_signature_beat_value'] = Variable<int>(
        timeSignatureBeatValue.value,
      );
    }
    if (sectionsJson.present) {
      map['sections_json'] = Variable<String>(sectionsJson.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (coverImagePath.present) {
      map['cover_image_path'] = Variable<String>(coverImagePath.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (songWorkId.present) {
      map['song_work_id'] = Variable<String>(songWorkId.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (forkedFromVersionId.present) {
      map['forked_from_version_id'] = Variable<String>(
        forkedFromVersionId.value,
      );
    }
    if (sharedOrganizationIdsJson.present) {
      map['shared_organization_ids_json'] = Variable<String>(
        sharedOrganizationIdsJson.value,
      );
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (editedAtMs.present) {
      map['edited_at_ms'] = Variable<int>(editedAtMs.value);
    }
    if (sharingDirty.present) {
      map['sharing_dirty'] = Variable<bool>(sharingDirty.value);
    }
    if (songCreatorId.present) {
      map['song_creator_id'] = Variable<String>(songCreatorId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SongsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('key: $key, ')
          ..write('tempo: $tempo, ')
          ..write('timeSignatureBeats: $timeSignatureBeats, ')
          ..write('timeSignatureBeatValue: $timeSignatureBeatValue, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('coverImagePath: $coverImagePath, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('songWorkId: $songWorkId, ')
          ..write('ownerId: $ownerId, ')
          ..write('label: $label, ')
          ..write('visibility: $visibility, ')
          ..write('forkedFromVersionId: $forkedFromVersionId, ')
          ..write('sharedOrganizationIdsJson: $sharedOrganizationIdsJson, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('editedAtMs: $editedAtMs, ')
          ..write('sharingDirty: $sharingDirty, ')
          ..write('songCreatorId: $songCreatorId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetlistsTable extends Setlists
    with TableInfo<$SetlistsTable, SetlistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetlistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<DateTime> eventDate = GeneratedColumn<DateTime>(
    'event_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemsJsonMeta = const VerificationMeta(
    'itemsJson',
  );
  @override
  late final GeneratedColumn<String> itemsJson = GeneratedColumn<String>(
    'items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _organizationIdMeta = const VerificationMeta(
    'organizationId',
  );
  @override
  late final GeneratedColumn<String> organizationId = GeneratedColumn<String>(
    'organization_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMsMeta = const VerificationMeta(
    'editedAtMs',
  );
  @override
  late final GeneratedColumn<int> editedAtMs = GeneratedColumn<int>(
    'edited_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    eventDate,
    itemsJson,
    tagsJson,
    createdAt,
    updatedAt,
    organizationId,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    accountId,
    editedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'setlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetlistEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    }
    if (data.containsKey('items_json')) {
      context.handle(
        _itemsJsonMeta,
        itemsJson.isAcceptableOrUnknown(data['items_json']!, _itemsJsonMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('organization_id')) {
      context.handle(
        _organizationIdMeta,
        organizationId.isAcceptableOrUnknown(
          data['organization_id']!,
          _organizationIdMeta,
        ),
      );
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('edited_at_ms')) {
      context.handle(
        _editedAtMsMeta,
        editedAtMs.isAcceptableOrUnknown(
          data['edited_at_ms']!,
          _editedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetlistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetlistEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}event_date'],
      ),
      itemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}items_json'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      organizationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}organization_id'],
      ),
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_at'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      editedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at_ms'],
      )!,
    );
  }

  @override
  $SetlistsTable createAlias(String alias) {
    return $SetlistsTable(attachedDatabase, alias);
  }
}

class SetlistEntry extends DataClass implements Insertable<SetlistEntry> {
  final String id;
  final String title;
  final String? description;
  final DateTime? eventDate;
  final String itemsJson;
  final String tagsJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Null for a personal setlist.
  final String? organizationId;
  final bool isDirty;
  final DateTime? deletedAt;
  final String? remoteUpdatedAt;
  final String? accountId;

  /// See [Songs.editedAtMs].
  final int editedAtMs;
  const SetlistEntry({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    required this.itemsJson,
    required this.tagsJson,
    required this.createdAt,
    required this.updatedAt,
    this.organizationId,
    required this.isDirty,
    this.deletedAt,
    this.remoteUpdatedAt,
    this.accountId,
    required this.editedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || eventDate != null) {
      map['event_date'] = Variable<DateTime>(eventDate);
    }
    map['items_json'] = Variable<String>(itemsJson);
    map['tags_json'] = Variable<String>(tagsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || organizationId != null) {
      map['organization_id'] = Variable<String>(organizationId);
    }
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['edited_at_ms'] = Variable<int>(editedAtMs);
    return map;
  }

  SetlistsCompanion toCompanion(bool nullToAbsent) {
    return SetlistsCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      eventDate: eventDate == null && nullToAbsent
          ? const Value.absent()
          : Value(eventDate),
      itemsJson: Value(itemsJson),
      tagsJson: Value(tagsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      organizationId: organizationId == null && nullToAbsent
          ? const Value.absent()
          : Value(organizationId),
      isDirty: Value(isDirty),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      editedAtMs: Value(editedAtMs),
    );
  }

  factory SetlistEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetlistEntry(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      eventDate: serializer.fromJson<DateTime?>(json['eventDate']),
      itemsJson: serializer.fromJson<String>(json['itemsJson']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      organizationId: serializer.fromJson<String?>(json['organizationId']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      editedAtMs: serializer.fromJson<int>(json['editedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'eventDate': serializer.toJson<DateTime?>(eventDate),
      'itemsJson': serializer.toJson<String>(itemsJson),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'organizationId': serializer.toJson<String?>(organizationId),
      'isDirty': serializer.toJson<bool>(isDirty),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'accountId': serializer.toJson<String?>(accountId),
      'editedAtMs': serializer.toJson<int>(editedAtMs),
    };
  }

  SetlistEntry copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<DateTime?> eventDate = const Value.absent(),
    String? itemsJson,
    String? tagsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> organizationId = const Value.absent(),
    bool? isDirty,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> remoteUpdatedAt = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    int? editedAtMs,
  }) => SetlistEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    eventDate: eventDate.present ? eventDate.value : this.eventDate,
    itemsJson: itemsJson ?? this.itemsJson,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    organizationId: organizationId.present
        ? organizationId.value
        : this.organizationId,
    isDirty: isDirty ?? this.isDirty,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    accountId: accountId.present ? accountId.value : this.accountId,
    editedAtMs: editedAtMs ?? this.editedAtMs,
  );
  SetlistEntry copyWithCompanion(SetlistsCompanion data) {
    return SetlistEntry(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      itemsJson: data.itemsJson.present ? data.itemsJson.value : this.itemsJson,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      organizationId: data.organizationId.present
          ? data.organizationId.value
          : this.organizationId,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      editedAtMs: data.editedAtMs.present
          ? data.editedAtMs.value
          : this.editedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetlistEntry(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('organizationId: $organizationId, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('editedAtMs: $editedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    eventDate,
    itemsJson,
    tagsJson,
    createdAt,
    updatedAt,
    organizationId,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    accountId,
    editedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetlistEntry &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.eventDate == this.eventDate &&
          other.itemsJson == this.itemsJson &&
          other.tagsJson == this.tagsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.organizationId == this.organizationId &&
          other.isDirty == this.isDirty &&
          other.deletedAt == this.deletedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.accountId == this.accountId &&
          other.editedAtMs == this.editedAtMs);
}

class SetlistsCompanion extends UpdateCompanion<SetlistEntry> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime?> eventDate;
  final Value<String> itemsJson;
  final Value<String> tagsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> organizationId;
  final Value<bool> isDirty;
  final Value<DateTime?> deletedAt;
  final Value<String?> remoteUpdatedAt;
  final Value<String?> accountId;
  final Value<int> editedAtMs;
  final Value<int> rowid;
  const SetlistsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.organizationId = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetlistsCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.itemsJson = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.organizationId = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.accountId = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SetlistEntry> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? eventDate,
    Expression<String>? itemsJson,
    Expression<String>? tagsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? organizationId,
    Expression<bool>? isDirty,
    Expression<DateTime>? deletedAt,
    Expression<String>? remoteUpdatedAt,
    Expression<String>? accountId,
    Expression<int>? editedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (eventDate != null) 'event_date': eventDate,
      if (itemsJson != null) 'items_json': itemsJson,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (organizationId != null) 'organization_id': organizationId,
      if (isDirty != null) 'is_dirty': isDirty,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (accountId != null) 'account_id': accountId,
      if (editedAtMs != null) 'edited_at_ms': editedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetlistsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime?>? eventDate,
    Value<String>? itemsJson,
    Value<String>? tagsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? organizationId,
    Value<bool>? isDirty,
    Value<DateTime?>? deletedAt,
    Value<String?>? remoteUpdatedAt,
    Value<String?>? accountId,
    Value<int>? editedAtMs,
    Value<int>? rowid,
  }) {
    return SetlistsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      itemsJson: itemsJson ?? this.itemsJson,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      organizationId: organizationId ?? this.organizationId,
      isDirty: isDirty ?? this.isDirty,
      deletedAt: deletedAt ?? this.deletedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      accountId: accountId ?? this.accountId,
      editedAtMs: editedAtMs ?? this.editedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<DateTime>(eventDate.value);
    }
    if (itemsJson.present) {
      map['items_json'] = Variable<String>(itemsJson.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (organizationId.present) {
      map['organization_id'] = Variable<String>(organizationId.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (editedAtMs.present) {
      map['edited_at_ms'] = Variable<int>(editedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetlistsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('eventDate: $eventDate, ')
          ..write('itemsJson: $itemsJson, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('organizationId: $organizationId, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('accountId: $accountId, ')
          ..write('editedAtMs: $editedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScoresTable extends Scores with TableInfo<$ScoresTable, ScoreEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _songIdMeta = const VerificationMeta('songId');
  @override
  late final GeneratedColumn<String> songId = GeneratedColumn<String>(
    'song_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _composerMeta = const VerificationMeta(
    'composer',
  );
  @override
  late final GeneratedColumn<String> composer = GeneratedColumn<String>(
    'composer',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeSignatureJsonMeta = const VerificationMeta(
    'timeSignatureJson',
  );
  @override
  late final GeneratedColumn<String> timeSignatureJson =
      GeneratedColumn<String>(
        'time_signature_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _keySignatureMeta = const VerificationMeta(
    'keySignature',
  );
  @override
  late final GeneratedColumn<String> keySignature = GeneratedColumn<String>(
    'key_signature',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tempoMeta = const VerificationMeta('tempo');
  @override
  late final GeneratedColumn<int> tempo = GeneratedColumn<int>(
    'tempo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sectionsJsonMeta = const VerificationMeta(
    'sectionsJson',
  );
  @override
  late final GeneratedColumn<String> sectionsJson = GeneratedColumn<String>(
    'sections_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDirtyMeta = const VerificationMeta(
    'isDirty',
  );
  @override
  late final GeneratedColumn<bool> isDirty = GeneratedColumn<bool>(
    'is_dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dirty" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUpdatedAtMeta = const VerificationMeta(
    'remoteUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> remoteUpdatedAt = GeneratedColumn<String>(
    'remote_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMsMeta = const VerificationMeta(
    'editedAtMs',
  );
  @override
  late final GeneratedColumn<int> editedAtMs = GeneratedColumn<int>(
    'edited_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    songId,
    title,
    composer,
    artist,
    timeSignatureJson,
    keySignature,
    tempo,
    sectionsJson,
    metadataJson,
    updatedAt,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    editedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScoreEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('song_id')) {
      context.handle(
        _songIdMeta,
        songId.isAcceptableOrUnknown(data['song_id']!, _songIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('composer')) {
      context.handle(
        _composerMeta,
        composer.isAcceptableOrUnknown(data['composer']!, _composerMeta),
      );
    }
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('time_signature_json')) {
      context.handle(
        _timeSignatureJsonMeta,
        timeSignatureJson.isAcceptableOrUnknown(
          data['time_signature_json']!,
          _timeSignatureJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeSignatureJsonMeta);
    }
    if (data.containsKey('key_signature')) {
      context.handle(
        _keySignatureMeta,
        keySignature.isAcceptableOrUnknown(
          data['key_signature']!,
          _keySignatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keySignatureMeta);
    }
    if (data.containsKey('tempo')) {
      context.handle(
        _tempoMeta,
        tempo.isAcceptableOrUnknown(data['tempo']!, _tempoMeta),
      );
    } else if (isInserting) {
      context.missing(_tempoMeta);
    }
    if (data.containsKey('sections_json')) {
      context.handle(
        _sectionsJsonMeta,
        sectionsJson.isAcceptableOrUnknown(
          data['sections_json']!,
          _sectionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionsJsonMeta);
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_dirty')) {
      context.handle(
        _isDirtyMeta,
        isDirty.isAcceptableOrUnknown(data['is_dirty']!, _isDirtyMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('remote_updated_at')) {
      context.handle(
        _remoteUpdatedAtMeta,
        remoteUpdatedAt.isAcceptableOrUnknown(
          data['remote_updated_at']!,
          _remoteUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('edited_at_ms')) {
      context.handle(
        _editedAtMsMeta,
        editedAtMs.isAcceptableOrUnknown(
          data['edited_at_ms']!,
          _editedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScoreEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScoreEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      songId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}song_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      composer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}composer'],
      ),
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      timeSignatureJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_signature_json'],
      )!,
      keySignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key_signature'],
      )!,
      tempo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tempo'],
      )!,
      sectionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sections_json'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dirty'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      remoteUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_updated_at'],
      ),
      editedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at_ms'],
      )!,
    );
  }

  @override
  $ScoresTable createAlias(String alias) {
    return $ScoresTable(attachedDatabase, alias);
  }
}

class ScoreEntry extends DataClass implements Insertable<ScoreEntry> {
  final String id;
  final String? songId;
  final String title;
  final String? composer;
  final String? artist;
  final String timeSignatureJson;
  final String keySignature;
  final int tempo;
  final String sectionsJson;
  final String metadataJson;
  final DateTime updatedAt;
  final bool isDirty;
  final DateTime? deletedAt;
  final String? remoteUpdatedAt;

  /// See [Songs.editedAtMs].
  final int editedAtMs;
  const ScoreEntry({
    required this.id,
    this.songId,
    required this.title,
    this.composer,
    this.artist,
    required this.timeSignatureJson,
    required this.keySignature,
    required this.tempo,
    required this.sectionsJson,
    required this.metadataJson,
    required this.updatedAt,
    required this.isDirty,
    this.deletedAt,
    this.remoteUpdatedAt,
    required this.editedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || songId != null) {
      map['song_id'] = Variable<String>(songId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || composer != null) {
      map['composer'] = Variable<String>(composer);
    }
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    map['time_signature_json'] = Variable<String>(timeSignatureJson);
    map['key_signature'] = Variable<String>(keySignature);
    map['tempo'] = Variable<int>(tempo);
    map['sections_json'] = Variable<String>(sectionsJson);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_dirty'] = Variable<bool>(isDirty);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || remoteUpdatedAt != null) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt);
    }
    map['edited_at_ms'] = Variable<int>(editedAtMs);
    return map;
  }

  ScoresCompanion toCompanion(bool nullToAbsent) {
    return ScoresCompanion(
      id: Value(id),
      songId: songId == null && nullToAbsent
          ? const Value.absent()
          : Value(songId),
      title: Value(title),
      composer: composer == null && nullToAbsent
          ? const Value.absent()
          : Value(composer),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      timeSignatureJson: Value(timeSignatureJson),
      keySignature: Value(keySignature),
      tempo: Value(tempo),
      sectionsJson: Value(sectionsJson),
      metadataJson: Value(metadataJson),
      updatedAt: Value(updatedAt),
      isDirty: Value(isDirty),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      remoteUpdatedAt: remoteUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUpdatedAt),
      editedAtMs: Value(editedAtMs),
    );
  }

  factory ScoreEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScoreEntry(
      id: serializer.fromJson<String>(json['id']),
      songId: serializer.fromJson<String?>(json['songId']),
      title: serializer.fromJson<String>(json['title']),
      composer: serializer.fromJson<String?>(json['composer']),
      artist: serializer.fromJson<String?>(json['artist']),
      timeSignatureJson: serializer.fromJson<String>(json['timeSignatureJson']),
      keySignature: serializer.fromJson<String>(json['keySignature']),
      tempo: serializer.fromJson<int>(json['tempo']),
      sectionsJson: serializer.fromJson<String>(json['sectionsJson']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDirty: serializer.fromJson<bool>(json['isDirty']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      remoteUpdatedAt: serializer.fromJson<String?>(json['remoteUpdatedAt']),
      editedAtMs: serializer.fromJson<int>(json['editedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'songId': serializer.toJson<String?>(songId),
      'title': serializer.toJson<String>(title),
      'composer': serializer.toJson<String?>(composer),
      'artist': serializer.toJson<String?>(artist),
      'timeSignatureJson': serializer.toJson<String>(timeSignatureJson),
      'keySignature': serializer.toJson<String>(keySignature),
      'tempo': serializer.toJson<int>(tempo),
      'sectionsJson': serializer.toJson<String>(sectionsJson),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDirty': serializer.toJson<bool>(isDirty),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'remoteUpdatedAt': serializer.toJson<String?>(remoteUpdatedAt),
      'editedAtMs': serializer.toJson<int>(editedAtMs),
    };
  }

  ScoreEntry copyWith({
    String? id,
    Value<String?> songId = const Value.absent(),
    String? title,
    Value<String?> composer = const Value.absent(),
    Value<String?> artist = const Value.absent(),
    String? timeSignatureJson,
    String? keySignature,
    int? tempo,
    String? sectionsJson,
    String? metadataJson,
    DateTime? updatedAt,
    bool? isDirty,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> remoteUpdatedAt = const Value.absent(),
    int? editedAtMs,
  }) => ScoreEntry(
    id: id ?? this.id,
    songId: songId.present ? songId.value : this.songId,
    title: title ?? this.title,
    composer: composer.present ? composer.value : this.composer,
    artist: artist.present ? artist.value : this.artist,
    timeSignatureJson: timeSignatureJson ?? this.timeSignatureJson,
    keySignature: keySignature ?? this.keySignature,
    tempo: tempo ?? this.tempo,
    sectionsJson: sectionsJson ?? this.sectionsJson,
    metadataJson: metadataJson ?? this.metadataJson,
    updatedAt: updatedAt ?? this.updatedAt,
    isDirty: isDirty ?? this.isDirty,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    remoteUpdatedAt: remoteUpdatedAt.present
        ? remoteUpdatedAt.value
        : this.remoteUpdatedAt,
    editedAtMs: editedAtMs ?? this.editedAtMs,
  );
  ScoreEntry copyWithCompanion(ScoresCompanion data) {
    return ScoreEntry(
      id: data.id.present ? data.id.value : this.id,
      songId: data.songId.present ? data.songId.value : this.songId,
      title: data.title.present ? data.title.value : this.title,
      composer: data.composer.present ? data.composer.value : this.composer,
      artist: data.artist.present ? data.artist.value : this.artist,
      timeSignatureJson: data.timeSignatureJson.present
          ? data.timeSignatureJson.value
          : this.timeSignatureJson,
      keySignature: data.keySignature.present
          ? data.keySignature.value
          : this.keySignature,
      tempo: data.tempo.present ? data.tempo.value : this.tempo,
      sectionsJson: data.sectionsJson.present
          ? data.sectionsJson.value
          : this.sectionsJson,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDirty: data.isDirty.present ? data.isDirty.value : this.isDirty,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      remoteUpdatedAt: data.remoteUpdatedAt.present
          ? data.remoteUpdatedAt.value
          : this.remoteUpdatedAt,
      editedAtMs: data.editedAtMs.present
          ? data.editedAtMs.value
          : this.editedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScoreEntry(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('artist: $artist, ')
          ..write('timeSignatureJson: $timeSignatureJson, ')
          ..write('keySignature: $keySignature, ')
          ..write('tempo: $tempo, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('editedAtMs: $editedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    songId,
    title,
    composer,
    artist,
    timeSignatureJson,
    keySignature,
    tempo,
    sectionsJson,
    metadataJson,
    updatedAt,
    isDirty,
    deletedAt,
    remoteUpdatedAt,
    editedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScoreEntry &&
          other.id == this.id &&
          other.songId == this.songId &&
          other.title == this.title &&
          other.composer == this.composer &&
          other.artist == this.artist &&
          other.timeSignatureJson == this.timeSignatureJson &&
          other.keySignature == this.keySignature &&
          other.tempo == this.tempo &&
          other.sectionsJson == this.sectionsJson &&
          other.metadataJson == this.metadataJson &&
          other.updatedAt == this.updatedAt &&
          other.isDirty == this.isDirty &&
          other.deletedAt == this.deletedAt &&
          other.remoteUpdatedAt == this.remoteUpdatedAt &&
          other.editedAtMs == this.editedAtMs);
}

class ScoresCompanion extends UpdateCompanion<ScoreEntry> {
  final Value<String> id;
  final Value<String?> songId;
  final Value<String> title;
  final Value<String?> composer;
  final Value<String?> artist;
  final Value<String> timeSignatureJson;
  final Value<String> keySignature;
  final Value<int> tempo;
  final Value<String> sectionsJson;
  final Value<String> metadataJson;
  final Value<DateTime> updatedAt;
  final Value<bool> isDirty;
  final Value<DateTime?> deletedAt;
  final Value<String?> remoteUpdatedAt;
  final Value<int> editedAtMs;
  final Value<int> rowid;
  const ScoresCompanion({
    this.id = const Value.absent(),
    this.songId = const Value.absent(),
    this.title = const Value.absent(),
    this.composer = const Value.absent(),
    this.artist = const Value.absent(),
    this.timeSignatureJson = const Value.absent(),
    this.keySignature = const Value.absent(),
    this.tempo = const Value.absent(),
    this.sectionsJson = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScoresCompanion.insert({
    required String id,
    this.songId = const Value.absent(),
    required String title,
    this.composer = const Value.absent(),
    this.artist = const Value.absent(),
    required String timeSignatureJson,
    required String keySignature,
    required int tempo,
    required String sectionsJson,
    this.metadataJson = const Value.absent(),
    required DateTime updatedAt,
    this.isDirty = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.remoteUpdatedAt = const Value.absent(),
    this.editedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       timeSignatureJson = Value(timeSignatureJson),
       keySignature = Value(keySignature),
       tempo = Value(tempo),
       sectionsJson = Value(sectionsJson),
       updatedAt = Value(updatedAt);
  static Insertable<ScoreEntry> custom({
    Expression<String>? id,
    Expression<String>? songId,
    Expression<String>? title,
    Expression<String>? composer,
    Expression<String>? artist,
    Expression<String>? timeSignatureJson,
    Expression<String>? keySignature,
    Expression<int>? tempo,
    Expression<String>? sectionsJson,
    Expression<String>? metadataJson,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDirty,
    Expression<DateTime>? deletedAt,
    Expression<String>? remoteUpdatedAt,
    Expression<int>? editedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (songId != null) 'song_id': songId,
      if (title != null) 'title': title,
      if (composer != null) 'composer': composer,
      if (artist != null) 'artist': artist,
      if (timeSignatureJson != null) 'time_signature_json': timeSignatureJson,
      if (keySignature != null) 'key_signature': keySignature,
      if (tempo != null) 'tempo': tempo,
      if (sectionsJson != null) 'sections_json': sectionsJson,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDirty != null) 'is_dirty': isDirty,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (remoteUpdatedAt != null) 'remote_updated_at': remoteUpdatedAt,
      if (editedAtMs != null) 'edited_at_ms': editedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScoresCompanion copyWith({
    Value<String>? id,
    Value<String?>? songId,
    Value<String>? title,
    Value<String?>? composer,
    Value<String?>? artist,
    Value<String>? timeSignatureJson,
    Value<String>? keySignature,
    Value<int>? tempo,
    Value<String>? sectionsJson,
    Value<String>? metadataJson,
    Value<DateTime>? updatedAt,
    Value<bool>? isDirty,
    Value<DateTime?>? deletedAt,
    Value<String?>? remoteUpdatedAt,
    Value<int>? editedAtMs,
    Value<int>? rowid,
  }) {
    return ScoresCompanion(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      title: title ?? this.title,
      composer: composer ?? this.composer,
      artist: artist ?? this.artist,
      timeSignatureJson: timeSignatureJson ?? this.timeSignatureJson,
      keySignature: keySignature ?? this.keySignature,
      tempo: tempo ?? this.tempo,
      sectionsJson: sectionsJson ?? this.sectionsJson,
      metadataJson: metadataJson ?? this.metadataJson,
      updatedAt: updatedAt ?? this.updatedAt,
      isDirty: isDirty ?? this.isDirty,
      deletedAt: deletedAt ?? this.deletedAt,
      remoteUpdatedAt: remoteUpdatedAt ?? this.remoteUpdatedAt,
      editedAtMs: editedAtMs ?? this.editedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (songId.present) {
      map['song_id'] = Variable<String>(songId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (composer.present) {
      map['composer'] = Variable<String>(composer.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (timeSignatureJson.present) {
      map['time_signature_json'] = Variable<String>(timeSignatureJson.value);
    }
    if (keySignature.present) {
      map['key_signature'] = Variable<String>(keySignature.value);
    }
    if (tempo.present) {
      map['tempo'] = Variable<int>(tempo.value);
    }
    if (sectionsJson.present) {
      map['sections_json'] = Variable<String>(sectionsJson.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDirty.present) {
      map['is_dirty'] = Variable<bool>(isDirty.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (remoteUpdatedAt.present) {
      map['remote_updated_at'] = Variable<String>(remoteUpdatedAt.value);
    }
    if (editedAtMs.present) {
      map['edited_at_ms'] = Variable<int>(editedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScoresCompanion(')
          ..write('id: $id, ')
          ..write('songId: $songId, ')
          ..write('title: $title, ')
          ..write('composer: $composer, ')
          ..write('artist: $artist, ')
          ..write('timeSignatureJson: $timeSignatureJson, ')
          ..write('keySignature: $keySignature, ')
          ..write('tempo: $tempo, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDirty: $isDirty, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('remoteUpdatedAt: $remoteUpdatedAt, ')
          ..write('editedAtMs: $editedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheRecordsTable extends CacheRecords
    with TableInfo<$CacheRecordsTable, CacheRecordEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordKindMeta = const VerificationMeta(
    'recordKind',
  );
  @override
  late final GeneratedColumn<String> recordKind = GeneratedColumn<String>(
    'record_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    recordKind,
    recordId,
    scopeId,
    json,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheRecordEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('record_kind')) {
      context.handle(
        _recordKindMeta,
        recordKind.isAcceptableOrUnknown(data['record_kind']!, _recordKindMeta),
      );
    } else if (isInserting) {
      context.missing(_recordKindMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, recordKind, recordId};
  @override
  CacheRecordEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheRecordEntry(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      recordKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_kind'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
    );
  }

  @override
  $CacheRecordsTable createAlias(String alias) {
    return $CacheRecordsTable(attachedDatabase, alias);
  }
}

class CacheRecordEntry extends DataClass
    implements Insertable<CacheRecordEntry> {
  final String accountId;
  final String recordKind;
  final String recordId;
  final String scopeId;
  final String json;
  const CacheRecordEntry({
    required this.accountId,
    required this.recordKind,
    required this.recordId,
    required this.scopeId,
    required this.json,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['record_kind'] = Variable<String>(recordKind);
    map['record_id'] = Variable<String>(recordId);
    map['scope_id'] = Variable<String>(scopeId);
    map['json'] = Variable<String>(json);
    return map;
  }

  CacheRecordsCompanion toCompanion(bool nullToAbsent) {
    return CacheRecordsCompanion(
      accountId: Value(accountId),
      recordKind: Value(recordKind),
      recordId: Value(recordId),
      scopeId: Value(scopeId),
      json: Value(json),
    );
  }

  factory CacheRecordEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheRecordEntry(
      accountId: serializer.fromJson<String>(json['accountId']),
      recordKind: serializer.fromJson<String>(json['recordKind']),
      recordId: serializer.fromJson<String>(json['recordId']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      json: serializer.fromJson<String>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'recordKind': serializer.toJson<String>(recordKind),
      'recordId': serializer.toJson<String>(recordId),
      'scopeId': serializer.toJson<String>(scopeId),
      'json': serializer.toJson<String>(json),
    };
  }

  CacheRecordEntry copyWith({
    String? accountId,
    String? recordKind,
    String? recordId,
    String? scopeId,
    String? json,
  }) => CacheRecordEntry(
    accountId: accountId ?? this.accountId,
    recordKind: recordKind ?? this.recordKind,
    recordId: recordId ?? this.recordId,
    scopeId: scopeId ?? this.scopeId,
    json: json ?? this.json,
  );
  CacheRecordEntry copyWithCompanion(CacheRecordsCompanion data) {
    return CacheRecordEntry(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recordKind: data.recordKind.present
          ? data.recordKind.value
          : this.recordKind,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheRecordEntry(')
          ..write('accountId: $accountId, ')
          ..write('recordKind: $recordKind, ')
          ..write('recordId: $recordId, ')
          ..write('scopeId: $scopeId, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, recordKind, recordId, scopeId, json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheRecordEntry &&
          other.accountId == this.accountId &&
          other.recordKind == this.recordKind &&
          other.recordId == this.recordId &&
          other.scopeId == this.scopeId &&
          other.json == this.json);
}

class CacheRecordsCompanion extends UpdateCompanion<CacheRecordEntry> {
  final Value<String> accountId;
  final Value<String> recordKind;
  final Value<String> recordId;
  final Value<String> scopeId;
  final Value<String> json;
  final Value<int> rowid;
  const CacheRecordsCompanion({
    this.accountId = const Value.absent(),
    this.recordKind = const Value.absent(),
    this.recordId = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.json = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheRecordsCompanion.insert({
    required String accountId,
    required String recordKind,
    required String recordId,
    this.scopeId = const Value.absent(),
    required String json,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       recordKind = Value(recordKind),
       recordId = Value(recordId),
       json = Value(json);
  static Insertable<CacheRecordEntry> custom({
    Expression<String>? accountId,
    Expression<String>? recordKind,
    Expression<String>? recordId,
    Expression<String>? scopeId,
    Expression<String>? json,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (recordKind != null) 'record_kind': recordKind,
      if (recordId != null) 'record_id': recordId,
      if (scopeId != null) 'scope_id': scopeId,
      if (json != null) 'json': json,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheRecordsCompanion copyWith({
    Value<String>? accountId,
    Value<String>? recordKind,
    Value<String>? recordId,
    Value<String>? scopeId,
    Value<String>? json,
    Value<int>? rowid,
  }) {
    return CacheRecordsCompanion(
      accountId: accountId ?? this.accountId,
      recordKind: recordKind ?? this.recordKind,
      recordId: recordId ?? this.recordId,
      scopeId: scopeId ?? this.scopeId,
      json: json ?? this.json,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recordKind.present) {
      map['record_kind'] = Variable<String>(recordKind.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheRecordsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('recordKind: $recordKind, ')
          ..write('recordId: $recordId, ')
          ..write('scopeId: $scopeId, ')
          ..write('json: $json, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheRefreshesTable extends CacheRefreshes
    with TableInfo<$CacheRefreshesTable, CacheRefreshEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheRefreshesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordKindMeta = const VerificationMeta(
    'recordKind',
  );
  @override
  late final GeneratedColumn<String> recordKind = GeneratedColumn<String>(
    'record_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeIdMeta = const VerificationMeta(
    'scopeId',
  );
  @override
  late final GeneratedColumn<String> scopeId = GeneratedColumn<String>(
    'scope_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _refreshedAtMeta = const VerificationMeta(
    'refreshedAt',
  );
  @override
  late final GeneratedColumn<DateTime> refreshedAt = GeneratedColumn<DateTime>(
    'refreshed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    recordKind,
    scopeId,
    refreshedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_refreshes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheRefreshEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('record_kind')) {
      context.handle(
        _recordKindMeta,
        recordKind.isAcceptableOrUnknown(data['record_kind']!, _recordKindMeta),
      );
    } else if (isInserting) {
      context.missing(_recordKindMeta);
    }
    if (data.containsKey('scope_id')) {
      context.handle(
        _scopeIdMeta,
        scopeId.isAcceptableOrUnknown(data['scope_id']!, _scopeIdMeta),
      );
    }
    if (data.containsKey('refreshed_at')) {
      context.handle(
        _refreshedAtMeta,
        refreshedAt.isAcceptableOrUnknown(
          data['refreshed_at']!,
          _refreshedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, recordKind, scopeId};
  @override
  CacheRefreshEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheRefreshEntry(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      recordKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_kind'],
      )!,
      scopeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_id'],
      )!,
      refreshedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refreshed_at'],
      )!,
    );
  }

  @override
  $CacheRefreshesTable createAlias(String alias) {
    return $CacheRefreshesTable(attachedDatabase, alias);
  }
}

class CacheRefreshEntry extends DataClass
    implements Insertable<CacheRefreshEntry> {
  final String accountId;
  final String recordKind;
  final String scopeId;
  final DateTime refreshedAt;
  const CacheRefreshEntry({
    required this.accountId,
    required this.recordKind,
    required this.scopeId,
    required this.refreshedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['record_kind'] = Variable<String>(recordKind);
    map['scope_id'] = Variable<String>(scopeId);
    map['refreshed_at'] = Variable<DateTime>(refreshedAt);
    return map;
  }

  CacheRefreshesCompanion toCompanion(bool nullToAbsent) {
    return CacheRefreshesCompanion(
      accountId: Value(accountId),
      recordKind: Value(recordKind),
      scopeId: Value(scopeId),
      refreshedAt: Value(refreshedAt),
    );
  }

  factory CacheRefreshEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheRefreshEntry(
      accountId: serializer.fromJson<String>(json['accountId']),
      recordKind: serializer.fromJson<String>(json['recordKind']),
      scopeId: serializer.fromJson<String>(json['scopeId']),
      refreshedAt: serializer.fromJson<DateTime>(json['refreshedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'recordKind': serializer.toJson<String>(recordKind),
      'scopeId': serializer.toJson<String>(scopeId),
      'refreshedAt': serializer.toJson<DateTime>(refreshedAt),
    };
  }

  CacheRefreshEntry copyWith({
    String? accountId,
    String? recordKind,
    String? scopeId,
    DateTime? refreshedAt,
  }) => CacheRefreshEntry(
    accountId: accountId ?? this.accountId,
    recordKind: recordKind ?? this.recordKind,
    scopeId: scopeId ?? this.scopeId,
    refreshedAt: refreshedAt ?? this.refreshedAt,
  );
  CacheRefreshEntry copyWithCompanion(CacheRefreshesCompanion data) {
    return CacheRefreshEntry(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recordKind: data.recordKind.present
          ? data.recordKind.value
          : this.recordKind,
      scopeId: data.scopeId.present ? data.scopeId.value : this.scopeId,
      refreshedAt: data.refreshedAt.present
          ? data.refreshedAt.value
          : this.refreshedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheRefreshEntry(')
          ..write('accountId: $accountId, ')
          ..write('recordKind: $recordKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('refreshedAt: $refreshedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(accountId, recordKind, scopeId, refreshedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheRefreshEntry &&
          other.accountId == this.accountId &&
          other.recordKind == this.recordKind &&
          other.scopeId == this.scopeId &&
          other.refreshedAt == this.refreshedAt);
}

class CacheRefreshesCompanion extends UpdateCompanion<CacheRefreshEntry> {
  final Value<String> accountId;
  final Value<String> recordKind;
  final Value<String> scopeId;
  final Value<DateTime> refreshedAt;
  final Value<int> rowid;
  const CacheRefreshesCompanion({
    this.accountId = const Value.absent(),
    this.recordKind = const Value.absent(),
    this.scopeId = const Value.absent(),
    this.refreshedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheRefreshesCompanion.insert({
    required String accountId,
    required String recordKind,
    this.scopeId = const Value.absent(),
    required DateTime refreshedAt,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       recordKind = Value(recordKind),
       refreshedAt = Value(refreshedAt);
  static Insertable<CacheRefreshEntry> custom({
    Expression<String>? accountId,
    Expression<String>? recordKind,
    Expression<String>? scopeId,
    Expression<DateTime>? refreshedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (recordKind != null) 'record_kind': recordKind,
      if (scopeId != null) 'scope_id': scopeId,
      if (refreshedAt != null) 'refreshed_at': refreshedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheRefreshesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? recordKind,
    Value<String>? scopeId,
    Value<DateTime>? refreshedAt,
    Value<int>? rowid,
  }) {
    return CacheRefreshesCompanion(
      accountId: accountId ?? this.accountId,
      recordKind: recordKind ?? this.recordKind,
      scopeId: scopeId ?? this.scopeId,
      refreshedAt: refreshedAt ?? this.refreshedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recordKind.present) {
      map['record_kind'] = Variable<String>(recordKind.value);
    }
    if (scopeId.present) {
      map['scope_id'] = Variable<String>(scopeId.value);
    }
    if (refreshedAt.present) {
      map['refreshed_at'] = Variable<DateTime>(refreshedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheRefreshesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('recordKind: $recordKind, ')
          ..write('scopeId: $scopeId, ')
          ..write('refreshedAt: $refreshedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SongsTable songs = $SongsTable(this);
  late final $SetlistsTable setlists = $SetlistsTable(this);
  late final $ScoresTable scores = $ScoresTable(this);
  late final $CacheRecordsTable cacheRecords = $CacheRecordsTable(this);
  late final $CacheRefreshesTable cacheRefreshes = $CacheRefreshesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    songs,
    setlists,
    scores,
    cacheRecords,
    cacheRefreshes,
  ];
}

typedef $$SongsTableCreateCompanionBuilder = SongsCompanion Function({
  required String id,
  required String title,
  required String artist,
  required String key,
  required int tempo,
  Value<int> timeSignatureBeats,
  Value<int> timeSignatureBeatValue,
  Value<String> sectionsJson,
  Value<String> tagsJson,
  Value<String?> coverImagePath,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> songWorkId,
  Value<String?> ownerId,
  Value<String> label,
  Value<String> visibility,
  Value<String?> forkedFromVersionId,
  Value<String> sharedOrganizationIdsJson,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<String?> accountId,
  Value<int> editedAtMs,
  Value<bool> sharingDirty,
  Value<String?> songCreatorId,
  Value<int> rowid,
});
typedef $$SongsTableUpdateCompanionBuilder = SongsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> artist,
  Value<String> key,
  Value<int> tempo,
  Value<int> timeSignatureBeats,
  Value<int> timeSignatureBeatValue,
  Value<String> sectionsJson,
  Value<String> tagsJson,
  Value<String?> coverImagePath,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> songWorkId,
  Value<String?> ownerId,
  Value<String> label,
  Value<String> visibility,
  Value<String?> forkedFromVersionId,
  Value<String> sharedOrganizationIdsJson,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<String?> accountId,
  Value<int> editedAtMs,
  Value<bool> sharingDirty,
  Value<String?> songCreatorId,
  Value<int> rowid,
});

class $$SongsTableFilterComposer extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSignatureBeats => $composableBuilder(
    column: $table.timeSignatureBeats,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeSignatureBeatValue => $composableBuilder(
    column: $table.timeSignatureBeatValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songWorkId => $composableBuilder(
    column: $table.songWorkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get forkedFromVersionId => $composableBuilder(
    column: $table.forkedFromVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedOrganizationIdsJson => $composableBuilder(
    column: $table.sharedOrganizationIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sharingDirty => $composableBuilder(
    column: $table.sharingDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songCreatorId => $composableBuilder(
    column: $table.songCreatorId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SongsTableOrderingComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSignatureBeats => $composableBuilder(
    column: $table.timeSignatureBeats,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeSignatureBeatValue => $composableBuilder(
    column: $table.timeSignatureBeatValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songWorkId => $composableBuilder(
    column: $table.songWorkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get forkedFromVersionId => $composableBuilder(
    column: $table.forkedFromVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedOrganizationIdsJson => $composableBuilder(
    column: $table.sharedOrganizationIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sharingDirty => $composableBuilder(
    column: $table.sharingDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songCreatorId => $composableBuilder(
    column: $table.songCreatorId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SongsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SongsTable> {
  $$SongsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<int> get timeSignatureBeats => $composableBuilder(
    column: $table.timeSignatureBeats,
    builder: (column) => column,
  );

  GeneratedColumn<int> get timeSignatureBeatValue => $composableBuilder(
    column: $table.timeSignatureBeatValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get coverImagePath => $composableBuilder(
    column: $table.coverImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get songWorkId => $composableBuilder(
    column: $table.songWorkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
    column: $table.visibility,
    builder: (column) => column,
  );

  GeneratedColumn<String> get forkedFromVersionId => $composableBuilder(
    column: $table.forkedFromVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedOrganizationIdsJson => $composableBuilder(
    column: $table.sharedOrganizationIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sharingDirty => $composableBuilder(
    column: $table.sharingDirty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get songCreatorId => $composableBuilder(
    column: $table.songCreatorId,
    builder: (column) => column,
  );
}

class $$SongsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SongsTable,
          SongEntry,
          $$SongsTableFilterComposer,
          $$SongsTableOrderingComposer,
          $$SongsTableAnnotationComposer,
          $$SongsTableCreateCompanionBuilder,
          $$SongsTableUpdateCompanionBuilder,
          (SongEntry, BaseReferences<_$AppDatabase, $SongsTable, SongEntry>),
          SongEntry,
          PrefetchHooks Function()
        > {
  $$SongsTableTableManager(_$AppDatabase db, $SongsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SongsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SongsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SongsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> artist = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<int> tempo = const Value.absent(),
                Value<int> timeSignatureBeats = const Value.absent(),
                Value<int> timeSignatureBeatValue = const Value.absent(),
                Value<String> sectionsJson = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> songWorkId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String?> forkedFromVersionId = const Value.absent(),
                Value<String> sharedOrganizationIdsJson = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<bool> sharingDirty = const Value.absent(),
                Value<String?> songCreatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion(
                id: id,
                title: title,
                artist: artist,
                key: key,
                tempo: tempo,
                timeSignatureBeats: timeSignatureBeats,
                timeSignatureBeatValue: timeSignatureBeatValue,
                sectionsJson: sectionsJson,
                tagsJson: tagsJson,
                coverImagePath: coverImagePath,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                songWorkId: songWorkId,
                ownerId: ownerId,
                label: label,
                visibility: visibility,
                forkedFromVersionId: forkedFromVersionId,
                sharedOrganizationIdsJson: sharedOrganizationIdsJson,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                accountId: accountId,
                editedAtMs: editedAtMs,
                sharingDirty: sharingDirty,
                songCreatorId: songCreatorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String artist,
                required String key,
                required int tempo,
                Value<int> timeSignatureBeats = const Value.absent(),
                Value<int> timeSignatureBeatValue = const Value.absent(),
                Value<String> sectionsJson = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> coverImagePath = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> songWorkId = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> visibility = const Value.absent(),
                Value<String?> forkedFromVersionId = const Value.absent(),
                Value<String> sharedOrganizationIdsJson = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<bool> sharingDirty = const Value.absent(),
                Value<String?> songCreatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SongsCompanion.insert(
                id: id,
                title: title,
                artist: artist,
                key: key,
                tempo: tempo,
                timeSignatureBeats: timeSignatureBeats,
                timeSignatureBeatValue: timeSignatureBeatValue,
                sectionsJson: sectionsJson,
                tagsJson: tagsJson,
                coverImagePath: coverImagePath,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                songWorkId: songWorkId,
                ownerId: ownerId,
                label: label,
                visibility: visibility,
                forkedFromVersionId: forkedFromVersionId,
                sharedOrganizationIdsJson: sharedOrganizationIdsJson,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                accountId: accountId,
                editedAtMs: editedAtMs,
                sharingDirty: sharingDirty,
                songCreatorId: songCreatorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SongsTable, SongEntry>(table),
                  BaseReferences<_$AppDatabase, $SongsTable, SongEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SongsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SongsTable,
      SongEntry,
      $$SongsTableFilterComposer,
      $$SongsTableOrderingComposer,
      $$SongsTableAnnotationComposer,
      $$SongsTableCreateCompanionBuilder,
      $$SongsTableUpdateCompanionBuilder,
      (SongEntry, BaseReferences<_$AppDatabase, $SongsTable, SongEntry>),
      SongEntry,
      PrefetchHooks Function()
    >;
typedef $$SetlistsTableCreateCompanionBuilder = SetlistsCompanion Function({
  required String id,
  required String title,
  Value<String?> description,
  Value<DateTime?> eventDate,
  Value<String> itemsJson,
  Value<String> tagsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String?> organizationId,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<String?> accountId,
  Value<int> editedAtMs,
  Value<int> rowid,
});
typedef $$SetlistsTableUpdateCompanionBuilder = SetlistsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> description,
  Value<DateTime?> eventDate,
  Value<String> itemsJson,
  Value<String> tagsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String?> organizationId,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<String?> accountId,
  Value<int> editedAtMs,
  Value<int> rowid,
});

class $$SetlistsTableFilterComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SetlistsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemsJson => $composableBuilder(
    column: $table.itemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetlistsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetlistsTable> {
  $$SetlistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get itemsJson =>
      $composableBuilder(column: $table.itemsJson, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get organizationId => $composableBuilder(
    column: $table.organizationId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => column,
  );
}

class $$SetlistsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetlistsTable,
          SetlistEntry,
          $$SetlistsTableFilterComposer,
          $$SetlistsTableOrderingComposer,
          $$SetlistsTableAnnotationComposer,
          $$SetlistsTableCreateCompanionBuilder,
          $$SetlistsTableUpdateCompanionBuilder,
          (
            SetlistEntry,
            BaseReferences<_$AppDatabase, $SetlistsTable, SetlistEntry>,
          ),
          SetlistEntry,
          PrefetchHooks Function()
        > {
  $$SetlistsTableTableManager(_$AppDatabase db, $SetlistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetlistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetlistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetlistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> eventDate = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> organizationId = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion(
                id: id,
                title: title,
                description: description,
                eventDate: eventDate,
                itemsJson: itemsJson,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                organizationId: organizationId,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                accountId: accountId,
                editedAtMs: editedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<DateTime?> eventDate = const Value.absent(),
                Value<String> itemsJson = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> organizationId = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetlistsCompanion.insert(
                id: id,
                title: title,
                description: description,
                eventDate: eventDate,
                itemsJson: itemsJson,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                organizationId: organizationId,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                accountId: accountId,
                editedAtMs: editedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SetlistsTable, SetlistEntry>(table),
                  BaseReferences<_$AppDatabase, $SetlistsTable, SetlistEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SetlistsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetlistsTable,
      SetlistEntry,
      $$SetlistsTableFilterComposer,
      $$SetlistsTableOrderingComposer,
      $$SetlistsTableAnnotationComposer,
      $$SetlistsTableCreateCompanionBuilder,
      $$SetlistsTableUpdateCompanionBuilder,
      (
        SetlistEntry,
        BaseReferences<_$AppDatabase, $SetlistsTable, SetlistEntry>,
      ),
      SetlistEntry,
      PrefetchHooks Function()
    >;
typedef $$ScoresTableCreateCompanionBuilder = ScoresCompanion Function({
  required String id,
  Value<String?> songId,
  required String title,
  Value<String?> composer,
  Value<String?> artist,
  required String timeSignatureJson,
  required String keySignature,
  required int tempo,
  required String sectionsJson,
  Value<String> metadataJson,
  required DateTime updatedAt,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<int> editedAtMs,
  Value<int> rowid,
});
typedef $$ScoresTableUpdateCompanionBuilder = ScoresCompanion Function({
  Value<String> id,
  Value<String?> songId,
  Value<String> title,
  Value<String?> composer,
  Value<String?> artist,
  Value<String> timeSignatureJson,
  Value<String> keySignature,
  Value<int> tempo,
  Value<String> sectionsJson,
  Value<String> metadataJson,
  Value<DateTime> updatedAt,
  Value<bool> isDirty,
  Value<DateTime?> deletedAt,
  Value<String?> remoteUpdatedAt,
  Value<int> editedAtMs,
  Value<int> rowid,
});

class $$ScoresTableFilterComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSignatureJson => $composableBuilder(
    column: $table.timeSignatureJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keySignature => $composableBuilder(
    column: $table.keySignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get songId => $composableBuilder(
    column: $table.songId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get composer => $composableBuilder(
    column: $table.composer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artist => $composableBuilder(
    column: $table.artist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSignatureJson => $composableBuilder(
    column: $table.timeSignatureJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keySignature => $composableBuilder(
    column: $table.keySignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tempo => $composableBuilder(
    column: $table.tempo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDirty => $composableBuilder(
    column: $table.isDirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScoresTable> {
  $$ScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get songId =>
      $composableBuilder(column: $table.songId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get composer =>
      $composableBuilder(column: $table.composer, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get timeSignatureJson => $composableBuilder(
    column: $table.timeSignatureJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keySignature => $composableBuilder(
    column: $table.keySignature,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tempo =>
      $composableBuilder(column: $table.tempo, builder: (column) => column);

  GeneratedColumn<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDirty =>
      $composableBuilder(column: $table.isDirty, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get remoteUpdatedAt => $composableBuilder(
    column: $table.remoteUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get editedAtMs => $composableBuilder(
    column: $table.editedAtMs,
    builder: (column) => column,
  );
}

class $$ScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScoresTable,
          ScoreEntry,
          $$ScoresTableFilterComposer,
          $$ScoresTableOrderingComposer,
          $$ScoresTableAnnotationComposer,
          $$ScoresTableCreateCompanionBuilder,
          $$ScoresTableUpdateCompanionBuilder,
          (ScoreEntry, BaseReferences<_$AppDatabase, $ScoresTable, ScoreEntry>),
          ScoreEntry,
          PrefetchHooks Function()
        > {
  $$ScoresTableTableManager(_$AppDatabase db, $ScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> songId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> composer = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String> timeSignatureJson = const Value.absent(),
                Value<String> keySignature = const Value.absent(),
                Value<int> tempo = const Value.absent(),
                Value<String> sectionsJson = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion(
                id: id,
                songId: songId,
                title: title,
                composer: composer,
                artist: artist,
                timeSignatureJson: timeSignatureJson,
                keySignature: keySignature,
                tempo: tempo,
                sectionsJson: sectionsJson,
                metadataJson: metadataJson,
                updatedAt: updatedAt,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                editedAtMs: editedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> songId = const Value.absent(),
                required String title,
                Value<String?> composer = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                required String timeSignatureJson,
                required String keySignature,
                required int tempo,
                required String sectionsJson,
                Value<String> metadataJson = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> isDirty = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> remoteUpdatedAt = const Value.absent(),
                Value<int> editedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScoresCompanion.insert(
                id: id,
                songId: songId,
                title: title,
                composer: composer,
                artist: artist,
                timeSignatureJson: timeSignatureJson,
                keySignature: keySignature,
                tempo: tempo,
                sectionsJson: sectionsJson,
                metadataJson: metadataJson,
                updatedAt: updatedAt,
                isDirty: isDirty,
                deletedAt: deletedAt,
                remoteUpdatedAt: remoteUpdatedAt,
                editedAtMs: editedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ScoresTable, ScoreEntry>(table),
                  BaseReferences<_$AppDatabase, $ScoresTable, ScoreEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScoresTable,
      ScoreEntry,
      $$ScoresTableFilterComposer,
      $$ScoresTableOrderingComposer,
      $$ScoresTableAnnotationComposer,
      $$ScoresTableCreateCompanionBuilder,
      $$ScoresTableUpdateCompanionBuilder,
      (ScoreEntry, BaseReferences<_$AppDatabase, $ScoresTable, ScoreEntry>),
      ScoreEntry,
      PrefetchHooks Function()
    >;
typedef $$CacheRecordsTableCreateCompanionBuilder =
    CacheRecordsCompanion Function({
      required String accountId,
      required String recordKind,
      required String recordId,
      Value<String> scopeId,
      required String json,
      Value<int> rowid,
    });
typedef $$CacheRecordsTableUpdateCompanionBuilder =
    CacheRecordsCompanion Function({
      Value<String> accountId,
      Value<String> recordKind,
      Value<String> recordId,
      Value<String> scopeId,
      Value<String> json,
      Value<int> rowid,
    });

class $$CacheRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $CacheRecordsTable> {
  $$CacheRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheRecordsTable> {
  $$CacheRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheRecordsTable> {
  $$CacheRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);
}

class $$CacheRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheRecordsTable,
          CacheRecordEntry,
          $$CacheRecordsTableFilterComposer,
          $$CacheRecordsTableOrderingComposer,
          $$CacheRecordsTableAnnotationComposer,
          $$CacheRecordsTableCreateCompanionBuilder,
          $$CacheRecordsTableUpdateCompanionBuilder,
          (
            CacheRecordEntry,
            BaseReferences<_$AppDatabase, $CacheRecordsTable, CacheRecordEntry>,
          ),
          CacheRecordEntry,
          PrefetchHooks Function()
        > {
  $$CacheRecordsTableTableManager(_$AppDatabase db, $CacheRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> recordKind = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheRecordsCompanion(
                accountId: accountId,
                recordKind: recordKind,
                recordId: recordId,
                scopeId: scopeId,
                json: json,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String recordKind,
                required String recordId,
                Value<String> scopeId = const Value.absent(),
                required String json,
                Value<int> rowid = const Value.absent(),
              }) => CacheRecordsCompanion.insert(
                accountId: accountId,
                recordKind: recordKind,
                recordId: recordId,
                scopeId: scopeId,
                json: json,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheRecordsTable, CacheRecordEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CacheRecordsTable,
                    CacheRecordEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheRecordsTable,
      CacheRecordEntry,
      $$CacheRecordsTableFilterComposer,
      $$CacheRecordsTableOrderingComposer,
      $$CacheRecordsTableAnnotationComposer,
      $$CacheRecordsTableCreateCompanionBuilder,
      $$CacheRecordsTableUpdateCompanionBuilder,
      (
        CacheRecordEntry,
        BaseReferences<_$AppDatabase, $CacheRecordsTable, CacheRecordEntry>,
      ),
      CacheRecordEntry,
      PrefetchHooks Function()
    >;
typedef $$CacheRefreshesTableCreateCompanionBuilder =
    CacheRefreshesCompanion Function({
      required String accountId,
      required String recordKind,
      Value<String> scopeId,
      required DateTime refreshedAt,
      Value<int> rowid,
    });
typedef $$CacheRefreshesTableUpdateCompanionBuilder =
    CacheRefreshesCompanion Function({
      Value<String> accountId,
      Value<String> recordKind,
      Value<String> scopeId,
      Value<DateTime> refreshedAt,
      Value<int> rowid,
    });

class $$CacheRefreshesTableFilterComposer
    extends Composer<_$AppDatabase, $CacheRefreshesTable> {
  $$CacheRefreshesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CacheRefreshesTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheRefreshesTable> {
  $$CacheRefreshesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeId => $composableBuilder(
    column: $table.scopeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CacheRefreshesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheRefreshesTable> {
  $$CacheRefreshesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recordKind => $composableBuilder(
    column: $table.recordKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scopeId =>
      $composableBuilder(column: $table.scopeId, builder: (column) => column);

  GeneratedColumn<DateTime> get refreshedAt => $composableBuilder(
    column: $table.refreshedAt,
    builder: (column) => column,
  );
}

class $$CacheRefreshesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CacheRefreshesTable,
          CacheRefreshEntry,
          $$CacheRefreshesTableFilterComposer,
          $$CacheRefreshesTableOrderingComposer,
          $$CacheRefreshesTableAnnotationComposer,
          $$CacheRefreshesTableCreateCompanionBuilder,
          $$CacheRefreshesTableUpdateCompanionBuilder,
          (
            CacheRefreshEntry,
            BaseReferences<
              _$AppDatabase,
              $CacheRefreshesTable,
              CacheRefreshEntry
            >,
          ),
          CacheRefreshEntry,
          PrefetchHooks Function()
        > {
  $$CacheRefreshesTableTableManager(
    _$AppDatabase db,
    $CacheRefreshesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheRefreshesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheRefreshesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheRefreshesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> recordKind = const Value.absent(),
                Value<String> scopeId = const Value.absent(),
                Value<DateTime> refreshedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheRefreshesCompanion(
                accountId: accountId,
                recordKind: recordKind,
                scopeId: scopeId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String recordKind,
                Value<String> scopeId = const Value.absent(),
                required DateTime refreshedAt,
                Value<int> rowid = const Value.absent(),
              }) => CacheRefreshesCompanion.insert(
                accountId: accountId,
                recordKind: recordKind,
                scopeId: scopeId,
                refreshedAt: refreshedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheRefreshesTable, CacheRefreshEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CacheRefreshesTable,
                    CacheRefreshEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheRefreshesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CacheRefreshesTable,
      CacheRefreshEntry,
      $$CacheRefreshesTableFilterComposer,
      $$CacheRefreshesTableOrderingComposer,
      $$CacheRefreshesTableAnnotationComposer,
      $$CacheRefreshesTableCreateCompanionBuilder,
      $$CacheRefreshesTableUpdateCompanionBuilder,
      (
        CacheRefreshEntry,
        BaseReferences<_$AppDatabase, $CacheRefreshesTable, CacheRefreshEntry>,
      ),
      CacheRefreshEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db, _db.setlists);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db, _db.scores);
  $$CacheRecordsTableTableManager get cacheRecords =>
      $$CacheRecordsTableTableManager(_db, _db.cacheRecords);
  $$CacheRefreshesTableTableManager get cacheRefreshes =>
      $$CacheRefreshesTableTableManager(_db, _db.cacheRefreshes);
}
