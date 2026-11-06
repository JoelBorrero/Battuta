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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
  );
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
          other.updatedAt == this.updatedAt);
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
  const SetlistEntry({
    required this.id,
    required this.title,
    this.description,
    this.eventDate,
    required this.itemsJson,
    required this.tagsJson,
    required this.createdAt,
    required this.updatedAt,
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
  }) => SetlistEntry(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    eventDate: eventDate.present ? eventDate.value : this.eventDate,
    itemsJson: itemsJson ?? this.itemsJson,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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
          ..write('updatedAt: $updatedAt')
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
          other.updatedAt == this.updatedAt);
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
          ..write('updatedAt: $updatedAt')
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
          other.updatedAt == this.updatedAt);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [songs, setlists, scores];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SongsTableTableManager get songs =>
      $$SongsTableTableManager(_db, _db.songs);
  $$SetlistsTableTableManager get setlists =>
      $$SetlistsTableTableManager(_db, _db.setlists);
  $$ScoresTableTableManager get scores =>
      $$ScoresTableTableManager(_db, _db.scores);
}
