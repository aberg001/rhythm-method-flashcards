// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TopicsTable extends Topics with TableInfo<$TopicsTable, TopicRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TopicsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES topics (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
  static const VerificationMeta _reverseDrillMeta = const VerificationMeta(
    'reverseDrill',
  );
  @override
  late final GeneratedColumn<bool> reverseDrill = GeneratedColumn<bool>(
    'reverse_drill',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reverse_drill" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    name,
    position,
    createdAt,
    reverseDrill,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'topics';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopicRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('reverse_drill')) {
      context.handle(
        _reverseDrillMeta,
        reverseDrill.isAcceptableOrUnknown(
          data['reverse_drill']!,
          _reverseDrillMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopicRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopicRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      reverseDrill: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reverse_drill'],
      )!,
    );
  }

  @override
  $TopicsTable createAlias(String alias) {
    return $TopicsTable(attachedDatabase, alias);
  }
}

class TopicRow extends DataClass implements Insertable<TopicRow> {
  final String id;
  final String? parentId;
  final String name;
  final int position;
  final DateTime createdAt;

  /// Back-to-front drills for this topic's own cards. Not inherited.
  final bool reverseDrill;
  const TopicRow({
    required this.id,
    this.parentId,
    required this.name,
    required this.position,
    required this.createdAt,
    required this.reverseDrill,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['reverse_drill'] = Variable<bool>(reverseDrill);
    return map;
  }

  TopicsCompanion toCompanion(bool nullToAbsent) {
    return TopicsCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      position: Value(position),
      createdAt: Value(createdAt),
      reverseDrill: Value(reverseDrill),
    );
  }

  factory TopicRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopicRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      reverseDrill: serializer.fromJson<bool>(json['reverseDrill']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'reverseDrill': serializer.toJson<bool>(reverseDrill),
    };
  }

  TopicRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? name,
    int? position,
    DateTime? createdAt,
    bool? reverseDrill,
  }) => TopicRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    name: name ?? this.name,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    reverseDrill: reverseDrill ?? this.reverseDrill,
  );
  TopicRow copyWithCompanion(TopicsCompanion data) {
    return TopicRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      reverseDrill: data.reverseDrill.present
          ? data.reverseDrill.value
          : this.reverseDrill,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopicRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('reverseDrill: $reverseDrill')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, parentId, name, position, createdAt, reverseDrill);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopicRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.reverseDrill == this.reverseDrill);
}

class TopicsCompanion extends UpdateCompanion<TopicRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<bool> reverseDrill;
  final Value<int> rowid;
  const TopicsCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reverseDrill = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TopicsCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    required int position,
    required DateTime createdAt,
    this.reverseDrill = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position),
       createdAt = Value(createdAt);
  static Insertable<TopicRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<int>? position,
    Expression<DateTime>? createdAt,
    Expression<bool>? reverseDrill,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (reverseDrill != null) 'reverse_drill': reverseDrill,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TopicsCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? name,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<bool>? reverseDrill,
    Value<int>? rowid,
  }) {
    return TopicsCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      reverseDrill: reverseDrill ?? this.reverseDrill,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (reverseDrill.present) {
      map['reverse_drill'] = Variable<bool>(reverseDrill.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TopicsCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('reverseDrill: $reverseDrill, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicIdMeta = const VerificationMeta(
    'topicId',
  );
  @override
  late final GeneratedColumn<String> topicId = GeneratedColumn<String>(
    'topic_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES topics (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningMeta = const VerificationMeta(
    'learning',
  );
  @override
  late final GeneratedColumn<bool> learning = GeneratedColumn<bool>(
    'learning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learning" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _intervalSecondsMeta = const VerificationMeta(
    'intervalSeconds',
  );
  @override
  late final GeneratedColumn<int> intervalSeconds = GeneratedColumn<int>(
    'interval_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  static const VerificationMeta _reverseLearningMeta = const VerificationMeta(
    'reverseLearning',
  );
  @override
  late final GeneratedColumn<bool> reverseLearning = GeneratedColumn<bool>(
    'reverse_learning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reverse_learning" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reverseLastReviewMeta = const VerificationMeta(
    'reverseLastReview',
  );
  @override
  late final GeneratedColumn<DateTime> reverseLastReview =
      GeneratedColumn<DateTime>(
        'reverse_last_review',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reverseIntervalSecondsMeta =
      const VerificationMeta('reverseIntervalSeconds');
  @override
  late final GeneratedColumn<int> reverseIntervalSeconds = GeneratedColumn<int>(
    'reverse_interval_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reverseDifficultyMeta = const VerificationMeta(
    'reverseDifficulty',
  );
  @override
  late final GeneratedColumn<double> reverseDifficulty =
      GeneratedColumn<double>(
        'reverse_difficulty',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reverseQueuedAtMeta = const VerificationMeta(
    'reverseQueuedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reverseQueuedAt =
      GeneratedColumn<DateTime>(
        'reverse_queued_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    topicId,
    front,
    back,
    learning,
    lastReview,
    intervalSeconds,
    difficulty,
    createdAt,
    reverseLearning,
    reverseLastReview,
    reverseIntervalSeconds,
    reverseDifficulty,
    reverseQueuedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('topic_id')) {
      context.handle(
        _topicIdMeta,
        topicId.isAcceptableOrUnknown(data['topic_id']!, _topicIdMeta),
      );
    } else if (isInserting) {
      context.missing(_topicIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('learning')) {
      context.handle(
        _learningMeta,
        learning.isAcceptableOrUnknown(data['learning']!, _learningMeta),
      );
    } else if (isInserting) {
      context.missing(_learningMeta);
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('interval_seconds')) {
      context.handle(
        _intervalSecondsMeta,
        intervalSeconds.isAcceptableOrUnknown(
          data['interval_seconds']!,
          _intervalSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalSecondsMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('reverse_learning')) {
      context.handle(
        _reverseLearningMeta,
        reverseLearning.isAcceptableOrUnknown(
          data['reverse_learning']!,
          _reverseLearningMeta,
        ),
      );
    }
    if (data.containsKey('reverse_last_review')) {
      context.handle(
        _reverseLastReviewMeta,
        reverseLastReview.isAcceptableOrUnknown(
          data['reverse_last_review']!,
          _reverseLastReviewMeta,
        ),
      );
    }
    if (data.containsKey('reverse_interval_seconds')) {
      context.handle(
        _reverseIntervalSecondsMeta,
        reverseIntervalSeconds.isAcceptableOrUnknown(
          data['reverse_interval_seconds']!,
          _reverseIntervalSecondsMeta,
        ),
      );
    }
    if (data.containsKey('reverse_difficulty')) {
      context.handle(
        _reverseDifficultyMeta,
        reverseDifficulty.isAcceptableOrUnknown(
          data['reverse_difficulty']!,
          _reverseDifficultyMeta,
        ),
      );
    }
    if (data.containsKey('reverse_queued_at')) {
      context.handle(
        _reverseQueuedAtMeta,
        reverseQueuedAt.isAcceptableOrUnknown(
          data['reverse_queued_at']!,
          _reverseQueuedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      topicId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      learning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learning'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      intervalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_seconds'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      reverseLearning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reverse_learning'],
      )!,
      reverseLastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reverse_last_review'],
      ),
      reverseIntervalSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reverse_interval_seconds'],
      ),
      reverseDifficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reverse_difficulty'],
      ),
      reverseQueuedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reverse_queued_at'],
      ),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final String id;
  final String topicId;
  final String front;
  final String back;
  final bool learning;
  final DateTime? lastReview;
  final int intervalSeconds;
  final double difficulty;
  final DateTime createdAt;

  /// Null [reverseQueuedAt] means there is no reverse face. The other reverse
  /// columns are null in that case, except [reverseLearning], which stays false.
  final bool reverseLearning;
  final DateTime? reverseLastReview;
  final int? reverseIntervalSeconds;
  final double? reverseDifficulty;
  final DateTime? reverseQueuedAt;
  const CardRow({
    required this.id,
    required this.topicId,
    required this.front,
    required this.back,
    required this.learning,
    this.lastReview,
    required this.intervalSeconds,
    required this.difficulty,
    required this.createdAt,
    required this.reverseLearning,
    this.reverseLastReview,
    this.reverseIntervalSeconds,
    this.reverseDifficulty,
    this.reverseQueuedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['topic_id'] = Variable<String>(topicId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['learning'] = Variable<bool>(learning);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['interval_seconds'] = Variable<int>(intervalSeconds);
    map['difficulty'] = Variable<double>(difficulty);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['reverse_learning'] = Variable<bool>(reverseLearning);
    if (!nullToAbsent || reverseLastReview != null) {
      map['reverse_last_review'] = Variable<DateTime>(reverseLastReview);
    }
    if (!nullToAbsent || reverseIntervalSeconds != null) {
      map['reverse_interval_seconds'] = Variable<int>(reverseIntervalSeconds);
    }
    if (!nullToAbsent || reverseDifficulty != null) {
      map['reverse_difficulty'] = Variable<double>(reverseDifficulty);
    }
    if (!nullToAbsent || reverseQueuedAt != null) {
      map['reverse_queued_at'] = Variable<DateTime>(reverseQueuedAt);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      topicId: Value(topicId),
      front: Value(front),
      back: Value(back),
      learning: Value(learning),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      intervalSeconds: Value(intervalSeconds),
      difficulty: Value(difficulty),
      createdAt: Value(createdAt),
      reverseLearning: Value(reverseLearning),
      reverseLastReview: reverseLastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseLastReview),
      reverseIntervalSeconds: reverseIntervalSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseIntervalSeconds),
      reverseDifficulty: reverseDifficulty == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseDifficulty),
      reverseQueuedAt: reverseQueuedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reverseQueuedAt),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<String>(json['id']),
      topicId: serializer.fromJson<String>(json['topicId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      learning: serializer.fromJson<bool>(json['learning']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      intervalSeconds: serializer.fromJson<int>(json['intervalSeconds']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      reverseLearning: serializer.fromJson<bool>(json['reverseLearning']),
      reverseLastReview: serializer.fromJson<DateTime?>(
        json['reverseLastReview'],
      ),
      reverseIntervalSeconds: serializer.fromJson<int?>(
        json['reverseIntervalSeconds'],
      ),
      reverseDifficulty: serializer.fromJson<double?>(
        json['reverseDifficulty'],
      ),
      reverseQueuedAt: serializer.fromJson<DateTime?>(json['reverseQueuedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'topicId': serializer.toJson<String>(topicId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'learning': serializer.toJson<bool>(learning),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'intervalSeconds': serializer.toJson<int>(intervalSeconds),
      'difficulty': serializer.toJson<double>(difficulty),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'reverseLearning': serializer.toJson<bool>(reverseLearning),
      'reverseLastReview': serializer.toJson<DateTime?>(reverseLastReview),
      'reverseIntervalSeconds': serializer.toJson<int?>(reverseIntervalSeconds),
      'reverseDifficulty': serializer.toJson<double?>(reverseDifficulty),
      'reverseQueuedAt': serializer.toJson<DateTime?>(reverseQueuedAt),
    };
  }

  CardRow copyWith({
    String? id,
    String? topicId,
    String? front,
    String? back,
    bool? learning,
    Value<DateTime?> lastReview = const Value.absent(),
    int? intervalSeconds,
    double? difficulty,
    DateTime? createdAt,
    bool? reverseLearning,
    Value<DateTime?> reverseLastReview = const Value.absent(),
    Value<int?> reverseIntervalSeconds = const Value.absent(),
    Value<double?> reverseDifficulty = const Value.absent(),
    Value<DateTime?> reverseQueuedAt = const Value.absent(),
  }) => CardRow(
    id: id ?? this.id,
    topicId: topicId ?? this.topicId,
    front: front ?? this.front,
    back: back ?? this.back,
    learning: learning ?? this.learning,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    intervalSeconds: intervalSeconds ?? this.intervalSeconds,
    difficulty: difficulty ?? this.difficulty,
    createdAt: createdAt ?? this.createdAt,
    reverseLearning: reverseLearning ?? this.reverseLearning,
    reverseLastReview: reverseLastReview.present
        ? reverseLastReview.value
        : this.reverseLastReview,
    reverseIntervalSeconds: reverseIntervalSeconds.present
        ? reverseIntervalSeconds.value
        : this.reverseIntervalSeconds,
    reverseDifficulty: reverseDifficulty.present
        ? reverseDifficulty.value
        : this.reverseDifficulty,
    reverseQueuedAt: reverseQueuedAt.present
        ? reverseQueuedAt.value
        : this.reverseQueuedAt,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      topicId: data.topicId.present ? data.topicId.value : this.topicId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      learning: data.learning.present ? data.learning.value : this.learning,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      intervalSeconds: data.intervalSeconds.present
          ? data.intervalSeconds.value
          : this.intervalSeconds,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      reverseLearning: data.reverseLearning.present
          ? data.reverseLearning.value
          : this.reverseLearning,
      reverseLastReview: data.reverseLastReview.present
          ? data.reverseLastReview.value
          : this.reverseLastReview,
      reverseIntervalSeconds: data.reverseIntervalSeconds.present
          ? data.reverseIntervalSeconds.value
          : this.reverseIntervalSeconds,
      reverseDifficulty: data.reverseDifficulty.present
          ? data.reverseDifficulty.value
          : this.reverseDifficulty,
      reverseQueuedAt: data.reverseQueuedAt.present
          ? data.reverseQueuedAt.value
          : this.reverseQueuedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('learning: $learning, ')
          ..write('lastReview: $lastReview, ')
          ..write('intervalSeconds: $intervalSeconds, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('reverseLearning: $reverseLearning, ')
          ..write('reverseLastReview: $reverseLastReview, ')
          ..write('reverseIntervalSeconds: $reverseIntervalSeconds, ')
          ..write('reverseDifficulty: $reverseDifficulty, ')
          ..write('reverseQueuedAt: $reverseQueuedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    topicId,
    front,
    back,
    learning,
    lastReview,
    intervalSeconds,
    difficulty,
    createdAt,
    reverseLearning,
    reverseLastReview,
    reverseIntervalSeconds,
    reverseDifficulty,
    reverseQueuedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.topicId == this.topicId &&
          other.front == this.front &&
          other.back == this.back &&
          other.learning == this.learning &&
          other.lastReview == this.lastReview &&
          other.intervalSeconds == this.intervalSeconds &&
          other.difficulty == this.difficulty &&
          other.createdAt == this.createdAt &&
          other.reverseLearning == this.reverseLearning &&
          other.reverseLastReview == this.reverseLastReview &&
          other.reverseIntervalSeconds == this.reverseIntervalSeconds &&
          other.reverseDifficulty == this.reverseDifficulty &&
          other.reverseQueuedAt == this.reverseQueuedAt);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<String> id;
  final Value<String> topicId;
  final Value<String> front;
  final Value<String> back;
  final Value<bool> learning;
  final Value<DateTime?> lastReview;
  final Value<int> intervalSeconds;
  final Value<double> difficulty;
  final Value<DateTime> createdAt;
  final Value<bool> reverseLearning;
  final Value<DateTime?> reverseLastReview;
  final Value<int?> reverseIntervalSeconds;
  final Value<double?> reverseDifficulty;
  final Value<DateTime?> reverseQueuedAt;
  final Value<int> rowid;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.topicId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.learning = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.intervalSeconds = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reverseLearning = const Value.absent(),
    this.reverseLastReview = const Value.absent(),
    this.reverseIntervalSeconds = const Value.absent(),
    this.reverseDifficulty = const Value.absent(),
    this.reverseQueuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String id,
    required String topicId,
    required String front,
    required String back,
    required bool learning,
    this.lastReview = const Value.absent(),
    required int intervalSeconds,
    required double difficulty,
    required DateTime createdAt,
    this.reverseLearning = const Value.absent(),
    this.reverseLastReview = const Value.absent(),
    this.reverseIntervalSeconds = const Value.absent(),
    this.reverseDifficulty = const Value.absent(),
    this.reverseQueuedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       topicId = Value(topicId),
       front = Value(front),
       back = Value(back),
       learning = Value(learning),
       intervalSeconds = Value(intervalSeconds),
       difficulty = Value(difficulty),
       createdAt = Value(createdAt);
  static Insertable<CardRow> custom({
    Expression<String>? id,
    Expression<String>? topicId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<bool>? learning,
    Expression<DateTime>? lastReview,
    Expression<int>? intervalSeconds,
    Expression<double>? difficulty,
    Expression<DateTime>? createdAt,
    Expression<bool>? reverseLearning,
    Expression<DateTime>? reverseLastReview,
    Expression<int>? reverseIntervalSeconds,
    Expression<double>? reverseDifficulty,
    Expression<DateTime>? reverseQueuedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (topicId != null) 'topic_id': topicId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (learning != null) 'learning': learning,
      if (lastReview != null) 'last_review': lastReview,
      if (intervalSeconds != null) 'interval_seconds': intervalSeconds,
      if (difficulty != null) 'difficulty': difficulty,
      if (createdAt != null) 'created_at': createdAt,
      if (reverseLearning != null) 'reverse_learning': reverseLearning,
      if (reverseLastReview != null) 'reverse_last_review': reverseLastReview,
      if (reverseIntervalSeconds != null)
        'reverse_interval_seconds': reverseIntervalSeconds,
      if (reverseDifficulty != null) 'reverse_difficulty': reverseDifficulty,
      if (reverseQueuedAt != null) 'reverse_queued_at': reverseQueuedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? id,
    Value<String>? topicId,
    Value<String>? front,
    Value<String>? back,
    Value<bool>? learning,
    Value<DateTime?>? lastReview,
    Value<int>? intervalSeconds,
    Value<double>? difficulty,
    Value<DateTime>? createdAt,
    Value<bool>? reverseLearning,
    Value<DateTime?>? reverseLastReview,
    Value<int?>? reverseIntervalSeconds,
    Value<double?>? reverseDifficulty,
    Value<DateTime?>? reverseQueuedAt,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      front: front ?? this.front,
      back: back ?? this.back,
      learning: learning ?? this.learning,
      lastReview: lastReview ?? this.lastReview,
      intervalSeconds: intervalSeconds ?? this.intervalSeconds,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      reverseLearning: reverseLearning ?? this.reverseLearning,
      reverseLastReview: reverseLastReview ?? this.reverseLastReview,
      reverseIntervalSeconds:
          reverseIntervalSeconds ?? this.reverseIntervalSeconds,
      reverseDifficulty: reverseDifficulty ?? this.reverseDifficulty,
      reverseQueuedAt: reverseQueuedAt ?? this.reverseQueuedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (topicId.present) {
      map['topic_id'] = Variable<String>(topicId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (learning.present) {
      map['learning'] = Variable<bool>(learning.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (intervalSeconds.present) {
      map['interval_seconds'] = Variable<int>(intervalSeconds.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (reverseLearning.present) {
      map['reverse_learning'] = Variable<bool>(reverseLearning.value);
    }
    if (reverseLastReview.present) {
      map['reverse_last_review'] = Variable<DateTime>(reverseLastReview.value);
    }
    if (reverseIntervalSeconds.present) {
      map['reverse_interval_seconds'] = Variable<int>(
        reverseIntervalSeconds.value,
      );
    }
    if (reverseDifficulty.present) {
      map['reverse_difficulty'] = Variable<double>(reverseDifficulty.value);
    }
    if (reverseQueuedAt.present) {
      map['reverse_queued_at'] = Variable<DateTime>(reverseQueuedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('topicId: $topicId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('learning: $learning, ')
          ..write('lastReview: $lastReview, ')
          ..write('intervalSeconds: $intervalSeconds, ')
          ..write('difficulty: $difficulty, ')
          ..write('createdAt: $createdAt, ')
          ..write('reverseLearning: $reverseLearning, ')
          ..write('reverseLastReview: $reverseLastReview, ')
          ..write('reverseIntervalSeconds: $reverseIntervalSeconds, ')
          ..write('reverseDifficulty: $reverseDifficulty, ')
          ..write('reverseQueuedAt: $reverseQueuedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, ReviewRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalBeforeMeta = const VerificationMeta(
    'intervalBefore',
  );
  @override
  late final GeneratedColumn<int> intervalBefore = GeneratedColumn<int>(
    'interval_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalAfterMeta = const VerificationMeta(
    'intervalAfter',
  );
  @override
  late final GeneratedColumn<int> intervalAfter = GeneratedColumn<int>(
    'interval_after',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyBeforeMeta = const VerificationMeta(
    'difficultyBefore',
  );
  @override
  late final GeneratedColumn<double> difficultyBefore = GeneratedColumn<double>(
    'difficulty_before',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyAfterMeta = const VerificationMeta(
    'difficultyAfter',
  );
  @override
  late final GeneratedColumn<double> difficultyAfter = GeneratedColumn<double>(
    'difficulty_after',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningBeforeMeta = const VerificationMeta(
    'learningBefore',
  );
  @override
  late final GeneratedColumn<bool> learningBefore = GeneratedColumn<bool>(
    'learning_before',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learning_before" IN (0, 1))',
    ),
  );
  static const VerificationMeta _learningAfterMeta = const VerificationMeta(
    'learningAfter',
  );
  @override
  late final GeneratedColumn<bool> learningAfter = GeneratedColumn<bool>(
    'learning_after',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("learning_after" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastReviewBeforeMeta = const VerificationMeta(
    'lastReviewBefore',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewBefore =
      GeneratedColumn<DateTime>(
        'last_review_before',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _directionMeta = const VerificationMeta(
    'direction',
  );
  @override
  late final GeneratedColumn<String> direction = GeneratedColumn<String>(
    'direction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('forward'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    reviewedAt,
    outcome,
    intervalBefore,
    intervalAfter,
    difficultyBefore,
    difficultyAfter,
    learningBefore,
    learningAfter,
    lastReviewBefore,
    direction,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReviewRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('interval_before')) {
      context.handle(
        _intervalBeforeMeta,
        intervalBefore.isAcceptableOrUnknown(
          data['interval_before']!,
          _intervalBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalBeforeMeta);
    }
    if (data.containsKey('interval_after')) {
      context.handle(
        _intervalAfterMeta,
        intervalAfter.isAcceptableOrUnknown(
          data['interval_after']!,
          _intervalAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalAfterMeta);
    }
    if (data.containsKey('difficulty_before')) {
      context.handle(
        _difficultyBeforeMeta,
        difficultyBefore.isAcceptableOrUnknown(
          data['difficulty_before']!,
          _difficultyBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyBeforeMeta);
    }
    if (data.containsKey('difficulty_after')) {
      context.handle(
        _difficultyAfterMeta,
        difficultyAfter.isAcceptableOrUnknown(
          data['difficulty_after']!,
          _difficultyAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyAfterMeta);
    }
    if (data.containsKey('learning_before')) {
      context.handle(
        _learningBeforeMeta,
        learningBefore.isAcceptableOrUnknown(
          data['learning_before']!,
          _learningBeforeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningBeforeMeta);
    }
    if (data.containsKey('learning_after')) {
      context.handle(
        _learningAfterMeta,
        learningAfter.isAcceptableOrUnknown(
          data['learning_after']!,
          _learningAfterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningAfterMeta);
    }
    if (data.containsKey('last_review_before')) {
      context.handle(
        _lastReviewBeforeMeta,
        lastReviewBefore.isAcceptableOrUnknown(
          data['last_review_before']!,
          _lastReviewBeforeMeta,
        ),
      );
    }
    if (data.containsKey('direction')) {
      context.handle(
        _directionMeta,
        direction.isAcceptableOrUnknown(data['direction']!, _directionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      intervalBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_before'],
      )!,
      intervalAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_after'],
      )!,
      difficultyBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_before'],
      )!,
      difficultyAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_after'],
      )!,
      learningBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learning_before'],
      )!,
      learningAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}learning_after'],
      )!,
      lastReviewBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review_before'],
      ),
      direction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direction'],
      )!,
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }
}

class ReviewRow extends DataClass implements Insertable<ReviewRow> {
  final int id;
  final String cardId;
  final DateTime reviewedAt;
  final String outcome;
  final int intervalBefore;
  final int intervalAfter;
  final double difficultyBefore;
  final double difficultyAfter;
  final bool learningBefore;
  final bool learningAfter;

  /// Not part of the grade arithmetic. Stored so a persisted undo can put
  /// [FlashCard.lastReview] back.
  final DateTime? lastReviewBefore;

  /// `forward` or `reverse`. Undo shows this face again.
  final String direction;
  const ReviewRow({
    required this.id,
    required this.cardId,
    required this.reviewedAt,
    required this.outcome,
    required this.intervalBefore,
    required this.intervalAfter,
    required this.difficultyBefore,
    required this.difficultyAfter,
    required this.learningBefore,
    required this.learningAfter,
    this.lastReviewBefore,
    required this.direction,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<String>(cardId);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['outcome'] = Variable<String>(outcome);
    map['interval_before'] = Variable<int>(intervalBefore);
    map['interval_after'] = Variable<int>(intervalAfter);
    map['difficulty_before'] = Variable<double>(difficultyBefore);
    map['difficulty_after'] = Variable<double>(difficultyAfter);
    map['learning_before'] = Variable<bool>(learningBefore);
    map['learning_after'] = Variable<bool>(learningAfter);
    if (!nullToAbsent || lastReviewBefore != null) {
      map['last_review_before'] = Variable<DateTime>(lastReviewBefore);
    }
    map['direction'] = Variable<String>(direction);
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      reviewedAt: Value(reviewedAt),
      outcome: Value(outcome),
      intervalBefore: Value(intervalBefore),
      intervalAfter: Value(intervalAfter),
      difficultyBefore: Value(difficultyBefore),
      difficultyAfter: Value(difficultyAfter),
      learningBefore: Value(learningBefore),
      learningAfter: Value(learningAfter),
      lastReviewBefore: lastReviewBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewBefore),
      direction: Value(direction),
    );
  }

  factory ReviewRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewRow(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      outcome: serializer.fromJson<String>(json['outcome']),
      intervalBefore: serializer.fromJson<int>(json['intervalBefore']),
      intervalAfter: serializer.fromJson<int>(json['intervalAfter']),
      difficultyBefore: serializer.fromJson<double>(json['difficultyBefore']),
      difficultyAfter: serializer.fromJson<double>(json['difficultyAfter']),
      learningBefore: serializer.fromJson<bool>(json['learningBefore']),
      learningAfter: serializer.fromJson<bool>(json['learningAfter']),
      lastReviewBefore: serializer.fromJson<DateTime?>(
        json['lastReviewBefore'],
      ),
      direction: serializer.fromJson<String>(json['direction']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<String>(cardId),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'outcome': serializer.toJson<String>(outcome),
      'intervalBefore': serializer.toJson<int>(intervalBefore),
      'intervalAfter': serializer.toJson<int>(intervalAfter),
      'difficultyBefore': serializer.toJson<double>(difficultyBefore),
      'difficultyAfter': serializer.toJson<double>(difficultyAfter),
      'learningBefore': serializer.toJson<bool>(learningBefore),
      'learningAfter': serializer.toJson<bool>(learningAfter),
      'lastReviewBefore': serializer.toJson<DateTime?>(lastReviewBefore),
      'direction': serializer.toJson<String>(direction),
    };
  }

  ReviewRow copyWith({
    int? id,
    String? cardId,
    DateTime? reviewedAt,
    String? outcome,
    int? intervalBefore,
    int? intervalAfter,
    double? difficultyBefore,
    double? difficultyAfter,
    bool? learningBefore,
    bool? learningAfter,
    Value<DateTime?> lastReviewBefore = const Value.absent(),
    String? direction,
  }) => ReviewRow(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    outcome: outcome ?? this.outcome,
    intervalBefore: intervalBefore ?? this.intervalBefore,
    intervalAfter: intervalAfter ?? this.intervalAfter,
    difficultyBefore: difficultyBefore ?? this.difficultyBefore,
    difficultyAfter: difficultyAfter ?? this.difficultyAfter,
    learningBefore: learningBefore ?? this.learningBefore,
    learningAfter: learningAfter ?? this.learningAfter,
    lastReviewBefore: lastReviewBefore.present
        ? lastReviewBefore.value
        : this.lastReviewBefore,
    direction: direction ?? this.direction,
  );
  ReviewRow copyWithCompanion(ReviewsCompanion data) {
    return ReviewRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      intervalBefore: data.intervalBefore.present
          ? data.intervalBefore.value
          : this.intervalBefore,
      intervalAfter: data.intervalAfter.present
          ? data.intervalAfter.value
          : this.intervalAfter,
      difficultyBefore: data.difficultyBefore.present
          ? data.difficultyBefore.value
          : this.difficultyBefore,
      difficultyAfter: data.difficultyAfter.present
          ? data.difficultyAfter.value
          : this.difficultyAfter,
      learningBefore: data.learningBefore.present
          ? data.learningBefore.value
          : this.learningBefore,
      learningAfter: data.learningAfter.present
          ? data.learningAfter.value
          : this.learningAfter,
      lastReviewBefore: data.lastReviewBefore.present
          ? data.lastReviewBefore.value
          : this.lastReviewBefore,
      direction: data.direction.present ? data.direction.value : this.direction,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('outcome: $outcome, ')
          ..write('intervalBefore: $intervalBefore, ')
          ..write('intervalAfter: $intervalAfter, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('learningBefore: $learningBefore, ')
          ..write('learningAfter: $learningAfter, ')
          ..write('lastReviewBefore: $lastReviewBefore, ')
          ..write('direction: $direction')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    reviewedAt,
    outcome,
    intervalBefore,
    intervalAfter,
    difficultyBefore,
    difficultyAfter,
    learningBefore,
    learningAfter,
    lastReviewBefore,
    direction,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.reviewedAt == this.reviewedAt &&
          other.outcome == this.outcome &&
          other.intervalBefore == this.intervalBefore &&
          other.intervalAfter == this.intervalAfter &&
          other.difficultyBefore == this.difficultyBefore &&
          other.difficultyAfter == this.difficultyAfter &&
          other.learningBefore == this.learningBefore &&
          other.learningAfter == this.learningAfter &&
          other.lastReviewBefore == this.lastReviewBefore &&
          other.direction == this.direction);
}

class ReviewsCompanion extends UpdateCompanion<ReviewRow> {
  final Value<int> id;
  final Value<String> cardId;
  final Value<DateTime> reviewedAt;
  final Value<String> outcome;
  final Value<int> intervalBefore;
  final Value<int> intervalAfter;
  final Value<double> difficultyBefore;
  final Value<double> difficultyAfter;
  final Value<bool> learningBefore;
  final Value<bool> learningAfter;
  final Value<DateTime?> lastReviewBefore;
  final Value<String> direction;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.outcome = const Value.absent(),
    this.intervalBefore = const Value.absent(),
    this.intervalAfter = const Value.absent(),
    this.difficultyBefore = const Value.absent(),
    this.difficultyAfter = const Value.absent(),
    this.learningBefore = const Value.absent(),
    this.learningAfter = const Value.absent(),
    this.lastReviewBefore = const Value.absent(),
    this.direction = const Value.absent(),
  });
  ReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String cardId,
    required DateTime reviewedAt,
    required String outcome,
    required int intervalBefore,
    required int intervalAfter,
    required double difficultyBefore,
    required double difficultyAfter,
    required bool learningBefore,
    required bool learningAfter,
    this.lastReviewBefore = const Value.absent(),
    this.direction = const Value.absent(),
  }) : cardId = Value(cardId),
       reviewedAt = Value(reviewedAt),
       outcome = Value(outcome),
       intervalBefore = Value(intervalBefore),
       intervalAfter = Value(intervalAfter),
       difficultyBefore = Value(difficultyBefore),
       difficultyAfter = Value(difficultyAfter),
       learningBefore = Value(learningBefore),
       learningAfter = Value(learningAfter);
  static Insertable<ReviewRow> custom({
    Expression<int>? id,
    Expression<String>? cardId,
    Expression<DateTime>? reviewedAt,
    Expression<String>? outcome,
    Expression<int>? intervalBefore,
    Expression<int>? intervalAfter,
    Expression<double>? difficultyBefore,
    Expression<double>? difficultyAfter,
    Expression<bool>? learningBefore,
    Expression<bool>? learningAfter,
    Expression<DateTime>? lastReviewBefore,
    Expression<String>? direction,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (outcome != null) 'outcome': outcome,
      if (intervalBefore != null) 'interval_before': intervalBefore,
      if (intervalAfter != null) 'interval_after': intervalAfter,
      if (difficultyBefore != null) 'difficulty_before': difficultyBefore,
      if (difficultyAfter != null) 'difficulty_after': difficultyAfter,
      if (learningBefore != null) 'learning_before': learningBefore,
      if (learningAfter != null) 'learning_after': learningAfter,
      if (lastReviewBefore != null) 'last_review_before': lastReviewBefore,
      if (direction != null) 'direction': direction,
    });
  }

  ReviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? cardId,
    Value<DateTime>? reviewedAt,
    Value<String>? outcome,
    Value<int>? intervalBefore,
    Value<int>? intervalAfter,
    Value<double>? difficultyBefore,
    Value<double>? difficultyAfter,
    Value<bool>? learningBefore,
    Value<bool>? learningAfter,
    Value<DateTime?>? lastReviewBefore,
    Value<String>? direction,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      outcome: outcome ?? this.outcome,
      intervalBefore: intervalBefore ?? this.intervalBefore,
      intervalAfter: intervalAfter ?? this.intervalAfter,
      difficultyBefore: difficultyBefore ?? this.difficultyBefore,
      difficultyAfter: difficultyAfter ?? this.difficultyAfter,
      learningBefore: learningBefore ?? this.learningBefore,
      learningAfter: learningAfter ?? this.learningAfter,
      lastReviewBefore: lastReviewBefore ?? this.lastReviewBefore,
      direction: direction ?? this.direction,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (intervalBefore.present) {
      map['interval_before'] = Variable<int>(intervalBefore.value);
    }
    if (intervalAfter.present) {
      map['interval_after'] = Variable<int>(intervalAfter.value);
    }
    if (difficultyBefore.present) {
      map['difficulty_before'] = Variable<double>(difficultyBefore.value);
    }
    if (difficultyAfter.present) {
      map['difficulty_after'] = Variable<double>(difficultyAfter.value);
    }
    if (learningBefore.present) {
      map['learning_before'] = Variable<bool>(learningBefore.value);
    }
    if (learningAfter.present) {
      map['learning_after'] = Variable<bool>(learningAfter.value);
    }
    if (lastReviewBefore.present) {
      map['last_review_before'] = Variable<DateTime>(lastReviewBefore.value);
    }
    if (direction.present) {
      map['direction'] = Variable<String>(direction.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('outcome: $outcome, ')
          ..write('intervalBefore: $intervalBefore, ')
          ..write('intervalAfter: $intervalAfter, ')
          ..write('difficultyBefore: $difficultyBefore, ')
          ..write('difficultyAfter: $difficultyAfter, ')
          ..write('learningBefore: $learningBefore, ')
          ..write('learningAfter: $learningAfter, ')
          ..write('lastReviewBefore: $lastReviewBefore, ')
          ..write('direction: $direction')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _correctFactorMeta = const VerificationMeta(
    'correctFactor',
  );
  @override
  late final GeneratedColumn<double> correctFactor = GeneratedColumn<double>(
    'correct_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wrongFactorMeta = const VerificationMeta(
    'wrongFactor',
  );
  @override
  late final GeneratedColumn<double> wrongFactor = GeneratedColumn<double>(
    'wrong_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyFactorMeta = const VerificationMeta(
    'difficultyFactor',
  );
  @override
  late final GeneratedColumn<double> difficultyFactor = GeneratedColumn<double>(
    'difficulty_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningWindowSizeMeta =
      const VerificationMeta('learningWindowSize');
  @override
  late final GeneratedColumn<int> learningWindowSize = GeneratedColumn<int>(
    'learning_window_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learnedThresholdSecondsMeta =
      const VerificationMeta('learnedThresholdSeconds');
  @override
  late final GeneratedColumn<int> learnedThresholdSeconds =
      GeneratedColumn<int>(
        'learned_threshold_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    correctFactor,
    wrongFactor,
    difficultyFactor,
    learningWindowSize,
    learnedThresholdSeconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('correct_factor')) {
      context.handle(
        _correctFactorMeta,
        correctFactor.isAcceptableOrUnknown(
          data['correct_factor']!,
          _correctFactorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctFactorMeta);
    }
    if (data.containsKey('wrong_factor')) {
      context.handle(
        _wrongFactorMeta,
        wrongFactor.isAcceptableOrUnknown(
          data['wrong_factor']!,
          _wrongFactorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_wrongFactorMeta);
    }
    if (data.containsKey('difficulty_factor')) {
      context.handle(
        _difficultyFactorMeta,
        difficultyFactor.isAcceptableOrUnknown(
          data['difficulty_factor']!,
          _difficultyFactorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_difficultyFactorMeta);
    }
    if (data.containsKey('learning_window_size')) {
      context.handle(
        _learningWindowSizeMeta,
        learningWindowSize.isAcceptableOrUnknown(
          data['learning_window_size']!,
          _learningWindowSizeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learningWindowSizeMeta);
    }
    if (data.containsKey('learned_threshold_seconds')) {
      context.handle(
        _learnedThresholdSecondsMeta,
        learnedThresholdSeconds.isAcceptableOrUnknown(
          data['learned_threshold_seconds']!,
          _learnedThresholdSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_learnedThresholdSecondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      correctFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}correct_factor'],
      )!,
      wrongFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}wrong_factor'],
      )!,
      difficultyFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty_factor'],
      )!,
      learningWindowSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learning_window_size'],
      )!,
      learnedThresholdSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learned_threshold_seconds'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final int id;
  final double correctFactor;
  final double wrongFactor;
  final double difficultyFactor;
  final int learningWindowSize;
  final int learnedThresholdSeconds;
  const SettingRow({
    required this.id,
    required this.correctFactor,
    required this.wrongFactor,
    required this.difficultyFactor,
    required this.learningWindowSize,
    required this.learnedThresholdSeconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['correct_factor'] = Variable<double>(correctFactor);
    map['wrong_factor'] = Variable<double>(wrongFactor);
    map['difficulty_factor'] = Variable<double>(difficultyFactor);
    map['learning_window_size'] = Variable<int>(learningWindowSize);
    map['learned_threshold_seconds'] = Variable<int>(learnedThresholdSeconds);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      correctFactor: Value(correctFactor),
      wrongFactor: Value(wrongFactor),
      difficultyFactor: Value(difficultyFactor),
      learningWindowSize: Value(learningWindowSize),
      learnedThresholdSeconds: Value(learnedThresholdSeconds),
    );
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      id: serializer.fromJson<int>(json['id']),
      correctFactor: serializer.fromJson<double>(json['correctFactor']),
      wrongFactor: serializer.fromJson<double>(json['wrongFactor']),
      difficultyFactor: serializer.fromJson<double>(json['difficultyFactor']),
      learningWindowSize: serializer.fromJson<int>(json['learningWindowSize']),
      learnedThresholdSeconds: serializer.fromJson<int>(
        json['learnedThresholdSeconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'correctFactor': serializer.toJson<double>(correctFactor),
      'wrongFactor': serializer.toJson<double>(wrongFactor),
      'difficultyFactor': serializer.toJson<double>(difficultyFactor),
      'learningWindowSize': serializer.toJson<int>(learningWindowSize),
      'learnedThresholdSeconds': serializer.toJson<int>(
        learnedThresholdSeconds,
      ),
    };
  }

  SettingRow copyWith({
    int? id,
    double? correctFactor,
    double? wrongFactor,
    double? difficultyFactor,
    int? learningWindowSize,
    int? learnedThresholdSeconds,
  }) => SettingRow(
    id: id ?? this.id,
    correctFactor: correctFactor ?? this.correctFactor,
    wrongFactor: wrongFactor ?? this.wrongFactor,
    difficultyFactor: difficultyFactor ?? this.difficultyFactor,
    learningWindowSize: learningWindowSize ?? this.learningWindowSize,
    learnedThresholdSeconds:
        learnedThresholdSeconds ?? this.learnedThresholdSeconds,
  );
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      id: data.id.present ? data.id.value : this.id,
      correctFactor: data.correctFactor.present
          ? data.correctFactor.value
          : this.correctFactor,
      wrongFactor: data.wrongFactor.present
          ? data.wrongFactor.value
          : this.wrongFactor,
      difficultyFactor: data.difficultyFactor.present
          ? data.difficultyFactor.value
          : this.difficultyFactor,
      learningWindowSize: data.learningWindowSize.present
          ? data.learningWindowSize.value
          : this.learningWindowSize,
      learnedThresholdSeconds: data.learnedThresholdSeconds.present
          ? data.learnedThresholdSeconds.value
          : this.learnedThresholdSeconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('id: $id, ')
          ..write('correctFactor: $correctFactor, ')
          ..write('wrongFactor: $wrongFactor, ')
          ..write('difficultyFactor: $difficultyFactor, ')
          ..write('learningWindowSize: $learningWindowSize, ')
          ..write('learnedThresholdSeconds: $learnedThresholdSeconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    correctFactor,
    wrongFactor,
    difficultyFactor,
    learningWindowSize,
    learnedThresholdSeconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.id == this.id &&
          other.correctFactor == this.correctFactor &&
          other.wrongFactor == this.wrongFactor &&
          other.difficultyFactor == this.difficultyFactor &&
          other.learningWindowSize == this.learningWindowSize &&
          other.learnedThresholdSeconds == this.learnedThresholdSeconds);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<int> id;
  final Value<double> correctFactor;
  final Value<double> wrongFactor;
  final Value<double> difficultyFactor;
  final Value<int> learningWindowSize;
  final Value<int> learnedThresholdSeconds;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.correctFactor = const Value.absent(),
    this.wrongFactor = const Value.absent(),
    this.difficultyFactor = const Value.absent(),
    this.learningWindowSize = const Value.absent(),
    this.learnedThresholdSeconds = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    required double correctFactor,
    required double wrongFactor,
    required double difficultyFactor,
    required int learningWindowSize,
    required int learnedThresholdSeconds,
  }) : correctFactor = Value(correctFactor),
       wrongFactor = Value(wrongFactor),
       difficultyFactor = Value(difficultyFactor),
       learningWindowSize = Value(learningWindowSize),
       learnedThresholdSeconds = Value(learnedThresholdSeconds);
  static Insertable<SettingRow> custom({
    Expression<int>? id,
    Expression<double>? correctFactor,
    Expression<double>? wrongFactor,
    Expression<double>? difficultyFactor,
    Expression<int>? learningWindowSize,
    Expression<int>? learnedThresholdSeconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (correctFactor != null) 'correct_factor': correctFactor,
      if (wrongFactor != null) 'wrong_factor': wrongFactor,
      if (difficultyFactor != null) 'difficulty_factor': difficultyFactor,
      if (learningWindowSize != null)
        'learning_window_size': learningWindowSize,
      if (learnedThresholdSeconds != null)
        'learned_threshold_seconds': learnedThresholdSeconds,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<double>? correctFactor,
    Value<double>? wrongFactor,
    Value<double>? difficultyFactor,
    Value<int>? learningWindowSize,
    Value<int>? learnedThresholdSeconds,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      correctFactor: correctFactor ?? this.correctFactor,
      wrongFactor: wrongFactor ?? this.wrongFactor,
      difficultyFactor: difficultyFactor ?? this.difficultyFactor,
      learningWindowSize: learningWindowSize ?? this.learningWindowSize,
      learnedThresholdSeconds:
          learnedThresholdSeconds ?? this.learnedThresholdSeconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (correctFactor.present) {
      map['correct_factor'] = Variable<double>(correctFactor.value);
    }
    if (wrongFactor.present) {
      map['wrong_factor'] = Variable<double>(wrongFactor.value);
    }
    if (difficultyFactor.present) {
      map['difficulty_factor'] = Variable<double>(difficultyFactor.value);
    }
    if (learningWindowSize.present) {
      map['learning_window_size'] = Variable<int>(learningWindowSize.value);
    }
    if (learnedThresholdSeconds.present) {
      map['learned_threshold_seconds'] = Variable<int>(
        learnedThresholdSeconds.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('correctFactor: $correctFactor, ')
          ..write('wrongFactor: $wrongFactor, ')
          ..write('difficultyFactor: $difficultyFactor, ')
          ..write('learningWindowSize: $learningWindowSize, ')
          ..write('learnedThresholdSeconds: $learnedThresholdSeconds')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagRow extends DataClass implements Insertable<TagRow> {
  final String id;
  final String name;
  final int position;
  const TagRow({required this.id, required this.name, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      name: Value(name),
      position: Value(position),
    );
  }

  factory TagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
    };
  }

  TagRow copyWith({String? id, String? name, int? position}) => TagRow(
    id: id ?? this.id,
    name: name ?? this.name,
    position: position ?? this.position,
  );
  TagRow copyWithCompanion(TagsCompanion data) {
    return TagRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.position == this.position);
}

class TagsCompanion extends UpdateCompanion<TagRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> position;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String name,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       position = Value(position);
  static Insertable<TagRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CardTagsTable extends CardTags
    with TableInfo<$CardTagsTable, CardTagRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cards (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [cardId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardTagRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cardId, tagId};
  @override
  CardTagRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardTagRow(
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $CardTagsTable createAlias(String alias) {
    return $CardTagsTable(attachedDatabase, alias);
  }
}

class CardTagRow extends DataClass implements Insertable<CardTagRow> {
  final String cardId;
  final String tagId;
  const CardTagRow({required this.cardId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['card_id'] = Variable<String>(cardId);
    map['tag_id'] = Variable<String>(tagId);
    return map;
  }

  CardTagsCompanion toCompanion(bool nullToAbsent) {
    return CardTagsCompanion(cardId: Value(cardId), tagId: Value(tagId));
  }

  factory CardTagRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardTagRow(
      cardId: serializer.fromJson<String>(json['cardId']),
      tagId: serializer.fromJson<String>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cardId': serializer.toJson<String>(cardId),
      'tagId': serializer.toJson<String>(tagId),
    };
  }

  CardTagRow copyWith({String? cardId, String? tagId}) =>
      CardTagRow(cardId: cardId ?? this.cardId, tagId: tagId ?? this.tagId);
  CardTagRow copyWithCompanion(CardTagsCompanion data) {
    return CardTagRow(
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardTagRow(')
          ..write('cardId: $cardId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cardId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardTagRow &&
          other.cardId == this.cardId &&
          other.tagId == this.tagId);
}

class CardTagsCompanion extends UpdateCompanion<CardTagRow> {
  final Value<String> cardId;
  final Value<String> tagId;
  final Value<int> rowid;
  const CardTagsCompanion({
    this.cardId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardTagsCompanion.insert({
    required String cardId,
    required String tagId,
    this.rowid = const Value.absent(),
  }) : cardId = Value(cardId),
       tagId = Value(tagId);
  static Insertable<CardTagRow> custom({
    Expression<String>? cardId,
    Expression<String>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cardId != null) 'card_id': cardId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardTagsCompanion copyWith({
    Value<String>? cardId,
    Value<String>? tagId,
    Value<int>? rowid,
  }) {
    return CardTagsCompanion(
      cardId: cardId ?? this.cardId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardTagsCompanion(')
          ..write('cardId: $cardId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LibraryDatabase extends GeneratedDatabase {
  _$LibraryDatabase(QueryExecutor e) : super(e);
  $LibraryDatabaseManager get managers => $LibraryDatabaseManager(this);
  late final $TopicsTable topics = $TopicsTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $CardTagsTable cardTags = $CardTagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    topics,
    cards,
    reviews,
    settings,
    tags,
    cardTags,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reviews', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'cards',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('card_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('card_tags', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TopicsTableCreateCompanionBuilder =
    TopicsCompanion Function({
      required String id,
      Value<String?> parentId,
      required String name,
      required int position,
      required DateTime createdAt,
      Value<bool> reverseDrill,
      Value<int> rowid,
    });
typedef $$TopicsTableUpdateCompanionBuilder =
    TopicsCompanion Function({
      Value<String> id,
      Value<String?> parentId,
      Value<String> name,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<bool> reverseDrill,
      Value<int> rowid,
    });

final class $$TopicsTableReferences
    extends BaseReferences<_$LibraryDatabase, $TopicsTable, TopicRow> {
  $$TopicsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TopicsTable _parentIdTable(_$LibraryDatabase db) => db.topics
      .createAlias($_aliasNameGenerator(db.topics.parentId, db.topics.id));

  $$TopicsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$TopicsTableTableManager(
      $_db,
      $_db.topics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<CardRow>> _cardsRefsTable(
    _$LibraryDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: $_aliasNameGenerator(db.topics.id, db.cards.topicId),
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.topicId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TopicsTableFilterComposer
    extends Composer<_$LibraryDatabase, $TopicsTable> {
  $$TopicsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reverseDrill => $composableBuilder(
    column: $table.reverseDrill,
    builder: (column) => ColumnFilters(column),
  );

  $$TopicsTableFilterComposer get parentId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableFilterComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TopicsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $TopicsTable> {
  $$TopicsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reverseDrill => $composableBuilder(
    column: $table.reverseDrill,
    builder: (column) => ColumnOrderings(column),
  );

  $$TopicsTableOrderingComposer get parentId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableOrderingComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TopicsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $TopicsTable> {
  $$TopicsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get reverseDrill => $composableBuilder(
    column: $table.reverseDrill,
    builder: (column) => column,
  );

  $$TopicsTableAnnotationComposer get parentId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.topicId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TopicsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $TopicsTable,
          TopicRow,
          $$TopicsTableFilterComposer,
          $$TopicsTableOrderingComposer,
          $$TopicsTableAnnotationComposer,
          $$TopicsTableCreateCompanionBuilder,
          $$TopicsTableUpdateCompanionBuilder,
          (TopicRow, $$TopicsTableReferences),
          TopicRow,
          PrefetchHooks Function({bool parentId, bool cardsRefs})
        > {
  $$TopicsTableTableManager(_$LibraryDatabase db, $TopicsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TopicsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TopicsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TopicsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> reverseDrill = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicsCompanion(
                id: id,
                parentId: parentId,
                name: name,
                position: position,
                createdAt: createdAt,
                reverseDrill: reverseDrill,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String name,
                required int position,
                required DateTime createdAt,
                Value<bool> reverseDrill = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TopicsCompanion.insert(
                id: id,
                parentId: parentId,
                name: name,
                position: position,
                createdAt: createdAt,
                reverseDrill: reverseDrill,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TopicsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({parentId = false, cardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardsRefs) db.cards],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (parentId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.parentId,
                                referencedTable: $$TopicsTableReferences
                                    ._parentIdTable(db),
                                referencedColumn: $$TopicsTableReferences
                                    ._parentIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardsRefs)
                    await $_getPrefetchedData<TopicRow, $TopicsTable, CardRow>(
                      currentTable: table,
                      referencedTable: $$TopicsTableReferences._cardsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TopicsTableReferences(db, table, p0).cardsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.topicId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TopicsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $TopicsTable,
      TopicRow,
      $$TopicsTableFilterComposer,
      $$TopicsTableOrderingComposer,
      $$TopicsTableAnnotationComposer,
      $$TopicsTableCreateCompanionBuilder,
      $$TopicsTableUpdateCompanionBuilder,
      (TopicRow, $$TopicsTableReferences),
      TopicRow,
      PrefetchHooks Function({bool parentId, bool cardsRefs})
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String id,
      required String topicId,
      required String front,
      required String back,
      required bool learning,
      Value<DateTime?> lastReview,
      required int intervalSeconds,
      required double difficulty,
      required DateTime createdAt,
      Value<bool> reverseLearning,
      Value<DateTime?> reverseLastReview,
      Value<int?> reverseIntervalSeconds,
      Value<double?> reverseDifficulty,
      Value<DateTime?> reverseQueuedAt,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> id,
      Value<String> topicId,
      Value<String> front,
      Value<String> back,
      Value<bool> learning,
      Value<DateTime?> lastReview,
      Value<int> intervalSeconds,
      Value<double> difficulty,
      Value<DateTime> createdAt,
      Value<bool> reverseLearning,
      Value<DateTime?> reverseLastReview,
      Value<int?> reverseIntervalSeconds,
      Value<double?> reverseDifficulty,
      Value<DateTime?> reverseQueuedAt,
      Value<int> rowid,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$LibraryDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TopicsTable _topicIdTable(_$LibraryDatabase db) => db.topics
      .createAlias($_aliasNameGenerator(db.cards.topicId, db.topics.id));

  $$TopicsTableProcessedTableManager get topicId {
    final $_column = $_itemColumn<String>('topic_id')!;

    final manager = $$TopicsTableTableManager(
      $_db,
      $_db.topics,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_topicIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReviewsTable, List<ReviewRow>> _reviewsRefsTable(
    _$LibraryDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.reviews,
    aliasName: $_aliasNameGenerator(db.cards.id, db.reviews.cardId),
  );

  $$ReviewsTableProcessedTableManager get reviewsRefs {
    final manager = $$ReviewsTableTableManager(
      $_db,
      $_db.reviews,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardTagsTable, List<CardTagRow>>
  _cardTagsRefsTable(_$LibraryDatabase db) => MultiTypedResultKey.fromTable(
    db.cardTags,
    aliasName: $_aliasNameGenerator(db.cards.id, db.cardTags.cardId),
  );

  $$CardTagsTableProcessedTableManager get cardTagsRefs {
    final manager = $$CardTagsTableTableManager(
      $_db,
      $_db.cardTags,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CardsTableFilterComposer
    extends Composer<_$LibraryDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
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

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get learning => $composableBuilder(
    column: $table.learning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reverseLearning => $composableBuilder(
    column: $table.reverseLearning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reverseLastReview => $composableBuilder(
    column: $table.reverseLastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reverseIntervalSeconds => $composableBuilder(
    column: $table.reverseIntervalSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reverseDifficulty => $composableBuilder(
    column: $table.reverseDifficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reverseQueuedAt => $composableBuilder(
    column: $table.reverseQueuedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$TopicsTableFilterComposer get topicId {
    final $$TopicsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableFilterComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> reviewsRefs(
    Expression<bool> Function($$ReviewsTableFilterComposer f) f,
  ) {
    final $$ReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableFilterComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardTagsRefs(
    Expression<bool> Function($$CardTagsTableFilterComposer f) f,
  ) {
    final $$CardTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardTags,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardTagsTableFilterComposer(
            $db: $db,
            $table: $db.cardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
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

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get learning => $composableBuilder(
    column: $table.learning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reverseLearning => $composableBuilder(
    column: $table.reverseLearning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reverseLastReview => $composableBuilder(
    column: $table.reverseLastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reverseIntervalSeconds => $composableBuilder(
    column: $table.reverseIntervalSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reverseDifficulty => $composableBuilder(
    column: $table.reverseDifficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reverseQueuedAt => $composableBuilder(
    column: $table.reverseQueuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TopicsTableOrderingComposer get topicId {
    final $$TopicsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableOrderingComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<bool> get learning =>
      $composableBuilder(column: $table.learning, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalSeconds => $composableBuilder(
    column: $table.intervalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get reverseLearning => $composableBuilder(
    column: $table.reverseLearning,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reverseLastReview => $composableBuilder(
    column: $table.reverseLastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reverseIntervalSeconds => $composableBuilder(
    column: $table.reverseIntervalSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reverseDifficulty => $composableBuilder(
    column: $table.reverseDifficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reverseQueuedAt => $composableBuilder(
    column: $table.reverseQueuedAt,
    builder: (column) => column,
  );

  $$TopicsTableAnnotationComposer get topicId {
    final $$TopicsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.topicId,
      referencedTable: $db.topics,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TopicsTableAnnotationComposer(
            $db: $db,
            $table: $db.topics,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> reviewsRefs<T extends Object>(
    Expression<T> Function($$ReviewsTableAnnotationComposer a) f,
  ) {
    final $$ReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardTagsRefs<T extends Object>(
    Expression<T> Function($$CardTagsTableAnnotationComposer a) f,
  ) {
    final $$CardTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardTags,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, $$CardsTableReferences),
          CardRow,
          PrefetchHooks Function({
            bool topicId,
            bool reviewsRefs,
            bool cardTagsRefs,
          })
        > {
  $$CardsTableTableManager(_$LibraryDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> topicId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<bool> learning = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> intervalSeconds = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> reverseLearning = const Value.absent(),
                Value<DateTime?> reverseLastReview = const Value.absent(),
                Value<int?> reverseIntervalSeconds = const Value.absent(),
                Value<double?> reverseDifficulty = const Value.absent(),
                Value<DateTime?> reverseQueuedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                topicId: topicId,
                front: front,
                back: back,
                learning: learning,
                lastReview: lastReview,
                intervalSeconds: intervalSeconds,
                difficulty: difficulty,
                createdAt: createdAt,
                reverseLearning: reverseLearning,
                reverseLastReview: reverseLastReview,
                reverseIntervalSeconds: reverseIntervalSeconds,
                reverseDifficulty: reverseDifficulty,
                reverseQueuedAt: reverseQueuedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String topicId,
                required String front,
                required String back,
                required bool learning,
                Value<DateTime?> lastReview = const Value.absent(),
                required int intervalSeconds,
                required double difficulty,
                required DateTime createdAt,
                Value<bool> reverseLearning = const Value.absent(),
                Value<DateTime?> reverseLastReview = const Value.absent(),
                Value<int?> reverseIntervalSeconds = const Value.absent(),
                Value<double?> reverseDifficulty = const Value.absent(),
                Value<DateTime?> reverseQueuedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                topicId: topicId,
                front: front,
                back: back,
                learning: learning,
                lastReview: lastReview,
                intervalSeconds: intervalSeconds,
                difficulty: difficulty,
                createdAt: createdAt,
                reverseLearning: reverseLearning,
                reverseLastReview: reverseLastReview,
                reverseIntervalSeconds: reverseIntervalSeconds,
                reverseDifficulty: reverseDifficulty,
                reverseQueuedAt: reverseQueuedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({topicId = false, reviewsRefs = false, cardTagsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (reviewsRefs) db.reviews,
                    if (cardTagsRefs) db.cardTags,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (topicId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.topicId,
                                    referencedTable: $$CardsTableReferences
                                        ._topicIdTable(db),
                                    referencedColumn: $$CardsTableReferences
                                        ._topicIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (reviewsRefs)
                        await $_getPrefetchedData<
                          CardRow,
                          $CardsTable,
                          ReviewRow
                        >(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._reviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(db, table, p0).reviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardTagsRefs)
                        await $_getPrefetchedData<
                          CardRow,
                          $CardsTable,
                          CardTagRow
                        >(
                          currentTable: table,
                          referencedTable: $$CardsTableReferences
                              ._cardTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CardsTableReferences(
                                db,
                                table,
                                p0,
                              ).cardTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cardId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, $$CardsTableReferences),
      CardRow,
      PrefetchHooks Function({
        bool topicId,
        bool reviewsRefs,
        bool cardTagsRefs,
      })
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      required String cardId,
      required DateTime reviewedAt,
      required String outcome,
      required int intervalBefore,
      required int intervalAfter,
      required double difficultyBefore,
      required double difficultyAfter,
      required bool learningBefore,
      required bool learningAfter,
      Value<DateTime?> lastReviewBefore,
      Value<String> direction,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      Value<String> cardId,
      Value<DateTime> reviewedAt,
      Value<String> outcome,
      Value<int> intervalBefore,
      Value<int> intervalAfter,
      Value<double> difficultyBefore,
      Value<double> difficultyAfter,
      Value<bool> learningBefore,
      Value<bool> learningAfter,
      Value<DateTime?> lastReviewBefore,
      Value<String> direction,
    });

final class $$ReviewsTableReferences
    extends BaseReferences<_$LibraryDatabase, $ReviewsTable, ReviewRow> {
  $$ReviewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$LibraryDatabase db) => db.cards.createAlias(
    $_aliasNameGenerator(db.reviews.cardId, db.cards.id),
  );

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewsTableFilterComposer
    extends Composer<_$LibraryDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get learningBefore => $composableBuilder(
    column: $table.learningBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get learningAfter => $composableBuilder(
    column: $table.learningAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewBefore => $composableBuilder(
    column: $table.lastReviewBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnFilters(column),
  );

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get learningBefore => $composableBuilder(
    column: $table.learningBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get learningAfter => $composableBuilder(
    column: $table.learningAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewBefore => $composableBuilder(
    column: $table.lastReviewBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direction => $composableBuilder(
    column: $table.direction,
    builder: (column) => ColumnOrderings(column),
  );

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<int> get intervalBefore => $composableBuilder(
    column: $table.intervalBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalAfter => $composableBuilder(
    column: $table.intervalAfter,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyBefore => $composableBuilder(
    column: $table.difficultyBefore,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyAfter => $composableBuilder(
    column: $table.difficultyAfter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get learningBefore => $composableBuilder(
    column: $table.learningBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get learningAfter => $composableBuilder(
    column: $table.learningAfter,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastReviewBefore => $composableBuilder(
    column: $table.lastReviewBefore,
    builder: (column) => column,
  );

  GeneratedColumn<String> get direction =>
      $composableBuilder(column: $table.direction, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $ReviewsTable,
          ReviewRow,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (ReviewRow, $$ReviewsTableReferences),
          ReviewRow,
          PrefetchHooks Function({bool cardId})
        > {
  $$ReviewsTableTableManager(_$LibraryDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<int> intervalBefore = const Value.absent(),
                Value<int> intervalAfter = const Value.absent(),
                Value<double> difficultyBefore = const Value.absent(),
                Value<double> difficultyAfter = const Value.absent(),
                Value<bool> learningBefore = const Value.absent(),
                Value<bool> learningAfter = const Value.absent(),
                Value<DateTime?> lastReviewBefore = const Value.absent(),
                Value<String> direction = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                cardId: cardId,
                reviewedAt: reviewedAt,
                outcome: outcome,
                intervalBefore: intervalBefore,
                intervalAfter: intervalAfter,
                difficultyBefore: difficultyBefore,
                difficultyAfter: difficultyAfter,
                learningBefore: learningBefore,
                learningAfter: learningAfter,
                lastReviewBefore: lastReviewBefore,
                direction: direction,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String cardId,
                required DateTime reviewedAt,
                required String outcome,
                required int intervalBefore,
                required int intervalAfter,
                required double difficultyBefore,
                required double difficultyAfter,
                required bool learningBefore,
                required bool learningAfter,
                Value<DateTime?> lastReviewBefore = const Value.absent(),
                Value<String> direction = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                cardId: cardId,
                reviewedAt: reviewedAt,
                outcome: outcome,
                intervalBefore: intervalBefore,
                intervalAfter: intervalAfter,
                difficultyBefore: difficultyBefore,
                difficultyAfter: difficultyAfter,
                learningBefore: learningBefore,
                learningAfter: learningAfter,
                lastReviewBefore: lastReviewBefore,
                direction: direction,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$ReviewsTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$ReviewsTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $ReviewsTable,
      ReviewRow,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (ReviewRow, $$ReviewsTableReferences),
      ReviewRow,
      PrefetchHooks Function({bool cardId})
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      required double correctFactor,
      required double wrongFactor,
      required double difficultyFactor,
      required int learningWindowSize,
      required int learnedThresholdSeconds,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<int> id,
      Value<double> correctFactor,
      Value<double> wrongFactor,
      Value<double> difficultyFactor,
      Value<int> learningWindowSize,
      Value<int> learnedThresholdSeconds,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$LibraryDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get correctFactor => $composableBuilder(
    column: $table.correctFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get wrongFactor => $composableBuilder(
    column: $table.wrongFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficultyFactor => $composableBuilder(
    column: $table.difficultyFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learningWindowSize => $composableBuilder(
    column: $table.learningWindowSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learnedThresholdSeconds => $composableBuilder(
    column: $table.learnedThresholdSeconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get correctFactor => $composableBuilder(
    column: $table.correctFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get wrongFactor => $composableBuilder(
    column: $table.wrongFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficultyFactor => $composableBuilder(
    column: $table.difficultyFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learningWindowSize => $composableBuilder(
    column: $table.learningWindowSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learnedThresholdSeconds => $composableBuilder(
    column: $table.learnedThresholdSeconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get correctFactor => $composableBuilder(
    column: $table.correctFactor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get wrongFactor => $composableBuilder(
    column: $table.wrongFactor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get difficultyFactor => $composableBuilder(
    column: $table.difficultyFactor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learningWindowSize => $composableBuilder(
    column: $table.learningWindowSize,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learnedThresholdSeconds => $composableBuilder(
    column: $table.learnedThresholdSeconds,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $SettingsTable,
          SettingRow,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (
            SettingRow,
            BaseReferences<_$LibraryDatabase, $SettingsTable, SettingRow>,
          ),
          SettingRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$LibraryDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> correctFactor = const Value.absent(),
                Value<double> wrongFactor = const Value.absent(),
                Value<double> difficultyFactor = const Value.absent(),
                Value<int> learningWindowSize = const Value.absent(),
                Value<int> learnedThresholdSeconds = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                correctFactor: correctFactor,
                wrongFactor: wrongFactor,
                difficultyFactor: difficultyFactor,
                learningWindowSize: learningWindowSize,
                learnedThresholdSeconds: learnedThresholdSeconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double correctFactor,
                required double wrongFactor,
                required double difficultyFactor,
                required int learningWindowSize,
                required int learnedThresholdSeconds,
              }) => SettingsCompanion.insert(
                id: id,
                correctFactor: correctFactor,
                wrongFactor: wrongFactor,
                difficultyFactor: difficultyFactor,
                learningWindowSize: learningWindowSize,
                learnedThresholdSeconds: learnedThresholdSeconds,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $SettingsTable,
      SettingRow,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (
        SettingRow,
        BaseReferences<_$LibraryDatabase, $SettingsTable, SettingRow>,
      ),
      SettingRow,
      PrefetchHooks Function()
    >;
typedef $$TagsTableCreateCompanionBuilder =
    TagsCompanion Function({
      required String id,
      required String name,
      required int position,
      Value<int> rowid,
    });
typedef $$TagsTableUpdateCompanionBuilder =
    TagsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> position,
      Value<int> rowid,
    });

final class $$TagsTableReferences
    extends BaseReferences<_$LibraryDatabase, $TagsTable, TagRow> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CardTagsTable, List<CardTagRow>>
  _cardTagsRefsTable(_$LibraryDatabase db) => MultiTypedResultKey.fromTable(
    db.cardTags,
    aliasName: $_aliasNameGenerator(db.tags.id, db.cardTags.tagId),
  );

  $$CardTagsTableProcessedTableManager get cardTagsRefs {
    final manager = $$CardTagsTableTableManager(
      $_db,
      $_db.cardTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer
    extends Composer<_$LibraryDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cardTagsRefs(
    Expression<bool> Function($$CardTagsTableFilterComposer f) f,
  ) {
    final $$CardTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardTagsTableFilterComposer(
            $db: $db,
            $table: $db.cardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> cardTagsRefs<T extends Object>(
    Expression<T> Function($$CardTagsTableAnnotationComposer a) f,
  ) {
    final $$CardTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cardTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.cardTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $TagsTable,
          TagRow,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagRow, $$TagsTableReferences),
          TagRow,
          PrefetchHooks Function({bool cardTagsRefs})
        > {
  $$TagsTableTableManager(_$LibraryDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                name: name,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                name: name,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TagsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({cardTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cardTagsRefs) db.cardTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cardTagsRefs)
                    await $_getPrefetchedData<TagRow, $TagsTable, CardTagRow>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._cardTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).cardTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $TagsTable,
      TagRow,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagRow, $$TagsTableReferences),
      TagRow,
      PrefetchHooks Function({bool cardTagsRefs})
    >;
typedef $$CardTagsTableCreateCompanionBuilder =
    CardTagsCompanion Function({
      required String cardId,
      required String tagId,
      Value<int> rowid,
    });
typedef $$CardTagsTableUpdateCompanionBuilder =
    CardTagsCompanion Function({
      Value<String> cardId,
      Value<String> tagId,
      Value<int> rowid,
    });

final class $$CardTagsTableReferences
    extends BaseReferences<_$LibraryDatabase, $CardTagsTable, CardTagRow> {
  $$CardTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$LibraryDatabase db) => db.cards.createAlias(
    $_aliasNameGenerator(db.cardTags.cardId, db.cards.id),
  );

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$LibraryDatabase db) =>
      db.tags.createAlias($_aliasNameGenerator(db.cardTags.tagId, db.tags.id));

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardTagsTableFilterComposer
    extends Composer<_$LibraryDatabase, $CardTagsTable> {
  $$CardTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardTagsTableOrderingComposer
    extends Composer<_$LibraryDatabase, $CardTagsTable> {
  $$CardTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableOrderingComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardTagsTableAnnotationComposer
    extends Composer<_$LibraryDatabase, $CardTagsTable> {
  $$CardTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardTagsTableTableManager
    extends
        RootTableManager<
          _$LibraryDatabase,
          $CardTagsTable,
          CardTagRow,
          $$CardTagsTableFilterComposer,
          $$CardTagsTableOrderingComposer,
          $$CardTagsTableAnnotationComposer,
          $$CardTagsTableCreateCompanionBuilder,
          $$CardTagsTableUpdateCompanionBuilder,
          (CardTagRow, $$CardTagsTableReferences),
          CardTagRow,
          PrefetchHooks Function({bool cardId, bool tagId})
        > {
  $$CardTagsTableTableManager(_$LibraryDatabase db, $CardTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cardId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  CardTagsCompanion(cardId: cardId, tagId: tagId, rowid: rowid),
          createCompanionCallback:
              ({
                required String cardId,
                required String tagId,
                Value<int> rowid = const Value.absent(),
              }) => CardTagsCompanion.insert(
                cardId: cardId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CardTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable: $$CardTagsTableReferences
                                    ._cardIdTable(db),
                                referencedColumn: $$CardTagsTableReferences
                                    ._cardIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: $$CardTagsTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: $$CardTagsTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$LibraryDatabase,
      $CardTagsTable,
      CardTagRow,
      $$CardTagsTableFilterComposer,
      $$CardTagsTableOrderingComposer,
      $$CardTagsTableAnnotationComposer,
      $$CardTagsTableCreateCompanionBuilder,
      $$CardTagsTableUpdateCompanionBuilder,
      (CardTagRow, $$CardTagsTableReferences),
      CardTagRow,
      PrefetchHooks Function({bool cardId, bool tagId})
    >;

class $LibraryDatabaseManager {
  final _$LibraryDatabase _db;
  $LibraryDatabaseManager(this._db);
  $$TopicsTableTableManager get topics =>
      $$TopicsTableTableManager(_db, _db.topics);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$CardTagsTableTableManager get cardTags =>
      $$CardTagsTableTableManager(_db, _db.cardTags);
}
