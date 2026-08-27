// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SourceAccountsTable extends SourceAccounts
    with TableInfo<$SourceAccountsTable, SourceAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceProvider, String> provider =
      GeneratedColumn<String>(
        'provider',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceProvider>($SourceAccountsTable.$converterprovider);
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _machineIdentifierMeta = const VerificationMeta(
    'machineIdentifier',
  );
  @override
  late final GeneratedColumn<String> machineIdentifier =
      GeneratedColumn<String>(
        'machine_identifier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _baseUriMeta = const VerificationMeta(
    'baseUri',
  );
  @override
  late final GeneratedColumn<String> baseUri = GeneratedColumn<String>(
    'base_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryCodeMeta = const VerificationMeta(
    'countryCode',
  );
  @override
  late final GeneratedColumn<String> countryCode = GeneratedColumn<String>(
    'country_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _keychainRefMeta = const VerificationMeta(
    'keychainRef',
  );
  @override
  late final GeneratedColumn<String> keychainRef = GeneratedColumn<String>(
    'keychain_ref',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _offlineEntitledMeta = const VerificationMeta(
    'offlineEntitled',
  );
  @override
  late final GeneratedColumn<bool> offlineEntitled = GeneratedColumn<bool>(
    'offline_entitled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("offline_entitled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastVerifiedAt =
      GeneratedColumn<int>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>(
        $SourceAccountsTable.$converterlastVerifiedAtn,
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SourceAccountsTable.$convertercreatedAt);
  static const VerificationMeta _isOwnedMeta = const VerificationMeta(
    'isOwned',
  );
  @override
  late final GeneratedColumn<bool> isOwned = GeneratedColumn<bool>(
    'is_owned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_owned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    provider,
    displayName,
    machineIdentifier,
    baseUri,
    countryCode,
    keychainRef,
    offlineEntitled,
    lastVerifiedAt,
    createdAt,
    isOwned,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('machine_identifier')) {
      context.handle(
        _machineIdentifierMeta,
        machineIdentifier.isAcceptableOrUnknown(
          data['machine_identifier']!,
          _machineIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('base_uri')) {
      context.handle(
        _baseUriMeta,
        baseUri.isAcceptableOrUnknown(data['base_uri']!, _baseUriMeta),
      );
    }
    if (data.containsKey('country_code')) {
      context.handle(
        _countryCodeMeta,
        countryCode.isAcceptableOrUnknown(
          data['country_code']!,
          _countryCodeMeta,
        ),
      );
    }
    if (data.containsKey('keychain_ref')) {
      context.handle(
        _keychainRefMeta,
        keychainRef.isAcceptableOrUnknown(
          data['keychain_ref']!,
          _keychainRefMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_keychainRefMeta);
    }
    if (data.containsKey('offline_entitled')) {
      context.handle(
        _offlineEntitledMeta,
        offlineEntitled.isAcceptableOrUnknown(
          data['offline_entitled']!,
          _offlineEntitledMeta,
        ),
      );
    }
    if (data.containsKey('is_owned')) {
      context.handle(
        _isOwnedMeta,
        isOwned.isAcceptableOrUnknown(data['is_owned']!, _isOwnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      provider: $SourceAccountsTable.$converterprovider.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}provider'],
        )!,
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      machineIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}machine_identifier'],
      ),
      baseUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_uri'],
      ),
      countryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_code'],
      ),
      keychainRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}keychain_ref'],
      )!,
      offlineEntitled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}offline_entitled'],
      )!,
      lastVerifiedAt: $SourceAccountsTable.$converterlastVerifiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_verified_at'],
        ),
      ),
      createdAt: $SourceAccountsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      isOwned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_owned'],
      )!,
    );
  }

  @override
  $SourceAccountsTable createAlias(String alias) {
    return $SourceAccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceProvider, String, String> $converterprovider =
      const EnumNameConverter<SourceProvider>(SourceProvider.values);
  static TypeConverter<DateTime, int> $converterlastVerifiedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastVerifiedAtn =
      NullAwareTypeConverter.wrap($converterlastVerifiedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
}

class SourceAccount extends DataClass implements Insertable<SourceAccount> {
  final String id;
  final SourceProvider provider;
  final String displayName;

  /// Plex server uuid. A `ratingKey` is only unique within one server, which is
  /// why every remote track carries its account.
  final String? machineIdentifier;
  final String? baseUri;

  /// TIDAL requires this on most endpoints.
  final String? countryCode;
  final String keychainRef;

  /// True only where TIDAL has granted this integration an offline licence.
  /// Ships false; `MediaResolver.policyFor` reads it rather than assuming.
  final bool offlineEntitled;
  final DateTime? lastVerifiedAt;
  final DateTime createdAt;

  /// Plex: your own server, or a library someone shared with you. A shared
  /// library is not cacheable — see `MediaResolver.policyFor` — so an unset
  /// value defaults to the restrictive answer rather than the convenient one.
  final bool isOwned;
  const SourceAccount({
    required this.id,
    required this.provider,
    required this.displayName,
    this.machineIdentifier,
    this.baseUri,
    this.countryCode,
    required this.keychainRef,
    required this.offlineEntitled,
    this.lastVerifiedAt,
    required this.createdAt,
    required this.isOwned,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['provider'] = Variable<String>(
        $SourceAccountsTable.$converterprovider.toSql(provider),
      );
    }
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || machineIdentifier != null) {
      map['machine_identifier'] = Variable<String>(machineIdentifier);
    }
    if (!nullToAbsent || baseUri != null) {
      map['base_uri'] = Variable<String>(baseUri);
    }
    if (!nullToAbsent || countryCode != null) {
      map['country_code'] = Variable<String>(countryCode);
    }
    map['keychain_ref'] = Variable<String>(keychainRef);
    map['offline_entitled'] = Variable<bool>(offlineEntitled);
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<int>(
        $SourceAccountsTable.$converterlastVerifiedAtn.toSql(lastVerifiedAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $SourceAccountsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    map['is_owned'] = Variable<bool>(isOwned);
    return map;
  }

  SourceAccountsCompanion toCompanion(bool nullToAbsent) {
    return SourceAccountsCompanion(
      id: Value(id),
      provider: Value(provider),
      displayName: Value(displayName),
      machineIdentifier: machineIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(machineIdentifier),
      baseUri: baseUri == null && nullToAbsent
          ? const Value.absent()
          : Value(baseUri),
      countryCode: countryCode == null && nullToAbsent
          ? const Value.absent()
          : Value(countryCode),
      keychainRef: Value(keychainRef),
      offlineEntitled: Value(offlineEntitled),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
      createdAt: Value(createdAt),
      isOwned: Value(isOwned),
    );
  }

  factory SourceAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceAccount(
      id: serializer.fromJson<String>(json['id']),
      provider: $SourceAccountsTable.$converterprovider.fromJson(
        serializer.fromJson<String>(json['provider']),
      ),
      displayName: serializer.fromJson<String>(json['displayName']),
      machineIdentifier: serializer.fromJson<String?>(
        json['machineIdentifier'],
      ),
      baseUri: serializer.fromJson<String?>(json['baseUri']),
      countryCode: serializer.fromJson<String?>(json['countryCode']),
      keychainRef: serializer.fromJson<String>(json['keychainRef']),
      offlineEntitled: serializer.fromJson<bool>(json['offlineEntitled']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isOwned: serializer.fromJson<bool>(json['isOwned']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'provider': serializer.toJson<String>(
        $SourceAccountsTable.$converterprovider.toJson(provider),
      ),
      'displayName': serializer.toJson<String>(displayName),
      'machineIdentifier': serializer.toJson<String?>(machineIdentifier),
      'baseUri': serializer.toJson<String?>(baseUri),
      'countryCode': serializer.toJson<String?>(countryCode),
      'keychainRef': serializer.toJson<String>(keychainRef),
      'offlineEntitled': serializer.toJson<bool>(offlineEntitled),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isOwned': serializer.toJson<bool>(isOwned),
    };
  }

  SourceAccount copyWith({
    String? id,
    SourceProvider? provider,
    String? displayName,
    Value<String?> machineIdentifier = const Value.absent(),
    Value<String?> baseUri = const Value.absent(),
    Value<String?> countryCode = const Value.absent(),
    String? keychainRef,
    bool? offlineEntitled,
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
    DateTime? createdAt,
    bool? isOwned,
  }) => SourceAccount(
    id: id ?? this.id,
    provider: provider ?? this.provider,
    displayName: displayName ?? this.displayName,
    machineIdentifier: machineIdentifier.present
        ? machineIdentifier.value
        : this.machineIdentifier,
    baseUri: baseUri.present ? baseUri.value : this.baseUri,
    countryCode: countryCode.present ? countryCode.value : this.countryCode,
    keychainRef: keychainRef ?? this.keychainRef,
    offlineEntitled: offlineEntitled ?? this.offlineEntitled,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
    createdAt: createdAt ?? this.createdAt,
    isOwned: isOwned ?? this.isOwned,
  );
  SourceAccount copyWithCompanion(SourceAccountsCompanion data) {
    return SourceAccount(
      id: data.id.present ? data.id.value : this.id,
      provider: data.provider.present ? data.provider.value : this.provider,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      machineIdentifier: data.machineIdentifier.present
          ? data.machineIdentifier.value
          : this.machineIdentifier,
      baseUri: data.baseUri.present ? data.baseUri.value : this.baseUri,
      countryCode: data.countryCode.present
          ? data.countryCode.value
          : this.countryCode,
      keychainRef: data.keychainRef.present
          ? data.keychainRef.value
          : this.keychainRef,
      offlineEntitled: data.offlineEntitled.present
          ? data.offlineEntitled.value
          : this.offlineEntitled,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isOwned: data.isOwned.present ? data.isOwned.value : this.isOwned,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceAccount(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('displayName: $displayName, ')
          ..write('machineIdentifier: $machineIdentifier, ')
          ..write('baseUri: $baseUri, ')
          ..write('countryCode: $countryCode, ')
          ..write('keychainRef: $keychainRef, ')
          ..write('offlineEntitled: $offlineEntitled, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isOwned: $isOwned')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    provider,
    displayName,
    machineIdentifier,
    baseUri,
    countryCode,
    keychainRef,
    offlineEntitled,
    lastVerifiedAt,
    createdAt,
    isOwned,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceAccount &&
          other.id == this.id &&
          other.provider == this.provider &&
          other.displayName == this.displayName &&
          other.machineIdentifier == this.machineIdentifier &&
          other.baseUri == this.baseUri &&
          other.countryCode == this.countryCode &&
          other.keychainRef == this.keychainRef &&
          other.offlineEntitled == this.offlineEntitled &&
          other.lastVerifiedAt == this.lastVerifiedAt &&
          other.createdAt == this.createdAt &&
          other.isOwned == this.isOwned);
}

class SourceAccountsCompanion extends UpdateCompanion<SourceAccount> {
  final Value<String> id;
  final Value<SourceProvider> provider;
  final Value<String> displayName;
  final Value<String?> machineIdentifier;
  final Value<String?> baseUri;
  final Value<String?> countryCode;
  final Value<String> keychainRef;
  final Value<bool> offlineEntitled;
  final Value<DateTime?> lastVerifiedAt;
  final Value<DateTime> createdAt;
  final Value<bool> isOwned;
  final Value<int> rowid;
  const SourceAccountsCompanion({
    this.id = const Value.absent(),
    this.provider = const Value.absent(),
    this.displayName = const Value.absent(),
    this.machineIdentifier = const Value.absent(),
    this.baseUri = const Value.absent(),
    this.countryCode = const Value.absent(),
    this.keychainRef = const Value.absent(),
    this.offlineEntitled = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isOwned = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceAccountsCompanion.insert({
    required String id,
    required SourceProvider provider,
    required String displayName,
    this.machineIdentifier = const Value.absent(),
    this.baseUri = const Value.absent(),
    this.countryCode = const Value.absent(),
    required String keychainRef,
    this.offlineEntitled = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    required DateTime createdAt,
    this.isOwned = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       provider = Value(provider),
       displayName = Value(displayName),
       keychainRef = Value(keychainRef),
       createdAt = Value(createdAt);
  static Insertable<SourceAccount> custom({
    Expression<String>? id,
    Expression<String>? provider,
    Expression<String>? displayName,
    Expression<String>? machineIdentifier,
    Expression<String>? baseUri,
    Expression<String>? countryCode,
    Expression<String>? keychainRef,
    Expression<bool>? offlineEntitled,
    Expression<int>? lastVerifiedAt,
    Expression<int>? createdAt,
    Expression<bool>? isOwned,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (provider != null) 'provider': provider,
      if (displayName != null) 'display_name': displayName,
      if (machineIdentifier != null) 'machine_identifier': machineIdentifier,
      if (baseUri != null) 'base_uri': baseUri,
      if (countryCode != null) 'country_code': countryCode,
      if (keychainRef != null) 'keychain_ref': keychainRef,
      if (offlineEntitled != null) 'offline_entitled': offlineEntitled,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (isOwned != null) 'is_owned': isOwned,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceAccountsCompanion copyWith({
    Value<String>? id,
    Value<SourceProvider>? provider,
    Value<String>? displayName,
    Value<String?>? machineIdentifier,
    Value<String?>? baseUri,
    Value<String?>? countryCode,
    Value<String>? keychainRef,
    Value<bool>? offlineEntitled,
    Value<DateTime?>? lastVerifiedAt,
    Value<DateTime>? createdAt,
    Value<bool>? isOwned,
    Value<int>? rowid,
  }) {
    return SourceAccountsCompanion(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      displayName: displayName ?? this.displayName,
      machineIdentifier: machineIdentifier ?? this.machineIdentifier,
      baseUri: baseUri ?? this.baseUri,
      countryCode: countryCode ?? this.countryCode,
      keychainRef: keychainRef ?? this.keychainRef,
      offlineEntitled: offlineEntitled ?? this.offlineEntitled,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      createdAt: createdAt ?? this.createdAt,
      isOwned: isOwned ?? this.isOwned,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(
        $SourceAccountsTable.$converterprovider.toSql(provider.value),
      );
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (machineIdentifier.present) {
      map['machine_identifier'] = Variable<String>(machineIdentifier.value);
    }
    if (baseUri.present) {
      map['base_uri'] = Variable<String>(baseUri.value);
    }
    if (countryCode.present) {
      map['country_code'] = Variable<String>(countryCode.value);
    }
    if (keychainRef.present) {
      map['keychain_ref'] = Variable<String>(keychainRef.value);
    }
    if (offlineEntitled.present) {
      map['offline_entitled'] = Variable<bool>(offlineEntitled.value);
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<int>(
        $SourceAccountsTable.$converterlastVerifiedAtn.toSql(
          lastVerifiedAt.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $SourceAccountsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (isOwned.present) {
      map['is_owned'] = Variable<bool>(isOwned.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceAccountsCompanion(')
          ..write('id: $id, ')
          ..write('provider: $provider, ')
          ..write('displayName: $displayName, ')
          ..write('machineIdentifier: $machineIdentifier, ')
          ..write('baseUri: $baseUri, ')
          ..write('countryCode: $countryCode, ')
          ..write('keychainRef: $keychainRef, ')
          ..write('offlineEntitled: $offlineEntitled, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('isOwned: $isOwned, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DanceTypesTable extends DanceTypes
    with TableInfo<$DanceTypesTable, DanceType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DanceTypesTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _ttsTemplateMeta = const VerificationMeta(
    'ttsTemplate',
  );
  @override
  late final GeneratedColumn<String> ttsTemplate = GeneratedColumn<String>(
    'tts_template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Next dance: {name}'),
  );
  static const VerificationMeta _customClipPathMeta = const VerificationMeta(
    'customClipPath',
  );
  @override
  late final GeneratedColumn<String> customClipPath = GeneratedColumn<String>(
    'custom_clip_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMinMeta = const VerificationMeta('bpmMin');
  @override
  late final GeneratedColumn<double> bpmMin = GeneratedColumn<double>(
    'bpm_min',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bpmMaxMeta = const VerificationMeta('bpmMax');
  @override
  late final GeneratedColumn<double> bpmMax = GeneratedColumn<double>(
    'bpm_max',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeSignatureMeta = const VerificationMeta(
    'timeSignature',
  );
  @override
  late final GeneratedColumn<String> timeSignature = GeneratedColumn<String>(
    'time_signature',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortIndexMeta = const VerificationMeta(
    'sortIndex',
  );
  @override
  late final GeneratedColumn<int> sortIndex = GeneratedColumn<int>(
    'sort_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    slug,
    ttsTemplate,
    customClipPath,
    bpmMin,
    bpmMax,
    timeSignature,
    colorHex,
    sortIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'dance_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<DanceType> instance, {
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
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('tts_template')) {
      context.handle(
        _ttsTemplateMeta,
        ttsTemplate.isAcceptableOrUnknown(
          data['tts_template']!,
          _ttsTemplateMeta,
        ),
      );
    }
    if (data.containsKey('custom_clip_path')) {
      context.handle(
        _customClipPathMeta,
        customClipPath.isAcceptableOrUnknown(
          data['custom_clip_path']!,
          _customClipPathMeta,
        ),
      );
    }
    if (data.containsKey('bpm_min')) {
      context.handle(
        _bpmMinMeta,
        bpmMin.isAcceptableOrUnknown(data['bpm_min']!, _bpmMinMeta),
      );
    }
    if (data.containsKey('bpm_max')) {
      context.handle(
        _bpmMaxMeta,
        bpmMax.isAcceptableOrUnknown(data['bpm_max']!, _bpmMaxMeta),
      );
    }
    if (data.containsKey('time_signature')) {
      context.handle(
        _timeSignatureMeta,
        timeSignature.isAcceptableOrUnknown(
          data['time_signature']!,
          _timeSignatureMeta,
        ),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('sort_index')) {
      context.handle(
        _sortIndexMeta,
        sortIndex.isAcceptableOrUnknown(data['sort_index']!, _sortIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DanceType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DanceType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
      ttsTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_template'],
      )!,
      customClipPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_clip_path'],
      ),
      bpmMin: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bpm_min'],
      ),
      bpmMax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bpm_max'],
      ),
      timeSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_signature'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      sortIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_index'],
      )!,
    );
  }

  @override
  $DanceTypesTable createAlias(String alias) {
    return $DanceTypesTable(attachedDatabase, alias);
  }
}

class DanceType extends DataClass implements Insertable<DanceType> {
  final String id;

  /// 'Viennese Waltz'.
  final String name;

  /// 'viennese-waltz'.
  final String slug;

  /// `{name}` and `{next}` are substituted at render time.
  final String ttsTemplate;

  /// A pre-recorded MC clip, which wins over TTS when present.
  final String? customClipPath;
  final double? bpmMin;
  final double? bpmMax;

  /// '3/4', '4/4'.
  final String? timeSignature;
  final String? colorHex;
  final int sortIndex;
  const DanceType({
    required this.id,
    required this.name,
    required this.slug,
    required this.ttsTemplate,
    this.customClipPath,
    this.bpmMin,
    this.bpmMax,
    this.timeSignature,
    this.colorHex,
    required this.sortIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['slug'] = Variable<String>(slug);
    map['tts_template'] = Variable<String>(ttsTemplate);
    if (!nullToAbsent || customClipPath != null) {
      map['custom_clip_path'] = Variable<String>(customClipPath);
    }
    if (!nullToAbsent || bpmMin != null) {
      map['bpm_min'] = Variable<double>(bpmMin);
    }
    if (!nullToAbsent || bpmMax != null) {
      map['bpm_max'] = Variable<double>(bpmMax);
    }
    if (!nullToAbsent || timeSignature != null) {
      map['time_signature'] = Variable<String>(timeSignature);
    }
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['sort_index'] = Variable<int>(sortIndex);
    return map;
  }

  DanceTypesCompanion toCompanion(bool nullToAbsent) {
    return DanceTypesCompanion(
      id: Value(id),
      name: Value(name),
      slug: Value(slug),
      ttsTemplate: Value(ttsTemplate),
      customClipPath: customClipPath == null && nullToAbsent
          ? const Value.absent()
          : Value(customClipPath),
      bpmMin: bpmMin == null && nullToAbsent
          ? const Value.absent()
          : Value(bpmMin),
      bpmMax: bpmMax == null && nullToAbsent
          ? const Value.absent()
          : Value(bpmMax),
      timeSignature: timeSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(timeSignature),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      sortIndex: Value(sortIndex),
    );
  }

  factory DanceType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DanceType(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      slug: serializer.fromJson<String>(json['slug']),
      ttsTemplate: serializer.fromJson<String>(json['ttsTemplate']),
      customClipPath: serializer.fromJson<String?>(json['customClipPath']),
      bpmMin: serializer.fromJson<double?>(json['bpmMin']),
      bpmMax: serializer.fromJson<double?>(json['bpmMax']),
      timeSignature: serializer.fromJson<String?>(json['timeSignature']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      sortIndex: serializer.fromJson<int>(json['sortIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'slug': serializer.toJson<String>(slug),
      'ttsTemplate': serializer.toJson<String>(ttsTemplate),
      'customClipPath': serializer.toJson<String?>(customClipPath),
      'bpmMin': serializer.toJson<double?>(bpmMin),
      'bpmMax': serializer.toJson<double?>(bpmMax),
      'timeSignature': serializer.toJson<String?>(timeSignature),
      'colorHex': serializer.toJson<String?>(colorHex),
      'sortIndex': serializer.toJson<int>(sortIndex),
    };
  }

  DanceType copyWith({
    String? id,
    String? name,
    String? slug,
    String? ttsTemplate,
    Value<String?> customClipPath = const Value.absent(),
    Value<double?> bpmMin = const Value.absent(),
    Value<double?> bpmMax = const Value.absent(),
    Value<String?> timeSignature = const Value.absent(),
    Value<String?> colorHex = const Value.absent(),
    int? sortIndex,
  }) => DanceType(
    id: id ?? this.id,
    name: name ?? this.name,
    slug: slug ?? this.slug,
    ttsTemplate: ttsTemplate ?? this.ttsTemplate,
    customClipPath: customClipPath.present
        ? customClipPath.value
        : this.customClipPath,
    bpmMin: bpmMin.present ? bpmMin.value : this.bpmMin,
    bpmMax: bpmMax.present ? bpmMax.value : this.bpmMax,
    timeSignature: timeSignature.present
        ? timeSignature.value
        : this.timeSignature,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    sortIndex: sortIndex ?? this.sortIndex,
  );
  DanceType copyWithCompanion(DanceTypesCompanion data) {
    return DanceType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      slug: data.slug.present ? data.slug.value : this.slug,
      ttsTemplate: data.ttsTemplate.present
          ? data.ttsTemplate.value
          : this.ttsTemplate,
      customClipPath: data.customClipPath.present
          ? data.customClipPath.value
          : this.customClipPath,
      bpmMin: data.bpmMin.present ? data.bpmMin.value : this.bpmMin,
      bpmMax: data.bpmMax.present ? data.bpmMax.value : this.bpmMax,
      timeSignature: data.timeSignature.present
          ? data.timeSignature.value
          : this.timeSignature,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      sortIndex: data.sortIndex.present ? data.sortIndex.value : this.sortIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DanceType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('ttsTemplate: $ttsTemplate, ')
          ..write('customClipPath: $customClipPath, ')
          ..write('bpmMin: $bpmMin, ')
          ..write('bpmMax: $bpmMax, ')
          ..write('timeSignature: $timeSignature, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortIndex: $sortIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    slug,
    ttsTemplate,
    customClipPath,
    bpmMin,
    bpmMax,
    timeSignature,
    colorHex,
    sortIndex,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DanceType &&
          other.id == this.id &&
          other.name == this.name &&
          other.slug == this.slug &&
          other.ttsTemplate == this.ttsTemplate &&
          other.customClipPath == this.customClipPath &&
          other.bpmMin == this.bpmMin &&
          other.bpmMax == this.bpmMax &&
          other.timeSignature == this.timeSignature &&
          other.colorHex == this.colorHex &&
          other.sortIndex == this.sortIndex);
}

class DanceTypesCompanion extends UpdateCompanion<DanceType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> slug;
  final Value<String> ttsTemplate;
  final Value<String?> customClipPath;
  final Value<double?> bpmMin;
  final Value<double?> bpmMax;
  final Value<String?> timeSignature;
  final Value<String?> colorHex;
  final Value<int> sortIndex;
  final Value<int> rowid;
  const DanceTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.slug = const Value.absent(),
    this.ttsTemplate = const Value.absent(),
    this.customClipPath = const Value.absent(),
    this.bpmMin = const Value.absent(),
    this.bpmMax = const Value.absent(),
    this.timeSignature = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DanceTypesCompanion.insert({
    required String id,
    required String name,
    required String slug,
    this.ttsTemplate = const Value.absent(),
    this.customClipPath = const Value.absent(),
    this.bpmMin = const Value.absent(),
    this.bpmMax = const Value.absent(),
    this.timeSignature = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.sortIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       slug = Value(slug);
  static Insertable<DanceType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? slug,
    Expression<String>? ttsTemplate,
    Expression<String>? customClipPath,
    Expression<double>? bpmMin,
    Expression<double>? bpmMax,
    Expression<String>? timeSignature,
    Expression<String>? colorHex,
    Expression<int>? sortIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (ttsTemplate != null) 'tts_template': ttsTemplate,
      if (customClipPath != null) 'custom_clip_path': customClipPath,
      if (bpmMin != null) 'bpm_min': bpmMin,
      if (bpmMax != null) 'bpm_max': bpmMax,
      if (timeSignature != null) 'time_signature': timeSignature,
      if (colorHex != null) 'color_hex': colorHex,
      if (sortIndex != null) 'sort_index': sortIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DanceTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? slug,
    Value<String>? ttsTemplate,
    Value<String?>? customClipPath,
    Value<double?>? bpmMin,
    Value<double?>? bpmMax,
    Value<String?>? timeSignature,
    Value<String?>? colorHex,
    Value<int>? sortIndex,
    Value<int>? rowid,
  }) {
    return DanceTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      ttsTemplate: ttsTemplate ?? this.ttsTemplate,
      customClipPath: customClipPath ?? this.customClipPath,
      bpmMin: bpmMin ?? this.bpmMin,
      bpmMax: bpmMax ?? this.bpmMax,
      timeSignature: timeSignature ?? this.timeSignature,
      colorHex: colorHex ?? this.colorHex,
      sortIndex: sortIndex ?? this.sortIndex,
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
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (ttsTemplate.present) {
      map['tts_template'] = Variable<String>(ttsTemplate.value);
    }
    if (customClipPath.present) {
      map['custom_clip_path'] = Variable<String>(customClipPath.value);
    }
    if (bpmMin.present) {
      map['bpm_min'] = Variable<double>(bpmMin.value);
    }
    if (bpmMax.present) {
      map['bpm_max'] = Variable<double>(bpmMax.value);
    }
    if (timeSignature.present) {
      map['time_signature'] = Variable<String>(timeSignature.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (sortIndex.present) {
      map['sort_index'] = Variable<int>(sortIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DanceTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('ttsTemplate: $ttsTemplate, ')
          ..write('customClipPath: $customClipPath, ')
          ..write('bpmMin: $bpmMin, ')
          ..write('bpmMax: $bpmMax, ')
          ..write('timeSignature: $timeSignature, ')
          ..write('colorHex: $colorHex, ')
          ..write('sortIndex: $sortIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TracksTable extends Tracks with TableInfo<$TracksTable, Track> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SourceType, String> sourceType =
      GeneratedColumn<String>(
        'source_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SourceType>($TracksTable.$convertersourceType);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES source_accounts (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentUriMeta = const VerificationMeta(
    'contentUri',
  );
  @override
  late final GeneratedColumn<String> contentUri = GeneratedColumn<String>(
    'content_uri',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _securityBookmarkMeta = const VerificationMeta(
    'securityBookmark',
  );
  @override
  late final GeneratedColumn<Uint8List> securityBookmark =
      GeneratedColumn<Uint8List>(
        'security_bookmark',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePartIdMeta = const VerificationMeta(
    'sourcePartId',
  );
  @override
  late final GeneratedColumn<String> sourcePartId = GeneratedColumn<String>(
    'source_part_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUpdatedAtMeta = const VerificationMeta(
    'sourceUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> sourceUpdatedAt = GeneratedColumn<int>(
    'source_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _artistMeta = const VerificationMeta('artist');
  @override
  late final GeneratedColumn<String> artist = GeneratedColumn<String>(
    'artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _albumArtistMeta = const VerificationMeta(
    'albumArtist',
  );
  @override
  late final GeneratedColumn<String> albumArtist = GeneratedColumn<String>(
    'album_artist',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> durationMs =
      GeneratedColumn<int>(
        'duration_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($TracksTable.$converterdurationMs);
  static const VerificationMeta _bpmMeta = const VerificationMeta('bpm');
  @override
  late final GeneratedColumn<double> bpm = GeneratedColumn<double>(
    'bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _musicalKeyMeta = const VerificationMeta(
    'musicalKey',
  );
  @override
  late final GeneratedColumn<String> musicalKey = GeneratedColumn<String>(
    'musical_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codecMeta = const VerificationMeta('codec');
  @override
  late final GeneratedColumn<String> codec = GeneratedColumn<String>(
    'codec',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bitrateKbpsMeta = const VerificationMeta(
    'bitrateKbps',
  );
  @override
  late final GeneratedColumn<int> bitrateKbps = GeneratedColumn<int>(
    'bitrate_kbps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sampleRateHzMeta = const VerificationMeta(
    'sampleRateHz',
  );
  @override
  late final GeneratedColumn<int> sampleRateHz = GeneratedColumn<int>(
    'sample_rate_hz',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkUrlMeta = const VerificationMeta(
    'artworkUrl',
  );
  @override
  late final GeneratedColumn<String> artworkUrl = GeneratedColumn<String>(
    'artwork_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _artworkCachePathMeta = const VerificationMeta(
    'artworkCachePath',
  );
  @override
  late final GeneratedColumn<String> artworkCachePath = GeneratedColumn<String>(
    'artwork_cache_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gainDbMeta = const VerificationMeta('gainDb');
  @override
  late final GeneratedColumn<double> gainDb = GeneratedColumn<double>(
    'gain_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> cueInMs =
      GeneratedColumn<int>(
        'cue_in_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($TracksTable.$convertercueInMs);
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> cueOutMs =
      GeneratedColumn<int>(
        'cue_out_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>($TracksTable.$convertercueOutMsn);
  static const VerificationMeta _isDrmMeta = const VerificationMeta('isDrm');
  @override
  late final GeneratedColumn<bool> isDrm = GeneratedColumn<bool>(
    'is_drm',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_drm" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CachePolicy, String> cachePolicy =
      GeneratedColumn<String>(
        'cache_policy',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('allow'),
      ).withConverter<CachePolicy>($TracksTable.$convertercachePolicy);
  static const VerificationMeta _defaultDanceTypeIdMeta =
      const VerificationMeta('defaultDanceTypeId');
  @override
  late final GeneratedColumn<String> defaultDanceTypeId =
      GeneratedColumn<String>(
        'default_dance_type_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES dance_types (id) ON DELETE SET NULL',
        ),
      );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> addedAt =
      GeneratedColumn<int>(
        'added_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TracksTable.$converteraddedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TracksTable.$converterupdatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastVerifiedAt =
      GeneratedColumn<int>(
        'last_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($TracksTable.$converterlastVerifiedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceType,
    accountId,
    localPath,
    contentUri,
    securityBookmark,
    sourceId,
    sourcePartId,
    sourceUpdatedAt,
    title,
    artist,
    album,
    albumArtist,
    year,
    durationMs,
    bpm,
    musicalKey,
    codec,
    bitrateKbps,
    sampleRateHz,
    artworkUrl,
    artworkCachePath,
    gainDb,
    cueInMs,
    cueOutMs,
    isDrm,
    cachePolicy,
    defaultDanceTypeId,
    addedAt,
    updatedAt,
    lastVerifiedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Track> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('content_uri')) {
      context.handle(
        _contentUriMeta,
        contentUri.isAcceptableOrUnknown(data['content_uri']!, _contentUriMeta),
      );
    }
    if (data.containsKey('security_bookmark')) {
      context.handle(
        _securityBookmarkMeta,
        securityBookmark.isAcceptableOrUnknown(
          data['security_bookmark']!,
          _securityBookmarkMeta,
        ),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('source_part_id')) {
      context.handle(
        _sourcePartIdMeta,
        sourcePartId.isAcceptableOrUnknown(
          data['source_part_id']!,
          _sourcePartIdMeta,
        ),
      );
    }
    if (data.containsKey('source_updated_at')) {
      context.handle(
        _sourceUpdatedAtMeta,
        sourceUpdatedAt.isAcceptableOrUnknown(
          data['source_updated_at']!,
          _sourceUpdatedAtMeta,
        ),
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
    if (data.containsKey('artist')) {
      context.handle(
        _artistMeta,
        artist.isAcceptableOrUnknown(data['artist']!, _artistMeta),
      );
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('album_artist')) {
      context.handle(
        _albumArtistMeta,
        albumArtist.isAcceptableOrUnknown(
          data['album_artist']!,
          _albumArtistMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('bpm')) {
      context.handle(
        _bpmMeta,
        bpm.isAcceptableOrUnknown(data['bpm']!, _bpmMeta),
      );
    }
    if (data.containsKey('musical_key')) {
      context.handle(
        _musicalKeyMeta,
        musicalKey.isAcceptableOrUnknown(data['musical_key']!, _musicalKeyMeta),
      );
    }
    if (data.containsKey('codec')) {
      context.handle(
        _codecMeta,
        codec.isAcceptableOrUnknown(data['codec']!, _codecMeta),
      );
    }
    if (data.containsKey('bitrate_kbps')) {
      context.handle(
        _bitrateKbpsMeta,
        bitrateKbps.isAcceptableOrUnknown(
          data['bitrate_kbps']!,
          _bitrateKbpsMeta,
        ),
      );
    }
    if (data.containsKey('sample_rate_hz')) {
      context.handle(
        _sampleRateHzMeta,
        sampleRateHz.isAcceptableOrUnknown(
          data['sample_rate_hz']!,
          _sampleRateHzMeta,
        ),
      );
    }
    if (data.containsKey('artwork_url')) {
      context.handle(
        _artworkUrlMeta,
        artworkUrl.isAcceptableOrUnknown(data['artwork_url']!, _artworkUrlMeta),
      );
    }
    if (data.containsKey('artwork_cache_path')) {
      context.handle(
        _artworkCachePathMeta,
        artworkCachePath.isAcceptableOrUnknown(
          data['artwork_cache_path']!,
          _artworkCachePathMeta,
        ),
      );
    }
    if (data.containsKey('gain_db')) {
      context.handle(
        _gainDbMeta,
        gainDb.isAcceptableOrUnknown(data['gain_db']!, _gainDbMeta),
      );
    }
    if (data.containsKey('is_drm')) {
      context.handle(
        _isDrmMeta,
        isDrm.isAcceptableOrUnknown(data['is_drm']!, _isDrmMeta),
      );
    }
    if (data.containsKey('default_dance_type_id')) {
      context.handle(
        _defaultDanceTypeIdMeta,
        defaultDanceTypeId.isAcceptableOrUnknown(
          data['default_dance_type_id']!,
          _defaultDanceTypeIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Track map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Track(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceType: $TracksTable.$convertersourceType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source_type'],
        )!,
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      contentUri: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_uri'],
      ),
      securityBookmark: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}security_bookmark'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      sourcePartId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_part_id'],
      ),
      sourceUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_updated_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      artist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artist'],
      ),
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      albumArtist: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album_artist'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      durationMs: $TracksTable.$converterdurationMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration_ms'],
        )!,
      ),
      bpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bpm'],
      ),
      musicalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}musical_key'],
      ),
      codec: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codec'],
      ),
      bitrateKbps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bitrate_kbps'],
      ),
      sampleRateHz: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_rate_hz'],
      ),
      artworkUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_url'],
      ),
      artworkCachePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}artwork_cache_path'],
      ),
      gainDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gain_db'],
      )!,
      cueInMs: $TracksTable.$convertercueInMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}cue_in_ms'],
        )!,
      ),
      cueOutMs: $TracksTable.$convertercueOutMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}cue_out_ms'],
        ),
      ),
      isDrm: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_drm'],
      )!,
      cachePolicy: $TracksTable.$convertercachePolicy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cache_policy'],
        )!,
      ),
      defaultDanceTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_dance_type_id'],
      ),
      addedAt: $TracksTable.$converteraddedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}added_at'],
        )!,
      ),
      updatedAt: $TracksTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      lastVerifiedAt: $TracksTable.$converterlastVerifiedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_verified_at'],
        ),
      ),
    );
  }

  @override
  $TracksTable createAlias(String alias) {
    return $TracksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SourceType, String, String> $convertersourceType =
      const EnumNameConverter<SourceType>(SourceType.values);
  static TypeConverter<Duration, int> $converterdurationMs =
      const MillisDurationConverter();
  static TypeConverter<Duration, int> $convertercueInMs =
      const MillisDurationConverter();
  static TypeConverter<Duration, int> $convertercueOutMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $convertercueOutMsn =
      NullAwareTypeConverter.wrap($convertercueOutMs);
  static TypeConverter<CachePolicy, String> $convertercachePolicy =
      const CachePolicyConverter();
  static TypeConverter<DateTime, int> $converteraddedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastVerifiedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastVerifiedAtn =
      NullAwareTypeConverter.wrap($converterlastVerifiedAt);
}

class Track extends DataClass implements Insertable<Track> {
  final String id;
  final SourceType sourceType;
  final String? accountId;
  final String? localPath;

  /// Android SAF `content://` URI.
  final String? contentUri;

  /// iOS/macOS security-scoped bookmark. Raw paths from a file picker stop
  /// resolving after relaunch; this is the durable handle.
  final Uint8List? securityBookmark;

  /// Plex `ratingKey` or TIDAL track id.
  final String? sourceId;

  /// Plex part id, for the direct-play URL.
  final String? sourcePartId;

  /// Plex part `updatedAt`, used to bust the cache when the file changes.
  final int? sourceUpdatedAt;
  final String title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final int? year;
  final Duration durationMs;
  final double? bpm;
  final String? musicalKey;
  final String? codec;
  final int? bitrateKbps;
  final int? sampleRateHz;
  final String? artworkUrl;
  final String? artworkCachePath;

  /// ReplayGain or a manual trim.
  final double gainDb;

  /// Skips leading silence or a count-in.
  final Duration cueInMs;

  /// Null plays to the end.
  final Duration? cueOutMs;
  final bool isDrm;
  final CachePolicy cachePolicy;
  final String? defaultDanceTypeId;
  final DateTime addedAt;
  final DateTime updatedAt;
  final DateTime? lastVerifiedAt;
  const Track({
    required this.id,
    required this.sourceType,
    this.accountId,
    this.localPath,
    this.contentUri,
    this.securityBookmark,
    this.sourceId,
    this.sourcePartId,
    this.sourceUpdatedAt,
    required this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.year,
    required this.durationMs,
    this.bpm,
    this.musicalKey,
    this.codec,
    this.bitrateKbps,
    this.sampleRateHz,
    this.artworkUrl,
    this.artworkCachePath,
    required this.gainDb,
    required this.cueInMs,
    this.cueOutMs,
    required this.isDrm,
    required this.cachePolicy,
    this.defaultDanceTypeId,
    required this.addedAt,
    required this.updatedAt,
    this.lastVerifiedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['source_type'] = Variable<String>(
        $TracksTable.$convertersourceType.toSql(sourceType),
      );
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || contentUri != null) {
      map['content_uri'] = Variable<String>(contentUri);
    }
    if (!nullToAbsent || securityBookmark != null) {
      map['security_bookmark'] = Variable<Uint8List>(securityBookmark);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    if (!nullToAbsent || sourcePartId != null) {
      map['source_part_id'] = Variable<String>(sourcePartId);
    }
    if (!nullToAbsent || sourceUpdatedAt != null) {
      map['source_updated_at'] = Variable<int>(sourceUpdatedAt);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || artist != null) {
      map['artist'] = Variable<String>(artist);
    }
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || albumArtist != null) {
      map['album_artist'] = Variable<String>(albumArtist);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    {
      map['duration_ms'] = Variable<int>(
        $TracksTable.$converterdurationMs.toSql(durationMs),
      );
    }
    if (!nullToAbsent || bpm != null) {
      map['bpm'] = Variable<double>(bpm);
    }
    if (!nullToAbsent || musicalKey != null) {
      map['musical_key'] = Variable<String>(musicalKey);
    }
    if (!nullToAbsent || codec != null) {
      map['codec'] = Variable<String>(codec);
    }
    if (!nullToAbsent || bitrateKbps != null) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps);
    }
    if (!nullToAbsent || sampleRateHz != null) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz);
    }
    if (!nullToAbsent || artworkUrl != null) {
      map['artwork_url'] = Variable<String>(artworkUrl);
    }
    if (!nullToAbsent || artworkCachePath != null) {
      map['artwork_cache_path'] = Variable<String>(artworkCachePath);
    }
    map['gain_db'] = Variable<double>(gainDb);
    {
      map['cue_in_ms'] = Variable<int>(
        $TracksTable.$convertercueInMs.toSql(cueInMs),
      );
    }
    if (!nullToAbsent || cueOutMs != null) {
      map['cue_out_ms'] = Variable<int>(
        $TracksTable.$convertercueOutMsn.toSql(cueOutMs),
      );
    }
    map['is_drm'] = Variable<bool>(isDrm);
    {
      map['cache_policy'] = Variable<String>(
        $TracksTable.$convertercachePolicy.toSql(cachePolicy),
      );
    }
    if (!nullToAbsent || defaultDanceTypeId != null) {
      map['default_dance_type_id'] = Variable<String>(defaultDanceTypeId);
    }
    {
      map['added_at'] = Variable<int>(
        $TracksTable.$converteraddedAt.toSql(addedAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $TracksTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || lastVerifiedAt != null) {
      map['last_verified_at'] = Variable<int>(
        $TracksTable.$converterlastVerifiedAtn.toSql(lastVerifiedAt),
      );
    }
    return map;
  }

  TracksCompanion toCompanion(bool nullToAbsent) {
    return TracksCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      contentUri: contentUri == null && nullToAbsent
          ? const Value.absent()
          : Value(contentUri),
      securityBookmark: securityBookmark == null && nullToAbsent
          ? const Value.absent()
          : Value(securityBookmark),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      sourcePartId: sourcePartId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePartId),
      sourceUpdatedAt: sourceUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUpdatedAt),
      title: Value(title),
      artist: artist == null && nullToAbsent
          ? const Value.absent()
          : Value(artist),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      albumArtist: albumArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(albumArtist),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      durationMs: Value(durationMs),
      bpm: bpm == null && nullToAbsent ? const Value.absent() : Value(bpm),
      musicalKey: musicalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(musicalKey),
      codec: codec == null && nullToAbsent
          ? const Value.absent()
          : Value(codec),
      bitrateKbps: bitrateKbps == null && nullToAbsent
          ? const Value.absent()
          : Value(bitrateKbps),
      sampleRateHz: sampleRateHz == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleRateHz),
      artworkUrl: artworkUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkUrl),
      artworkCachePath: artworkCachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(artworkCachePath),
      gainDb: Value(gainDb),
      cueInMs: Value(cueInMs),
      cueOutMs: cueOutMs == null && nullToAbsent
          ? const Value.absent()
          : Value(cueOutMs),
      isDrm: Value(isDrm),
      cachePolicy: Value(cachePolicy),
      defaultDanceTypeId: defaultDanceTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDanceTypeId),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      lastVerifiedAt: lastVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastVerifiedAt),
    );
  }

  factory Track.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Track(
      id: serializer.fromJson<String>(json['id']),
      sourceType: $TracksTable.$convertersourceType.fromJson(
        serializer.fromJson<String>(json['sourceType']),
      ),
      accountId: serializer.fromJson<String?>(json['accountId']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      contentUri: serializer.fromJson<String?>(json['contentUri']),
      securityBookmark: serializer.fromJson<Uint8List?>(
        json['securityBookmark'],
      ),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      sourcePartId: serializer.fromJson<String?>(json['sourcePartId']),
      sourceUpdatedAt: serializer.fromJson<int?>(json['sourceUpdatedAt']),
      title: serializer.fromJson<String>(json['title']),
      artist: serializer.fromJson<String?>(json['artist']),
      album: serializer.fromJson<String?>(json['album']),
      albumArtist: serializer.fromJson<String?>(json['albumArtist']),
      year: serializer.fromJson<int?>(json['year']),
      durationMs: serializer.fromJson<Duration>(json['durationMs']),
      bpm: serializer.fromJson<double?>(json['bpm']),
      musicalKey: serializer.fromJson<String?>(json['musicalKey']),
      codec: serializer.fromJson<String?>(json['codec']),
      bitrateKbps: serializer.fromJson<int?>(json['bitrateKbps']),
      sampleRateHz: serializer.fromJson<int?>(json['sampleRateHz']),
      artworkUrl: serializer.fromJson<String?>(json['artworkUrl']),
      artworkCachePath: serializer.fromJson<String?>(json['artworkCachePath']),
      gainDb: serializer.fromJson<double>(json['gainDb']),
      cueInMs: serializer.fromJson<Duration>(json['cueInMs']),
      cueOutMs: serializer.fromJson<Duration?>(json['cueOutMs']),
      isDrm: serializer.fromJson<bool>(json['isDrm']),
      cachePolicy: serializer.fromJson<CachePolicy>(json['cachePolicy']),
      defaultDanceTypeId: serializer.fromJson<String?>(
        json['defaultDanceTypeId'],
      ),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastVerifiedAt: serializer.fromJson<DateTime?>(json['lastVerifiedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(
        $TracksTable.$convertersourceType.toJson(sourceType),
      ),
      'accountId': serializer.toJson<String?>(accountId),
      'localPath': serializer.toJson<String?>(localPath),
      'contentUri': serializer.toJson<String?>(contentUri),
      'securityBookmark': serializer.toJson<Uint8List?>(securityBookmark),
      'sourceId': serializer.toJson<String?>(sourceId),
      'sourcePartId': serializer.toJson<String?>(sourcePartId),
      'sourceUpdatedAt': serializer.toJson<int?>(sourceUpdatedAt),
      'title': serializer.toJson<String>(title),
      'artist': serializer.toJson<String?>(artist),
      'album': serializer.toJson<String?>(album),
      'albumArtist': serializer.toJson<String?>(albumArtist),
      'year': serializer.toJson<int?>(year),
      'durationMs': serializer.toJson<Duration>(durationMs),
      'bpm': serializer.toJson<double?>(bpm),
      'musicalKey': serializer.toJson<String?>(musicalKey),
      'codec': serializer.toJson<String?>(codec),
      'bitrateKbps': serializer.toJson<int?>(bitrateKbps),
      'sampleRateHz': serializer.toJson<int?>(sampleRateHz),
      'artworkUrl': serializer.toJson<String?>(artworkUrl),
      'artworkCachePath': serializer.toJson<String?>(artworkCachePath),
      'gainDb': serializer.toJson<double>(gainDb),
      'cueInMs': serializer.toJson<Duration>(cueInMs),
      'cueOutMs': serializer.toJson<Duration?>(cueOutMs),
      'isDrm': serializer.toJson<bool>(isDrm),
      'cachePolicy': serializer.toJson<CachePolicy>(cachePolicy),
      'defaultDanceTypeId': serializer.toJson<String?>(defaultDanceTypeId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastVerifiedAt': serializer.toJson<DateTime?>(lastVerifiedAt),
    };
  }

  Track copyWith({
    String? id,
    SourceType? sourceType,
    Value<String?> accountId = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<String?> contentUri = const Value.absent(),
    Value<Uint8List?> securityBookmark = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    Value<String?> sourcePartId = const Value.absent(),
    Value<int?> sourceUpdatedAt = const Value.absent(),
    String? title,
    Value<String?> artist = const Value.absent(),
    Value<String?> album = const Value.absent(),
    Value<String?> albumArtist = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Duration? durationMs,
    Value<double?> bpm = const Value.absent(),
    Value<String?> musicalKey = const Value.absent(),
    Value<String?> codec = const Value.absent(),
    Value<int?> bitrateKbps = const Value.absent(),
    Value<int?> sampleRateHz = const Value.absent(),
    Value<String?> artworkUrl = const Value.absent(),
    Value<String?> artworkCachePath = const Value.absent(),
    double? gainDb,
    Duration? cueInMs,
    Value<Duration?> cueOutMs = const Value.absent(),
    bool? isDrm,
    CachePolicy? cachePolicy,
    Value<String?> defaultDanceTypeId = const Value.absent(),
    DateTime? addedAt,
    DateTime? updatedAt,
    Value<DateTime?> lastVerifiedAt = const Value.absent(),
  }) => Track(
    id: id ?? this.id,
    sourceType: sourceType ?? this.sourceType,
    accountId: accountId.present ? accountId.value : this.accountId,
    localPath: localPath.present ? localPath.value : this.localPath,
    contentUri: contentUri.present ? contentUri.value : this.contentUri,
    securityBookmark: securityBookmark.present
        ? securityBookmark.value
        : this.securityBookmark,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    sourcePartId: sourcePartId.present ? sourcePartId.value : this.sourcePartId,
    sourceUpdatedAt: sourceUpdatedAt.present
        ? sourceUpdatedAt.value
        : this.sourceUpdatedAt,
    title: title ?? this.title,
    artist: artist.present ? artist.value : this.artist,
    album: album.present ? album.value : this.album,
    albumArtist: albumArtist.present ? albumArtist.value : this.albumArtist,
    year: year.present ? year.value : this.year,
    durationMs: durationMs ?? this.durationMs,
    bpm: bpm.present ? bpm.value : this.bpm,
    musicalKey: musicalKey.present ? musicalKey.value : this.musicalKey,
    codec: codec.present ? codec.value : this.codec,
    bitrateKbps: bitrateKbps.present ? bitrateKbps.value : this.bitrateKbps,
    sampleRateHz: sampleRateHz.present ? sampleRateHz.value : this.sampleRateHz,
    artworkUrl: artworkUrl.present ? artworkUrl.value : this.artworkUrl,
    artworkCachePath: artworkCachePath.present
        ? artworkCachePath.value
        : this.artworkCachePath,
    gainDb: gainDb ?? this.gainDb,
    cueInMs: cueInMs ?? this.cueInMs,
    cueOutMs: cueOutMs.present ? cueOutMs.value : this.cueOutMs,
    isDrm: isDrm ?? this.isDrm,
    cachePolicy: cachePolicy ?? this.cachePolicy,
    defaultDanceTypeId: defaultDanceTypeId.present
        ? defaultDanceTypeId.value
        : this.defaultDanceTypeId,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastVerifiedAt: lastVerifiedAt.present
        ? lastVerifiedAt.value
        : this.lastVerifiedAt,
  );
  Track copyWithCompanion(TracksCompanion data) {
    return Track(
      id: data.id.present ? data.id.value : this.id,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      contentUri: data.contentUri.present
          ? data.contentUri.value
          : this.contentUri,
      securityBookmark: data.securityBookmark.present
          ? data.securityBookmark.value
          : this.securityBookmark,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      sourcePartId: data.sourcePartId.present
          ? data.sourcePartId.value
          : this.sourcePartId,
      sourceUpdatedAt: data.sourceUpdatedAt.present
          ? data.sourceUpdatedAt.value
          : this.sourceUpdatedAt,
      title: data.title.present ? data.title.value : this.title,
      artist: data.artist.present ? data.artist.value : this.artist,
      album: data.album.present ? data.album.value : this.album,
      albumArtist: data.albumArtist.present
          ? data.albumArtist.value
          : this.albumArtist,
      year: data.year.present ? data.year.value : this.year,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      bpm: data.bpm.present ? data.bpm.value : this.bpm,
      musicalKey: data.musicalKey.present
          ? data.musicalKey.value
          : this.musicalKey,
      codec: data.codec.present ? data.codec.value : this.codec,
      bitrateKbps: data.bitrateKbps.present
          ? data.bitrateKbps.value
          : this.bitrateKbps,
      sampleRateHz: data.sampleRateHz.present
          ? data.sampleRateHz.value
          : this.sampleRateHz,
      artworkUrl: data.artworkUrl.present
          ? data.artworkUrl.value
          : this.artworkUrl,
      artworkCachePath: data.artworkCachePath.present
          ? data.artworkCachePath.value
          : this.artworkCachePath,
      gainDb: data.gainDb.present ? data.gainDb.value : this.gainDb,
      cueInMs: data.cueInMs.present ? data.cueInMs.value : this.cueInMs,
      cueOutMs: data.cueOutMs.present ? data.cueOutMs.value : this.cueOutMs,
      isDrm: data.isDrm.present ? data.isDrm.value : this.isDrm,
      cachePolicy: data.cachePolicy.present
          ? data.cachePolicy.value
          : this.cachePolicy,
      defaultDanceTypeId: data.defaultDanceTypeId.present
          ? data.defaultDanceTypeId.value
          : this.defaultDanceTypeId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastVerifiedAt: data.lastVerifiedAt.present
          ? data.lastVerifiedAt.value
          : this.lastVerifiedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Track(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('accountId: $accountId, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('securityBookmark: $securityBookmark, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePartId: $sourcePartId, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bpm: $bpm, ')
          ..write('musicalKey: $musicalKey, ')
          ..write('codec: $codec, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('artworkCachePath: $artworkCachePath, ')
          ..write('gainDb: $gainDb, ')
          ..write('cueInMs: $cueInMs, ')
          ..write('cueOutMs: $cueOutMs, ')
          ..write('isDrm: $isDrm, ')
          ..write('cachePolicy: $cachePolicy, ')
          ..write('defaultDanceTypeId: $defaultDanceTypeId, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    sourceType,
    accountId,
    localPath,
    contentUri,
    $driftBlobEquality.hash(securityBookmark),
    sourceId,
    sourcePartId,
    sourceUpdatedAt,
    title,
    artist,
    album,
    albumArtist,
    year,
    durationMs,
    bpm,
    musicalKey,
    codec,
    bitrateKbps,
    sampleRateHz,
    artworkUrl,
    artworkCachePath,
    gainDb,
    cueInMs,
    cueOutMs,
    isDrm,
    cachePolicy,
    defaultDanceTypeId,
    addedAt,
    updatedAt,
    lastVerifiedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Track &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.accountId == this.accountId &&
          other.localPath == this.localPath &&
          other.contentUri == this.contentUri &&
          $driftBlobEquality.equals(
            other.securityBookmark,
            this.securityBookmark,
          ) &&
          other.sourceId == this.sourceId &&
          other.sourcePartId == this.sourcePartId &&
          other.sourceUpdatedAt == this.sourceUpdatedAt &&
          other.title == this.title &&
          other.artist == this.artist &&
          other.album == this.album &&
          other.albumArtist == this.albumArtist &&
          other.year == this.year &&
          other.durationMs == this.durationMs &&
          other.bpm == this.bpm &&
          other.musicalKey == this.musicalKey &&
          other.codec == this.codec &&
          other.bitrateKbps == this.bitrateKbps &&
          other.sampleRateHz == this.sampleRateHz &&
          other.artworkUrl == this.artworkUrl &&
          other.artworkCachePath == this.artworkCachePath &&
          other.gainDb == this.gainDb &&
          other.cueInMs == this.cueInMs &&
          other.cueOutMs == this.cueOutMs &&
          other.isDrm == this.isDrm &&
          other.cachePolicy == this.cachePolicy &&
          other.defaultDanceTypeId == this.defaultDanceTypeId &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.lastVerifiedAt == this.lastVerifiedAt);
}

class TracksCompanion extends UpdateCompanion<Track> {
  final Value<String> id;
  final Value<SourceType> sourceType;
  final Value<String?> accountId;
  final Value<String?> localPath;
  final Value<String?> contentUri;
  final Value<Uint8List?> securityBookmark;
  final Value<String?> sourceId;
  final Value<String?> sourcePartId;
  final Value<int?> sourceUpdatedAt;
  final Value<String> title;
  final Value<String?> artist;
  final Value<String?> album;
  final Value<String?> albumArtist;
  final Value<int?> year;
  final Value<Duration> durationMs;
  final Value<double?> bpm;
  final Value<String?> musicalKey;
  final Value<String?> codec;
  final Value<int?> bitrateKbps;
  final Value<int?> sampleRateHz;
  final Value<String?> artworkUrl;
  final Value<String?> artworkCachePath;
  final Value<double> gainDb;
  final Value<Duration> cueInMs;
  final Value<Duration?> cueOutMs;
  final Value<bool> isDrm;
  final Value<CachePolicy> cachePolicy;
  final Value<String?> defaultDanceTypeId;
  final Value<DateTime> addedAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastVerifiedAt;
  final Value<int> rowid;
  const TracksCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.accountId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.securityBookmark = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourcePartId = const Value.absent(),
    this.sourceUpdatedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.year = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.bpm = const Value.absent(),
    this.musicalKey = const Value.absent(),
    this.codec = const Value.absent(),
    this.bitrateKbps = const Value.absent(),
    this.sampleRateHz = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.artworkCachePath = const Value.absent(),
    this.gainDb = const Value.absent(),
    this.cueInMs = const Value.absent(),
    this.cueOutMs = const Value.absent(),
    this.isDrm = const Value.absent(),
    this.cachePolicy = const Value.absent(),
    this.defaultDanceTypeId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TracksCompanion.insert({
    required String id,
    required SourceType sourceType,
    this.accountId = const Value.absent(),
    this.localPath = const Value.absent(),
    this.contentUri = const Value.absent(),
    this.securityBookmark = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.sourcePartId = const Value.absent(),
    this.sourceUpdatedAt = const Value.absent(),
    required String title,
    this.artist = const Value.absent(),
    this.album = const Value.absent(),
    this.albumArtist = const Value.absent(),
    this.year = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.bpm = const Value.absent(),
    this.musicalKey = const Value.absent(),
    this.codec = const Value.absent(),
    this.bitrateKbps = const Value.absent(),
    this.sampleRateHz = const Value.absent(),
    this.artworkUrl = const Value.absent(),
    this.artworkCachePath = const Value.absent(),
    this.gainDb = const Value.absent(),
    this.cueInMs = const Value.absent(),
    this.cueOutMs = const Value.absent(),
    this.isDrm = const Value.absent(),
    this.cachePolicy = const Value.absent(),
    this.defaultDanceTypeId = const Value.absent(),
    required DateTime addedAt,
    required DateTime updatedAt,
    this.lastVerifiedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceType = Value(sourceType),
       title = Value(title),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt);
  static Insertable<Track> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? accountId,
    Expression<String>? localPath,
    Expression<String>? contentUri,
    Expression<Uint8List>? securityBookmark,
    Expression<String>? sourceId,
    Expression<String>? sourcePartId,
    Expression<int>? sourceUpdatedAt,
    Expression<String>? title,
    Expression<String>? artist,
    Expression<String>? album,
    Expression<String>? albumArtist,
    Expression<int>? year,
    Expression<int>? durationMs,
    Expression<double>? bpm,
    Expression<String>? musicalKey,
    Expression<String>? codec,
    Expression<int>? bitrateKbps,
    Expression<int>? sampleRateHz,
    Expression<String>? artworkUrl,
    Expression<String>? artworkCachePath,
    Expression<double>? gainDb,
    Expression<int>? cueInMs,
    Expression<int>? cueOutMs,
    Expression<bool>? isDrm,
    Expression<String>? cachePolicy,
    Expression<String>? defaultDanceTypeId,
    Expression<int>? addedAt,
    Expression<int>? updatedAt,
    Expression<int>? lastVerifiedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (accountId != null) 'account_id': accountId,
      if (localPath != null) 'local_path': localPath,
      if (contentUri != null) 'content_uri': contentUri,
      if (securityBookmark != null) 'security_bookmark': securityBookmark,
      if (sourceId != null) 'source_id': sourceId,
      if (sourcePartId != null) 'source_part_id': sourcePartId,
      if (sourceUpdatedAt != null) 'source_updated_at': sourceUpdatedAt,
      if (title != null) 'title': title,
      if (artist != null) 'artist': artist,
      if (album != null) 'album': album,
      if (albumArtist != null) 'album_artist': albumArtist,
      if (year != null) 'year': year,
      if (durationMs != null) 'duration_ms': durationMs,
      if (bpm != null) 'bpm': bpm,
      if (musicalKey != null) 'musical_key': musicalKey,
      if (codec != null) 'codec': codec,
      if (bitrateKbps != null) 'bitrate_kbps': bitrateKbps,
      if (sampleRateHz != null) 'sample_rate_hz': sampleRateHz,
      if (artworkUrl != null) 'artwork_url': artworkUrl,
      if (artworkCachePath != null) 'artwork_cache_path': artworkCachePath,
      if (gainDb != null) 'gain_db': gainDb,
      if (cueInMs != null) 'cue_in_ms': cueInMs,
      if (cueOutMs != null) 'cue_out_ms': cueOutMs,
      if (isDrm != null) 'is_drm': isDrm,
      if (cachePolicy != null) 'cache_policy': cachePolicy,
      if (defaultDanceTypeId != null)
        'default_dance_type_id': defaultDanceTypeId,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastVerifiedAt != null) 'last_verified_at': lastVerifiedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TracksCompanion copyWith({
    Value<String>? id,
    Value<SourceType>? sourceType,
    Value<String?>? accountId,
    Value<String?>? localPath,
    Value<String?>? contentUri,
    Value<Uint8List?>? securityBookmark,
    Value<String?>? sourceId,
    Value<String?>? sourcePartId,
    Value<int?>? sourceUpdatedAt,
    Value<String>? title,
    Value<String?>? artist,
    Value<String?>? album,
    Value<String?>? albumArtist,
    Value<int?>? year,
    Value<Duration>? durationMs,
    Value<double?>? bpm,
    Value<String?>? musicalKey,
    Value<String?>? codec,
    Value<int?>? bitrateKbps,
    Value<int?>? sampleRateHz,
    Value<String?>? artworkUrl,
    Value<String?>? artworkCachePath,
    Value<double>? gainDb,
    Value<Duration>? cueInMs,
    Value<Duration?>? cueOutMs,
    Value<bool>? isDrm,
    Value<CachePolicy>? cachePolicy,
    Value<String?>? defaultDanceTypeId,
    Value<DateTime>? addedAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastVerifiedAt,
    Value<int>? rowid,
  }) {
    return TracksCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      accountId: accountId ?? this.accountId,
      localPath: localPath ?? this.localPath,
      contentUri: contentUri ?? this.contentUri,
      securityBookmark: securityBookmark ?? this.securityBookmark,
      sourceId: sourceId ?? this.sourceId,
      sourcePartId: sourcePartId ?? this.sourcePartId,
      sourceUpdatedAt: sourceUpdatedAt ?? this.sourceUpdatedAt,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      year: year ?? this.year,
      durationMs: durationMs ?? this.durationMs,
      bpm: bpm ?? this.bpm,
      musicalKey: musicalKey ?? this.musicalKey,
      codec: codec ?? this.codec,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
      sampleRateHz: sampleRateHz ?? this.sampleRateHz,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      artworkCachePath: artworkCachePath ?? this.artworkCachePath,
      gainDb: gainDb ?? this.gainDb,
      cueInMs: cueInMs ?? this.cueInMs,
      cueOutMs: cueOutMs ?? this.cueOutMs,
      isDrm: isDrm ?? this.isDrm,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      defaultDanceTypeId: defaultDanceTypeId ?? this.defaultDanceTypeId,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(
        $TracksTable.$convertersourceType.toSql(sourceType.value),
      );
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (contentUri.present) {
      map['content_uri'] = Variable<String>(contentUri.value);
    }
    if (securityBookmark.present) {
      map['security_bookmark'] = Variable<Uint8List>(securityBookmark.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (sourcePartId.present) {
      map['source_part_id'] = Variable<String>(sourcePartId.value);
    }
    if (sourceUpdatedAt.present) {
      map['source_updated_at'] = Variable<int>(sourceUpdatedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (artist.present) {
      map['artist'] = Variable<String>(artist.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (albumArtist.present) {
      map['album_artist'] = Variable<String>(albumArtist.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(
        $TracksTable.$converterdurationMs.toSql(durationMs.value),
      );
    }
    if (bpm.present) {
      map['bpm'] = Variable<double>(bpm.value);
    }
    if (musicalKey.present) {
      map['musical_key'] = Variable<String>(musicalKey.value);
    }
    if (codec.present) {
      map['codec'] = Variable<String>(codec.value);
    }
    if (bitrateKbps.present) {
      map['bitrate_kbps'] = Variable<int>(bitrateKbps.value);
    }
    if (sampleRateHz.present) {
      map['sample_rate_hz'] = Variable<int>(sampleRateHz.value);
    }
    if (artworkUrl.present) {
      map['artwork_url'] = Variable<String>(artworkUrl.value);
    }
    if (artworkCachePath.present) {
      map['artwork_cache_path'] = Variable<String>(artworkCachePath.value);
    }
    if (gainDb.present) {
      map['gain_db'] = Variable<double>(gainDb.value);
    }
    if (cueInMs.present) {
      map['cue_in_ms'] = Variable<int>(
        $TracksTable.$convertercueInMs.toSql(cueInMs.value),
      );
    }
    if (cueOutMs.present) {
      map['cue_out_ms'] = Variable<int>(
        $TracksTable.$convertercueOutMsn.toSql(cueOutMs.value),
      );
    }
    if (isDrm.present) {
      map['is_drm'] = Variable<bool>(isDrm.value);
    }
    if (cachePolicy.present) {
      map['cache_policy'] = Variable<String>(
        $TracksTable.$convertercachePolicy.toSql(cachePolicy.value),
      );
    }
    if (defaultDanceTypeId.present) {
      map['default_dance_type_id'] = Variable<String>(defaultDanceTypeId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(
        $TracksTable.$converteraddedAt.toSql(addedAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $TracksTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (lastVerifiedAt.present) {
      map['last_verified_at'] = Variable<int>(
        $TracksTable.$converterlastVerifiedAtn.toSql(lastVerifiedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TracksCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('accountId: $accountId, ')
          ..write('localPath: $localPath, ')
          ..write('contentUri: $contentUri, ')
          ..write('securityBookmark: $securityBookmark, ')
          ..write('sourceId: $sourceId, ')
          ..write('sourcePartId: $sourcePartId, ')
          ..write('sourceUpdatedAt: $sourceUpdatedAt, ')
          ..write('title: $title, ')
          ..write('artist: $artist, ')
          ..write('album: $album, ')
          ..write('albumArtist: $albumArtist, ')
          ..write('year: $year, ')
          ..write('durationMs: $durationMs, ')
          ..write('bpm: $bpm, ')
          ..write('musicalKey: $musicalKey, ')
          ..write('codec: $codec, ')
          ..write('bitrateKbps: $bitrateKbps, ')
          ..write('sampleRateHz: $sampleRateHz, ')
          ..write('artworkUrl: $artworkUrl, ')
          ..write('artworkCachePath: $artworkCachePath, ')
          ..write('gainDb: $gainDb, ')
          ..write('cueInMs: $cueInMs, ')
          ..write('cueOutMs: $cueOutMs, ')
          ..write('isDrm: $isDrm, ')
          ..write('cachePolicy: $cachePolicy, ')
          ..write('defaultDanceTypeId: $defaultDanceTypeId, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastVerifiedAt: $lastVerifiedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistsTable extends Playlists
    with TableInfo<$PlaylistsTable, Playlist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _eventKindMeta = const VerificationMeta(
    'eventKind',
  );
  @override
  late final GeneratedColumn<String> eventKind = GeneratedColumn<String>(
    'event_kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> eventDate =
      GeneratedColumn<int>(
        'event_date',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($PlaylistsTable.$convertereventDaten);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> crossfadeMs =
      GeneratedColumn<int>(
        'crossfade_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(4000),
      ).withConverter<Duration>($PlaylistsTable.$convertercrossfadeMs);
  @override
  late final GeneratedColumnWithTypeConverter<FadeCurve, String> fadeInCurve =
      GeneratedColumn<String>(
        'fade_in_curve',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('equalPower'),
      ).withConverter<FadeCurve>($PlaylistsTable.$converterfadeInCurve);
  @override
  late final GeneratedColumnWithTypeConverter<FadeCurve, String> fadeOutCurve =
      GeneratedColumn<String>(
        'fade_out_curve',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('equalPower'),
      ).withConverter<FadeCurve>($PlaylistsTable.$converterfadeOutCurve);
  @override
  late final GeneratedColumnWithTypeConverter<AnnounceMode, String>
  announceMode = GeneratedColumn<String>(
    'announce_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('beforeMusic'),
  ).withConverter<AnnounceMode>($PlaylistsTable.$converterannounceMode);
  static const VerificationMeta _duckLevelMeta = const VerificationMeta(
    'duckLevel',
  );
  @override
  late final GeneratedColumn<double> duckLevel = GeneratedColumn<double>(
    'duck_level',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.20),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> duckFadeMs =
      GeneratedColumn<int>(
        'duck_fade_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(600),
      ).withConverter<Duration>($PlaylistsTable.$converterduckFadeMs);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> duckHoldMs =
      GeneratedColumn<int>(
        'duck_hold_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(250),
      ).withConverter<Duration>($PlaylistsTable.$converterduckHoldMs);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> duckRestoreFadeMs =
      GeneratedColumn<int>(
        'duck_restore_fade_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(900),
      ).withConverter<Duration>($PlaylistsTable.$converterduckRestoreFadeMs);
  static const VerificationMeta _ttsVoiceIdMeta = const VerificationMeta(
    'ttsVoiceId',
  );
  @override
  late final GeneratedColumn<String> ttsVoiceId = GeneratedColumn<String>(
    'tts_voice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ttsRateMeta = const VerificationMeta(
    'ttsRate',
  );
  @override
  late final GeneratedColumn<double> ttsRate = GeneratedColumn<double>(
    'tts_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.5),
  );
  static const VerificationMeta _ttsPitchMeta = const VerificationMeta(
    'ttsPitch',
  );
  @override
  late final GeneratedColumn<double> ttsPitch = GeneratedColumn<double>(
    'tts_pitch',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlaylistsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlaylistsTable.$converterupdatedAt);
  static const VerificationMeta _songLimitMeta = const VerificationMeta(
    'songLimit',
  );
  @override
  late final GeneratedColumn<int> songLimit = GeneratedColumn<int>(
    'song_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> targetDurationMs =
      GeneratedColumn<int>(
        'target_duration_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>($PlaylistsTable.$convertertargetDurationMsn);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> rotationGapMs =
      GeneratedColumn<int>(
        'rotation_gap_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($PlaylistsTable.$converterrotationGapMs);
  static const VerificationMeta _snowballStagesMeta = const VerificationMeta(
    'snowballStages',
  );
  @override
  late final GeneratedColumn<int> snowballStages = GeneratedColumn<int>(
    'snowball_stages',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    eventKind,
    eventDate,
    crossfadeMs,
    fadeInCurve,
    fadeOutCurve,
    announceMode,
    duckLevel,
    duckFadeMs,
    duckHoldMs,
    duckRestoreFadeMs,
    ttsVoiceId,
    ttsRate,
    ttsPitch,
    isArchived,
    createdAt,
    updatedAt,
    songLimit,
    targetDurationMs,
    rotationGapMs,
    snowballStages,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<Playlist> instance, {
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('event_kind')) {
      context.handle(
        _eventKindMeta,
        eventKind.isAcceptableOrUnknown(data['event_kind']!, _eventKindMeta),
      );
    }
    if (data.containsKey('duck_level')) {
      context.handle(
        _duckLevelMeta,
        duckLevel.isAcceptableOrUnknown(data['duck_level']!, _duckLevelMeta),
      );
    }
    if (data.containsKey('tts_voice_id')) {
      context.handle(
        _ttsVoiceIdMeta,
        ttsVoiceId.isAcceptableOrUnknown(
          data['tts_voice_id']!,
          _ttsVoiceIdMeta,
        ),
      );
    }
    if (data.containsKey('tts_rate')) {
      context.handle(
        _ttsRateMeta,
        ttsRate.isAcceptableOrUnknown(data['tts_rate']!, _ttsRateMeta),
      );
    }
    if (data.containsKey('tts_pitch')) {
      context.handle(
        _ttsPitchMeta,
        ttsPitch.isAcceptableOrUnknown(data['tts_pitch']!, _ttsPitchMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('song_limit')) {
      context.handle(
        _songLimitMeta,
        songLimit.isAcceptableOrUnknown(data['song_limit']!, _songLimitMeta),
      );
    }
    if (data.containsKey('snowball_stages')) {
      context.handle(
        _snowballStagesMeta,
        snowballStages.isAcceptableOrUnknown(
          data['snowball_stages']!,
          _snowballStagesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Playlist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Playlist(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      eventKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_kind'],
      ),
      eventDate: $PlaylistsTable.$convertereventDaten.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}event_date'],
        ),
      ),
      crossfadeMs: $PlaylistsTable.$convertercrossfadeMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}crossfade_ms'],
        )!,
      ),
      fadeInCurve: $PlaylistsTable.$converterfadeInCurve.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fade_in_curve'],
        )!,
      ),
      fadeOutCurve: $PlaylistsTable.$converterfadeOutCurve.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fade_out_curve'],
        )!,
      ),
      announceMode: $PlaylistsTable.$converterannounceMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}announce_mode'],
        )!,
      ),
      duckLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duck_level'],
      )!,
      duckFadeMs: $PlaylistsTable.$converterduckFadeMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duck_fade_ms'],
        )!,
      ),
      duckHoldMs: $PlaylistsTable.$converterduckHoldMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duck_hold_ms'],
        )!,
      ),
      duckRestoreFadeMs: $PlaylistsTable.$converterduckRestoreFadeMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duck_restore_fade_ms'],
        )!,
      ),
      ttsVoiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tts_voice_id'],
      ),
      ttsRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tts_rate'],
      )!,
      ttsPitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}tts_pitch'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: $PlaylistsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $PlaylistsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      songLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}song_limit'],
      ),
      targetDurationMs: $PlaylistsTable.$convertertargetDurationMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}target_duration_ms'],
        ),
      ),
      rotationGapMs: $PlaylistsTable.$converterrotationGapMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}rotation_gap_ms'],
        )!,
      ),
      snowballStages: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snowball_stages'],
      )!,
    );
  }

  @override
  $PlaylistsTable createAlias(String alias) {
    return $PlaylistsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertereventDate =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $convertereventDaten =
      NullAwareTypeConverter.wrap($convertereventDate);
  static TypeConverter<Duration, int> $convertercrossfadeMs =
      const MillisDurationConverter();
  static JsonTypeConverter2<FadeCurve, String, String> $converterfadeInCurve =
      const EnumNameConverter<FadeCurve>(FadeCurve.values);
  static JsonTypeConverter2<FadeCurve, String, String> $converterfadeOutCurve =
      const EnumNameConverter<FadeCurve>(FadeCurve.values);
  static JsonTypeConverter2<AnnounceMode, String, String>
  $converterannounceMode = const EnumNameConverter<AnnounceMode>(
    AnnounceMode.values,
  );
  static TypeConverter<Duration, int> $converterduckFadeMs =
      const MillisDurationConverter();
  static TypeConverter<Duration, int> $converterduckHoldMs =
      const MillisDurationConverter();
  static TypeConverter<Duration, int> $converterduckRestoreFadeMs =
      const MillisDurationConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisConverter();
  static TypeConverter<Duration, int> $convertertargetDurationMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $convertertargetDurationMsn =
      NullAwareTypeConverter.wrap($convertertargetDurationMs);
  static TypeConverter<Duration, int> $converterrotationGapMs =
      const MillisDurationConverter();
}

class Playlist extends DataClass implements Insertable<Playlist> {
  final String id;
  final String name;
  final String? description;

  /// 'social', 'competition', 'showcase', 'practice'. Deliberately free text:
  /// house styles vary and an unknown value should not fail an insert.
  final String? eventKind;
  final DateTime? eventDate;
  final Duration crossfadeMs;
  final FadeCurve fadeInCurve;
  final FadeCurve fadeOutCurve;
  final AnnounceMode announceMode;

  /// Music level while the voice plays, as a fraction of the current level.
  final double duckLevel;
  final Duration duckFadeMs;
  final Duration duckHoldMs;
  final Duration duckRestoreFadeMs;
  final String? ttsVoiceId;
  final double ttsRate;
  final double ttsPitch;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Stop after this many songs. Null plays the list as written, which is what
  /// a set built track by track wants.
  final int? songLimit;

  /// How much of each song to play before handing over — two minutes of every
  /// track in a rotation, a competition round's ninety seconds. Null plays
  /// each track to its end. A row's own `targetDurationMs` overrides this.
  final Duration? targetDurationMs;

  /// Silence held between songs so a floor can change partners.
  ///
  /// Zero is an ordinary set. Anything above it makes every transition
  /// sequential — music out, chime, wait, music in — because a rotation needs
  /// the room actually quiet, not a crossfade with a voice over it.
  final Duration rotationGapMs;

  /// How many stages a Snowball climbs through. Zero is not a Snowball.
  ///
  /// It changes nothing about how the set plays — the climb is the tempo
  /// order, which is written into the rows themselves. This only decides what
  /// the operator is shown while it runs.
  final int snowballStages;
  const Playlist({
    required this.id,
    required this.name,
    this.description,
    this.eventKind,
    this.eventDate,
    required this.crossfadeMs,
    required this.fadeInCurve,
    required this.fadeOutCurve,
    required this.announceMode,
    required this.duckLevel,
    required this.duckFadeMs,
    required this.duckHoldMs,
    required this.duckRestoreFadeMs,
    this.ttsVoiceId,
    required this.ttsRate,
    required this.ttsPitch,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.songLimit,
    this.targetDurationMs,
    required this.rotationGapMs,
    required this.snowballStages,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || eventKind != null) {
      map['event_kind'] = Variable<String>(eventKind);
    }
    if (!nullToAbsent || eventDate != null) {
      map['event_date'] = Variable<int>(
        $PlaylistsTable.$convertereventDaten.toSql(eventDate),
      );
    }
    {
      map['crossfade_ms'] = Variable<int>(
        $PlaylistsTable.$convertercrossfadeMs.toSql(crossfadeMs),
      );
    }
    {
      map['fade_in_curve'] = Variable<String>(
        $PlaylistsTable.$converterfadeInCurve.toSql(fadeInCurve),
      );
    }
    {
      map['fade_out_curve'] = Variable<String>(
        $PlaylistsTable.$converterfadeOutCurve.toSql(fadeOutCurve),
      );
    }
    {
      map['announce_mode'] = Variable<String>(
        $PlaylistsTable.$converterannounceMode.toSql(announceMode),
      );
    }
    map['duck_level'] = Variable<double>(duckLevel);
    {
      map['duck_fade_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckFadeMs.toSql(duckFadeMs),
      );
    }
    {
      map['duck_hold_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckHoldMs.toSql(duckHoldMs),
      );
    }
    {
      map['duck_restore_fade_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckRestoreFadeMs.toSql(duckRestoreFadeMs),
      );
    }
    if (!nullToAbsent || ttsVoiceId != null) {
      map['tts_voice_id'] = Variable<String>(ttsVoiceId);
    }
    map['tts_rate'] = Variable<double>(ttsRate);
    map['tts_pitch'] = Variable<double>(ttsPitch);
    map['is_archived'] = Variable<bool>(isArchived);
    {
      map['created_at'] = Variable<int>(
        $PlaylistsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $PlaylistsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    if (!nullToAbsent || songLimit != null) {
      map['song_limit'] = Variable<int>(songLimit);
    }
    if (!nullToAbsent || targetDurationMs != null) {
      map['target_duration_ms'] = Variable<int>(
        $PlaylistsTable.$convertertargetDurationMsn.toSql(targetDurationMs),
      );
    }
    {
      map['rotation_gap_ms'] = Variable<int>(
        $PlaylistsTable.$converterrotationGapMs.toSql(rotationGapMs),
      );
    }
    map['snowball_stages'] = Variable<int>(snowballStages);
    return map;
  }

  PlaylistsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      eventKind: eventKind == null && nullToAbsent
          ? const Value.absent()
          : Value(eventKind),
      eventDate: eventDate == null && nullToAbsent
          ? const Value.absent()
          : Value(eventDate),
      crossfadeMs: Value(crossfadeMs),
      fadeInCurve: Value(fadeInCurve),
      fadeOutCurve: Value(fadeOutCurve),
      announceMode: Value(announceMode),
      duckLevel: Value(duckLevel),
      duckFadeMs: Value(duckFadeMs),
      duckHoldMs: Value(duckHoldMs),
      duckRestoreFadeMs: Value(duckRestoreFadeMs),
      ttsVoiceId: ttsVoiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(ttsVoiceId),
      ttsRate: Value(ttsRate),
      ttsPitch: Value(ttsPitch),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      songLimit: songLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(songLimit),
      targetDurationMs: targetDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDurationMs),
      rotationGapMs: Value(rotationGapMs),
      snowballStages: Value(snowballStages),
    );
  }

  factory Playlist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Playlist(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      eventKind: serializer.fromJson<String?>(json['eventKind']),
      eventDate: serializer.fromJson<DateTime?>(json['eventDate']),
      crossfadeMs: serializer.fromJson<Duration>(json['crossfadeMs']),
      fadeInCurve: $PlaylistsTable.$converterfadeInCurve.fromJson(
        serializer.fromJson<String>(json['fadeInCurve']),
      ),
      fadeOutCurve: $PlaylistsTable.$converterfadeOutCurve.fromJson(
        serializer.fromJson<String>(json['fadeOutCurve']),
      ),
      announceMode: $PlaylistsTable.$converterannounceMode.fromJson(
        serializer.fromJson<String>(json['announceMode']),
      ),
      duckLevel: serializer.fromJson<double>(json['duckLevel']),
      duckFadeMs: serializer.fromJson<Duration>(json['duckFadeMs']),
      duckHoldMs: serializer.fromJson<Duration>(json['duckHoldMs']),
      duckRestoreFadeMs: serializer.fromJson<Duration>(
        json['duckRestoreFadeMs'],
      ),
      ttsVoiceId: serializer.fromJson<String?>(json['ttsVoiceId']),
      ttsRate: serializer.fromJson<double>(json['ttsRate']),
      ttsPitch: serializer.fromJson<double>(json['ttsPitch']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      songLimit: serializer.fromJson<int?>(json['songLimit']),
      targetDurationMs: serializer.fromJson<Duration?>(
        json['targetDurationMs'],
      ),
      rotationGapMs: serializer.fromJson<Duration>(json['rotationGapMs']),
      snowballStages: serializer.fromJson<int>(json['snowballStages']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'eventKind': serializer.toJson<String?>(eventKind),
      'eventDate': serializer.toJson<DateTime?>(eventDate),
      'crossfadeMs': serializer.toJson<Duration>(crossfadeMs),
      'fadeInCurve': serializer.toJson<String>(
        $PlaylistsTable.$converterfadeInCurve.toJson(fadeInCurve),
      ),
      'fadeOutCurve': serializer.toJson<String>(
        $PlaylistsTable.$converterfadeOutCurve.toJson(fadeOutCurve),
      ),
      'announceMode': serializer.toJson<String>(
        $PlaylistsTable.$converterannounceMode.toJson(announceMode),
      ),
      'duckLevel': serializer.toJson<double>(duckLevel),
      'duckFadeMs': serializer.toJson<Duration>(duckFadeMs),
      'duckHoldMs': serializer.toJson<Duration>(duckHoldMs),
      'duckRestoreFadeMs': serializer.toJson<Duration>(duckRestoreFadeMs),
      'ttsVoiceId': serializer.toJson<String?>(ttsVoiceId),
      'ttsRate': serializer.toJson<double>(ttsRate),
      'ttsPitch': serializer.toJson<double>(ttsPitch),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'songLimit': serializer.toJson<int?>(songLimit),
      'targetDurationMs': serializer.toJson<Duration?>(targetDurationMs),
      'rotationGapMs': serializer.toJson<Duration>(rotationGapMs),
      'snowballStages': serializer.toJson<int>(snowballStages),
    };
  }

  Playlist copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> eventKind = const Value.absent(),
    Value<DateTime?> eventDate = const Value.absent(),
    Duration? crossfadeMs,
    FadeCurve? fadeInCurve,
    FadeCurve? fadeOutCurve,
    AnnounceMode? announceMode,
    double? duckLevel,
    Duration? duckFadeMs,
    Duration? duckHoldMs,
    Duration? duckRestoreFadeMs,
    Value<String?> ttsVoiceId = const Value.absent(),
    double? ttsRate,
    double? ttsPitch,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<int?> songLimit = const Value.absent(),
    Value<Duration?> targetDurationMs = const Value.absent(),
    Duration? rotationGapMs,
    int? snowballStages,
  }) => Playlist(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    eventKind: eventKind.present ? eventKind.value : this.eventKind,
    eventDate: eventDate.present ? eventDate.value : this.eventDate,
    crossfadeMs: crossfadeMs ?? this.crossfadeMs,
    fadeInCurve: fadeInCurve ?? this.fadeInCurve,
    fadeOutCurve: fadeOutCurve ?? this.fadeOutCurve,
    announceMode: announceMode ?? this.announceMode,
    duckLevel: duckLevel ?? this.duckLevel,
    duckFadeMs: duckFadeMs ?? this.duckFadeMs,
    duckHoldMs: duckHoldMs ?? this.duckHoldMs,
    duckRestoreFadeMs: duckRestoreFadeMs ?? this.duckRestoreFadeMs,
    ttsVoiceId: ttsVoiceId.present ? ttsVoiceId.value : this.ttsVoiceId,
    ttsRate: ttsRate ?? this.ttsRate,
    ttsPitch: ttsPitch ?? this.ttsPitch,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    songLimit: songLimit.present ? songLimit.value : this.songLimit,
    targetDurationMs: targetDurationMs.present
        ? targetDurationMs.value
        : this.targetDurationMs,
    rotationGapMs: rotationGapMs ?? this.rotationGapMs,
    snowballStages: snowballStages ?? this.snowballStages,
  );
  Playlist copyWithCompanion(PlaylistsCompanion data) {
    return Playlist(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      eventKind: data.eventKind.present ? data.eventKind.value : this.eventKind,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      crossfadeMs: data.crossfadeMs.present
          ? data.crossfadeMs.value
          : this.crossfadeMs,
      fadeInCurve: data.fadeInCurve.present
          ? data.fadeInCurve.value
          : this.fadeInCurve,
      fadeOutCurve: data.fadeOutCurve.present
          ? data.fadeOutCurve.value
          : this.fadeOutCurve,
      announceMode: data.announceMode.present
          ? data.announceMode.value
          : this.announceMode,
      duckLevel: data.duckLevel.present ? data.duckLevel.value : this.duckLevel,
      duckFadeMs: data.duckFadeMs.present
          ? data.duckFadeMs.value
          : this.duckFadeMs,
      duckHoldMs: data.duckHoldMs.present
          ? data.duckHoldMs.value
          : this.duckHoldMs,
      duckRestoreFadeMs: data.duckRestoreFadeMs.present
          ? data.duckRestoreFadeMs.value
          : this.duckRestoreFadeMs,
      ttsVoiceId: data.ttsVoiceId.present
          ? data.ttsVoiceId.value
          : this.ttsVoiceId,
      ttsRate: data.ttsRate.present ? data.ttsRate.value : this.ttsRate,
      ttsPitch: data.ttsPitch.present ? data.ttsPitch.value : this.ttsPitch,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      songLimit: data.songLimit.present ? data.songLimit.value : this.songLimit,
      targetDurationMs: data.targetDurationMs.present
          ? data.targetDurationMs.value
          : this.targetDurationMs,
      rotationGapMs: data.rotationGapMs.present
          ? data.rotationGapMs.value
          : this.rotationGapMs,
      snowballStages: data.snowballStages.present
          ? data.snowballStages.value
          : this.snowballStages,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Playlist(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('eventKind: $eventKind, ')
          ..write('eventDate: $eventDate, ')
          ..write('crossfadeMs: $crossfadeMs, ')
          ..write('fadeInCurve: $fadeInCurve, ')
          ..write('fadeOutCurve: $fadeOutCurve, ')
          ..write('announceMode: $announceMode, ')
          ..write('duckLevel: $duckLevel, ')
          ..write('duckFadeMs: $duckFadeMs, ')
          ..write('duckHoldMs: $duckHoldMs, ')
          ..write('duckRestoreFadeMs: $duckRestoreFadeMs, ')
          ..write('ttsVoiceId: $ttsVoiceId, ')
          ..write('ttsRate: $ttsRate, ')
          ..write('ttsPitch: $ttsPitch, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('songLimit: $songLimit, ')
          ..write('targetDurationMs: $targetDurationMs, ')
          ..write('rotationGapMs: $rotationGapMs, ')
          ..write('snowballStages: $snowballStages')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    description,
    eventKind,
    eventDate,
    crossfadeMs,
    fadeInCurve,
    fadeOutCurve,
    announceMode,
    duckLevel,
    duckFadeMs,
    duckHoldMs,
    duckRestoreFadeMs,
    ttsVoiceId,
    ttsRate,
    ttsPitch,
    isArchived,
    createdAt,
    updatedAt,
    songLimit,
    targetDurationMs,
    rotationGapMs,
    snowballStages,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.eventKind == this.eventKind &&
          other.eventDate == this.eventDate &&
          other.crossfadeMs == this.crossfadeMs &&
          other.fadeInCurve == this.fadeInCurve &&
          other.fadeOutCurve == this.fadeOutCurve &&
          other.announceMode == this.announceMode &&
          other.duckLevel == this.duckLevel &&
          other.duckFadeMs == this.duckFadeMs &&
          other.duckHoldMs == this.duckHoldMs &&
          other.duckRestoreFadeMs == this.duckRestoreFadeMs &&
          other.ttsVoiceId == this.ttsVoiceId &&
          other.ttsRate == this.ttsRate &&
          other.ttsPitch == this.ttsPitch &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.songLimit == this.songLimit &&
          other.targetDurationMs == this.targetDurationMs &&
          other.rotationGapMs == this.rotationGapMs &&
          other.snowballStages == this.snowballStages);
}

class PlaylistsCompanion extends UpdateCompanion<Playlist> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> eventKind;
  final Value<DateTime?> eventDate;
  final Value<Duration> crossfadeMs;
  final Value<FadeCurve> fadeInCurve;
  final Value<FadeCurve> fadeOutCurve;
  final Value<AnnounceMode> announceMode;
  final Value<double> duckLevel;
  final Value<Duration> duckFadeMs;
  final Value<Duration> duckHoldMs;
  final Value<Duration> duckRestoreFadeMs;
  final Value<String?> ttsVoiceId;
  final Value<double> ttsRate;
  final Value<double> ttsPitch;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int?> songLimit;
  final Value<Duration?> targetDurationMs;
  final Value<Duration> rotationGapMs;
  final Value<int> snowballStages;
  final Value<int> rowid;
  const PlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.eventKind = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.crossfadeMs = const Value.absent(),
    this.fadeInCurve = const Value.absent(),
    this.fadeOutCurve = const Value.absent(),
    this.announceMode = const Value.absent(),
    this.duckLevel = const Value.absent(),
    this.duckFadeMs = const Value.absent(),
    this.duckHoldMs = const Value.absent(),
    this.duckRestoreFadeMs = const Value.absent(),
    this.ttsVoiceId = const Value.absent(),
    this.ttsRate = const Value.absent(),
    this.ttsPitch = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.songLimit = const Value.absent(),
    this.targetDurationMs = const Value.absent(),
    this.rotationGapMs = const Value.absent(),
    this.snowballStages = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.eventKind = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.crossfadeMs = const Value.absent(),
    this.fadeInCurve = const Value.absent(),
    this.fadeOutCurve = const Value.absent(),
    this.announceMode = const Value.absent(),
    this.duckLevel = const Value.absent(),
    this.duckFadeMs = const Value.absent(),
    this.duckHoldMs = const Value.absent(),
    this.duckRestoreFadeMs = const Value.absent(),
    this.ttsVoiceId = const Value.absent(),
    this.ttsRate = const Value.absent(),
    this.ttsPitch = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.songLimit = const Value.absent(),
    this.targetDurationMs = const Value.absent(),
    this.rotationGapMs = const Value.absent(),
    this.snowballStages = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Playlist> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? eventKind,
    Expression<int>? eventDate,
    Expression<int>? crossfadeMs,
    Expression<String>? fadeInCurve,
    Expression<String>? fadeOutCurve,
    Expression<String>? announceMode,
    Expression<double>? duckLevel,
    Expression<int>? duckFadeMs,
    Expression<int>? duckHoldMs,
    Expression<int>? duckRestoreFadeMs,
    Expression<String>? ttsVoiceId,
    Expression<double>? ttsRate,
    Expression<double>? ttsPitch,
    Expression<bool>? isArchived,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? songLimit,
    Expression<int>? targetDurationMs,
    Expression<int>? rotationGapMs,
    Expression<int>? snowballStages,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (eventKind != null) 'event_kind': eventKind,
      if (eventDate != null) 'event_date': eventDate,
      if (crossfadeMs != null) 'crossfade_ms': crossfadeMs,
      if (fadeInCurve != null) 'fade_in_curve': fadeInCurve,
      if (fadeOutCurve != null) 'fade_out_curve': fadeOutCurve,
      if (announceMode != null) 'announce_mode': announceMode,
      if (duckLevel != null) 'duck_level': duckLevel,
      if (duckFadeMs != null) 'duck_fade_ms': duckFadeMs,
      if (duckHoldMs != null) 'duck_hold_ms': duckHoldMs,
      if (duckRestoreFadeMs != null) 'duck_restore_fade_ms': duckRestoreFadeMs,
      if (ttsVoiceId != null) 'tts_voice_id': ttsVoiceId,
      if (ttsRate != null) 'tts_rate': ttsRate,
      if (ttsPitch != null) 'tts_pitch': ttsPitch,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (songLimit != null) 'song_limit': songLimit,
      if (targetDurationMs != null) 'target_duration_ms': targetDurationMs,
      if (rotationGapMs != null) 'rotation_gap_ms': rotationGapMs,
      if (snowballStages != null) 'snowball_stages': snowballStages,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? eventKind,
    Value<DateTime?>? eventDate,
    Value<Duration>? crossfadeMs,
    Value<FadeCurve>? fadeInCurve,
    Value<FadeCurve>? fadeOutCurve,
    Value<AnnounceMode>? announceMode,
    Value<double>? duckLevel,
    Value<Duration>? duckFadeMs,
    Value<Duration>? duckHoldMs,
    Value<Duration>? duckRestoreFadeMs,
    Value<String?>? ttsVoiceId,
    Value<double>? ttsRate,
    Value<double>? ttsPitch,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int?>? songLimit,
    Value<Duration?>? targetDurationMs,
    Value<Duration>? rotationGapMs,
    Value<int>? snowballStages,
    Value<int>? rowid,
  }) {
    return PlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      eventKind: eventKind ?? this.eventKind,
      eventDate: eventDate ?? this.eventDate,
      crossfadeMs: crossfadeMs ?? this.crossfadeMs,
      fadeInCurve: fadeInCurve ?? this.fadeInCurve,
      fadeOutCurve: fadeOutCurve ?? this.fadeOutCurve,
      announceMode: announceMode ?? this.announceMode,
      duckLevel: duckLevel ?? this.duckLevel,
      duckFadeMs: duckFadeMs ?? this.duckFadeMs,
      duckHoldMs: duckHoldMs ?? this.duckHoldMs,
      duckRestoreFadeMs: duckRestoreFadeMs ?? this.duckRestoreFadeMs,
      ttsVoiceId: ttsVoiceId ?? this.ttsVoiceId,
      ttsRate: ttsRate ?? this.ttsRate,
      ttsPitch: ttsPitch ?? this.ttsPitch,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      songLimit: songLimit ?? this.songLimit,
      targetDurationMs: targetDurationMs ?? this.targetDurationMs,
      rotationGapMs: rotationGapMs ?? this.rotationGapMs,
      snowballStages: snowballStages ?? this.snowballStages,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (eventKind.present) {
      map['event_kind'] = Variable<String>(eventKind.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<int>(
        $PlaylistsTable.$convertereventDaten.toSql(eventDate.value),
      );
    }
    if (crossfadeMs.present) {
      map['crossfade_ms'] = Variable<int>(
        $PlaylistsTable.$convertercrossfadeMs.toSql(crossfadeMs.value),
      );
    }
    if (fadeInCurve.present) {
      map['fade_in_curve'] = Variable<String>(
        $PlaylistsTable.$converterfadeInCurve.toSql(fadeInCurve.value),
      );
    }
    if (fadeOutCurve.present) {
      map['fade_out_curve'] = Variable<String>(
        $PlaylistsTable.$converterfadeOutCurve.toSql(fadeOutCurve.value),
      );
    }
    if (announceMode.present) {
      map['announce_mode'] = Variable<String>(
        $PlaylistsTable.$converterannounceMode.toSql(announceMode.value),
      );
    }
    if (duckLevel.present) {
      map['duck_level'] = Variable<double>(duckLevel.value);
    }
    if (duckFadeMs.present) {
      map['duck_fade_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckFadeMs.toSql(duckFadeMs.value),
      );
    }
    if (duckHoldMs.present) {
      map['duck_hold_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckHoldMs.toSql(duckHoldMs.value),
      );
    }
    if (duckRestoreFadeMs.present) {
      map['duck_restore_fade_ms'] = Variable<int>(
        $PlaylistsTable.$converterduckRestoreFadeMs.toSql(
          duckRestoreFadeMs.value,
        ),
      );
    }
    if (ttsVoiceId.present) {
      map['tts_voice_id'] = Variable<String>(ttsVoiceId.value);
    }
    if (ttsRate.present) {
      map['tts_rate'] = Variable<double>(ttsRate.value);
    }
    if (ttsPitch.present) {
      map['tts_pitch'] = Variable<double>(ttsPitch.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $PlaylistsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $PlaylistsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (songLimit.present) {
      map['song_limit'] = Variable<int>(songLimit.value);
    }
    if (targetDurationMs.present) {
      map['target_duration_ms'] = Variable<int>(
        $PlaylistsTable.$convertertargetDurationMsn.toSql(
          targetDurationMs.value,
        ),
      );
    }
    if (rotationGapMs.present) {
      map['rotation_gap_ms'] = Variable<int>(
        $PlaylistsTable.$converterrotationGapMs.toSql(rotationGapMs.value),
      );
    }
    if (snowballStages.present) {
      map['snowball_stages'] = Variable<int>(snowballStages.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('eventKind: $eventKind, ')
          ..write('eventDate: $eventDate, ')
          ..write('crossfadeMs: $crossfadeMs, ')
          ..write('fadeInCurve: $fadeInCurve, ')
          ..write('fadeOutCurve: $fadeOutCurve, ')
          ..write('announceMode: $announceMode, ')
          ..write('duckLevel: $duckLevel, ')
          ..write('duckFadeMs: $duckFadeMs, ')
          ..write('duckHoldMs: $duckHoldMs, ')
          ..write('duckRestoreFadeMs: $duckRestoreFadeMs, ')
          ..write('ttsVoiceId: $ttsVoiceId, ')
          ..write('ttsRate: $ttsRate, ')
          ..write('ttsPitch: $ttsPitch, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('songLimit: $songLimit, ')
          ..write('targetDurationMs: $targetDurationMs, ')
          ..write('rotationGapMs: $rotationGapMs, ')
          ..write('snowballStages: $snowballStages, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlaylistItemsTable extends PlaylistItems
    with TableInfo<$PlaylistItemsTable, PlaylistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlaylistItemType, String>
  itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('track'),
  ).withConverter<PlaylistItemType>($PlaylistItemsTable.$converteritemType);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _danceTypeIdMeta = const VerificationMeta(
    'danceTypeId',
  );
  @override
  late final GeneratedColumn<String> danceTypeId = GeneratedColumn<String>(
    'dance_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dance_types (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AnnounceMode?, String>
  announceMode = GeneratedColumn<String>(
    'announce_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<AnnounceMode?>($PlaylistItemsTable.$converterannounceModen);
  static const VerificationMeta _announcementTextMeta = const VerificationMeta(
    'announcementText',
  );
  @override
  late final GeneratedColumn<String> announcementText = GeneratedColumn<String>(
    'announcement_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _announcementClipPathMeta =
      const VerificationMeta('announcementClipPath');
  @override
  late final GeneratedColumn<String> announcementClipPath =
      GeneratedColumn<String>(
        'announcement_clip_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> crossfadeMs =
      GeneratedColumn<int>(
        'crossfade_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>($PlaylistItemsTable.$convertercrossfadeMsn);
  @override
  late final GeneratedColumnWithTypeConverter<FadeCurve?, String> fadeInCurve =
      GeneratedColumn<String>(
        'fade_in_curve',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<FadeCurve?>($PlaylistItemsTable.$converterfadeInCurven);
  @override
  late final GeneratedColumnWithTypeConverter<FadeCurve?, String> fadeOutCurve =
      GeneratedColumn<String>(
        'fade_out_curve',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<FadeCurve?>($PlaylistItemsTable.$converterfadeOutCurven);
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> startOffsetMs =
      GeneratedColumn<int>(
        'start_offset_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($PlaylistItemsTable.$converterstartOffsetMs);
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> endOffsetMs =
      GeneratedColumn<int>(
        'end_offset_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>($PlaylistItemsTable.$converterendOffsetMsn);
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> targetDurationMs =
      GeneratedColumn<int>(
        'target_duration_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>(
        $PlaylistItemsTable.$convertertargetDurationMsn,
      );
  static const VerificationMeta _gainOffsetDbMeta = const VerificationMeta(
    'gainOffsetDb',
  );
  @override
  late final GeneratedColumn<double> gainOffsetDb = GeneratedColumn<double>(
    'gain_offset_db',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration?, int> silenceMs =
      GeneratedColumn<int>(
        'silence_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<Duration?>($PlaylistItemsTable.$convertersilenceMsn);
  static const VerificationMeta _pauseAfterMeta = const VerificationMeta(
    'pauseAfter',
  );
  @override
  late final GeneratedColumn<bool> pauseAfter = GeneratedColumn<bool>(
    'pause_after',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pause_after" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlaylistItemsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlaylistItemsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlistId,
    position,
    itemType,
    trackId,
    danceTypeId,
    announceMode,
    announcementText,
    announcementClipPath,
    crossfadeMs,
    fadeInCurve,
    fadeOutCurve,
    startOffsetMs,
    endOffsetMs,
    targetDurationMs,
    gainOffsetDb,
    silenceMs,
    pauseAfter,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('dance_type_id')) {
      context.handle(
        _danceTypeIdMeta,
        danceTypeId.isAcceptableOrUnknown(
          data['dance_type_id']!,
          _danceTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('announcement_text')) {
      context.handle(
        _announcementTextMeta,
        announcementText.isAcceptableOrUnknown(
          data['announcement_text']!,
          _announcementTextMeta,
        ),
      );
    }
    if (data.containsKey('announcement_clip_path')) {
      context.handle(
        _announcementClipPathMeta,
        announcementClipPath.isAcceptableOrUnknown(
          data['announcement_clip_path']!,
          _announcementClipPathMeta,
        ),
      );
    }
    if (data.containsKey('gain_offset_db')) {
      context.handle(
        _gainOffsetDbMeta,
        gainOffsetDb.isAcceptableOrUnknown(
          data['gain_offset_db']!,
          _gainOffsetDbMeta,
        ),
      );
    }
    if (data.containsKey('pause_after')) {
      context.handle(
        _pauseAfterMeta,
        pauseAfter.isAcceptableOrUnknown(data['pause_after']!, _pauseAfterMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position'],
      )!,
      itemType: $PlaylistItemsTable.$converteritemType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}item_type'],
        )!,
      ),
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      ),
      danceTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dance_type_id'],
      ),
      announceMode: $PlaylistItemsTable.$converterannounceModen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}announce_mode'],
        ),
      ),
      announcementText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}announcement_text'],
      ),
      announcementClipPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}announcement_clip_path'],
      ),
      crossfadeMs: $PlaylistItemsTable.$convertercrossfadeMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}crossfade_ms'],
        ),
      ),
      fadeInCurve: $PlaylistItemsTable.$converterfadeInCurven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fade_in_curve'],
        ),
      ),
      fadeOutCurve: $PlaylistItemsTable.$converterfadeOutCurven.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}fade_out_curve'],
        ),
      ),
      startOffsetMs: $PlaylistItemsTable.$converterstartOffsetMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}start_offset_ms'],
        )!,
      ),
      endOffsetMs: $PlaylistItemsTable.$converterendOffsetMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_offset_ms'],
        ),
      ),
      targetDurationMs: $PlaylistItemsTable.$convertertargetDurationMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}target_duration_ms'],
        ),
      ),
      gainOffsetDb: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gain_offset_db'],
      )!,
      silenceMs: $PlaylistItemsTable.$convertersilenceMsn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}silence_ms'],
        ),
      ),
      pauseAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pause_after'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: $PlaylistItemsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $PlaylistItemsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $PlaylistItemsTable createAlias(String alias) {
    return $PlaylistItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlaylistItemType, String, String>
  $converteritemType = const EnumNameConverter<PlaylistItemType>(
    PlaylistItemType.values,
  );
  static JsonTypeConverter2<AnnounceMode, String, String>
  $converterannounceMode = const EnumNameConverter<AnnounceMode>(
    AnnounceMode.values,
  );
  static JsonTypeConverter2<AnnounceMode?, String?, String?>
  $converterannounceModen = JsonTypeConverter2.asNullable(
    $converterannounceMode,
  );
  static TypeConverter<Duration, int> $convertercrossfadeMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $convertercrossfadeMsn =
      NullAwareTypeConverter.wrap($convertercrossfadeMs);
  static JsonTypeConverter2<FadeCurve, String, String> $converterfadeInCurve =
      const EnumNameConverter<FadeCurve>(FadeCurve.values);
  static JsonTypeConverter2<FadeCurve?, String?, String?>
  $converterfadeInCurven = JsonTypeConverter2.asNullable($converterfadeInCurve);
  static JsonTypeConverter2<FadeCurve, String, String> $converterfadeOutCurve =
      const EnumNameConverter<FadeCurve>(FadeCurve.values);
  static JsonTypeConverter2<FadeCurve?, String?, String?>
  $converterfadeOutCurven = JsonTypeConverter2.asNullable(
    $converterfadeOutCurve,
  );
  static TypeConverter<Duration, int> $converterstartOffsetMs =
      const MillisDurationConverter();
  static TypeConverter<Duration, int> $converterendOffsetMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $converterendOffsetMsn =
      NullAwareTypeConverter.wrap($converterendOffsetMs);
  static TypeConverter<Duration, int> $convertertargetDurationMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $convertertargetDurationMsn =
      NullAwareTypeConverter.wrap($convertertargetDurationMs);
  static TypeConverter<Duration, int> $convertersilenceMs =
      const MillisDurationConverter();
  static TypeConverter<Duration?, int?> $convertersilenceMsn =
      NullAwareTypeConverter.wrap($convertersilenceMs);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const MillisConverter();
}

class PlaylistItem extends DataClass implements Insertable<PlaylistItem> {
  final String id;
  final String playlistId;
  final double position;
  final PlaylistItemType itemType;
  final String? trackId;
  final String? danceTypeId;
  final AnnounceMode? announceMode;

  /// Overrides the dance type's template.
  final String? announcementText;

  /// Overrides TTS entirely.
  final String? announcementClipPath;
  final Duration? crossfadeMs;
  final FadeCurve? fadeInCurve;
  final FadeCurve? fadeOutCurve;
  final Duration startOffsetMs;

  /// A hard stop point.
  final Duration? endOffsetMs;

  /// e.g. 1:45 for a competition round.
  final Duration? targetDurationMs;
  final double gainOffsetDb;

  /// Only meaningful when [itemType] is [PlaylistItemType.silence].
  final Duration? silenceMs;

  /// Stop after this row and wait for the operator — applause, MC handover.
  final bool pauseAfter;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const PlaylistItem({
    required this.id,
    required this.playlistId,
    required this.position,
    required this.itemType,
    this.trackId,
    this.danceTypeId,
    this.announceMode,
    this.announcementText,
    this.announcementClipPath,
    this.crossfadeMs,
    this.fadeInCurve,
    this.fadeOutCurve,
    required this.startOffsetMs,
    this.endOffsetMs,
    this.targetDurationMs,
    required this.gainOffsetDb,
    this.silenceMs,
    required this.pauseAfter,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['playlist_id'] = Variable<String>(playlistId);
    map['position'] = Variable<double>(position);
    {
      map['item_type'] = Variable<String>(
        $PlaylistItemsTable.$converteritemType.toSql(itemType),
      );
    }
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<String>(trackId);
    }
    if (!nullToAbsent || danceTypeId != null) {
      map['dance_type_id'] = Variable<String>(danceTypeId);
    }
    if (!nullToAbsent || announceMode != null) {
      map['announce_mode'] = Variable<String>(
        $PlaylistItemsTable.$converterannounceModen.toSql(announceMode),
      );
    }
    if (!nullToAbsent || announcementText != null) {
      map['announcement_text'] = Variable<String>(announcementText);
    }
    if (!nullToAbsent || announcementClipPath != null) {
      map['announcement_clip_path'] = Variable<String>(announcementClipPath);
    }
    if (!nullToAbsent || crossfadeMs != null) {
      map['crossfade_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertercrossfadeMsn.toSql(crossfadeMs),
      );
    }
    if (!nullToAbsent || fadeInCurve != null) {
      map['fade_in_curve'] = Variable<String>(
        $PlaylistItemsTable.$converterfadeInCurven.toSql(fadeInCurve),
      );
    }
    if (!nullToAbsent || fadeOutCurve != null) {
      map['fade_out_curve'] = Variable<String>(
        $PlaylistItemsTable.$converterfadeOutCurven.toSql(fadeOutCurve),
      );
    }
    {
      map['start_offset_ms'] = Variable<int>(
        $PlaylistItemsTable.$converterstartOffsetMs.toSql(startOffsetMs),
      );
    }
    if (!nullToAbsent || endOffsetMs != null) {
      map['end_offset_ms'] = Variable<int>(
        $PlaylistItemsTable.$converterendOffsetMsn.toSql(endOffsetMs),
      );
    }
    if (!nullToAbsent || targetDurationMs != null) {
      map['target_duration_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertertargetDurationMsn.toSql(targetDurationMs),
      );
    }
    map['gain_offset_db'] = Variable<double>(gainOffsetDb);
    if (!nullToAbsent || silenceMs != null) {
      map['silence_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertersilenceMsn.toSql(silenceMs),
      );
    }
    map['pause_after'] = Variable<bool>(pauseAfter);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['created_at'] = Variable<int>(
        $PlaylistItemsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $PlaylistItemsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  PlaylistItemsCompanion toCompanion(bool nullToAbsent) {
    return PlaylistItemsCompanion(
      id: Value(id),
      playlistId: Value(playlistId),
      position: Value(position),
      itemType: Value(itemType),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      danceTypeId: danceTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(danceTypeId),
      announceMode: announceMode == null && nullToAbsent
          ? const Value.absent()
          : Value(announceMode),
      announcementText: announcementText == null && nullToAbsent
          ? const Value.absent()
          : Value(announcementText),
      announcementClipPath: announcementClipPath == null && nullToAbsent
          ? const Value.absent()
          : Value(announcementClipPath),
      crossfadeMs: crossfadeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(crossfadeMs),
      fadeInCurve: fadeInCurve == null && nullToAbsent
          ? const Value.absent()
          : Value(fadeInCurve),
      fadeOutCurve: fadeOutCurve == null && nullToAbsent
          ? const Value.absent()
          : Value(fadeOutCurve),
      startOffsetMs: Value(startOffsetMs),
      endOffsetMs: endOffsetMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endOffsetMs),
      targetDurationMs: targetDurationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDurationMs),
      gainOffsetDb: Value(gainOffsetDb),
      silenceMs: silenceMs == null && nullToAbsent
          ? const Value.absent()
          : Value(silenceMs),
      pauseAfter: Value(pauseAfter),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory PlaylistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistItem(
      id: serializer.fromJson<String>(json['id']),
      playlistId: serializer.fromJson<String>(json['playlistId']),
      position: serializer.fromJson<double>(json['position']),
      itemType: $PlaylistItemsTable.$converteritemType.fromJson(
        serializer.fromJson<String>(json['itemType']),
      ),
      trackId: serializer.fromJson<String?>(json['trackId']),
      danceTypeId: serializer.fromJson<String?>(json['danceTypeId']),
      announceMode: $PlaylistItemsTable.$converterannounceModen.fromJson(
        serializer.fromJson<String?>(json['announceMode']),
      ),
      announcementText: serializer.fromJson<String?>(json['announcementText']),
      announcementClipPath: serializer.fromJson<String?>(
        json['announcementClipPath'],
      ),
      crossfadeMs: serializer.fromJson<Duration?>(json['crossfadeMs']),
      fadeInCurve: $PlaylistItemsTable.$converterfadeInCurven.fromJson(
        serializer.fromJson<String?>(json['fadeInCurve']),
      ),
      fadeOutCurve: $PlaylistItemsTable.$converterfadeOutCurven.fromJson(
        serializer.fromJson<String?>(json['fadeOutCurve']),
      ),
      startOffsetMs: serializer.fromJson<Duration>(json['startOffsetMs']),
      endOffsetMs: serializer.fromJson<Duration?>(json['endOffsetMs']),
      targetDurationMs: serializer.fromJson<Duration?>(
        json['targetDurationMs'],
      ),
      gainOffsetDb: serializer.fromJson<double>(json['gainOffsetDb']),
      silenceMs: serializer.fromJson<Duration?>(json['silenceMs']),
      pauseAfter: serializer.fromJson<bool>(json['pauseAfter']),
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
      'playlistId': serializer.toJson<String>(playlistId),
      'position': serializer.toJson<double>(position),
      'itemType': serializer.toJson<String>(
        $PlaylistItemsTable.$converteritemType.toJson(itemType),
      ),
      'trackId': serializer.toJson<String?>(trackId),
      'danceTypeId': serializer.toJson<String?>(danceTypeId),
      'announceMode': serializer.toJson<String?>(
        $PlaylistItemsTable.$converterannounceModen.toJson(announceMode),
      ),
      'announcementText': serializer.toJson<String?>(announcementText),
      'announcementClipPath': serializer.toJson<String?>(announcementClipPath),
      'crossfadeMs': serializer.toJson<Duration?>(crossfadeMs),
      'fadeInCurve': serializer.toJson<String?>(
        $PlaylistItemsTable.$converterfadeInCurven.toJson(fadeInCurve),
      ),
      'fadeOutCurve': serializer.toJson<String?>(
        $PlaylistItemsTable.$converterfadeOutCurven.toJson(fadeOutCurve),
      ),
      'startOffsetMs': serializer.toJson<Duration>(startOffsetMs),
      'endOffsetMs': serializer.toJson<Duration?>(endOffsetMs),
      'targetDurationMs': serializer.toJson<Duration?>(targetDurationMs),
      'gainOffsetDb': serializer.toJson<double>(gainOffsetDb),
      'silenceMs': serializer.toJson<Duration?>(silenceMs),
      'pauseAfter': serializer.toJson<bool>(pauseAfter),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PlaylistItem copyWith({
    String? id,
    String? playlistId,
    double? position,
    PlaylistItemType? itemType,
    Value<String?> trackId = const Value.absent(),
    Value<String?> danceTypeId = const Value.absent(),
    Value<AnnounceMode?> announceMode = const Value.absent(),
    Value<String?> announcementText = const Value.absent(),
    Value<String?> announcementClipPath = const Value.absent(),
    Value<Duration?> crossfadeMs = const Value.absent(),
    Value<FadeCurve?> fadeInCurve = const Value.absent(),
    Value<FadeCurve?> fadeOutCurve = const Value.absent(),
    Duration? startOffsetMs,
    Value<Duration?> endOffsetMs = const Value.absent(),
    Value<Duration?> targetDurationMs = const Value.absent(),
    double? gainOffsetDb,
    Value<Duration?> silenceMs = const Value.absent(),
    bool? pauseAfter,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => PlaylistItem(
    id: id ?? this.id,
    playlistId: playlistId ?? this.playlistId,
    position: position ?? this.position,
    itemType: itemType ?? this.itemType,
    trackId: trackId.present ? trackId.value : this.trackId,
    danceTypeId: danceTypeId.present ? danceTypeId.value : this.danceTypeId,
    announceMode: announceMode.present ? announceMode.value : this.announceMode,
    announcementText: announcementText.present
        ? announcementText.value
        : this.announcementText,
    announcementClipPath: announcementClipPath.present
        ? announcementClipPath.value
        : this.announcementClipPath,
    crossfadeMs: crossfadeMs.present ? crossfadeMs.value : this.crossfadeMs,
    fadeInCurve: fadeInCurve.present ? fadeInCurve.value : this.fadeInCurve,
    fadeOutCurve: fadeOutCurve.present ? fadeOutCurve.value : this.fadeOutCurve,
    startOffsetMs: startOffsetMs ?? this.startOffsetMs,
    endOffsetMs: endOffsetMs.present ? endOffsetMs.value : this.endOffsetMs,
    targetDurationMs: targetDurationMs.present
        ? targetDurationMs.value
        : this.targetDurationMs,
    gainOffsetDb: gainOffsetDb ?? this.gainOffsetDb,
    silenceMs: silenceMs.present ? silenceMs.value : this.silenceMs,
    pauseAfter: pauseAfter ?? this.pauseAfter,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PlaylistItem copyWithCompanion(PlaylistItemsCompanion data) {
    return PlaylistItem(
      id: data.id.present ? data.id.value : this.id,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      position: data.position.present ? data.position.value : this.position,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      danceTypeId: data.danceTypeId.present
          ? data.danceTypeId.value
          : this.danceTypeId,
      announceMode: data.announceMode.present
          ? data.announceMode.value
          : this.announceMode,
      announcementText: data.announcementText.present
          ? data.announcementText.value
          : this.announcementText,
      announcementClipPath: data.announcementClipPath.present
          ? data.announcementClipPath.value
          : this.announcementClipPath,
      crossfadeMs: data.crossfadeMs.present
          ? data.crossfadeMs.value
          : this.crossfadeMs,
      fadeInCurve: data.fadeInCurve.present
          ? data.fadeInCurve.value
          : this.fadeInCurve,
      fadeOutCurve: data.fadeOutCurve.present
          ? data.fadeOutCurve.value
          : this.fadeOutCurve,
      startOffsetMs: data.startOffsetMs.present
          ? data.startOffsetMs.value
          : this.startOffsetMs,
      endOffsetMs: data.endOffsetMs.present
          ? data.endOffsetMs.value
          : this.endOffsetMs,
      targetDurationMs: data.targetDurationMs.present
          ? data.targetDurationMs.value
          : this.targetDurationMs,
      gainOffsetDb: data.gainOffsetDb.present
          ? data.gainOffsetDb.value
          : this.gainOffsetDb,
      silenceMs: data.silenceMs.present ? data.silenceMs.value : this.silenceMs,
      pauseAfter: data.pauseAfter.present
          ? data.pauseAfter.value
          : this.pauseAfter,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItem(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('itemType: $itemType, ')
          ..write('trackId: $trackId, ')
          ..write('danceTypeId: $danceTypeId, ')
          ..write('announceMode: $announceMode, ')
          ..write('announcementText: $announcementText, ')
          ..write('announcementClipPath: $announcementClipPath, ')
          ..write('crossfadeMs: $crossfadeMs, ')
          ..write('fadeInCurve: $fadeInCurve, ')
          ..write('fadeOutCurve: $fadeOutCurve, ')
          ..write('startOffsetMs: $startOffsetMs, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('targetDurationMs: $targetDurationMs, ')
          ..write('gainOffsetDb: $gainOffsetDb, ')
          ..write('silenceMs: $silenceMs, ')
          ..write('pauseAfter: $pauseAfter, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    playlistId,
    position,
    itemType,
    trackId,
    danceTypeId,
    announceMode,
    announcementText,
    announcementClipPath,
    crossfadeMs,
    fadeInCurve,
    fadeOutCurve,
    startOffsetMs,
    endOffsetMs,
    targetDurationMs,
    gainOffsetDb,
    silenceMs,
    pauseAfter,
    notes,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistItem &&
          other.id == this.id &&
          other.playlistId == this.playlistId &&
          other.position == this.position &&
          other.itemType == this.itemType &&
          other.trackId == this.trackId &&
          other.danceTypeId == this.danceTypeId &&
          other.announceMode == this.announceMode &&
          other.announcementText == this.announcementText &&
          other.announcementClipPath == this.announcementClipPath &&
          other.crossfadeMs == this.crossfadeMs &&
          other.fadeInCurve == this.fadeInCurve &&
          other.fadeOutCurve == this.fadeOutCurve &&
          other.startOffsetMs == this.startOffsetMs &&
          other.endOffsetMs == this.endOffsetMs &&
          other.targetDurationMs == this.targetDurationMs &&
          other.gainOffsetDb == this.gainOffsetDb &&
          other.silenceMs == this.silenceMs &&
          other.pauseAfter == this.pauseAfter &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlaylistItemsCompanion extends UpdateCompanion<PlaylistItem> {
  final Value<String> id;
  final Value<String> playlistId;
  final Value<double> position;
  final Value<PlaylistItemType> itemType;
  final Value<String?> trackId;
  final Value<String?> danceTypeId;
  final Value<AnnounceMode?> announceMode;
  final Value<String?> announcementText;
  final Value<String?> announcementClipPath;
  final Value<Duration?> crossfadeMs;
  final Value<FadeCurve?> fadeInCurve;
  final Value<FadeCurve?> fadeOutCurve;
  final Value<Duration> startOffsetMs;
  final Value<Duration?> endOffsetMs;
  final Value<Duration?> targetDurationMs;
  final Value<double> gainOffsetDb;
  final Value<Duration?> silenceMs;
  final Value<bool> pauseAfter;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PlaylistItemsCompanion({
    this.id = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.position = const Value.absent(),
    this.itemType = const Value.absent(),
    this.trackId = const Value.absent(),
    this.danceTypeId = const Value.absent(),
    this.announceMode = const Value.absent(),
    this.announcementText = const Value.absent(),
    this.announcementClipPath = const Value.absent(),
    this.crossfadeMs = const Value.absent(),
    this.fadeInCurve = const Value.absent(),
    this.fadeOutCurve = const Value.absent(),
    this.startOffsetMs = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    this.targetDurationMs = const Value.absent(),
    this.gainOffsetDb = const Value.absent(),
    this.silenceMs = const Value.absent(),
    this.pauseAfter = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlaylistItemsCompanion.insert({
    required String id,
    required String playlistId,
    required double position,
    this.itemType = const Value.absent(),
    this.trackId = const Value.absent(),
    this.danceTypeId = const Value.absent(),
    this.announceMode = const Value.absent(),
    this.announcementText = const Value.absent(),
    this.announcementClipPath = const Value.absent(),
    this.crossfadeMs = const Value.absent(),
    this.fadeInCurve = const Value.absent(),
    this.fadeOutCurve = const Value.absent(),
    this.startOffsetMs = const Value.absent(),
    this.endOffsetMs = const Value.absent(),
    this.targetDurationMs = const Value.absent(),
    this.gainOffsetDb = const Value.absent(),
    this.silenceMs = const Value.absent(),
    this.pauseAfter = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       playlistId = Value(playlistId),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<PlaylistItem> custom({
    Expression<String>? id,
    Expression<String>? playlistId,
    Expression<double>? position,
    Expression<String>? itemType,
    Expression<String>? trackId,
    Expression<String>? danceTypeId,
    Expression<String>? announceMode,
    Expression<String>? announcementText,
    Expression<String>? announcementClipPath,
    Expression<int>? crossfadeMs,
    Expression<String>? fadeInCurve,
    Expression<String>? fadeOutCurve,
    Expression<int>? startOffsetMs,
    Expression<int>? endOffsetMs,
    Expression<int>? targetDurationMs,
    Expression<double>? gainOffsetDb,
    Expression<int>? silenceMs,
    Expression<bool>? pauseAfter,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlistId != null) 'playlist_id': playlistId,
      if (position != null) 'position': position,
      if (itemType != null) 'item_type': itemType,
      if (trackId != null) 'track_id': trackId,
      if (danceTypeId != null) 'dance_type_id': danceTypeId,
      if (announceMode != null) 'announce_mode': announceMode,
      if (announcementText != null) 'announcement_text': announcementText,
      if (announcementClipPath != null)
        'announcement_clip_path': announcementClipPath,
      if (crossfadeMs != null) 'crossfade_ms': crossfadeMs,
      if (fadeInCurve != null) 'fade_in_curve': fadeInCurve,
      if (fadeOutCurve != null) 'fade_out_curve': fadeOutCurve,
      if (startOffsetMs != null) 'start_offset_ms': startOffsetMs,
      if (endOffsetMs != null) 'end_offset_ms': endOffsetMs,
      if (targetDurationMs != null) 'target_duration_ms': targetDurationMs,
      if (gainOffsetDb != null) 'gain_offset_db': gainOffsetDb,
      if (silenceMs != null) 'silence_ms': silenceMs,
      if (pauseAfter != null) 'pause_after': pauseAfter,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlaylistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? playlistId,
    Value<double>? position,
    Value<PlaylistItemType>? itemType,
    Value<String?>? trackId,
    Value<String?>? danceTypeId,
    Value<AnnounceMode?>? announceMode,
    Value<String?>? announcementText,
    Value<String?>? announcementClipPath,
    Value<Duration?>? crossfadeMs,
    Value<FadeCurve?>? fadeInCurve,
    Value<FadeCurve?>? fadeOutCurve,
    Value<Duration>? startOffsetMs,
    Value<Duration?>? endOffsetMs,
    Value<Duration?>? targetDurationMs,
    Value<double>? gainOffsetDb,
    Value<Duration?>? silenceMs,
    Value<bool>? pauseAfter,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PlaylistItemsCompanion(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      position: position ?? this.position,
      itemType: itemType ?? this.itemType,
      trackId: trackId ?? this.trackId,
      danceTypeId: danceTypeId ?? this.danceTypeId,
      announceMode: announceMode ?? this.announceMode,
      announcementText: announcementText ?? this.announcementText,
      announcementClipPath: announcementClipPath ?? this.announcementClipPath,
      crossfadeMs: crossfadeMs ?? this.crossfadeMs,
      fadeInCurve: fadeInCurve ?? this.fadeInCurve,
      fadeOutCurve: fadeOutCurve ?? this.fadeOutCurve,
      startOffsetMs: startOffsetMs ?? this.startOffsetMs,
      endOffsetMs: endOffsetMs ?? this.endOffsetMs,
      targetDurationMs: targetDurationMs ?? this.targetDurationMs,
      gainOffsetDb: gainOffsetDb ?? this.gainOffsetDb,
      silenceMs: silenceMs ?? this.silenceMs,
      pauseAfter: pauseAfter ?? this.pauseAfter,
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
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(
        $PlaylistItemsTable.$converteritemType.toSql(itemType.value),
      );
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (danceTypeId.present) {
      map['dance_type_id'] = Variable<String>(danceTypeId.value);
    }
    if (announceMode.present) {
      map['announce_mode'] = Variable<String>(
        $PlaylistItemsTable.$converterannounceModen.toSql(announceMode.value),
      );
    }
    if (announcementText.present) {
      map['announcement_text'] = Variable<String>(announcementText.value);
    }
    if (announcementClipPath.present) {
      map['announcement_clip_path'] = Variable<String>(
        announcementClipPath.value,
      );
    }
    if (crossfadeMs.present) {
      map['crossfade_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertercrossfadeMsn.toSql(crossfadeMs.value),
      );
    }
    if (fadeInCurve.present) {
      map['fade_in_curve'] = Variable<String>(
        $PlaylistItemsTable.$converterfadeInCurven.toSql(fadeInCurve.value),
      );
    }
    if (fadeOutCurve.present) {
      map['fade_out_curve'] = Variable<String>(
        $PlaylistItemsTable.$converterfadeOutCurven.toSql(fadeOutCurve.value),
      );
    }
    if (startOffsetMs.present) {
      map['start_offset_ms'] = Variable<int>(
        $PlaylistItemsTable.$converterstartOffsetMs.toSql(startOffsetMs.value),
      );
    }
    if (endOffsetMs.present) {
      map['end_offset_ms'] = Variable<int>(
        $PlaylistItemsTable.$converterendOffsetMsn.toSql(endOffsetMs.value),
      );
    }
    if (targetDurationMs.present) {
      map['target_duration_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertertargetDurationMsn.toSql(
          targetDurationMs.value,
        ),
      );
    }
    if (gainOffsetDb.present) {
      map['gain_offset_db'] = Variable<double>(gainOffsetDb.value);
    }
    if (silenceMs.present) {
      map['silence_ms'] = Variable<int>(
        $PlaylistItemsTable.$convertersilenceMsn.toSql(silenceMs.value),
      );
    }
    if (pauseAfter.present) {
      map['pause_after'] = Variable<bool>(pauseAfter.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $PlaylistItemsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $PlaylistItemsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistItemsCompanion(')
          ..write('id: $id, ')
          ..write('playlistId: $playlistId, ')
          ..write('position: $position, ')
          ..write('itemType: $itemType, ')
          ..write('trackId: $trackId, ')
          ..write('danceTypeId: $danceTypeId, ')
          ..write('announceMode: $announceMode, ')
          ..write('announcementText: $announcementText, ')
          ..write('announcementClipPath: $announcementClipPath, ')
          ..write('crossfadeMs: $crossfadeMs, ')
          ..write('fadeInCurve: $fadeInCurve, ')
          ..write('fadeOutCurve: $fadeOutCurve, ')
          ..write('startOffsetMs: $startOffsetMs, ')
          ..write('endOffsetMs: $endOffsetMs, ')
          ..write('targetDurationMs: $targetDurationMs, ')
          ..write('gainOffsetDb: $gainOffsetDb, ')
          ..write('silenceMs: $silenceMs, ')
          ..write('pauseAfter: $pauseAfter, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheEntriesTable extends CacheEntries
    with TableInfo<$CacheEntriesTable, CacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CacheState, String> state =
      GeneratedColumn<String>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('none'),
      ).withConverter<CacheState>($CacheEntriesTable.$converterstate);
  static const VerificationMeta _cachePathMeta = const VerificationMeta(
    'cachePath',
  );
  @override
  late final GeneratedColumn<String> cachePath = GeneratedColumn<String>(
    'cache_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesDownloadedMeta = const VerificationMeta(
    'bytesDownloaded',
  );
  @override
  late final GeneratedColumn<int> bytesDownloaded = GeneratedColumn<int>(
    'bytes_downloaded',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _encryptionKeyRefMeta = const VerificationMeta(
    'encryptionKeyRef',
  );
  @override
  late final GeneratedColumn<String> encryptionKeyRef = GeneratedColumn<String>(
    'encryption_key_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _policyAllowsPersistMeta =
      const VerificationMeta('policyAllowsPersist');
  @override
  late final GeneratedColumn<bool> policyAllowsPersist = GeneratedColumn<bool>(
    'policy_allows_persist',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("policy_allows_persist" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _drmLicensePathMeta = const VerificationMeta(
    'drmLicensePath',
  );
  @override
  late final GeneratedColumn<String> drmLicensePath = GeneratedColumn<String>(
    'drm_license_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int>
  drmLicenseExpiresAt = GeneratedColumn<int>(
    'drm_license_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  ).withConverter<DateTime?>($CacheEntriesTable.$converterdrmLicenseExpiresAtn);
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
    'pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> expiresAt =
      GeneratedColumn<int>(
        'expires_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CacheEntriesTable.$converterexpiresAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastAccessedAt =
      GeneratedColumn<int>(
        'last_accessed_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($CacheEntriesTable.$converterlastAccessedAtn);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CacheEntriesTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    trackId,
    state,
    cachePath,
    byteSize,
    bytesDownloaded,
    encryptionKeyRef,
    policyAllowsPersist,
    drmLicensePath,
    drmLicenseExpiresAt,
    pinned,
    expiresAt,
    lastAccessedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trackIdMeta);
    }
    if (data.containsKey('cache_path')) {
      context.handle(
        _cachePathMeta,
        cachePath.isAcceptableOrUnknown(data['cache_path']!, _cachePathMeta),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('bytes_downloaded')) {
      context.handle(
        _bytesDownloadedMeta,
        bytesDownloaded.isAcceptableOrUnknown(
          data['bytes_downloaded']!,
          _bytesDownloadedMeta,
        ),
      );
    }
    if (data.containsKey('encryption_key_ref')) {
      context.handle(
        _encryptionKeyRefMeta,
        encryptionKeyRef.isAcceptableOrUnknown(
          data['encryption_key_ref']!,
          _encryptionKeyRefMeta,
        ),
      );
    }
    if (data.containsKey('policy_allows_persist')) {
      context.handle(
        _policyAllowsPersistMeta,
        policyAllowsPersist.isAcceptableOrUnknown(
          data['policy_allows_persist']!,
          _policyAllowsPersistMeta,
        ),
      );
    }
    if (data.containsKey('drm_license_path')) {
      context.handle(
        _drmLicensePathMeta,
        drmLicensePath.isAcceptableOrUnknown(
          data['drm_license_path']!,
          _drmLicensePathMeta,
        ),
      );
    }
    if (data.containsKey('pinned')) {
      context.handle(
        _pinnedMeta,
        pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trackId};
  @override
  CacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheEntry(
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      )!,
      state: $CacheEntriesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}state'],
        )!,
      ),
      cachePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_path'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      bytesDownloaded: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_downloaded'],
      )!,
      encryptionKeyRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encryption_key_ref'],
      ),
      policyAllowsPersist: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}policy_allows_persist'],
      )!,
      drmLicensePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}drm_license_path'],
      ),
      drmLicenseExpiresAt: $CacheEntriesTable.$converterdrmLicenseExpiresAtn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.int,
              data['${effectivePrefix}drm_license_expires_at'],
            ),
          ),
      pinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pinned'],
      )!,
      expiresAt: $CacheEntriesTable.$converterexpiresAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}expires_at'],
        ),
      ),
      lastAccessedAt: $CacheEntriesTable.$converterlastAccessedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_accessed_at'],
        ),
      ),
      createdAt: $CacheEntriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $CacheEntriesTable createAlias(String alias) {
    return $CacheEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CacheState, String, String> $converterstate =
      const EnumNameConverter<CacheState>(CacheState.values);
  static TypeConverter<DateTime, int> $converterdrmLicenseExpiresAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterdrmLicenseExpiresAtn =
      NullAwareTypeConverter.wrap($converterdrmLicenseExpiresAt);
  static TypeConverter<DateTime, int> $converterexpiresAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterexpiresAtn =
      NullAwareTypeConverter.wrap($converterexpiresAt);
  static TypeConverter<DateTime, int> $converterlastAccessedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastAccessedAtn =
      NullAwareTypeConverter.wrap($converterlastAccessedAt);
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
}

class CacheEntry extends DataClass implements Insertable<CacheEntry> {
  final String trackId;
  final CacheState state;
  final String? cachePath;
  final int byteSize;
  final int bytesDownloaded;

  /// Keychain ref for the at-rest encryption key.
  final String? encryptionKeyRef;
  final bool policyAllowsPersist;

  /// Offline Widevine or persistent FairPlay key.
  final String? drmLicensePath;
  final DateTime? drmLicenseExpiresAt;

  /// Exempt from LRU eviction.
  final bool pinned;
  final DateTime? expiresAt;
  final DateTime? lastAccessedAt;
  final DateTime createdAt;
  const CacheEntry({
    required this.trackId,
    required this.state,
    this.cachePath,
    required this.byteSize,
    required this.bytesDownloaded,
    this.encryptionKeyRef,
    required this.policyAllowsPersist,
    this.drmLicensePath,
    this.drmLicenseExpiresAt,
    required this.pinned,
    this.expiresAt,
    this.lastAccessedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['track_id'] = Variable<String>(trackId);
    {
      map['state'] = Variable<String>(
        $CacheEntriesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || cachePath != null) {
      map['cache_path'] = Variable<String>(cachePath);
    }
    map['byte_size'] = Variable<int>(byteSize);
    map['bytes_downloaded'] = Variable<int>(bytesDownloaded);
    if (!nullToAbsent || encryptionKeyRef != null) {
      map['encryption_key_ref'] = Variable<String>(encryptionKeyRef);
    }
    map['policy_allows_persist'] = Variable<bool>(policyAllowsPersist);
    if (!nullToAbsent || drmLicensePath != null) {
      map['drm_license_path'] = Variable<String>(drmLicensePath);
    }
    if (!nullToAbsent || drmLicenseExpiresAt != null) {
      map['drm_license_expires_at'] = Variable<int>(
        $CacheEntriesTable.$converterdrmLicenseExpiresAtn.toSql(
          drmLicenseExpiresAt,
        ),
      );
    }
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<int>(
        $CacheEntriesTable.$converterexpiresAtn.toSql(expiresAt),
      );
    }
    if (!nullToAbsent || lastAccessedAt != null) {
      map['last_accessed_at'] = Variable<int>(
        $CacheEntriesTable.$converterlastAccessedAtn.toSql(lastAccessedAt),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $CacheEntriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  CacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheEntriesCompanion(
      trackId: Value(trackId),
      state: Value(state),
      cachePath: cachePath == null && nullToAbsent
          ? const Value.absent()
          : Value(cachePath),
      byteSize: Value(byteSize),
      bytesDownloaded: Value(bytesDownloaded),
      encryptionKeyRef: encryptionKeyRef == null && nullToAbsent
          ? const Value.absent()
          : Value(encryptionKeyRef),
      policyAllowsPersist: Value(policyAllowsPersist),
      drmLicensePath: drmLicensePath == null && nullToAbsent
          ? const Value.absent()
          : Value(drmLicensePath),
      drmLicenseExpiresAt: drmLicenseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(drmLicenseExpiresAt),
      pinned: Value(pinned),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      lastAccessedAt: lastAccessedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAt),
      createdAt: Value(createdAt),
    );
  }

  factory CacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheEntry(
      trackId: serializer.fromJson<String>(json['trackId']),
      state: $CacheEntriesTable.$converterstate.fromJson(
        serializer.fromJson<String>(json['state']),
      ),
      cachePath: serializer.fromJson<String?>(json['cachePath']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      bytesDownloaded: serializer.fromJson<int>(json['bytesDownloaded']),
      encryptionKeyRef: serializer.fromJson<String?>(json['encryptionKeyRef']),
      policyAllowsPersist: serializer.fromJson<bool>(
        json['policyAllowsPersist'],
      ),
      drmLicensePath: serializer.fromJson<String?>(json['drmLicensePath']),
      drmLicenseExpiresAt: serializer.fromJson<DateTime?>(
        json['drmLicenseExpiresAt'],
      ),
      pinned: serializer.fromJson<bool>(json['pinned']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      lastAccessedAt: serializer.fromJson<DateTime?>(json['lastAccessedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trackId': serializer.toJson<String>(trackId),
      'state': serializer.toJson<String>(
        $CacheEntriesTable.$converterstate.toJson(state),
      ),
      'cachePath': serializer.toJson<String?>(cachePath),
      'byteSize': serializer.toJson<int>(byteSize),
      'bytesDownloaded': serializer.toJson<int>(bytesDownloaded),
      'encryptionKeyRef': serializer.toJson<String?>(encryptionKeyRef),
      'policyAllowsPersist': serializer.toJson<bool>(policyAllowsPersist),
      'drmLicensePath': serializer.toJson<String?>(drmLicensePath),
      'drmLicenseExpiresAt': serializer.toJson<DateTime?>(drmLicenseExpiresAt),
      'pinned': serializer.toJson<bool>(pinned),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'lastAccessedAt': serializer.toJson<DateTime?>(lastAccessedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CacheEntry copyWith({
    String? trackId,
    CacheState? state,
    Value<String?> cachePath = const Value.absent(),
    int? byteSize,
    int? bytesDownloaded,
    Value<String?> encryptionKeyRef = const Value.absent(),
    bool? policyAllowsPersist,
    Value<String?> drmLicensePath = const Value.absent(),
    Value<DateTime?> drmLicenseExpiresAt = const Value.absent(),
    bool? pinned,
    Value<DateTime?> expiresAt = const Value.absent(),
    Value<DateTime?> lastAccessedAt = const Value.absent(),
    DateTime? createdAt,
  }) => CacheEntry(
    trackId: trackId ?? this.trackId,
    state: state ?? this.state,
    cachePath: cachePath.present ? cachePath.value : this.cachePath,
    byteSize: byteSize ?? this.byteSize,
    bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
    encryptionKeyRef: encryptionKeyRef.present
        ? encryptionKeyRef.value
        : this.encryptionKeyRef,
    policyAllowsPersist: policyAllowsPersist ?? this.policyAllowsPersist,
    drmLicensePath: drmLicensePath.present
        ? drmLicensePath.value
        : this.drmLicensePath,
    drmLicenseExpiresAt: drmLicenseExpiresAt.present
        ? drmLicenseExpiresAt.value
        : this.drmLicenseExpiresAt,
    pinned: pinned ?? this.pinned,
    expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
    lastAccessedAt: lastAccessedAt.present
        ? lastAccessedAt.value
        : this.lastAccessedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  CacheEntry copyWithCompanion(CacheEntriesCompanion data) {
    return CacheEntry(
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      state: data.state.present ? data.state.value : this.state,
      cachePath: data.cachePath.present ? data.cachePath.value : this.cachePath,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      bytesDownloaded: data.bytesDownloaded.present
          ? data.bytesDownloaded.value
          : this.bytesDownloaded,
      encryptionKeyRef: data.encryptionKeyRef.present
          ? data.encryptionKeyRef.value
          : this.encryptionKeyRef,
      policyAllowsPersist: data.policyAllowsPersist.present
          ? data.policyAllowsPersist.value
          : this.policyAllowsPersist,
      drmLicensePath: data.drmLicensePath.present
          ? data.drmLicensePath.value
          : this.drmLicensePath,
      drmLicenseExpiresAt: data.drmLicenseExpiresAt.present
          ? data.drmLicenseExpiresAt.value
          : this.drmLicenseExpiresAt,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      lastAccessedAt: data.lastAccessedAt.present
          ? data.lastAccessedAt.value
          : this.lastAccessedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntry(')
          ..write('trackId: $trackId, ')
          ..write('state: $state, ')
          ..write('cachePath: $cachePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('encryptionKeyRef: $encryptionKeyRef, ')
          ..write('policyAllowsPersist: $policyAllowsPersist, ')
          ..write('drmLicensePath: $drmLicensePath, ')
          ..write('drmLicenseExpiresAt: $drmLicenseExpiresAt, ')
          ..write('pinned: $pinned, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trackId,
    state,
    cachePath,
    byteSize,
    bytesDownloaded,
    encryptionKeyRef,
    policyAllowsPersist,
    drmLicensePath,
    drmLicenseExpiresAt,
    pinned,
    expiresAt,
    lastAccessedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheEntry &&
          other.trackId == this.trackId &&
          other.state == this.state &&
          other.cachePath == this.cachePath &&
          other.byteSize == this.byteSize &&
          other.bytesDownloaded == this.bytesDownloaded &&
          other.encryptionKeyRef == this.encryptionKeyRef &&
          other.policyAllowsPersist == this.policyAllowsPersist &&
          other.drmLicensePath == this.drmLicensePath &&
          other.drmLicenseExpiresAt == this.drmLicenseExpiresAt &&
          other.pinned == this.pinned &&
          other.expiresAt == this.expiresAt &&
          other.lastAccessedAt == this.lastAccessedAt &&
          other.createdAt == this.createdAt);
}

class CacheEntriesCompanion extends UpdateCompanion<CacheEntry> {
  final Value<String> trackId;
  final Value<CacheState> state;
  final Value<String?> cachePath;
  final Value<int> byteSize;
  final Value<int> bytesDownloaded;
  final Value<String?> encryptionKeyRef;
  final Value<bool> policyAllowsPersist;
  final Value<String?> drmLicensePath;
  final Value<DateTime?> drmLicenseExpiresAt;
  final Value<bool> pinned;
  final Value<DateTime?> expiresAt;
  final Value<DateTime?> lastAccessedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CacheEntriesCompanion({
    this.trackId = const Value.absent(),
    this.state = const Value.absent(),
    this.cachePath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.encryptionKeyRef = const Value.absent(),
    this.policyAllowsPersist = const Value.absent(),
    this.drmLicensePath = const Value.absent(),
    this.drmLicenseExpiresAt = const Value.absent(),
    this.pinned = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheEntriesCompanion.insert({
    required String trackId,
    this.state = const Value.absent(),
    this.cachePath = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.bytesDownloaded = const Value.absent(),
    this.encryptionKeyRef = const Value.absent(),
    this.policyAllowsPersist = const Value.absent(),
    this.drmLicensePath = const Value.absent(),
    this.drmLicenseExpiresAt = const Value.absent(),
    this.pinned = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.lastAccessedAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : trackId = Value(trackId),
       createdAt = Value(createdAt);
  static Insertable<CacheEntry> custom({
    Expression<String>? trackId,
    Expression<String>? state,
    Expression<String>? cachePath,
    Expression<int>? byteSize,
    Expression<int>? bytesDownloaded,
    Expression<String>? encryptionKeyRef,
    Expression<bool>? policyAllowsPersist,
    Expression<String>? drmLicensePath,
    Expression<int>? drmLicenseExpiresAt,
    Expression<bool>? pinned,
    Expression<int>? expiresAt,
    Expression<int>? lastAccessedAt,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trackId != null) 'track_id': trackId,
      if (state != null) 'state': state,
      if (cachePath != null) 'cache_path': cachePath,
      if (byteSize != null) 'byte_size': byteSize,
      if (bytesDownloaded != null) 'bytes_downloaded': bytesDownloaded,
      if (encryptionKeyRef != null) 'encryption_key_ref': encryptionKeyRef,
      if (policyAllowsPersist != null)
        'policy_allows_persist': policyAllowsPersist,
      if (drmLicensePath != null) 'drm_license_path': drmLicensePath,
      if (drmLicenseExpiresAt != null)
        'drm_license_expires_at': drmLicenseExpiresAt,
      if (pinned != null) 'pinned': pinned,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (lastAccessedAt != null) 'last_accessed_at': lastAccessedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheEntriesCompanion copyWith({
    Value<String>? trackId,
    Value<CacheState>? state,
    Value<String?>? cachePath,
    Value<int>? byteSize,
    Value<int>? bytesDownloaded,
    Value<String?>? encryptionKeyRef,
    Value<bool>? policyAllowsPersist,
    Value<String?>? drmLicensePath,
    Value<DateTime?>? drmLicenseExpiresAt,
    Value<bool>? pinned,
    Value<DateTime?>? expiresAt,
    Value<DateTime?>? lastAccessedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CacheEntriesCompanion(
      trackId: trackId ?? this.trackId,
      state: state ?? this.state,
      cachePath: cachePath ?? this.cachePath,
      byteSize: byteSize ?? this.byteSize,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      encryptionKeyRef: encryptionKeyRef ?? this.encryptionKeyRef,
      policyAllowsPersist: policyAllowsPersist ?? this.policyAllowsPersist,
      drmLicensePath: drmLicensePath ?? this.drmLicensePath,
      drmLicenseExpiresAt: drmLicenseExpiresAt ?? this.drmLicenseExpiresAt,
      pinned: pinned ?? this.pinned,
      expiresAt: expiresAt ?? this.expiresAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(
        $CacheEntriesTable.$converterstate.toSql(state.value),
      );
    }
    if (cachePath.present) {
      map['cache_path'] = Variable<String>(cachePath.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (bytesDownloaded.present) {
      map['bytes_downloaded'] = Variable<int>(bytesDownloaded.value);
    }
    if (encryptionKeyRef.present) {
      map['encryption_key_ref'] = Variable<String>(encryptionKeyRef.value);
    }
    if (policyAllowsPersist.present) {
      map['policy_allows_persist'] = Variable<bool>(policyAllowsPersist.value);
    }
    if (drmLicensePath.present) {
      map['drm_license_path'] = Variable<String>(drmLicensePath.value);
    }
    if (drmLicenseExpiresAt.present) {
      map['drm_license_expires_at'] = Variable<int>(
        $CacheEntriesTable.$converterdrmLicenseExpiresAtn.toSql(
          drmLicenseExpiresAt.value,
        ),
      );
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<int>(
        $CacheEntriesTable.$converterexpiresAtn.toSql(expiresAt.value),
      );
    }
    if (lastAccessedAt.present) {
      map['last_accessed_at'] = Variable<int>(
        $CacheEntriesTable.$converterlastAccessedAtn.toSql(
          lastAccessedAt.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $CacheEntriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheEntriesCompanion(')
          ..write('trackId: $trackId, ')
          ..write('state: $state, ')
          ..write('cachePath: $cachePath, ')
          ..write('byteSize: $byteSize, ')
          ..write('bytesDownloaded: $bytesDownloaded, ')
          ..write('encryptionKeyRef: $encryptionKeyRef, ')
          ..write('policyAllowsPersist: $policyAllowsPersist, ')
          ..write('drmLicensePath: $drmLicensePath, ')
          ..write('drmLicenseExpiresAt: $drmLicenseExpiresAt, ')
          ..write('pinned: $pinned, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('lastAccessedAt: $lastAccessedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnnouncementCacheTable extends AnnouncementCache
    with TableInfo<$AnnouncementCacheTable, AnnouncementCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnnouncementCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
    'hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceIdMeta = const VerificationMeta(
    'voiceId',
  );
  @override
  late final GeneratedColumn<String> voiceId = GeneratedColumn<String>(
    'voice_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pitchMeta = const VerificationMeta('pitch');
  @override
  late final GeneratedColumn<double> pitch = GeneratedColumn<double>(
    'pitch',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> durationMs =
      GeneratedColumn<int>(
        'duration_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<Duration>($AnnouncementCacheTable.$converterdurationMs);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AnnouncementCacheTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> lastUsedAt =
      GeneratedColumn<int>(
        'last_used_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($AnnouncementCacheTable.$converterlastUsedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    hash,
    body,
    voiceId,
    rate,
    pitch,
    filePath,
    durationMs,
    createdAt,
    lastUsedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'announcement_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnnouncementCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('hash')) {
      context.handle(
        _hashMeta,
        hash.isAcceptableOrUnknown(data['hash']!, _hashMeta),
      );
    } else if (isInserting) {
      context.missing(_hashMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('voice_id')) {
      context.handle(
        _voiceIdMeta,
        voiceId.isAcceptableOrUnknown(data['voice_id']!, _voiceIdMeta),
      );
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('pitch')) {
      context.handle(
        _pitchMeta,
        pitch.isAcceptableOrUnknown(data['pitch']!, _pitchMeta),
      );
    } else if (isInserting) {
      context.missing(_pitchMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {hash};
  @override
  AnnouncementCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnnouncementCacheRow(
      hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hash'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      voiceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_id'],
      ),
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      pitch: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pitch'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      durationMs: $AnnouncementCacheTable.$converterdurationMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}duration_ms'],
        )!,
      ),
      createdAt: $AnnouncementCacheTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      lastUsedAt: $AnnouncementCacheTable.$converterlastUsedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_used_at'],
        ),
      ),
    );
  }

  @override
  $AnnouncementCacheTable createAlias(String alias) {
    return $AnnouncementCacheTable(attachedDatabase, alias);
  }

  static TypeConverter<Duration, int> $converterdurationMs =
      const MillisDurationConverter();
  static TypeConverter<DateTime, int> $convertercreatedAt =
      const MillisConverter();
  static TypeConverter<DateTime, int> $converterlastUsedAt =
      const MillisConverter();
  static TypeConverter<DateTime?, int?> $converterlastUsedAtn =
      NullAwareTypeConverter.wrap($converterlastUsedAt);
}

class AnnouncementCacheRow extends DataClass
    implements Insertable<AnnouncementCacheRow> {
  final String hash;
  final String body;
  final String? voiceId;
  final double rate;
  final double pitch;
  final String filePath;
  final Duration durationMs;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  const AnnouncementCacheRow({
    required this.hash,
    required this.body,
    this.voiceId,
    required this.rate,
    required this.pitch,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    this.lastUsedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['hash'] = Variable<String>(hash);
    map['text'] = Variable<String>(body);
    if (!nullToAbsent || voiceId != null) {
      map['voice_id'] = Variable<String>(voiceId);
    }
    map['rate'] = Variable<double>(rate);
    map['pitch'] = Variable<double>(pitch);
    map['file_path'] = Variable<String>(filePath);
    {
      map['duration_ms'] = Variable<int>(
        $AnnouncementCacheTable.$converterdurationMs.toSql(durationMs),
      );
    }
    {
      map['created_at'] = Variable<int>(
        $AnnouncementCacheTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    if (!nullToAbsent || lastUsedAt != null) {
      map['last_used_at'] = Variable<int>(
        $AnnouncementCacheTable.$converterlastUsedAtn.toSql(lastUsedAt),
      );
    }
    return map;
  }

  AnnouncementCacheCompanion toCompanion(bool nullToAbsent) {
    return AnnouncementCacheCompanion(
      hash: Value(hash),
      body: Value(body),
      voiceId: voiceId == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceId),
      rate: Value(rate),
      pitch: Value(pitch),
      filePath: Value(filePath),
      durationMs: Value(durationMs),
      createdAt: Value(createdAt),
      lastUsedAt: lastUsedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUsedAt),
    );
  }

  factory AnnouncementCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnnouncementCacheRow(
      hash: serializer.fromJson<String>(json['hash']),
      body: serializer.fromJson<String>(json['body']),
      voiceId: serializer.fromJson<String?>(json['voiceId']),
      rate: serializer.fromJson<double>(json['rate']),
      pitch: serializer.fromJson<double>(json['pitch']),
      filePath: serializer.fromJson<String>(json['filePath']),
      durationMs: serializer.fromJson<Duration>(json['durationMs']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastUsedAt: serializer.fromJson<DateTime?>(json['lastUsedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'hash': serializer.toJson<String>(hash),
      'body': serializer.toJson<String>(body),
      'voiceId': serializer.toJson<String?>(voiceId),
      'rate': serializer.toJson<double>(rate),
      'pitch': serializer.toJson<double>(pitch),
      'filePath': serializer.toJson<String>(filePath),
      'durationMs': serializer.toJson<Duration>(durationMs),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastUsedAt': serializer.toJson<DateTime?>(lastUsedAt),
    };
  }

  AnnouncementCacheRow copyWith({
    String? hash,
    String? body,
    Value<String?> voiceId = const Value.absent(),
    double? rate,
    double? pitch,
    String? filePath,
    Duration? durationMs,
    DateTime? createdAt,
    Value<DateTime?> lastUsedAt = const Value.absent(),
  }) => AnnouncementCacheRow(
    hash: hash ?? this.hash,
    body: body ?? this.body,
    voiceId: voiceId.present ? voiceId.value : this.voiceId,
    rate: rate ?? this.rate,
    pitch: pitch ?? this.pitch,
    filePath: filePath ?? this.filePath,
    durationMs: durationMs ?? this.durationMs,
    createdAt: createdAt ?? this.createdAt,
    lastUsedAt: lastUsedAt.present ? lastUsedAt.value : this.lastUsedAt,
  );
  AnnouncementCacheRow copyWithCompanion(AnnouncementCacheCompanion data) {
    return AnnouncementCacheRow(
      hash: data.hash.present ? data.hash.value : this.hash,
      body: data.body.present ? data.body.value : this.body,
      voiceId: data.voiceId.present ? data.voiceId.value : this.voiceId,
      rate: data.rate.present ? data.rate.value : this.rate,
      pitch: data.pitch.present ? data.pitch.value : this.pitch,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastUsedAt: data.lastUsedAt.present
          ? data.lastUsedAt.value
          : this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnnouncementCacheRow(')
          ..write('hash: $hash, ')
          ..write('body: $body, ')
          ..write('voiceId: $voiceId, ')
          ..write('rate: $rate, ')
          ..write('pitch: $pitch, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    hash,
    body,
    voiceId,
    rate,
    pitch,
    filePath,
    durationMs,
    createdAt,
    lastUsedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnnouncementCacheRow &&
          other.hash == this.hash &&
          other.body == this.body &&
          other.voiceId == this.voiceId &&
          other.rate == this.rate &&
          other.pitch == this.pitch &&
          other.filePath == this.filePath &&
          other.durationMs == this.durationMs &&
          other.createdAt == this.createdAt &&
          other.lastUsedAt == this.lastUsedAt);
}

class AnnouncementCacheCompanion extends UpdateCompanion<AnnouncementCacheRow> {
  final Value<String> hash;
  final Value<String> body;
  final Value<String?> voiceId;
  final Value<double> rate;
  final Value<double> pitch;
  final Value<String> filePath;
  final Value<Duration> durationMs;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastUsedAt;
  final Value<int> rowid;
  const AnnouncementCacheCompanion({
    this.hash = const Value.absent(),
    this.body = const Value.absent(),
    this.voiceId = const Value.absent(),
    this.rate = const Value.absent(),
    this.pitch = const Value.absent(),
    this.filePath = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnnouncementCacheCompanion.insert({
    required String hash,
    required String body,
    this.voiceId = const Value.absent(),
    required double rate,
    required double pitch,
    required String filePath,
    required Duration durationMs,
    required DateTime createdAt,
    this.lastUsedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : hash = Value(hash),
       body = Value(body),
       rate = Value(rate),
       pitch = Value(pitch),
       filePath = Value(filePath),
       durationMs = Value(durationMs),
       createdAt = Value(createdAt);
  static Insertable<AnnouncementCacheRow> custom({
    Expression<String>? hash,
    Expression<String>? body,
    Expression<String>? voiceId,
    Expression<double>? rate,
    Expression<double>? pitch,
    Expression<String>? filePath,
    Expression<int>? durationMs,
    Expression<int>? createdAt,
    Expression<int>? lastUsedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (hash != null) 'hash': hash,
      if (body != null) 'text': body,
      if (voiceId != null) 'voice_id': voiceId,
      if (rate != null) 'rate': rate,
      if (pitch != null) 'pitch': pitch,
      if (filePath != null) 'file_path': filePath,
      if (durationMs != null) 'duration_ms': durationMs,
      if (createdAt != null) 'created_at': createdAt,
      if (lastUsedAt != null) 'last_used_at': lastUsedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnnouncementCacheCompanion copyWith({
    Value<String>? hash,
    Value<String>? body,
    Value<String?>? voiceId,
    Value<double>? rate,
    Value<double>? pitch,
    Value<String>? filePath,
    Value<Duration>? durationMs,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastUsedAt,
    Value<int>? rowid,
  }) {
    return AnnouncementCacheCompanion(
      hash: hash ?? this.hash,
      body: body ?? this.body,
      voiceId: voiceId ?? this.voiceId,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (voiceId.present) {
      map['voice_id'] = Variable<String>(voiceId.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (pitch.present) {
      map['pitch'] = Variable<double>(pitch.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(
        $AnnouncementCacheTable.$converterdurationMs.toSql(durationMs.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $AnnouncementCacheTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (lastUsedAt.present) {
      map['last_used_at'] = Variable<int>(
        $AnnouncementCacheTable.$converterlastUsedAtn.toSql(lastUsedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnnouncementCacheCompanion(')
          ..write('hash: $hash, ')
          ..write('body: $body, ')
          ..write('voiceId: $voiceId, ')
          ..write('rate: $rate, ')
          ..write('pitch: $pitch, ')
          ..write('filePath: $filePath, ')
          ..write('durationMs: $durationMs, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastUsedAt: $lastUsedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlayHistoryTable extends PlayHistory
    with TableInfo<$PlayHistoryTable, PlayHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlayHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _trackIdMeta = const VerificationMeta(
    'trackId',
  );
  @override
  late final GeneratedColumn<String> trackId = GeneratedColumn<String>(
    'track_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tracks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES playlists (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _danceTypeIdMeta = const VerificationMeta(
    'danceTypeId',
  );
  @override
  late final GeneratedColumn<String> danceTypeId = GeneratedColumn<String>(
    'dance_type_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES dance_types (id) ON DELETE SET NULL',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> startedAt =
      GeneratedColumn<int>(
        'started_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PlayHistoryTable.$converterstartedAt);
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<Duration, int> playedMs =
      GeneratedColumn<int>(
        'played_ms',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<Duration>($PlayHistoryTable.$converterplayedMs);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    trackId,
    playlistId,
    danceTypeId,
    startedAt,
    completed,
    playedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlayHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('track_id')) {
      context.handle(
        _trackIdMeta,
        trackId.isAcceptableOrUnknown(data['track_id']!, _trackIdMeta),
      );
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    }
    if (data.containsKey('dance_type_id')) {
      context.handle(
        _danceTypeIdMeta,
        danceTypeId.isAcceptableOrUnknown(
          data['dance_type_id']!,
          _danceTypeIdMeta,
        ),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlayHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlayHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      trackId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}track_id'],
      ),
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      ),
      danceTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dance_type_id'],
      ),
      startedAt: $PlayHistoryTable.$converterstartedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}started_at'],
        )!,
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      playedMs: $PlayHistoryTable.$converterplayedMs.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}played_ms'],
        )!,
      ),
    );
  }

  @override
  $PlayHistoryTable createAlias(String alias) {
    return $PlayHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterstartedAt =
      const MillisConverter();
  static TypeConverter<Duration, int> $converterplayedMs =
      const MillisDurationConverter();
}

class PlayHistoryEntry extends DataClass
    implements Insertable<PlayHistoryEntry> {
  final int id;
  final String? trackId;
  final String? playlistId;
  final String? danceTypeId;
  final DateTime startedAt;
  final bool completed;
  final Duration playedMs;
  const PlayHistoryEntry({
    required this.id,
    this.trackId,
    this.playlistId,
    this.danceTypeId,
    required this.startedAt,
    required this.completed,
    required this.playedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || trackId != null) {
      map['track_id'] = Variable<String>(trackId);
    }
    if (!nullToAbsent || playlistId != null) {
      map['playlist_id'] = Variable<String>(playlistId);
    }
    if (!nullToAbsent || danceTypeId != null) {
      map['dance_type_id'] = Variable<String>(danceTypeId);
    }
    {
      map['started_at'] = Variable<int>(
        $PlayHistoryTable.$converterstartedAt.toSql(startedAt),
      );
    }
    map['completed'] = Variable<bool>(completed);
    {
      map['played_ms'] = Variable<int>(
        $PlayHistoryTable.$converterplayedMs.toSql(playedMs),
      );
    }
    return map;
  }

  PlayHistoryCompanion toCompanion(bool nullToAbsent) {
    return PlayHistoryCompanion(
      id: Value(id),
      trackId: trackId == null && nullToAbsent
          ? const Value.absent()
          : Value(trackId),
      playlistId: playlistId == null && nullToAbsent
          ? const Value.absent()
          : Value(playlistId),
      danceTypeId: danceTypeId == null && nullToAbsent
          ? const Value.absent()
          : Value(danceTypeId),
      startedAt: Value(startedAt),
      completed: Value(completed),
      playedMs: Value(playedMs),
    );
  }

  factory PlayHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlayHistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      trackId: serializer.fromJson<String?>(json['trackId']),
      playlistId: serializer.fromJson<String?>(json['playlistId']),
      danceTypeId: serializer.fromJson<String?>(json['danceTypeId']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completed: serializer.fromJson<bool>(json['completed']),
      playedMs: serializer.fromJson<Duration>(json['playedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'trackId': serializer.toJson<String?>(trackId),
      'playlistId': serializer.toJson<String?>(playlistId),
      'danceTypeId': serializer.toJson<String?>(danceTypeId),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completed': serializer.toJson<bool>(completed),
      'playedMs': serializer.toJson<Duration>(playedMs),
    };
  }

  PlayHistoryEntry copyWith({
    int? id,
    Value<String?> trackId = const Value.absent(),
    Value<String?> playlistId = const Value.absent(),
    Value<String?> danceTypeId = const Value.absent(),
    DateTime? startedAt,
    bool? completed,
    Duration? playedMs,
  }) => PlayHistoryEntry(
    id: id ?? this.id,
    trackId: trackId.present ? trackId.value : this.trackId,
    playlistId: playlistId.present ? playlistId.value : this.playlistId,
    danceTypeId: danceTypeId.present ? danceTypeId.value : this.danceTypeId,
    startedAt: startedAt ?? this.startedAt,
    completed: completed ?? this.completed,
    playedMs: playedMs ?? this.playedMs,
  );
  PlayHistoryEntry copyWithCompanion(PlayHistoryCompanion data) {
    return PlayHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      trackId: data.trackId.present ? data.trackId.value : this.trackId,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      danceTypeId: data.danceTypeId.present
          ? data.danceTypeId.value
          : this.danceTypeId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completed: data.completed.present ? data.completed.value : this.completed,
      playedMs: data.playedMs.present ? data.playedMs.value : this.playedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryEntry(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playlistId: $playlistId, ')
          ..write('danceTypeId: $danceTypeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completed: $completed, ')
          ..write('playedMs: $playedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    trackId,
    playlistId,
    danceTypeId,
    startedAt,
    completed,
    playedMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlayHistoryEntry &&
          other.id == this.id &&
          other.trackId == this.trackId &&
          other.playlistId == this.playlistId &&
          other.danceTypeId == this.danceTypeId &&
          other.startedAt == this.startedAt &&
          other.completed == this.completed &&
          other.playedMs == this.playedMs);
}

class PlayHistoryCompanion extends UpdateCompanion<PlayHistoryEntry> {
  final Value<int> id;
  final Value<String?> trackId;
  final Value<String?> playlistId;
  final Value<String?> danceTypeId;
  final Value<DateTime> startedAt;
  final Value<bool> completed;
  final Value<Duration> playedMs;
  const PlayHistoryCompanion({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.danceTypeId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completed = const Value.absent(),
    this.playedMs = const Value.absent(),
  });
  PlayHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.trackId = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.danceTypeId = const Value.absent(),
    required DateTime startedAt,
    this.completed = const Value.absent(),
    this.playedMs = const Value.absent(),
  }) : startedAt = Value(startedAt);
  static Insertable<PlayHistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? trackId,
    Expression<String>? playlistId,
    Expression<String>? danceTypeId,
    Expression<int>? startedAt,
    Expression<bool>? completed,
    Expression<int>? playedMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (trackId != null) 'track_id': trackId,
      if (playlistId != null) 'playlist_id': playlistId,
      if (danceTypeId != null) 'dance_type_id': danceTypeId,
      if (startedAt != null) 'started_at': startedAt,
      if (completed != null) 'completed': completed,
      if (playedMs != null) 'played_ms': playedMs,
    });
  }

  PlayHistoryCompanion copyWith({
    Value<int>? id,
    Value<String?>? trackId,
    Value<String?>? playlistId,
    Value<String?>? danceTypeId,
    Value<DateTime>? startedAt,
    Value<bool>? completed,
    Value<Duration>? playedMs,
  }) {
    return PlayHistoryCompanion(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      playlistId: playlistId ?? this.playlistId,
      danceTypeId: danceTypeId ?? this.danceTypeId,
      startedAt: startedAt ?? this.startedAt,
      completed: completed ?? this.completed,
      playedMs: playedMs ?? this.playedMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (trackId.present) {
      map['track_id'] = Variable<String>(trackId.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (danceTypeId.present) {
      map['dance_type_id'] = Variable<String>(danceTypeId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(
        $PlayHistoryTable.$converterstartedAt.toSql(startedAt.value),
      );
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (playedMs.present) {
      map['played_ms'] = Variable<int>(
        $PlayHistoryTable.$converterplayedMs.toSql(playedMs.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlayHistoryCompanion(')
          ..write('id: $id, ')
          ..write('trackId: $trackId, ')
          ..write('playlistId: $playlistId, ')
          ..write('danceTypeId: $danceTypeId, ')
          ..write('startedAt: $startedAt, ')
          ..write('completed: $completed, ')
          ..write('playedMs: $playedMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$SayawDatabase extends GeneratedDatabase {
  _$SayawDatabase(QueryExecutor e) : super(e);
  $SayawDatabaseManager get managers => $SayawDatabaseManager(this);
  late final $SourceAccountsTable sourceAccounts = $SourceAccountsTable(this);
  late final $DanceTypesTable danceTypes = $DanceTypesTable(this);
  late final $TracksTable tracks = $TracksTable(this);
  late final $PlaylistsTable playlists = $PlaylistsTable(this);
  late final $PlaylistItemsTable playlistItems = $PlaylistItemsTable(this);
  late final $CacheEntriesTable cacheEntries = $CacheEntriesTable(this);
  late final $AnnouncementCacheTable announcementCache =
      $AnnouncementCacheTable(this);
  late final $PlayHistoryTable playHistory = $PlayHistoryTable(this);
  late final TrackDao trackDao = TrackDao(this as SayawDatabase);
  late final PlaylistDao playlistDao = PlaylistDao(this as SayawDatabase);
  late final AnnouncementDao announcementDao = AnnouncementDao(
    this as SayawDatabase,
  );
  late final SourceAccountDao sourceAccountDao = SourceAccountDao(
    this as SayawDatabase,
  );
  late final CacheDao cacheDao = CacheDao(this as SayawDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sourceAccounts,
    danceTypes,
    tracks,
    playlists,
    playlistItems,
    cacheEntries,
    announcementCache,
    playHistory,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'source_accounts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dance_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tracks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dance_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_items', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cache_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tracks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_history', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_history', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'dance_types',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('play_history', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $$SourceAccountsTableCreateCompanionBuilder =
    SourceAccountsCompanion Function({
      required String id,
      required SourceProvider provider,
      required String displayName,
      Value<String?> machineIdentifier,
      Value<String?> baseUri,
      Value<String?> countryCode,
      required String keychainRef,
      Value<bool> offlineEntitled,
      Value<DateTime?> lastVerifiedAt,
      required DateTime createdAt,
      Value<bool> isOwned,
      Value<int> rowid,
    });
typedef $$SourceAccountsTableUpdateCompanionBuilder =
    SourceAccountsCompanion Function({
      Value<String> id,
      Value<SourceProvider> provider,
      Value<String> displayName,
      Value<String?> machineIdentifier,
      Value<String?> baseUri,
      Value<String?> countryCode,
      Value<String> keychainRef,
      Value<bool> offlineEntitled,
      Value<DateTime?> lastVerifiedAt,
      Value<DateTime> createdAt,
      Value<bool> isOwned,
      Value<int> rowid,
    });

final class $$SourceAccountsTableReferences
    extends
        BaseReferences<_$SayawDatabase, $SourceAccountsTable, SourceAccount> {
  $$SourceAccountsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$SayawDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: 'source_accounts__id__tracks__account_id',
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SourceAccountsTableFilterComposer
    extends Composer<_$SayawDatabase, $SourceAccountsTable> {
  $$SourceAccountsTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SourceProvider, SourceProvider, String>
  get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get machineIdentifier => $composableBuilder(
    column: $table.machineIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get baseUri => $composableBuilder(
    column: $table.baseUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get offlineEntitled => $composableBuilder(
    column: $table.offlineEntitled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isOwned => $composableBuilder(
    column: $table.isOwned,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceAccountsTableOrderingComposer
    extends Composer<_$SayawDatabase, $SourceAccountsTable> {
  $$SourceAccountsTableOrderingComposer({
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

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get machineIdentifier => $composableBuilder(
    column: $table.machineIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get baseUri => $composableBuilder(
    column: $table.baseUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get offlineEntitled => $composableBuilder(
    column: $table.offlineEntitled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOwned => $composableBuilder(
    column: $table.isOwned,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceAccountsTableAnnotationComposer
    extends Composer<_$SayawDatabase, $SourceAccountsTable> {
  $$SourceAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceProvider, String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get machineIdentifier => $composableBuilder(
    column: $table.machineIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<String> get baseUri =>
      $composableBuilder(column: $table.baseUri, builder: (column) => column);

  GeneratedColumn<String> get countryCode => $composableBuilder(
    column: $table.countryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get keychainRef => $composableBuilder(
    column: $table.keychainRef,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get offlineEntitled => $composableBuilder(
    column: $table.offlineEntitled,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isOwned =>
      $composableBuilder(column: $table.isOwned, builder: (column) => column);

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SourceAccountsTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $SourceAccountsTable,
          SourceAccount,
          $$SourceAccountsTableFilterComposer,
          $$SourceAccountsTableOrderingComposer,
          $$SourceAccountsTableAnnotationComposer,
          $$SourceAccountsTableCreateCompanionBuilder,
          $$SourceAccountsTableUpdateCompanionBuilder,
          (SourceAccount, $$SourceAccountsTableReferences),
          SourceAccount,
          PrefetchHooks Function({bool tracksRefs})
        > {
  $$SourceAccountsTableTableManager(
    _$SayawDatabase db,
    $SourceAccountsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SourceProvider> provider = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String?> machineIdentifier = const Value.absent(),
                Value<String?> baseUri = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                Value<String> keychainRef = const Value.absent(),
                Value<bool> offlineEntitled = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isOwned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceAccountsCompanion(
                id: id,
                provider: provider,
                displayName: displayName,
                machineIdentifier: machineIdentifier,
                baseUri: baseUri,
                countryCode: countryCode,
                keychainRef: keychainRef,
                offlineEntitled: offlineEntitled,
                lastVerifiedAt: lastVerifiedAt,
                createdAt: createdAt,
                isOwned: isOwned,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required SourceProvider provider,
                required String displayName,
                Value<String?> machineIdentifier = const Value.absent(),
                Value<String?> baseUri = const Value.absent(),
                Value<String?> countryCode = const Value.absent(),
                required String keychainRef,
                Value<bool> offlineEntitled = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isOwned = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceAccountsCompanion.insert(
                id: id,
                provider: provider,
                displayName: displayName,
                machineIdentifier: machineIdentifier,
                baseUri: baseUri,
                countryCode: countryCode,
                keychainRef: keychainRef,
                offlineEntitled: offlineEntitled,
                lastVerifiedAt: lastVerifiedAt,
                createdAt: createdAt,
                isOwned: isOwned,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SourceAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tracksRefs) db.tracks],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tracksRefs)
                    await $_getPrefetchedData<
                      SourceAccount,
                      $SourceAccountsTable,
                      Track
                    >(
                      currentTable: table,
                      referencedTable: $$SourceAccountsTableReferences
                          ._tracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SourceAccountsTableReferences(
                            db,
                            table,
                            p0,
                          ).tracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SourceAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $SourceAccountsTable,
      SourceAccount,
      $$SourceAccountsTableFilterComposer,
      $$SourceAccountsTableOrderingComposer,
      $$SourceAccountsTableAnnotationComposer,
      $$SourceAccountsTableCreateCompanionBuilder,
      $$SourceAccountsTableUpdateCompanionBuilder,
      (SourceAccount, $$SourceAccountsTableReferences),
      SourceAccount,
      PrefetchHooks Function({bool tracksRefs})
    >;
typedef $$DanceTypesTableCreateCompanionBuilder = DanceTypesCompanion Function({
  required String id,
  required String name,
  required String slug,
  Value<String> ttsTemplate,
  Value<String?> customClipPath,
  Value<double?> bpmMin,
  Value<double?> bpmMax,
  Value<String?> timeSignature,
  Value<String?> colorHex,
  Value<int> sortIndex,
  Value<int> rowid,
});
typedef $$DanceTypesTableUpdateCompanionBuilder = DanceTypesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> slug,
  Value<String> ttsTemplate,
  Value<String?> customClipPath,
  Value<double?> bpmMin,
  Value<double?> bpmMax,
  Value<String?> timeSignature,
  Value<String?> colorHex,
  Value<int> sortIndex,
  Value<int> rowid,
});

final class $$DanceTypesTableReferences
    extends BaseReferences<_$SayawDatabase, $DanceTypesTable, DanceType> {
  $$DanceTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TracksTable, List<Track>> _tracksRefsTable(
    _$SayawDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tracks,
    aliasName: 'dance_types__id__tracks__default_dance_type_id',
  );

  $$TracksTableProcessedTableManager get tracksRefs {
    final manager = $$TracksTableTableManager($_db, $_db.tracks).filter(
      (f) => f.defaultDanceTypeId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistItem>>
  _playlistItemsRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistItems,
    aliasName: 'dance_types__id__playlist_items__dance_type_id',
  );

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.danceTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayHistoryTable, List<PlayHistoryEntry>>
  _playHistoryRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playHistory,
    aliasName: 'dance_types__id__play_history__dance_type_id',
  );

  $$PlayHistoryTableProcessedTableManager get playHistoryRefs {
    final manager = $$PlayHistoryTableTableManager(
      $_db,
      $_db.playHistory,
    ).filter((f) => f.danceTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DanceTypesTableFilterComposer
    extends Composer<_$SayawDatabase, $DanceTypesTable> {
  $$DanceTypesTableFilterComposer({
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

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ttsTemplate => $composableBuilder(
    column: $table.ttsTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customClipPath => $composableBuilder(
    column: $table.customClipPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bpmMin => $composableBuilder(
    column: $table.bpmMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bpmMax => $composableBuilder(
    column: $table.bpmMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeSignature => $composableBuilder(
    column: $table.timeSignature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> tracksRefs(
    Expression<bool> Function($$TracksTableFilterComposer f) f,
  ) {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.defaultDanceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playlistItemsRefs(
    Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.danceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playHistoryRefs(
    Expression<bool> Function($$PlayHistoryTableFilterComposer f) f,
  ) {
    final $$PlayHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.danceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DanceTypesTableOrderingComposer
    extends Composer<_$SayawDatabase, $DanceTypesTable> {
  $$DanceTypesTableOrderingComposer({
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

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsTemplate => $composableBuilder(
    column: $table.ttsTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customClipPath => $composableBuilder(
    column: $table.customClipPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bpmMin => $composableBuilder(
    column: $table.bpmMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bpmMax => $composableBuilder(
    column: $table.bpmMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeSignature => $composableBuilder(
    column: $table.timeSignature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortIndex => $composableBuilder(
    column: $table.sortIndex,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DanceTypesTableAnnotationComposer
    extends Composer<_$SayawDatabase, $DanceTypesTable> {
  $$DanceTypesTableAnnotationComposer({
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

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get ttsTemplate => $composableBuilder(
    column: $table.ttsTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customClipPath => $composableBuilder(
    column: $table.customClipPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bpmMin =>
      $composableBuilder(column: $table.bpmMin, builder: (column) => column);

  GeneratedColumn<double> get bpmMax =>
      $composableBuilder(column: $table.bpmMax, builder: (column) => column);

  GeneratedColumn<String> get timeSignature => $composableBuilder(
    column: $table.timeSignature,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get sortIndex =>
      $composableBuilder(column: $table.sortIndex, builder: (column) => column);

  Expression<T> tracksRefs<T extends Object>(
    Expression<T> Function($$TracksTableAnnotationComposer a) f,
  ) {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.defaultDanceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.danceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playHistoryRefs<T extends Object>(
    Expression<T> Function($$PlayHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlayHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.danceTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DanceTypesTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $DanceTypesTable,
          DanceType,
          $$DanceTypesTableFilterComposer,
          $$DanceTypesTableOrderingComposer,
          $$DanceTypesTableAnnotationComposer,
          $$DanceTypesTableCreateCompanionBuilder,
          $$DanceTypesTableUpdateCompanionBuilder,
          (DanceType, $$DanceTypesTableReferences),
          DanceType,
          PrefetchHooks Function({
            bool tracksRefs,
            bool playlistItemsRefs,
            bool playHistoryRefs,
          })
        > {
  $$DanceTypesTableTableManager(_$SayawDatabase db, $DanceTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DanceTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DanceTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DanceTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> ttsTemplate = const Value.absent(),
                Value<String?> customClipPath = const Value.absent(),
                Value<double?> bpmMin = const Value.absent(),
                Value<double?> bpmMax = const Value.absent(),
                Value<String?> timeSignature = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DanceTypesCompanion(
                id: id,
                name: name,
                slug: slug,
                ttsTemplate: ttsTemplate,
                customClipPath: customClipPath,
                bpmMin: bpmMin,
                bpmMax: bpmMax,
                timeSignature: timeSignature,
                colorHex: colorHex,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String slug,
                Value<String> ttsTemplate = const Value.absent(),
                Value<String?> customClipPath = const Value.absent(),
                Value<double?> bpmMin = const Value.absent(),
                Value<double?> bpmMax = const Value.absent(),
                Value<String?> timeSignature = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<int> sortIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DanceTypesCompanion.insert(
                id: id,
                name: name,
                slug: slug,
                ttsTemplate: ttsTemplate,
                customClipPath: customClipPath,
                bpmMin: bpmMin,
                bpmMax: bpmMax,
                timeSignature: timeSignature,
                colorHex: colorHex,
                sortIndex: sortIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DanceTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                tracksRefs = false,
                playlistItemsRefs = false,
                playHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (tracksRefs) db.tracks,
                    if (playlistItemsRefs) db.playlistItems,
                    if (playHistoryRefs) db.playHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (tracksRefs)
                        await $_getPrefetchedData<
                          DanceType,
                          $DanceTypesTable,
                          Track
                        >(
                          currentTable: table,
                          referencedTable: $$DanceTypesTableReferences
                              ._tracksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DanceTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).tracksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.defaultDanceTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playlistItemsRefs)
                        await $_getPrefetchedData<
                          DanceType,
                          $DanceTypesTable,
                          PlaylistItem
                        >(
                          currentTable: table,
                          referencedTable: $$DanceTypesTableReferences
                              ._playlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DanceTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.danceTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playHistoryRefs)
                        await $_getPrefetchedData<
                          DanceType,
                          $DanceTypesTable,
                          PlayHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$DanceTypesTableReferences
                              ._playHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DanceTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).playHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.danceTypeId == item.id,
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

typedef $$DanceTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $DanceTypesTable,
      DanceType,
      $$DanceTypesTableFilterComposer,
      $$DanceTypesTableOrderingComposer,
      $$DanceTypesTableAnnotationComposer,
      $$DanceTypesTableCreateCompanionBuilder,
      $$DanceTypesTableUpdateCompanionBuilder,
      (DanceType, $$DanceTypesTableReferences),
      DanceType,
      PrefetchHooks Function({
        bool tracksRefs,
        bool playlistItemsRefs,
        bool playHistoryRefs,
      })
    >;
typedef $$TracksTableCreateCompanionBuilder = TracksCompanion Function({
  required String id,
  required SourceType sourceType,
  Value<String?> accountId,
  Value<String?> localPath,
  Value<String?> contentUri,
  Value<Uint8List?> securityBookmark,
  Value<String?> sourceId,
  Value<String?> sourcePartId,
  Value<int?> sourceUpdatedAt,
  required String title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> year,
  Value<Duration> durationMs,
  Value<double?> bpm,
  Value<String?> musicalKey,
  Value<String?> codec,
  Value<int?> bitrateKbps,
  Value<int?> sampleRateHz,
  Value<String?> artworkUrl,
  Value<String?> artworkCachePath,
  Value<double> gainDb,
  Value<Duration> cueInMs,
  Value<Duration?> cueOutMs,
  Value<bool> isDrm,
  Value<CachePolicy> cachePolicy,
  Value<String?> defaultDanceTypeId,
  required DateTime addedAt,
  required DateTime updatedAt,
  Value<DateTime?> lastVerifiedAt,
  Value<int> rowid,
});
typedef $$TracksTableUpdateCompanionBuilder = TracksCompanion Function({
  Value<String> id,
  Value<SourceType> sourceType,
  Value<String?> accountId,
  Value<String?> localPath,
  Value<String?> contentUri,
  Value<Uint8List?> securityBookmark,
  Value<String?> sourceId,
  Value<String?> sourcePartId,
  Value<int?> sourceUpdatedAt,
  Value<String> title,
  Value<String?> artist,
  Value<String?> album,
  Value<String?> albumArtist,
  Value<int?> year,
  Value<Duration> durationMs,
  Value<double?> bpm,
  Value<String?> musicalKey,
  Value<String?> codec,
  Value<int?> bitrateKbps,
  Value<int?> sampleRateHz,
  Value<String?> artworkUrl,
  Value<String?> artworkCachePath,
  Value<double> gainDb,
  Value<Duration> cueInMs,
  Value<Duration?> cueOutMs,
  Value<bool> isDrm,
  Value<CachePolicy> cachePolicy,
  Value<String?> defaultDanceTypeId,
  Value<DateTime> addedAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> lastVerifiedAt,
  Value<int> rowid,
});

final class $$TracksTableReferences
    extends BaseReferences<_$SayawDatabase, $TracksTable, Track> {
  $$TracksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SourceAccountsTable _accountIdTable(_$SayawDatabase db) =>
      db.sourceAccounts.createAlias('tracks__account_id__source_accounts__id');

  $$SourceAccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$SourceAccountsTableTableManager(
      $_db,
      $_db.sourceAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DanceTypesTable _defaultDanceTypeIdTable(_$SayawDatabase db) => db
      .danceTypes
      .createAlias('tracks__default_dance_type_id__dance_types__id');

  $$DanceTypesTableProcessedTableManager? get defaultDanceTypeId {
    final $_column = $_itemColumn<String>('default_dance_type_id');
    if ($_column == null) return null;
    final manager = $$DanceTypesTableTableManager(
      $_db,
      $_db.danceTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultDanceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistItem>>
  _playlistItemsRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistItems,
    aliasName: 'tracks__id__playlist_items__track_id',
  );

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CacheEntriesTable, List<CacheEntry>>
  _cacheEntriesRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.cacheEntries,
    aliasName: 'tracks__id__cache_entries__track_id',
  );

  $$CacheEntriesTableProcessedTableManager get cacheEntriesRefs {
    final manager = $$CacheEntriesTableTableManager(
      $_db,
      $_db.cacheEntries,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cacheEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayHistoryTable, List<PlayHistoryEntry>>
  _playHistoryRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playHistory,
    aliasName: 'tracks__id__play_history__track_id',
  );

  $$PlayHistoryTableProcessedTableManager get playHistoryRefs {
    final manager = $$PlayHistoryTableTableManager(
      $_db,
      $_db.playHistory,
    ).filter((f) => f.trackId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TracksTableFilterComposer
    extends Composer<_$SayawDatabase, $TracksTable> {
  $$TracksTableFilterComposer({
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

  ColumnWithTypeConverterFilters<SourceType, SourceType, String>
  get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get securityBookmark => $composableBuilder(
    column: $table.securityBookmark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePartId => $composableBuilder(
    column: $table.sourcePartId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
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

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get durationMs =>
      $composableBuilder(
        column: $table.durationMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get musicalKey => $composableBuilder(
    column: $table.musicalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get artworkCachePath => $composableBuilder(
    column: $table.artworkCachePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gainDb => $composableBuilder(
    column: $table.gainDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get cueInMs =>
      $composableBuilder(
        column: $table.cueInMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration?, Duration, int> get cueOutMs =>
      $composableBuilder(
        column: $table.cueOutMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isDrm => $composableBuilder(
    column: $table.isDrm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CachePolicy, CachePolicy, String>
  get cachePolicy => $composableBuilder(
    column: $table.cachePolicy,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get addedAt =>
      $composableBuilder(
        column: $table.addedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SourceAccountsTableFilterComposer get accountId {
    final $$SourceAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.sourceAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceAccountsTableFilterComposer(
            $db: $db,
            $table: $db.sourceAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableFilterComposer get defaultDanceTypeId {
    final $$DanceTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDanceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableFilterComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> playlistItemsRefs(
    Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cacheEntriesRefs(
    Expression<bool> Function($$CacheEntriesTableFilterComposer f) f,
  ) {
    final $$CacheEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cacheEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CacheEntriesTableFilterComposer(
            $db: $db,
            $table: $db.cacheEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playHistoryRefs(
    Expression<bool> Function($$PlayHistoryTableFilterComposer f) f,
  ) {
    final $$PlayHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableOrderingComposer
    extends Composer<_$SayawDatabase, $TracksTable> {
  $$TracksTableOrderingComposer({
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

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get securityBookmark => $composableBuilder(
    column: $table.securityBookmark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePartId => $composableBuilder(
    column: $table.sourcePartId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
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

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bpm => $composableBuilder(
    column: $table.bpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get musicalKey => $composableBuilder(
    column: $table.musicalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codec => $composableBuilder(
    column: $table.codec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get artworkCachePath => $composableBuilder(
    column: $table.artworkCachePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gainDb => $composableBuilder(
    column: $table.gainDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cueInMs => $composableBuilder(
    column: $table.cueInMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cueOutMs => $composableBuilder(
    column: $table.cueOutMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDrm => $composableBuilder(
    column: $table.isDrm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachePolicy => $composableBuilder(
    column: $table.cachePolicy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastVerifiedAt => $composableBuilder(
    column: $table.lastVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SourceAccountsTableOrderingComposer get accountId {
    final $$SourceAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.sourceAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.sourceAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableOrderingComposer get defaultDanceTypeId {
    final $$DanceTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDanceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableOrderingComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TracksTableAnnotationComposer
    extends Composer<_$SayawDatabase, $TracksTable> {
  $$TracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SourceType, String> get sourceType =>
      $composableBuilder(
        column: $table.sourceType,
        builder: (column) => column,
      );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get contentUri => $composableBuilder(
    column: $table.contentUri,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get securityBookmark => $composableBuilder(
    column: $table.securityBookmark,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get sourcePartId => $composableBuilder(
    column: $table.sourcePartId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceUpdatedAt => $composableBuilder(
    column: $table.sourceUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get artist =>
      $composableBuilder(column: $table.artist, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get albumArtist => $composableBuilder(
    column: $table.albumArtist,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get durationMs =>
      $composableBuilder(
        column: $table.durationMs,
        builder: (column) => column,
      );

  GeneratedColumn<double> get bpm =>
      $composableBuilder(column: $table.bpm, builder: (column) => column);

  GeneratedColumn<String> get musicalKey => $composableBuilder(
    column: $table.musicalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codec =>
      $composableBuilder(column: $table.codec, builder: (column) => column);

  GeneratedColumn<int> get bitrateKbps => $composableBuilder(
    column: $table.bitrateKbps,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleRateHz => $composableBuilder(
    column: $table.sampleRateHz,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkUrl => $composableBuilder(
    column: $table.artworkUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get artworkCachePath => $composableBuilder(
    column: $table.artworkCachePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get gainDb =>
      $composableBuilder(column: $table.gainDb, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get cueInMs =>
      $composableBuilder(column: $table.cueInMs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration?, int> get cueOutMs =>
      $composableBuilder(column: $table.cueOutMs, builder: (column) => column);

  GeneratedColumn<bool> get isDrm =>
      $composableBuilder(column: $table.isDrm, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CachePolicy, String> get cachePolicy =>
      $composableBuilder(
        column: $table.cachePolicy,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastVerifiedAt =>
      $composableBuilder(
        column: $table.lastVerifiedAt,
        builder: (column) => column,
      );

  $$SourceAccountsTableAnnotationComposer get accountId {
    final $$SourceAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.sourceAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SourceAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.sourceAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableAnnotationComposer get defaultDanceTypeId {
    final $$DanceTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDanceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cacheEntriesRefs<T extends Object>(
    Expression<T> Function($$CacheEntriesTableAnnotationComposer a) f,
  ) {
    final $$CacheEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cacheEntries,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CacheEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.cacheEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playHistoryRefs<T extends Object>(
    Expression<T> Function($$PlayHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlayHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.trackId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TracksTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $TracksTable,
          Track,
          $$TracksTableFilterComposer,
          $$TracksTableOrderingComposer,
          $$TracksTableAnnotationComposer,
          $$TracksTableCreateCompanionBuilder,
          $$TracksTableUpdateCompanionBuilder,
          (Track, $$TracksTableReferences),
          Track,
          PrefetchHooks Function({
            bool accountId,
            bool defaultDanceTypeId,
            bool playlistItemsRefs,
            bool cacheEntriesRefs,
            bool playHistoryRefs,
          })
        > {
  $$TracksTableTableManager(_$SayawDatabase db, $TracksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<SourceType> sourceType = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<Uint8List?> securityBookmark = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourcePartId = const Value.absent(),
                Value<int?> sourceUpdatedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<Duration> durationMs = const Value.absent(),
                Value<double?> bpm = const Value.absent(),
                Value<String?> musicalKey = const Value.absent(),
                Value<String?> codec = const Value.absent(),
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> sampleRateHz = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> artworkCachePath = const Value.absent(),
                Value<double> gainDb = const Value.absent(),
                Value<Duration> cueInMs = const Value.absent(),
                Value<Duration?> cueOutMs = const Value.absent(),
                Value<bool> isDrm = const Value.absent(),
                Value<CachePolicy> cachePolicy = const Value.absent(),
                Value<String?> defaultDanceTypeId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion(
                id: id,
                sourceType: sourceType,
                accountId: accountId,
                localPath: localPath,
                contentUri: contentUri,
                securityBookmark: securityBookmark,
                sourceId: sourceId,
                sourcePartId: sourcePartId,
                sourceUpdatedAt: sourceUpdatedAt,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                year: year,
                durationMs: durationMs,
                bpm: bpm,
                musicalKey: musicalKey,
                codec: codec,
                bitrateKbps: bitrateKbps,
                sampleRateHz: sampleRateHz,
                artworkUrl: artworkUrl,
                artworkCachePath: artworkCachePath,
                gainDb: gainDb,
                cueInMs: cueInMs,
                cueOutMs: cueOutMs,
                isDrm: isDrm,
                cachePolicy: cachePolicy,
                defaultDanceTypeId: defaultDanceTypeId,
                addedAt: addedAt,
                updatedAt: updatedAt,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required SourceType sourceType,
                Value<String?> accountId = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> contentUri = const Value.absent(),
                Value<Uint8List?> securityBookmark = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<String?> sourcePartId = const Value.absent(),
                Value<int?> sourceUpdatedAt = const Value.absent(),
                required String title,
                Value<String?> artist = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> albumArtist = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<Duration> durationMs = const Value.absent(),
                Value<double?> bpm = const Value.absent(),
                Value<String?> musicalKey = const Value.absent(),
                Value<String?> codec = const Value.absent(),
                Value<int?> bitrateKbps = const Value.absent(),
                Value<int?> sampleRateHz = const Value.absent(),
                Value<String?> artworkUrl = const Value.absent(),
                Value<String?> artworkCachePath = const Value.absent(),
                Value<double> gainDb = const Value.absent(),
                Value<Duration> cueInMs = const Value.absent(),
                Value<Duration?> cueOutMs = const Value.absent(),
                Value<bool> isDrm = const Value.absent(),
                Value<CachePolicy> cachePolicy = const Value.absent(),
                Value<String?> defaultDanceTypeId = const Value.absent(),
                required DateTime addedAt,
                required DateTime updatedAt,
                Value<DateTime?> lastVerifiedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TracksCompanion.insert(
                id: id,
                sourceType: sourceType,
                accountId: accountId,
                localPath: localPath,
                contentUri: contentUri,
                securityBookmark: securityBookmark,
                sourceId: sourceId,
                sourcePartId: sourcePartId,
                sourceUpdatedAt: sourceUpdatedAt,
                title: title,
                artist: artist,
                album: album,
                albumArtist: albumArtist,
                year: year,
                durationMs: durationMs,
                bpm: bpm,
                musicalKey: musicalKey,
                codec: codec,
                bitrateKbps: bitrateKbps,
                sampleRateHz: sampleRateHz,
                artworkUrl: artworkUrl,
                artworkCachePath: artworkCachePath,
                gainDb: gainDb,
                cueInMs: cueInMs,
                cueOutMs: cueOutMs,
                isDrm: isDrm,
                cachePolicy: cachePolicy,
                defaultDanceTypeId: defaultDanceTypeId,
                addedAt: addedAt,
                updatedAt: updatedAt,
                lastVerifiedAt: lastVerifiedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TracksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountId = false,
                defaultDanceTypeId = false,
                playlistItemsRefs = false,
                cacheEntriesRefs = false,
                playHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistItemsRefs) db.playlistItems,
                    if (cacheEntriesRefs) db.cacheEntries,
                    if (playHistoryRefs) db.playHistory,
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
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$TracksTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$TracksTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (defaultDanceTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.defaultDanceTypeId,
                            referencedTable: $$TracksTableReferences
                                ._defaultDanceTypeIdTable(db),
                            referencedColumn: $$TracksTableReferences
                                ._defaultDanceTypeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistItemsRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlaylistItem
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cacheEntriesRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          CacheEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._cacheEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).cacheEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playHistoryRefs)
                        await $_getPrefetchedData<
                          Track,
                          $TracksTable,
                          PlayHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$TracksTableReferences
                              ._playHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TracksTableReferences(
                                db,
                                table,
                                p0,
                              ).playHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trackId == item.id,
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

typedef $$TracksTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $TracksTable,
      Track,
      $$TracksTableFilterComposer,
      $$TracksTableOrderingComposer,
      $$TracksTableAnnotationComposer,
      $$TracksTableCreateCompanionBuilder,
      $$TracksTableUpdateCompanionBuilder,
      (Track, $$TracksTableReferences),
      Track,
      PrefetchHooks Function({
        bool accountId,
        bool defaultDanceTypeId,
        bool playlistItemsRefs,
        bool cacheEntriesRefs,
        bool playHistoryRefs,
      })
    >;
typedef $$PlaylistsTableCreateCompanionBuilder = PlaylistsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String?> eventKind,
  Value<DateTime?> eventDate,
  Value<Duration> crossfadeMs,
  Value<FadeCurve> fadeInCurve,
  Value<FadeCurve> fadeOutCurve,
  Value<AnnounceMode> announceMode,
  Value<double> duckLevel,
  Value<Duration> duckFadeMs,
  Value<Duration> duckHoldMs,
  Value<Duration> duckRestoreFadeMs,
  Value<String?> ttsVoiceId,
  Value<double> ttsRate,
  Value<double> ttsPitch,
  Value<bool> isArchived,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int?> songLimit,
  Value<Duration?> targetDurationMs,
  Value<Duration> rotationGapMs,
  Value<int> snowballStages,
  Value<int> rowid,
});
typedef $$PlaylistsTableUpdateCompanionBuilder = PlaylistsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> eventKind,
  Value<DateTime?> eventDate,
  Value<Duration> crossfadeMs,
  Value<FadeCurve> fadeInCurve,
  Value<FadeCurve> fadeOutCurve,
  Value<AnnounceMode> announceMode,
  Value<double> duckLevel,
  Value<Duration> duckFadeMs,
  Value<Duration> duckHoldMs,
  Value<Duration> duckRestoreFadeMs,
  Value<String?> ttsVoiceId,
  Value<double> ttsRate,
  Value<double> ttsPitch,
  Value<bool> isArchived,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int?> songLimit,
  Value<Duration?> targetDurationMs,
  Value<Duration> rotationGapMs,
  Value<int> snowballStages,
  Value<int> rowid,
});

final class $$PlaylistsTableReferences
    extends BaseReferences<_$SayawDatabase, $PlaylistsTable, Playlist> {
  $$PlaylistsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PlaylistItemsTable, List<PlaylistItem>>
  _playlistItemsRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playlistItems,
    aliasName: 'playlists__id__playlist_items__playlist_id',
  );

  $$PlaylistItemsTableProcessedTableManager get playlistItemsRefs {
    final manager = $$PlaylistItemsTableTableManager(
      $_db,
      $_db.playlistItems,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PlayHistoryTable, List<PlayHistoryEntry>>
  _playHistoryRefsTable(_$SayawDatabase db) => MultiTypedResultKey.fromTable(
    db.playHistory,
    aliasName: 'playlists__id__play_history__playlist_id',
  );

  $$PlayHistoryTableProcessedTableManager get playHistoryRefs {
    final manager = $$PlayHistoryTableTableManager(
      $_db,
      $_db.playHistory,
    ).filter((f) => f.playlistId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_playHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PlaylistsTableFilterComposer
    extends Composer<_$SayawDatabase, $PlaylistsTable> {
  $$PlaylistsTableFilterComposer({
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

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventKind => $composableBuilder(
    column: $table.eventKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get eventDate =>
      $composableBuilder(
        column: $table.eventDate,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get crossfadeMs =>
      $composableBuilder(
        column: $table.crossfadeMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<FadeCurve, FadeCurve, String>
  get fadeInCurve => $composableBuilder(
    column: $table.fadeInCurve,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<FadeCurve, FadeCurve, String>
  get fadeOutCurve => $composableBuilder(
    column: $table.fadeOutCurve,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<AnnounceMode, AnnounceMode, String>
  get announceMode => $composableBuilder(
    column: $table.announceMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get duckLevel => $composableBuilder(
    column: $table.duckLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get duckFadeMs =>
      $composableBuilder(
        column: $table.duckFadeMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get duckHoldMs =>
      $composableBuilder(
        column: $table.duckHoldMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration, Duration, int>
  get duckRestoreFadeMs => $composableBuilder(
    column: $table.duckRestoreFadeMs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get ttsVoiceId => $composableBuilder(
    column: $table.ttsVoiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ttsRate => $composableBuilder(
    column: $table.ttsRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ttsPitch => $composableBuilder(
    column: $table.ttsPitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get songLimit => $composableBuilder(
    column: $table.songLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration?, Duration, int>
  get targetDurationMs => $composableBuilder(
    column: $table.targetDurationMs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get rotationGapMs =>
      $composableBuilder(
        column: $table.rotationGapMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get snowballStages => $composableBuilder(
    column: $table.snowballStages,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistItemsRefs(
    Expression<bool> Function($$PlaylistItemsTableFilterComposer f) f,
  ) {
    final $$PlaylistItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableFilterComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> playHistoryRefs(
    Expression<bool> Function($$PlayHistoryTableFilterComposer f) f,
  ) {
    final $$PlayHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableFilterComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableOrderingComposer
    extends Composer<_$SayawDatabase, $PlaylistsTable> {
  $$PlaylistsTableOrderingComposer({
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

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventKind => $composableBuilder(
    column: $table.eventKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get crossfadeMs => $composableBuilder(
    column: $table.crossfadeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fadeInCurve => $composableBuilder(
    column: $table.fadeInCurve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fadeOutCurve => $composableBuilder(
    column: $table.fadeOutCurve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get announceMode => $composableBuilder(
    column: $table.announceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duckLevel => $composableBuilder(
    column: $table.duckLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duckFadeMs => $composableBuilder(
    column: $table.duckFadeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duckHoldMs => $composableBuilder(
    column: $table.duckHoldMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get duckRestoreFadeMs => $composableBuilder(
    column: $table.duckRestoreFadeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ttsVoiceId => $composableBuilder(
    column: $table.ttsVoiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ttsRate => $composableBuilder(
    column: $table.ttsRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ttsPitch => $composableBuilder(
    column: $table.ttsPitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get songLimit => $composableBuilder(
    column: $table.songLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDurationMs => $composableBuilder(
    column: $table.targetDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rotationGapMs => $composableBuilder(
    column: $table.rotationGapMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snowballStages => $composableBuilder(
    column: $table.snowballStages,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaylistsTableAnnotationComposer
    extends Composer<_$SayawDatabase, $PlaylistsTable> {
  $$PlaylistsTableAnnotationComposer({
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

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventKind =>
      $composableBuilder(column: $table.eventKind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get crossfadeMs =>
      $composableBuilder(
        column: $table.crossfadeMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FadeCurve, String> get fadeInCurve =>
      $composableBuilder(
        column: $table.fadeInCurve,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FadeCurve, String> get fadeOutCurve =>
      $composableBuilder(
        column: $table.fadeOutCurve,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<AnnounceMode, String> get announceMode =>
      $composableBuilder(
        column: $table.announceMode,
        builder: (column) => column,
      );

  GeneratedColumn<double> get duckLevel =>
      $composableBuilder(column: $table.duckLevel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get duckFadeMs =>
      $composableBuilder(
        column: $table.duckFadeMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration, int> get duckHoldMs =>
      $composableBuilder(
        column: $table.duckHoldMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration, int> get duckRestoreFadeMs =>
      $composableBuilder(
        column: $table.duckRestoreFadeMs,
        builder: (column) => column,
      );

  GeneratedColumn<String> get ttsVoiceId => $composableBuilder(
    column: $table.ttsVoiceId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get ttsRate =>
      $composableBuilder(column: $table.ttsRate, builder: (column) => column);

  GeneratedColumn<double> get ttsPitch =>
      $composableBuilder(column: $table.ttsPitch, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get songLimit =>
      $composableBuilder(column: $table.songLimit, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration?, int> get targetDurationMs =>
      $composableBuilder(
        column: $table.targetDurationMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration, int> get rotationGapMs =>
      $composableBuilder(
        column: $table.rotationGapMs,
        builder: (column) => column,
      );

  GeneratedColumn<int> get snowballStages => $composableBuilder(
    column: $table.snowballStages,
    builder: (column) => column,
  );

  Expression<T> playlistItemsRefs<T extends Object>(
    Expression<T> Function($$PlaylistItemsTableAnnotationComposer a) f,
  ) {
    final $$PlaylistItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistItems,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> playHistoryRefs<T extends Object>(
    Expression<T> Function($$PlayHistoryTableAnnotationComposer a) f,
  ) {
    final $$PlayHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playHistory,
      getReferencedColumn: (t) => t.playlistId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlayHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.playHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PlaylistsTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $PlaylistsTable,
          Playlist,
          $$PlaylistsTableFilterComposer,
          $$PlaylistsTableOrderingComposer,
          $$PlaylistsTableAnnotationComposer,
          $$PlaylistsTableCreateCompanionBuilder,
          $$PlaylistsTableUpdateCompanionBuilder,
          (Playlist, $$PlaylistsTableReferences),
          Playlist,
          PrefetchHooks Function({bool playlistItemsRefs, bool playHistoryRefs})
        > {
  $$PlaylistsTableTableManager(_$SayawDatabase db, $PlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> eventKind = const Value.absent(),
                Value<DateTime?> eventDate = const Value.absent(),
                Value<Duration> crossfadeMs = const Value.absent(),
                Value<FadeCurve> fadeInCurve = const Value.absent(),
                Value<FadeCurve> fadeOutCurve = const Value.absent(),
                Value<AnnounceMode> announceMode = const Value.absent(),
                Value<double> duckLevel = const Value.absent(),
                Value<Duration> duckFadeMs = const Value.absent(),
                Value<Duration> duckHoldMs = const Value.absent(),
                Value<Duration> duckRestoreFadeMs = const Value.absent(),
                Value<String?> ttsVoiceId = const Value.absent(),
                Value<double> ttsRate = const Value.absent(),
                Value<double> ttsPitch = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int?> songLimit = const Value.absent(),
                Value<Duration?> targetDurationMs = const Value.absent(),
                Value<Duration> rotationGapMs = const Value.absent(),
                Value<int> snowballStages = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion(
                id: id,
                name: name,
                description: description,
                eventKind: eventKind,
                eventDate: eventDate,
                crossfadeMs: crossfadeMs,
                fadeInCurve: fadeInCurve,
                fadeOutCurve: fadeOutCurve,
                announceMode: announceMode,
                duckLevel: duckLevel,
                duckFadeMs: duckFadeMs,
                duckHoldMs: duckHoldMs,
                duckRestoreFadeMs: duckRestoreFadeMs,
                ttsVoiceId: ttsVoiceId,
                ttsRate: ttsRate,
                ttsPitch: ttsPitch,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                songLimit: songLimit,
                targetDurationMs: targetDurationMs,
                rotationGapMs: rotationGapMs,
                snowballStages: snowballStages,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> eventKind = const Value.absent(),
                Value<DateTime?> eventDate = const Value.absent(),
                Value<Duration> crossfadeMs = const Value.absent(),
                Value<FadeCurve> fadeInCurve = const Value.absent(),
                Value<FadeCurve> fadeOutCurve = const Value.absent(),
                Value<AnnounceMode> announceMode = const Value.absent(),
                Value<double> duckLevel = const Value.absent(),
                Value<Duration> duckFadeMs = const Value.absent(),
                Value<Duration> duckHoldMs = const Value.absent(),
                Value<Duration> duckRestoreFadeMs = const Value.absent(),
                Value<String?> ttsVoiceId = const Value.absent(),
                Value<double> ttsRate = const Value.absent(),
                Value<double> ttsPitch = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int?> songLimit = const Value.absent(),
                Value<Duration?> targetDurationMs = const Value.absent(),
                Value<Duration> rotationGapMs = const Value.absent(),
                Value<int> snowballStages = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistsCompanion.insert(
                id: id,
                name: name,
                description: description,
                eventKind: eventKind,
                eventDate: eventDate,
                crossfadeMs: crossfadeMs,
                fadeInCurve: fadeInCurve,
                fadeOutCurve: fadeOutCurve,
                announceMode: announceMode,
                duckLevel: duckLevel,
                duckFadeMs: duckFadeMs,
                duckHoldMs: duckHoldMs,
                duckRestoreFadeMs: duckRestoreFadeMs,
                ttsVoiceId: ttsVoiceId,
                ttsRate: ttsRate,
                ttsPitch: ttsPitch,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                songLimit: songLimit,
                targetDurationMs: targetDurationMs,
                rotationGapMs: rotationGapMs,
                snowballStages: snowballStages,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistItemsRefs = false, playHistoryRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (playlistItemsRefs) db.playlistItems,
                    if (playHistoryRefs) db.playHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (playlistItemsRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          PlaylistItem
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._playlistItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).playlistItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (playHistoryRefs)
                        await $_getPrefetchedData<
                          Playlist,
                          $PlaylistsTable,
                          PlayHistoryEntry
                        >(
                          currentTable: table,
                          referencedTable: $$PlaylistsTableReferences
                              ._playHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PlaylistsTableReferences(
                                db,
                                table,
                                p0,
                              ).playHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.playlistId == item.id,
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

typedef $$PlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $PlaylistsTable,
      Playlist,
      $$PlaylistsTableFilterComposer,
      $$PlaylistsTableOrderingComposer,
      $$PlaylistsTableAnnotationComposer,
      $$PlaylistsTableCreateCompanionBuilder,
      $$PlaylistsTableUpdateCompanionBuilder,
      (Playlist, $$PlaylistsTableReferences),
      Playlist,
      PrefetchHooks Function({bool playlistItemsRefs, bool playHistoryRefs})
    >;
typedef $$PlaylistItemsTableCreateCompanionBuilder =
    PlaylistItemsCompanion Function({
      required String id,
      required String playlistId,
      required double position,
      Value<PlaylistItemType> itemType,
      Value<String?> trackId,
      Value<String?> danceTypeId,
      Value<AnnounceMode?> announceMode,
      Value<String?> announcementText,
      Value<String?> announcementClipPath,
      Value<Duration?> crossfadeMs,
      Value<FadeCurve?> fadeInCurve,
      Value<FadeCurve?> fadeOutCurve,
      Value<Duration> startOffsetMs,
      Value<Duration?> endOffsetMs,
      Value<Duration?> targetDurationMs,
      Value<double> gainOffsetDb,
      Value<Duration?> silenceMs,
      Value<bool> pauseAfter,
      Value<String?> notes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PlaylistItemsTableUpdateCompanionBuilder =
    PlaylistItemsCompanion Function({
      Value<String> id,
      Value<String> playlistId,
      Value<double> position,
      Value<PlaylistItemType> itemType,
      Value<String?> trackId,
      Value<String?> danceTypeId,
      Value<AnnounceMode?> announceMode,
      Value<String?> announcementText,
      Value<String?> announcementClipPath,
      Value<Duration?> crossfadeMs,
      Value<FadeCurve?> fadeInCurve,
      Value<FadeCurve?> fadeOutCurve,
      Value<Duration> startOffsetMs,
      Value<Duration?> endOffsetMs,
      Value<Duration?> targetDurationMs,
      Value<double> gainOffsetDb,
      Value<Duration?> silenceMs,
      Value<bool> pauseAfter,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$PlaylistItemsTableReferences
    extends BaseReferences<_$SayawDatabase, $PlaylistItemsTable, PlaylistItem> {
  $$PlaylistItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PlaylistsTable _playlistIdTable(_$SayawDatabase db) =>
      db.playlists.createAlias('playlist_items__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager get playlistId {
    final $_column = $_itemColumn<String>('playlist_id')!;

    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TracksTable _trackIdTable(_$SayawDatabase db) =>
      db.tracks.createAlias('playlist_items__track_id__tracks__id');

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<String>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DanceTypesTable _danceTypeIdTable(_$SayawDatabase db) => db.danceTypes
      .createAlias('playlist_items__dance_type_id__dance_types__id');

  $$DanceTypesTableProcessedTableManager? get danceTypeId {
    final $_column = $_itemColumn<String>('dance_type_id');
    if ($_column == null) return null;
    final manager = $$DanceTypesTableTableManager(
      $_db,
      $_db.danceTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_danceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistItemsTableFilterComposer
    extends Composer<_$SayawDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableFilterComposer({
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

  ColumnFilters<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlaylistItemType, PlaylistItemType, String>
  get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<AnnounceMode?, AnnounceMode, String>
  get announceMode => $composableBuilder(
    column: $table.announceMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get announcementText => $composableBuilder(
    column: $table.announcementText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get announcementClipPath => $composableBuilder(
    column: $table.announcementClipPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration?, Duration, int> get crossfadeMs =>
      $composableBuilder(
        column: $table.crossfadeMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<FadeCurve?, FadeCurve, String>
  get fadeInCurve => $composableBuilder(
    column: $table.fadeInCurve,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<FadeCurve?, FadeCurve, String>
  get fadeOutCurve => $composableBuilder(
    column: $table.fadeOutCurve,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get startOffsetMs =>
      $composableBuilder(
        column: $table.startOffsetMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration?, Duration, int> get endOffsetMs =>
      $composableBuilder(
        column: $table.endOffsetMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Duration?, Duration, int>
  get targetDurationMs => $composableBuilder(
    column: $table.targetDurationMs,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get gainOffsetDb => $composableBuilder(
    column: $table.gainOffsetDb,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration?, Duration, int> get silenceMs =>
      $composableBuilder(
        column: $table.silenceMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get pauseAfter => $composableBuilder(
    column: $table.pauseAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableFilterComposer get danceTypeId {
    final $$DanceTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableFilterComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableOrderingComposer
    extends Composer<_$SayawDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableOrderingComposer({
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

  ColumnOrderings<double> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get announceMode => $composableBuilder(
    column: $table.announceMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get announcementText => $composableBuilder(
    column: $table.announcementText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get announcementClipPath => $composableBuilder(
    column: $table.announcementClipPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get crossfadeMs => $composableBuilder(
    column: $table.crossfadeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fadeInCurve => $composableBuilder(
    column: $table.fadeInCurve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fadeOutCurve => $composableBuilder(
    column: $table.fadeOutCurve,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startOffsetMs => $composableBuilder(
    column: $table.startOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endOffsetMs => $composableBuilder(
    column: $table.endOffsetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDurationMs => $composableBuilder(
    column: $table.targetDurationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gainOffsetDb => $composableBuilder(
    column: $table.gainOffsetDb,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get silenceMs => $composableBuilder(
    column: $table.silenceMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pauseAfter => $composableBuilder(
    column: $table.pauseAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableOrderingComposer get danceTypeId {
    final $$DanceTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableOrderingComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableAnnotationComposer
    extends Composer<_$SayawDatabase, $PlaylistItemsTable> {
  $$PlaylistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<PlaylistItemType, String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AnnounceMode?, String> get announceMode =>
      $composableBuilder(
        column: $table.announceMode,
        builder: (column) => column,
      );

  GeneratedColumn<String> get announcementText => $composableBuilder(
    column: $table.announcementText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get announcementClipPath => $composableBuilder(
    column: $table.announcementClipPath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration?, int> get crossfadeMs =>
      $composableBuilder(
        column: $table.crossfadeMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FadeCurve?, String> get fadeInCurve =>
      $composableBuilder(
        column: $table.fadeInCurve,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<FadeCurve?, String> get fadeOutCurve =>
      $composableBuilder(
        column: $table.fadeOutCurve,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration, int> get startOffsetMs =>
      $composableBuilder(
        column: $table.startOffsetMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration?, int> get endOffsetMs =>
      $composableBuilder(
        column: $table.endOffsetMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Duration?, int> get targetDurationMs =>
      $composableBuilder(
        column: $table.targetDurationMs,
        builder: (column) => column,
      );

  GeneratedColumn<double> get gainOffsetDb => $composableBuilder(
    column: $table.gainOffsetDb,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Duration?, int> get silenceMs =>
      $composableBuilder(column: $table.silenceMs, builder: (column) => column);

  GeneratedColumn<bool> get pauseAfter => $composableBuilder(
    column: $table.pauseAfter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableAnnotationComposer get danceTypeId {
    final $$DanceTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistItemsTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $PlaylistItemsTable,
          PlaylistItem,
          $$PlaylistItemsTableFilterComposer,
          $$PlaylistItemsTableOrderingComposer,
          $$PlaylistItemsTableAnnotationComposer,
          $$PlaylistItemsTableCreateCompanionBuilder,
          $$PlaylistItemsTableUpdateCompanionBuilder,
          (PlaylistItem, $$PlaylistItemsTableReferences),
          PlaylistItem,
          PrefetchHooks Function({
            bool playlistId,
            bool trackId,
            bool danceTypeId,
          })
        > {
  $$PlaylistItemsTableTableManager(
    _$SayawDatabase db,
    $PlaylistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> playlistId = const Value.absent(),
                Value<double> position = const Value.absent(),
                Value<PlaylistItemType> itemType = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> danceTypeId = const Value.absent(),
                Value<AnnounceMode?> announceMode = const Value.absent(),
                Value<String?> announcementText = const Value.absent(),
                Value<String?> announcementClipPath = const Value.absent(),
                Value<Duration?> crossfadeMs = const Value.absent(),
                Value<FadeCurve?> fadeInCurve = const Value.absent(),
                Value<FadeCurve?> fadeOutCurve = const Value.absent(),
                Value<Duration> startOffsetMs = const Value.absent(),
                Value<Duration?> endOffsetMs = const Value.absent(),
                Value<Duration?> targetDurationMs = const Value.absent(),
                Value<double> gainOffsetDb = const Value.absent(),
                Value<Duration?> silenceMs = const Value.absent(),
                Value<bool> pauseAfter = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemsCompanion(
                id: id,
                playlistId: playlistId,
                position: position,
                itemType: itemType,
                trackId: trackId,
                danceTypeId: danceTypeId,
                announceMode: announceMode,
                announcementText: announcementText,
                announcementClipPath: announcementClipPath,
                crossfadeMs: crossfadeMs,
                fadeInCurve: fadeInCurve,
                fadeOutCurve: fadeOutCurve,
                startOffsetMs: startOffsetMs,
                endOffsetMs: endOffsetMs,
                targetDurationMs: targetDurationMs,
                gainOffsetDb: gainOffsetDb,
                silenceMs: silenceMs,
                pauseAfter: pauseAfter,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String playlistId,
                required double position,
                Value<PlaylistItemType> itemType = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> danceTypeId = const Value.absent(),
                Value<AnnounceMode?> announceMode = const Value.absent(),
                Value<String?> announcementText = const Value.absent(),
                Value<String?> announcementClipPath = const Value.absent(),
                Value<Duration?> crossfadeMs = const Value.absent(),
                Value<FadeCurve?> fadeInCurve = const Value.absent(),
                Value<FadeCurve?> fadeOutCurve = const Value.absent(),
                Value<Duration> startOffsetMs = const Value.absent(),
                Value<Duration?> endOffsetMs = const Value.absent(),
                Value<Duration?> targetDurationMs = const Value.absent(),
                Value<double> gainOffsetDb = const Value.absent(),
                Value<Duration?> silenceMs = const Value.absent(),
                Value<bool> pauseAfter = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PlaylistItemsCompanion.insert(
                id: id,
                playlistId: playlistId,
                position: position,
                itemType: itemType,
                trackId: trackId,
                danceTypeId: danceTypeId,
                announceMode: announceMode,
                announcementText: announcementText,
                announcementClipPath: announcementClipPath,
                crossfadeMs: crossfadeMs,
                fadeInCurve: fadeInCurve,
                fadeOutCurve: fadeOutCurve,
                startOffsetMs: startOffsetMs,
                endOffsetMs: endOffsetMs,
                targetDurationMs: targetDurationMs,
                gainOffsetDb: gainOffsetDb,
                silenceMs: silenceMs,
                pauseAfter: pauseAfter,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({playlistId = false, trackId = false, danceTypeId = false}) {
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
                        if (playlistId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.playlistId,
                            referencedTable: $$PlaylistItemsTableReferences
                                ._playlistIdTable(db),
                            referencedColumn: $$PlaylistItemsTableReferences
                                ._playlistIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (trackId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.trackId,
                            referencedTable: $$PlaylistItemsTableReferences
                                ._trackIdTable(db),
                            referencedColumn: $$PlaylistItemsTableReferences
                                ._trackIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (danceTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.danceTypeId,
                            referencedTable: $$PlaylistItemsTableReferences
                                ._danceTypeIdTable(db),
                            referencedColumn: $$PlaylistItemsTableReferences
                                ._danceTypeIdTable(db)
                                .id,
                          ) as T;
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

typedef $$PlaylistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $PlaylistItemsTable,
      PlaylistItem,
      $$PlaylistItemsTableFilterComposer,
      $$PlaylistItemsTableOrderingComposer,
      $$PlaylistItemsTableAnnotationComposer,
      $$PlaylistItemsTableCreateCompanionBuilder,
      $$PlaylistItemsTableUpdateCompanionBuilder,
      (PlaylistItem, $$PlaylistItemsTableReferences),
      PlaylistItem,
      PrefetchHooks Function({bool playlistId, bool trackId, bool danceTypeId})
    >;
typedef $$CacheEntriesTableCreateCompanionBuilder =
    CacheEntriesCompanion Function({
      required String trackId,
      Value<CacheState> state,
      Value<String?> cachePath,
      Value<int> byteSize,
      Value<int> bytesDownloaded,
      Value<String?> encryptionKeyRef,
      Value<bool> policyAllowsPersist,
      Value<String?> drmLicensePath,
      Value<DateTime?> drmLicenseExpiresAt,
      Value<bool> pinned,
      Value<DateTime?> expiresAt,
      Value<DateTime?> lastAccessedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CacheEntriesTableUpdateCompanionBuilder =
    CacheEntriesCompanion Function({
      Value<String> trackId,
      Value<CacheState> state,
      Value<String?> cachePath,
      Value<int> byteSize,
      Value<int> bytesDownloaded,
      Value<String?> encryptionKeyRef,
      Value<bool> policyAllowsPersist,
      Value<String?> drmLicensePath,
      Value<DateTime?> drmLicenseExpiresAt,
      Value<bool> pinned,
      Value<DateTime?> expiresAt,
      Value<DateTime?> lastAccessedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CacheEntriesTableReferences
    extends BaseReferences<_$SayawDatabase, $CacheEntriesTable, CacheEntry> {
  $$CacheEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$SayawDatabase db) =>
      db.tracks.createAlias('cache_entries__track_id__tracks__id');

  $$TracksTableProcessedTableManager get trackId {
    final $_column = $_itemColumn<String>('track_id')!;

    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CacheEntriesTableFilterComposer
    extends Composer<_$SayawDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<CacheState, CacheState, String> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get cachePath => $composableBuilder(
    column: $table.cachePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptionKeyRef => $composableBuilder(
    column: $table.encryptionKeyRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get policyAllowsPersist => $composableBuilder(
    column: $table.policyAllowsPersist,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get drmLicensePath => $composableBuilder(
    column: $table.drmLicensePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int>
  get drmLicenseExpiresAt => $composableBuilder(
    column: $table.drmLicenseExpiresAt,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get expiresAt =>
      $composableBuilder(
        column: $table.expiresAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastAccessedAt =>
      $composableBuilder(
        column: $table.lastAccessedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableOrderingComposer
    extends Composer<_$SayawDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cachePath => $composableBuilder(
    column: $table.cachePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptionKeyRef => $composableBuilder(
    column: $table.encryptionKeyRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get policyAllowsPersist => $composableBuilder(
    column: $table.policyAllowsPersist,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get drmLicensePath => $composableBuilder(
    column: $table.drmLicensePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get drmLicenseExpiresAt => $composableBuilder(
    column: $table.drmLicenseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pinned => $composableBuilder(
    column: $table.pinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAccessedAt => $composableBuilder(
    column: $table.lastAccessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableAnnotationComposer
    extends Composer<_$SayawDatabase, $CacheEntriesTable> {
  $$CacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<CacheState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get cachePath =>
      $composableBuilder(column: $table.cachePath, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<int> get bytesDownloaded => $composableBuilder(
    column: $table.bytesDownloaded,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptionKeyRef => $composableBuilder(
    column: $table.encryptionKeyRef,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get policyAllowsPersist => $composableBuilder(
    column: $table.policyAllowsPersist,
    builder: (column) => column,
  );

  GeneratedColumn<String> get drmLicensePath => $composableBuilder(
    column: $table.drmLicensePath,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime?, int> get drmLicenseExpiresAt =>
      $composableBuilder(
        column: $table.drmLicenseExpiresAt,
        builder: (column) => column,
      );

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastAccessedAt =>
      $composableBuilder(
        column: $table.lastAccessedAt,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CacheEntriesTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $CacheEntriesTable,
          CacheEntry,
          $$CacheEntriesTableFilterComposer,
          $$CacheEntriesTableOrderingComposer,
          $$CacheEntriesTableAnnotationComposer,
          $$CacheEntriesTableCreateCompanionBuilder,
          $$CacheEntriesTableUpdateCompanionBuilder,
          (CacheEntry, $$CacheEntriesTableReferences),
          CacheEntry,
          PrefetchHooks Function({bool trackId})
        > {
  $$CacheEntriesTableTableManager(_$SayawDatabase db, $CacheEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trackId = const Value.absent(),
                Value<CacheState> state = const Value.absent(),
                Value<String?> cachePath = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> bytesDownloaded = const Value.absent(),
                Value<String?> encryptionKeyRef = const Value.absent(),
                Value<bool> policyAllowsPersist = const Value.absent(),
                Value<String?> drmLicensePath = const Value.absent(),
                Value<DateTime?> drmLicenseExpiresAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion(
                trackId: trackId,
                state: state,
                cachePath: cachePath,
                byteSize: byteSize,
                bytesDownloaded: bytesDownloaded,
                encryptionKeyRef: encryptionKeyRef,
                policyAllowsPersist: policyAllowsPersist,
                drmLicensePath: drmLicensePath,
                drmLicenseExpiresAt: drmLicenseExpiresAt,
                pinned: pinned,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trackId,
                Value<CacheState> state = const Value.absent(),
                Value<String?> cachePath = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<int> bytesDownloaded = const Value.absent(),
                Value<String?> encryptionKeyRef = const Value.absent(),
                Value<bool> policyAllowsPersist = const Value.absent(),
                Value<String?> drmLicensePath = const Value.absent(),
                Value<DateTime?> drmLicenseExpiresAt = const Value.absent(),
                Value<bool> pinned = const Value.absent(),
                Value<DateTime?> expiresAt = const Value.absent(),
                Value<DateTime?> lastAccessedAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CacheEntriesCompanion.insert(
                trackId: trackId,
                state: state,
                cachePath: cachePath,
                byteSize: byteSize,
                bytesDownloaded: bytesDownloaded,
                encryptionKeyRef: encryptionKeyRef,
                policyAllowsPersist: policyAllowsPersist,
                drmLicensePath: drmLicensePath,
                drmLicenseExpiresAt: drmLicenseExpiresAt,
                pinned: pinned,
                expiresAt: expiresAt,
                lastAccessedAt: lastAccessedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CacheEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trackId = false}) {
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
                    if (trackId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trackId,
                        referencedTable: $$CacheEntriesTableReferences
                            ._trackIdTable(db),
                        referencedColumn: $$CacheEntriesTableReferences
                            ._trackIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $CacheEntriesTable,
      CacheEntry,
      $$CacheEntriesTableFilterComposer,
      $$CacheEntriesTableOrderingComposer,
      $$CacheEntriesTableAnnotationComposer,
      $$CacheEntriesTableCreateCompanionBuilder,
      $$CacheEntriesTableUpdateCompanionBuilder,
      (CacheEntry, $$CacheEntriesTableReferences),
      CacheEntry,
      PrefetchHooks Function({bool trackId})
    >;
typedef $$AnnouncementCacheTableCreateCompanionBuilder =
    AnnouncementCacheCompanion Function({
      required String hash,
      required String body,
      Value<String?> voiceId,
      required double rate,
      required double pitch,
      required String filePath,
      required Duration durationMs,
      required DateTime createdAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });
typedef $$AnnouncementCacheTableUpdateCompanionBuilder =
    AnnouncementCacheCompanion Function({
      Value<String> hash,
      Value<String> body,
      Value<String?> voiceId,
      Value<double> rate,
      Value<double> pitch,
      Value<String> filePath,
      Value<Duration> durationMs,
      Value<DateTime> createdAt,
      Value<DateTime?> lastUsedAt,
      Value<int> rowid,
    });

class $$AnnouncementCacheTableFilterComposer
    extends Composer<_$SayawDatabase, $AnnouncementCacheTable> {
  $$AnnouncementCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get durationMs =>
      $composableBuilder(
        column: $table.durationMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get lastUsedAt =>
      $composableBuilder(
        column: $table.lastUsedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AnnouncementCacheTableOrderingComposer
    extends Composer<_$SayawDatabase, $AnnouncementCacheTable> {
  $$AnnouncementCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get hash => $composableBuilder(
    column: $table.hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceId => $composableBuilder(
    column: $table.voiceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pitch => $composableBuilder(
    column: $table.pitch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAt => $composableBuilder(
    column: $table.lastUsedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnnouncementCacheTableAnnotationComposer
    extends Composer<_$SayawDatabase, $AnnouncementCacheTable> {
  $$AnnouncementCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get voiceId =>
      $composableBuilder(column: $table.voiceId, builder: (column) => column);

  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<double> get pitch =>
      $composableBuilder(column: $table.pitch, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get durationMs =>
      $composableBuilder(
        column: $table.durationMs,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get lastUsedAt =>
      $composableBuilder(
        column: $table.lastUsedAt,
        builder: (column) => column,
      );
}

class $$AnnouncementCacheTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $AnnouncementCacheTable,
          AnnouncementCacheRow,
          $$AnnouncementCacheTableFilterComposer,
          $$AnnouncementCacheTableOrderingComposer,
          $$AnnouncementCacheTableAnnotationComposer,
          $$AnnouncementCacheTableCreateCompanionBuilder,
          $$AnnouncementCacheTableUpdateCompanionBuilder,
          (
            AnnouncementCacheRow,
            BaseReferences<
              _$SayawDatabase,
              $AnnouncementCacheTable,
              AnnouncementCacheRow
            >,
          ),
          AnnouncementCacheRow,
          PrefetchHooks Function()
        > {
  $$AnnouncementCacheTableTableManager(
    _$SayawDatabase db,
    $AnnouncementCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnnouncementCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnnouncementCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnnouncementCacheTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> hash = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> voiceId = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<double> pitch = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<Duration> durationMs = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnouncementCacheCompanion(
                hash: hash,
                body: body,
                voiceId: voiceId,
                rate: rate,
                pitch: pitch,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String hash,
                required String body,
                Value<String?> voiceId = const Value.absent(),
                required double rate,
                required double pitch,
                required String filePath,
                required Duration durationMs,
                required DateTime createdAt,
                Value<DateTime?> lastUsedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnnouncementCacheCompanion.insert(
                hash: hash,
                body: body,
                voiceId: voiceId,
                rate: rate,
                pitch: pitch,
                filePath: filePath,
                durationMs: durationMs,
                createdAt: createdAt,
                lastUsedAt: lastUsedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnnouncementCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $AnnouncementCacheTable,
      AnnouncementCacheRow,
      $$AnnouncementCacheTableFilterComposer,
      $$AnnouncementCacheTableOrderingComposer,
      $$AnnouncementCacheTableAnnotationComposer,
      $$AnnouncementCacheTableCreateCompanionBuilder,
      $$AnnouncementCacheTableUpdateCompanionBuilder,
      (
        AnnouncementCacheRow,
        BaseReferences<
          _$SayawDatabase,
          $AnnouncementCacheTable,
          AnnouncementCacheRow
        >,
      ),
      AnnouncementCacheRow,
      PrefetchHooks Function()
    >;
typedef $$PlayHistoryTableCreateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<String?> trackId,
      Value<String?> playlistId,
      Value<String?> danceTypeId,
      required DateTime startedAt,
      Value<bool> completed,
      Value<Duration> playedMs,
    });
typedef $$PlayHistoryTableUpdateCompanionBuilder =
    PlayHistoryCompanion Function({
      Value<int> id,
      Value<String?> trackId,
      Value<String?> playlistId,
      Value<String?> danceTypeId,
      Value<DateTime> startedAt,
      Value<bool> completed,
      Value<Duration> playedMs,
    });

final class $$PlayHistoryTableReferences
    extends
        BaseReferences<_$SayawDatabase, $PlayHistoryTable, PlayHistoryEntry> {
  $$PlayHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TracksTable _trackIdTable(_$SayawDatabase db) =>
      db.tracks.createAlias('play_history__track_id__tracks__id');

  $$TracksTableProcessedTableManager? get trackId {
    final $_column = $_itemColumn<String>('track_id');
    if ($_column == null) return null;
    final manager = $$TracksTableTableManager(
      $_db,
      $_db.tracks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trackIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PlaylistsTable _playlistIdTable(_$SayawDatabase db) =>
      db.playlists.createAlias('play_history__playlist_id__playlists__id');

  $$PlaylistsTableProcessedTableManager? get playlistId {
    final $_column = $_itemColumn<String>('playlist_id');
    if ($_column == null) return null;
    final manager = $$PlaylistsTableTableManager(
      $_db,
      $_db.playlists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $DanceTypesTable _danceTypeIdTable(_$SayawDatabase db) =>
      db.danceTypes.createAlias('play_history__dance_type_id__dance_types__id');

  $$DanceTypesTableProcessedTableManager? get danceTypeId {
    final $_column = $_itemColumn<String>('dance_type_id');
    if ($_column == null) return null;
    final manager = $$DanceTypesTableTableManager(
      $_db,
      $_db.danceTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_danceTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlayHistoryTableFilterComposer
    extends Composer<_$SayawDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableFilterComposer({
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

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get startedAt =>
      $composableBuilder(
        column: $table.startedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Duration, Duration, int> get playedMs =>
      $composableBuilder(
        column: $table.playedMs,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$TracksTableFilterComposer get trackId {
    final $$TracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableFilterComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableFilterComposer get playlistId {
    final $$PlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableFilterComposer get danceTypeId {
    final $$DanceTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableFilterComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableOrderingComposer
    extends Composer<_$SayawDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableOrderingComposer({
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

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get playedMs => $composableBuilder(
    column: $table.playedMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$TracksTableOrderingComposer get trackId {
    final $$TracksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableOrderingComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableOrderingComposer get playlistId {
    final $$PlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableOrderingComposer get danceTypeId {
    final $$DanceTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableOrderingComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableAnnotationComposer
    extends Composer<_$SayawDatabase, $PlayHistoryTable> {
  $$PlayHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Duration, int> get playedMs =>
      $composableBuilder(column: $table.playedMs, builder: (column) => column);

  $$TracksTableAnnotationComposer get trackId {
    final $$TracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trackId,
      referencedTable: $db.tracks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TracksTableAnnotationComposer(
            $db: $db,
            $table: $db.tracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PlaylistsTableAnnotationComposer get playlistId {
    final $$PlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlistId,
      referencedTable: $db.playlists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.playlists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$DanceTypesTableAnnotationComposer get danceTypeId {
    final $$DanceTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.danceTypeId,
      referencedTable: $db.danceTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DanceTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.danceTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlayHistoryTableTableManager
    extends
        RootTableManager<
          _$SayawDatabase,
          $PlayHistoryTable,
          PlayHistoryEntry,
          $$PlayHistoryTableFilterComposer,
          $$PlayHistoryTableOrderingComposer,
          $$PlayHistoryTableAnnotationComposer,
          $$PlayHistoryTableCreateCompanionBuilder,
          $$PlayHistoryTableUpdateCompanionBuilder,
          (PlayHistoryEntry, $$PlayHistoryTableReferences),
          PlayHistoryEntry,
          PrefetchHooks Function({
            bool trackId,
            bool playlistId,
            bool danceTypeId,
          })
        > {
  $$PlayHistoryTableTableManager(_$SayawDatabase db, $PlayHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlayHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlayHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlayHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> playlistId = const Value.absent(),
                Value<String?> danceTypeId = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<Duration> playedMs = const Value.absent(),
              }) => PlayHistoryCompanion(
                id: id,
                trackId: trackId,
                playlistId: playlistId,
                danceTypeId: danceTypeId,
                startedAt: startedAt,
                completed: completed,
                playedMs: playedMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> trackId = const Value.absent(),
                Value<String?> playlistId = const Value.absent(),
                Value<String?> danceTypeId = const Value.absent(),
                required DateTime startedAt,
                Value<bool> completed = const Value.absent(),
                Value<Duration> playedMs = const Value.absent(),
              }) => PlayHistoryCompanion.insert(
                id: id,
                trackId: trackId,
                playlistId: playlistId,
                danceTypeId: danceTypeId,
                startedAt: startedAt,
                completed: completed,
                playedMs: playedMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlayHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({trackId = false, playlistId = false, danceTypeId = false}) {
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
                        if (trackId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.trackId,
                            referencedTable: $$PlayHistoryTableReferences
                                ._trackIdTable(db),
                            referencedColumn: $$PlayHistoryTableReferences
                                ._trackIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (playlistId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.playlistId,
                            referencedTable: $$PlayHistoryTableReferences
                                ._playlistIdTable(db),
                            referencedColumn: $$PlayHistoryTableReferences
                                ._playlistIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (danceTypeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.danceTypeId,
                            referencedTable: $$PlayHistoryTableReferences
                                ._danceTypeIdTable(db),
                            referencedColumn: $$PlayHistoryTableReferences
                                ._danceTypeIdTable(db)
                                .id,
                          ) as T;
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

typedef $$PlayHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$SayawDatabase,
      $PlayHistoryTable,
      PlayHistoryEntry,
      $$PlayHistoryTableFilterComposer,
      $$PlayHistoryTableOrderingComposer,
      $$PlayHistoryTableAnnotationComposer,
      $$PlayHistoryTableCreateCompanionBuilder,
      $$PlayHistoryTableUpdateCompanionBuilder,
      (PlayHistoryEntry, $$PlayHistoryTableReferences),
      PlayHistoryEntry,
      PrefetchHooks Function({bool trackId, bool playlistId, bool danceTypeId})
    >;

class $SayawDatabaseManager {
  final _$SayawDatabase _db;
  $SayawDatabaseManager(this._db);
  $$SourceAccountsTableTableManager get sourceAccounts =>
      $$SourceAccountsTableTableManager(_db, _db.sourceAccounts);
  $$DanceTypesTableTableManager get danceTypes =>
      $$DanceTypesTableTableManager(_db, _db.danceTypes);
  $$TracksTableTableManager get tracks =>
      $$TracksTableTableManager(_db, _db.tracks);
  $$PlaylistsTableTableManager get playlists =>
      $$PlaylistsTableTableManager(_db, _db.playlists);
  $$PlaylistItemsTableTableManager get playlistItems =>
      $$PlaylistItemsTableTableManager(_db, _db.playlistItems);
  $$CacheEntriesTableTableManager get cacheEntries =>
      $$CacheEntriesTableTableManager(_db, _db.cacheEntries);
  $$AnnouncementCacheTableTableManager get announcementCache =>
      $$AnnouncementCacheTableTableManager(_db, _db.announcementCache);
  $$PlayHistoryTableTableManager get playHistory =>
      $$PlayHistoryTableTableManager(_db, _db.playHistory);
}
