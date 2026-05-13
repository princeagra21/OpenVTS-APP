// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedVehiclesTable extends CachedVehicles
    with TableInfo<$CachedVehiclesTable, CachedVehicle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedVehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleIdMeta =
      const VerificationMeta('vehicleId');
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
      'vehicle_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _plateNumberMeta =
      const VerificationMeta('plateNumber');
  @override
  late final GeneratedColumn<String> plateNumber = GeneratedColumn<String>(
      'plate_number', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _imeiMeta = const VerificationMeta('imei');
  @override
  late final GeneratedColumn<String> imei = GeneratedColumn<String>(
      'imei', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _rawJsonMeta =
      const VerificationMeta('rawJson');
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
      'raw_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
      'page', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _limitMeta = const VerificationMeta('limit');
  @override
  late final GeneratedColumn<int> limit = GeneratedColumn<int>(
      'limit', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
      'total', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _cachedAtMillisMeta =
      const VerificationMeta('cachedAtMillis');
  @override
  late final GeneratedColumn<int> cachedAtMillis = GeneratedColumn<int>(
      'cached_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _staleAtMillisMeta =
      const VerificationMeta('staleAtMillis');
  @override
  late final GeneratedColumn<int> staleAtMillis = GeneratedColumn<int>(
      'stale_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMillisMeta =
      const VerificationMeta('expiresAtMillis');
  @override
  late final GeneratedColumn<int> expiresAtMillis = GeneratedColumn<int>(
      'expires_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        cacheKey,
        vehicleId,
        name,
        plateNumber,
        imei,
        status,
        rawJson,
        page,
        limit,
        total,
        sortOrder,
        cachedAtMillis,
        staleAtMillis,
        expiresAtMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_vehicles';
  @override
  VerificationContext validateIntegrity(Insertable<CachedVehicle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(_vehicleIdMeta,
          vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta));
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    }
    if (data.containsKey('plate_number')) {
      context.handle(
          _plateNumberMeta,
          plateNumber.isAcceptableOrUnknown(
              data['plate_number']!, _plateNumberMeta));
    }
    if (data.containsKey('imei')) {
      context.handle(
          _imeiMeta, imei.isAcceptableOrUnknown(data['imei']!, _imeiMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('raw_json')) {
      context.handle(_rawJsonMeta,
          rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta));
    }
    if (data.containsKey('page')) {
      context.handle(
          _pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    }
    if (data.containsKey('limit')) {
      context.handle(
          _limitMeta, limit.isAcceptableOrUnknown(data['limit']!, _limitMeta));
    }
    if (data.containsKey('total')) {
      context.handle(
          _totalMeta, total.isAcceptableOrUnknown(data['total']!, _totalMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('cached_at_millis')) {
      context.handle(
          _cachedAtMillisMeta,
          cachedAtMillis.isAcceptableOrUnknown(
              data['cached_at_millis']!, _cachedAtMillisMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMillisMeta);
    }
    if (data.containsKey('stale_at_millis')) {
      context.handle(
          _staleAtMillisMeta,
          staleAtMillis.isAcceptableOrUnknown(
              data['stale_at_millis']!, _staleAtMillisMeta));
    } else if (isInserting) {
      context.missing(_staleAtMillisMeta);
    }
    if (data.containsKey('expires_at_millis')) {
      context.handle(
          _expiresAtMillisMeta,
          expiresAtMillis.isAcceptableOrUnknown(
              data['expires_at_millis']!, _expiresAtMillisMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey, vehicleId};
  @override
  CachedVehicle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedVehicle(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      vehicleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      plateNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plate_number'])!,
      imei: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imei'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      page: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page'])!,
      limit: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}limit'])!,
      total: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      cachedAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at_millis'])!,
      staleAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stale_at_millis'])!,
      expiresAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at_millis'])!,
    );
  }

  @override
  $CachedVehiclesTable createAlias(String alias) {
    return $CachedVehiclesTable(attachedDatabase, alias);
  }
}

class CachedVehicle extends DataClass implements Insertable<CachedVehicle> {
  final String cacheKey;
  final String vehicleId;
  final String name;
  final String plateNumber;
  final String imei;
  final String status;
  final String rawJson;
  final int page;
  final int limit;
  final int total;
  final int sortOrder;
  final int cachedAtMillis;
  final int staleAtMillis;
  final int expiresAtMillis;
  const CachedVehicle(
      {required this.cacheKey,
      required this.vehicleId,
      required this.name,
      required this.plateNumber,
      required this.imei,
      required this.status,
      required this.rawJson,
      required this.page,
      required this.limit,
      required this.total,
      required this.sortOrder,
      required this.cachedAtMillis,
      required this.staleAtMillis,
      required this.expiresAtMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['name'] = Variable<String>(name);
    map['plate_number'] = Variable<String>(plateNumber);
    map['imei'] = Variable<String>(imei);
    map['status'] = Variable<String>(status);
    map['raw_json'] = Variable<String>(rawJson);
    map['page'] = Variable<int>(page);
    map['limit'] = Variable<int>(limit);
    map['total'] = Variable<int>(total);
    map['sort_order'] = Variable<int>(sortOrder);
    map['cached_at_millis'] = Variable<int>(cachedAtMillis);
    map['stale_at_millis'] = Variable<int>(staleAtMillis);
    map['expires_at_millis'] = Variable<int>(expiresAtMillis);
    return map;
  }

  CachedVehiclesCompanion toCompanion(bool nullToAbsent) {
    return CachedVehiclesCompanion(
      cacheKey: Value(cacheKey),
      vehicleId: Value(vehicleId),
      name: Value(name),
      plateNumber: Value(plateNumber),
      imei: Value(imei),
      status: Value(status),
      rawJson: Value(rawJson),
      page: Value(page),
      limit: Value(limit),
      total: Value(total),
      sortOrder: Value(sortOrder),
      cachedAtMillis: Value(cachedAtMillis),
      staleAtMillis: Value(staleAtMillis),
      expiresAtMillis: Value(expiresAtMillis),
    );
  }

  factory CachedVehicle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedVehicle(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      name: serializer.fromJson<String>(json['name']),
      plateNumber: serializer.fromJson<String>(json['plateNumber']),
      imei: serializer.fromJson<String>(json['imei']),
      status: serializer.fromJson<String>(json['status']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      page: serializer.fromJson<int>(json['page']),
      limit: serializer.fromJson<int>(json['limit']),
      total: serializer.fromJson<int>(json['total']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      cachedAtMillis: serializer.fromJson<int>(json['cachedAtMillis']),
      staleAtMillis: serializer.fromJson<int>(json['staleAtMillis']),
      expiresAtMillis: serializer.fromJson<int>(json['expiresAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'name': serializer.toJson<String>(name),
      'plateNumber': serializer.toJson<String>(plateNumber),
      'imei': serializer.toJson<String>(imei),
      'status': serializer.toJson<String>(status),
      'rawJson': serializer.toJson<String>(rawJson),
      'page': serializer.toJson<int>(page),
      'limit': serializer.toJson<int>(limit),
      'total': serializer.toJson<int>(total),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'cachedAtMillis': serializer.toJson<int>(cachedAtMillis),
      'staleAtMillis': serializer.toJson<int>(staleAtMillis),
      'expiresAtMillis': serializer.toJson<int>(expiresAtMillis),
    };
  }

  CachedVehicle copyWith(
          {String? cacheKey,
          String? vehicleId,
          String? name,
          String? plateNumber,
          String? imei,
          String? status,
          String? rawJson,
          int? page,
          int? limit,
          int? total,
          int? sortOrder,
          int? cachedAtMillis,
          int? staleAtMillis,
          int? expiresAtMillis}) =>
      CachedVehicle(
        cacheKey: cacheKey ?? this.cacheKey,
        vehicleId: vehicleId ?? this.vehicleId,
        name: name ?? this.name,
        plateNumber: plateNumber ?? this.plateNumber,
        imei: imei ?? this.imei,
        status: status ?? this.status,
        rawJson: rawJson ?? this.rawJson,
        page: page ?? this.page,
        limit: limit ?? this.limit,
        total: total ?? this.total,
        sortOrder: sortOrder ?? this.sortOrder,
        cachedAtMillis: cachedAtMillis ?? this.cachedAtMillis,
        staleAtMillis: staleAtMillis ?? this.staleAtMillis,
        expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      );
  CachedVehicle copyWithCompanion(CachedVehiclesCompanion data) {
    return CachedVehicle(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      name: data.name.present ? data.name.value : this.name,
      plateNumber:
          data.plateNumber.present ? data.plateNumber.value : this.plateNumber,
      imei: data.imei.present ? data.imei.value : this.imei,
      status: data.status.present ? data.status.value : this.status,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      page: data.page.present ? data.page.value : this.page,
      limit: data.limit.present ? data.limit.value : this.limit,
      total: data.total.present ? data.total.value : this.total,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      cachedAtMillis: data.cachedAtMillis.present
          ? data.cachedAtMillis.value
          : this.cachedAtMillis,
      staleAtMillis: data.staleAtMillis.present
          ? data.staleAtMillis.value
          : this.staleAtMillis,
      expiresAtMillis: data.expiresAtMillis.present
          ? data.expiresAtMillis.value
          : this.expiresAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedVehicle(')
          ..write('cacheKey: $cacheKey, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('imei: $imei, ')
          ..write('status: $status, ')
          ..write('rawJson: $rawJson, ')
          ..write('page: $page, ')
          ..write('limit: $limit, ')
          ..write('total: $total, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAtMillis: $cachedAtMillis, ')
          ..write('staleAtMillis: $staleAtMillis, ')
          ..write('expiresAtMillis: $expiresAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      cacheKey,
      vehicleId,
      name,
      plateNumber,
      imei,
      status,
      rawJson,
      page,
      limit,
      total,
      sortOrder,
      cachedAtMillis,
      staleAtMillis,
      expiresAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedVehicle &&
          other.cacheKey == this.cacheKey &&
          other.vehicleId == this.vehicleId &&
          other.name == this.name &&
          other.plateNumber == this.plateNumber &&
          other.imei == this.imei &&
          other.status == this.status &&
          other.rawJson == this.rawJson &&
          other.page == this.page &&
          other.limit == this.limit &&
          other.total == this.total &&
          other.sortOrder == this.sortOrder &&
          other.cachedAtMillis == this.cachedAtMillis &&
          other.staleAtMillis == this.staleAtMillis &&
          other.expiresAtMillis == this.expiresAtMillis);
}

class CachedVehiclesCompanion extends UpdateCompanion<CachedVehicle> {
  final Value<String> cacheKey;
  final Value<String> vehicleId;
  final Value<String> name;
  final Value<String> plateNumber;
  final Value<String> imei;
  final Value<String> status;
  final Value<String> rawJson;
  final Value<int> page;
  final Value<int> limit;
  final Value<int> total;
  final Value<int> sortOrder;
  final Value<int> cachedAtMillis;
  final Value<int> staleAtMillis;
  final Value<int> expiresAtMillis;
  final Value<int> rowid;
  const CachedVehiclesCompanion({
    this.cacheKey = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.name = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.imei = const Value.absent(),
    this.status = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.page = const Value.absent(),
    this.limit = const Value.absent(),
    this.total = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.cachedAtMillis = const Value.absent(),
    this.staleAtMillis = const Value.absent(),
    this.expiresAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedVehiclesCompanion.insert({
    required String cacheKey,
    required String vehicleId,
    this.name = const Value.absent(),
    this.plateNumber = const Value.absent(),
    this.imei = const Value.absent(),
    this.status = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.page = const Value.absent(),
    this.limit = const Value.absent(),
    this.total = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required int cachedAtMillis,
    required int staleAtMillis,
    required int expiresAtMillis,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        vehicleId = Value(vehicleId),
        cachedAtMillis = Value(cachedAtMillis),
        staleAtMillis = Value(staleAtMillis),
        expiresAtMillis = Value(expiresAtMillis);
  static Insertable<CachedVehicle> custom({
    Expression<String>? cacheKey,
    Expression<String>? vehicleId,
    Expression<String>? name,
    Expression<String>? plateNumber,
    Expression<String>? imei,
    Expression<String>? status,
    Expression<String>? rawJson,
    Expression<int>? page,
    Expression<int>? limit,
    Expression<int>? total,
    Expression<int>? sortOrder,
    Expression<int>? cachedAtMillis,
    Expression<int>? staleAtMillis,
    Expression<int>? expiresAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (name != null) 'name': name,
      if (plateNumber != null) 'plate_number': plateNumber,
      if (imei != null) 'imei': imei,
      if (status != null) 'status': status,
      if (rawJson != null) 'raw_json': rawJson,
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
      if (total != null) 'total': total,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (cachedAtMillis != null) 'cached_at_millis': cachedAtMillis,
      if (staleAtMillis != null) 'stale_at_millis': staleAtMillis,
      if (expiresAtMillis != null) 'expires_at_millis': expiresAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedVehiclesCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? vehicleId,
      Value<String>? name,
      Value<String>? plateNumber,
      Value<String>? imei,
      Value<String>? status,
      Value<String>? rawJson,
      Value<int>? page,
      Value<int>? limit,
      Value<int>? total,
      Value<int>? sortOrder,
      Value<int>? cachedAtMillis,
      Value<int>? staleAtMillis,
      Value<int>? expiresAtMillis,
      Value<int>? rowid}) {
    return CachedVehiclesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      vehicleId: vehicleId ?? this.vehicleId,
      name: name ?? this.name,
      plateNumber: plateNumber ?? this.plateNumber,
      imei: imei ?? this.imei,
      status: status ?? this.status,
      rawJson: rawJson ?? this.rawJson,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      sortOrder: sortOrder ?? this.sortOrder,
      cachedAtMillis: cachedAtMillis ?? this.cachedAtMillis,
      staleAtMillis: staleAtMillis ?? this.staleAtMillis,
      expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (plateNumber.present) {
      map['plate_number'] = Variable<String>(plateNumber.value);
    }
    if (imei.present) {
      map['imei'] = Variable<String>(imei.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (limit.present) {
      map['limit'] = Variable<int>(limit.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (cachedAtMillis.present) {
      map['cached_at_millis'] = Variable<int>(cachedAtMillis.value);
    }
    if (staleAtMillis.present) {
      map['stale_at_millis'] = Variable<int>(staleAtMillis.value);
    }
    if (expiresAtMillis.present) {
      map['expires_at_millis'] = Variable<int>(expiresAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedVehiclesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('name: $name, ')
          ..write('plateNumber: $plateNumber, ')
          ..write('imei: $imei, ')
          ..write('status: $status, ')
          ..write('rawJson: $rawJson, ')
          ..write('page: $page, ')
          ..write('limit: $limit, ')
          ..write('total: $total, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('cachedAtMillis: $cachedAtMillis, ')
          ..write('staleAtMillis: $staleAtMillis, ')
          ..write('expiresAtMillis: $expiresAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedHistoryPointsTable extends CachedHistoryPoints
    with TableInfo<$CachedHistoryPointsTable, CachedHistoryPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedHistoryPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vehicleIdMeta =
      const VerificationMeta('vehicleId');
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
      'vehicle_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imeiMeta = const VerificationMeta('imei');
  @override
  late final GeneratedColumn<String> imei = GeneratedColumn<String>(
      'imei', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _speedKphMeta =
      const VerificationMeta('speedKph');
  @override
  late final GeneratedColumn<double> speedKph = GeneratedColumn<double>(
      'speed_kph', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _headingMeta =
      const VerificationMeta('heading');
  @override
  late final GeneratedColumn<double> heading = GeneratedColumn<double>(
      'heading', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ignitionMeta =
      const VerificationMeta('ignition');
  @override
  late final GeneratedColumn<bool> ignition = GeneratedColumn<bool>(
      'ignition', aliasedName, true,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("ignition" IN (0, 1))'));
  static const VerificationMeta _recordedAtMillisMeta =
      const VerificationMeta('recordedAtMillis');
  @override
  late final GeneratedColumn<int> recordedAtMillis = GeneratedColumn<int>(
      'recorded_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _rawJsonMeta =
      const VerificationMeta('rawJson');
  @override
  late final GeneratedColumn<String> rawJson = GeneratedColumn<String>(
      'raw_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _cachedAtMillisMeta =
      const VerificationMeta('cachedAtMillis');
  @override
  late final GeneratedColumn<int> cachedAtMillis = GeneratedColumn<int>(
      'cached_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        cacheKey,
        vehicleId,
        imei,
        latitude,
        longitude,
        speedKph,
        heading,
        ignition,
        recordedAtMillis,
        rawJson,
        cachedAtMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_history_points';
  @override
  VerificationContext validateIntegrity(Insertable<CachedHistoryPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(_vehicleIdMeta,
          vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta));
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('imei')) {
      context.handle(
          _imeiMeta, imei.isAcceptableOrUnknown(data['imei']!, _imeiMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('speed_kph')) {
      context.handle(_speedKphMeta,
          speedKph.isAcceptableOrUnknown(data['speed_kph']!, _speedKphMeta));
    }
    if (data.containsKey('heading')) {
      context.handle(_headingMeta,
          heading.isAcceptableOrUnknown(data['heading']!, _headingMeta));
    }
    if (data.containsKey('ignition')) {
      context.handle(_ignitionMeta,
          ignition.isAcceptableOrUnknown(data['ignition']!, _ignitionMeta));
    }
    if (data.containsKey('recorded_at_millis')) {
      context.handle(
          _recordedAtMillisMeta,
          recordedAtMillis.isAcceptableOrUnknown(
              data['recorded_at_millis']!, _recordedAtMillisMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMillisMeta);
    }
    if (data.containsKey('raw_json')) {
      context.handle(_rawJsonMeta,
          rawJson.isAcceptableOrUnknown(data['raw_json']!, _rawJsonMeta));
    }
    if (data.containsKey('cached_at_millis')) {
      context.handle(
          _cachedAtMillisMeta,
          cachedAtMillis.isAcceptableOrUnknown(
              data['cached_at_millis']!, _cachedAtMillisMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey =>
      {cacheKey, vehicleId, recordedAtMillis};
  @override
  CachedHistoryPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedHistoryPoint(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      vehicleId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vehicle_id'])!,
      imei: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}imei'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      speedKph: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}speed_kph']),
      heading: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}heading']),
      ignition: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}ignition']),
      recordedAtMillis: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}recorded_at_millis'])!,
      rawJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}raw_json'])!,
      cachedAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cached_at_millis'])!,
    );
  }

  @override
  $CachedHistoryPointsTable createAlias(String alias) {
    return $CachedHistoryPointsTable(attachedDatabase, alias);
  }
}

class CachedHistoryPoint extends DataClass
    implements Insertable<CachedHistoryPoint> {
  final String cacheKey;
  final String vehicleId;
  final String imei;
  final double latitude;
  final double longitude;
  final double? speedKph;
  final double? heading;
  final bool? ignition;
  final int recordedAtMillis;
  final String rawJson;
  final int cachedAtMillis;
  const CachedHistoryPoint(
      {required this.cacheKey,
      required this.vehicleId,
      required this.imei,
      required this.latitude,
      required this.longitude,
      this.speedKph,
      this.heading,
      this.ignition,
      required this.recordedAtMillis,
      required this.rawJson,
      required this.cachedAtMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['imei'] = Variable<String>(imei);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || speedKph != null) {
      map['speed_kph'] = Variable<double>(speedKph);
    }
    if (!nullToAbsent || heading != null) {
      map['heading'] = Variable<double>(heading);
    }
    if (!nullToAbsent || ignition != null) {
      map['ignition'] = Variable<bool>(ignition);
    }
    map['recorded_at_millis'] = Variable<int>(recordedAtMillis);
    map['raw_json'] = Variable<String>(rawJson);
    map['cached_at_millis'] = Variable<int>(cachedAtMillis);
    return map;
  }

  CachedHistoryPointsCompanion toCompanion(bool nullToAbsent) {
    return CachedHistoryPointsCompanion(
      cacheKey: Value(cacheKey),
      vehicleId: Value(vehicleId),
      imei: Value(imei),
      latitude: Value(latitude),
      longitude: Value(longitude),
      speedKph: speedKph == null && nullToAbsent
          ? const Value.absent()
          : Value(speedKph),
      heading: heading == null && nullToAbsent
          ? const Value.absent()
          : Value(heading),
      ignition: ignition == null && nullToAbsent
          ? const Value.absent()
          : Value(ignition),
      recordedAtMillis: Value(recordedAtMillis),
      rawJson: Value(rawJson),
      cachedAtMillis: Value(cachedAtMillis),
    );
  }

  factory CachedHistoryPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedHistoryPoint(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      imei: serializer.fromJson<String>(json['imei']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      speedKph: serializer.fromJson<double?>(json['speedKph']),
      heading: serializer.fromJson<double?>(json['heading']),
      ignition: serializer.fromJson<bool?>(json['ignition']),
      recordedAtMillis: serializer.fromJson<int>(json['recordedAtMillis']),
      rawJson: serializer.fromJson<String>(json['rawJson']),
      cachedAtMillis: serializer.fromJson<int>(json['cachedAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'imei': serializer.toJson<String>(imei),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'speedKph': serializer.toJson<double?>(speedKph),
      'heading': serializer.toJson<double?>(heading),
      'ignition': serializer.toJson<bool?>(ignition),
      'recordedAtMillis': serializer.toJson<int>(recordedAtMillis),
      'rawJson': serializer.toJson<String>(rawJson),
      'cachedAtMillis': serializer.toJson<int>(cachedAtMillis),
    };
  }

  CachedHistoryPoint copyWith(
          {String? cacheKey,
          String? vehicleId,
          String? imei,
          double? latitude,
          double? longitude,
          Value<double?> speedKph = const Value.absent(),
          Value<double?> heading = const Value.absent(),
          Value<bool?> ignition = const Value.absent(),
          int? recordedAtMillis,
          String? rawJson,
          int? cachedAtMillis}) =>
      CachedHistoryPoint(
        cacheKey: cacheKey ?? this.cacheKey,
        vehicleId: vehicleId ?? this.vehicleId,
        imei: imei ?? this.imei,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        speedKph: speedKph.present ? speedKph.value : this.speedKph,
        heading: heading.present ? heading.value : this.heading,
        ignition: ignition.present ? ignition.value : this.ignition,
        recordedAtMillis: recordedAtMillis ?? this.recordedAtMillis,
        rawJson: rawJson ?? this.rawJson,
        cachedAtMillis: cachedAtMillis ?? this.cachedAtMillis,
      );
  CachedHistoryPoint copyWithCompanion(CachedHistoryPointsCompanion data) {
    return CachedHistoryPoint(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      imei: data.imei.present ? data.imei.value : this.imei,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      speedKph: data.speedKph.present ? data.speedKph.value : this.speedKph,
      heading: data.heading.present ? data.heading.value : this.heading,
      ignition: data.ignition.present ? data.ignition.value : this.ignition,
      recordedAtMillis: data.recordedAtMillis.present
          ? data.recordedAtMillis.value
          : this.recordedAtMillis,
      rawJson: data.rawJson.present ? data.rawJson.value : this.rawJson,
      cachedAtMillis: data.cachedAtMillis.present
          ? data.cachedAtMillis.value
          : this.cachedAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedHistoryPoint(')
          ..write('cacheKey: $cacheKey, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('imei: $imei, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('speedKph: $speedKph, ')
          ..write('heading: $heading, ')
          ..write('ignition: $ignition, ')
          ..write('recordedAtMillis: $recordedAtMillis, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAtMillis: $cachedAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      cacheKey,
      vehicleId,
      imei,
      latitude,
      longitude,
      speedKph,
      heading,
      ignition,
      recordedAtMillis,
      rawJson,
      cachedAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedHistoryPoint &&
          other.cacheKey == this.cacheKey &&
          other.vehicleId == this.vehicleId &&
          other.imei == this.imei &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.speedKph == this.speedKph &&
          other.heading == this.heading &&
          other.ignition == this.ignition &&
          other.recordedAtMillis == this.recordedAtMillis &&
          other.rawJson == this.rawJson &&
          other.cachedAtMillis == this.cachedAtMillis);
}

class CachedHistoryPointsCompanion extends UpdateCompanion<CachedHistoryPoint> {
  final Value<String> cacheKey;
  final Value<String> vehicleId;
  final Value<String> imei;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> speedKph;
  final Value<double?> heading;
  final Value<bool?> ignition;
  final Value<int> recordedAtMillis;
  final Value<String> rawJson;
  final Value<int> cachedAtMillis;
  final Value<int> rowid;
  const CachedHistoryPointsCompanion({
    this.cacheKey = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.imei = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.speedKph = const Value.absent(),
    this.heading = const Value.absent(),
    this.ignition = const Value.absent(),
    this.recordedAtMillis = const Value.absent(),
    this.rawJson = const Value.absent(),
    this.cachedAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedHistoryPointsCompanion.insert({
    required String cacheKey,
    required String vehicleId,
    this.imei = const Value.absent(),
    required double latitude,
    required double longitude,
    this.speedKph = const Value.absent(),
    this.heading = const Value.absent(),
    this.ignition = const Value.absent(),
    required int recordedAtMillis,
    this.rawJson = const Value.absent(),
    required int cachedAtMillis,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        vehicleId = Value(vehicleId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        recordedAtMillis = Value(recordedAtMillis),
        cachedAtMillis = Value(cachedAtMillis);
  static Insertable<CachedHistoryPoint> custom({
    Expression<String>? cacheKey,
    Expression<String>? vehicleId,
    Expression<String>? imei,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? speedKph,
    Expression<double>? heading,
    Expression<bool>? ignition,
    Expression<int>? recordedAtMillis,
    Expression<String>? rawJson,
    Expression<int>? cachedAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (imei != null) 'imei': imei,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (speedKph != null) 'speed_kph': speedKph,
      if (heading != null) 'heading': heading,
      if (ignition != null) 'ignition': ignition,
      if (recordedAtMillis != null) 'recorded_at_millis': recordedAtMillis,
      if (rawJson != null) 'raw_json': rawJson,
      if (cachedAtMillis != null) 'cached_at_millis': cachedAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedHistoryPointsCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? vehicleId,
      Value<String>? imei,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double?>? speedKph,
      Value<double?>? heading,
      Value<bool?>? ignition,
      Value<int>? recordedAtMillis,
      Value<String>? rawJson,
      Value<int>? cachedAtMillis,
      Value<int>? rowid}) {
    return CachedHistoryPointsCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      vehicleId: vehicleId ?? this.vehicleId,
      imei: imei ?? this.imei,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKph: speedKph ?? this.speedKph,
      heading: heading ?? this.heading,
      ignition: ignition ?? this.ignition,
      recordedAtMillis: recordedAtMillis ?? this.recordedAtMillis,
      rawJson: rawJson ?? this.rawJson,
      cachedAtMillis: cachedAtMillis ?? this.cachedAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (imei.present) {
      map['imei'] = Variable<String>(imei.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (speedKph.present) {
      map['speed_kph'] = Variable<double>(speedKph.value);
    }
    if (heading.present) {
      map['heading'] = Variable<double>(heading.value);
    }
    if (ignition.present) {
      map['ignition'] = Variable<bool>(ignition.value);
    }
    if (recordedAtMillis.present) {
      map['recorded_at_millis'] = Variable<int>(recordedAtMillis.value);
    }
    if (rawJson.present) {
      map['raw_json'] = Variable<String>(rawJson.value);
    }
    if (cachedAtMillis.present) {
      map['cached_at_millis'] = Variable<int>(cachedAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedHistoryPointsCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('imei: $imei, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('speedKph: $speedKph, ')
          ..write('heading: $heading, ')
          ..write('ignition: $ignition, ')
          ..write('recordedAtMillis: $recordedAtMillis, ')
          ..write('rawJson: $rawJson, ')
          ..write('cachedAtMillis: $cachedAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CacheMetadataEntriesTable extends CacheMetadataEntries
    with TableInfo<$CacheMetadataEntriesTable, CacheMetadataEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _featureKeyMeta =
      const VerificationMeta('featureKey');
  @override
  late final GeneratedColumn<String> featureKey = GeneratedColumn<String>(
      'feature_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _environmentKeyMeta =
      const VerificationMeta('environmentKey');
  @override
  late final GeneratedColumn<String> environmentKey = GeneratedColumn<String>(
      'environment_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _queryHashMeta =
      const VerificationMeta('queryHash');
  @override
  late final GeneratedColumn<String> queryHash = GeneratedColumn<String>(
      'query_hash', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _itemCountMeta =
      const VerificationMeta('itemCount');
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
      'item_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMillisMeta =
      const VerificationMeta('createdAtMillis');
  @override
  late final GeneratedColumn<int> createdAtMillis = GeneratedColumn<int>(
      'created_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMillisMeta =
      const VerificationMeta('updatedAtMillis');
  @override
  late final GeneratedColumn<int> updatedAtMillis = GeneratedColumn<int>(
      'updated_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _staleAtMillisMeta =
      const VerificationMeta('staleAtMillis');
  @override
  late final GeneratedColumn<int> staleAtMillis = GeneratedColumn<int>(
      'stale_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMillisMeta =
      const VerificationMeta('expiresAtMillis');
  @override
  late final GeneratedColumn<int> expiresAtMillis = GeneratedColumn<int>(
      'expires_at_millis', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        cacheKey,
        featureKey,
        role,
        accountId,
        userId,
        environmentKey,
        queryHash,
        itemCount,
        createdAtMillis,
        updatedAtMillis,
        staleAtMillis,
        expiresAtMillis
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cache_metadata_entries';
  @override
  VerificationContext validateIntegrity(Insertable<CacheMetadataEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('feature_key')) {
      context.handle(
          _featureKeyMeta,
          featureKey.isAcceptableOrUnknown(
              data['feature_key']!, _featureKeyMeta));
    } else if (isInserting) {
      context.missing(_featureKeyMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('environment_key')) {
      context.handle(
          _environmentKeyMeta,
          environmentKey.isAcceptableOrUnknown(
              data['environment_key']!, _environmentKeyMeta));
    } else if (isInserting) {
      context.missing(_environmentKeyMeta);
    }
    if (data.containsKey('query_hash')) {
      context.handle(_queryHashMeta,
          queryHash.isAcceptableOrUnknown(data['query_hash']!, _queryHashMeta));
    }
    if (data.containsKey('item_count')) {
      context.handle(_itemCountMeta,
          itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta));
    }
    if (data.containsKey('created_at_millis')) {
      context.handle(
          _createdAtMillisMeta,
          createdAtMillis.isAcceptableOrUnknown(
              data['created_at_millis']!, _createdAtMillisMeta));
    } else if (isInserting) {
      context.missing(_createdAtMillisMeta);
    }
    if (data.containsKey('updated_at_millis')) {
      context.handle(
          _updatedAtMillisMeta,
          updatedAtMillis.isAcceptableOrUnknown(
              data['updated_at_millis']!, _updatedAtMillisMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMillisMeta);
    }
    if (data.containsKey('stale_at_millis')) {
      context.handle(
          _staleAtMillisMeta,
          staleAtMillis.isAcceptableOrUnknown(
              data['stale_at_millis']!, _staleAtMillisMeta));
    } else if (isInserting) {
      context.missing(_staleAtMillisMeta);
    }
    if (data.containsKey('expires_at_millis')) {
      context.handle(
          _expiresAtMillisMeta,
          expiresAtMillis.isAcceptableOrUnknown(
              data['expires_at_millis']!, _expiresAtMillisMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMillisMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  CacheMetadataEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetadataEntry(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      featureKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}feature_key'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      environmentKey: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}environment_key'])!,
      queryHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}query_hash'])!,
      itemCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}item_count'])!,
      createdAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_millis'])!,
      updatedAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at_millis'])!,
      staleAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stale_at_millis'])!,
      expiresAtMillis: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expires_at_millis'])!,
    );
  }

  @override
  $CacheMetadataEntriesTable createAlias(String alias) {
    return $CacheMetadataEntriesTable(attachedDatabase, alias);
  }
}

class CacheMetadataEntry extends DataClass
    implements Insertable<CacheMetadataEntry> {
  final String cacheKey;
  final String featureKey;
  final String role;
  final String accountId;
  final String userId;
  final String environmentKey;
  final String queryHash;
  final int itemCount;
  final int createdAtMillis;
  final int updatedAtMillis;
  final int staleAtMillis;
  final int expiresAtMillis;
  const CacheMetadataEntry(
      {required this.cacheKey,
      required this.featureKey,
      required this.role,
      required this.accountId,
      required this.userId,
      required this.environmentKey,
      required this.queryHash,
      required this.itemCount,
      required this.createdAtMillis,
      required this.updatedAtMillis,
      required this.staleAtMillis,
      required this.expiresAtMillis});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['feature_key'] = Variable<String>(featureKey);
    map['role'] = Variable<String>(role);
    map['account_id'] = Variable<String>(accountId);
    map['user_id'] = Variable<String>(userId);
    map['environment_key'] = Variable<String>(environmentKey);
    map['query_hash'] = Variable<String>(queryHash);
    map['item_count'] = Variable<int>(itemCount);
    map['created_at_millis'] = Variable<int>(createdAtMillis);
    map['updated_at_millis'] = Variable<int>(updatedAtMillis);
    map['stale_at_millis'] = Variable<int>(staleAtMillis);
    map['expires_at_millis'] = Variable<int>(expiresAtMillis);
    return map;
  }

  CacheMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return CacheMetadataEntriesCompanion(
      cacheKey: Value(cacheKey),
      featureKey: Value(featureKey),
      role: Value(role),
      accountId: Value(accountId),
      userId: Value(userId),
      environmentKey: Value(environmentKey),
      queryHash: Value(queryHash),
      itemCount: Value(itemCount),
      createdAtMillis: Value(createdAtMillis),
      updatedAtMillis: Value(updatedAtMillis),
      staleAtMillis: Value(staleAtMillis),
      expiresAtMillis: Value(expiresAtMillis),
    );
  }

  factory CacheMetadataEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetadataEntry(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      featureKey: serializer.fromJson<String>(json['featureKey']),
      role: serializer.fromJson<String>(json['role']),
      accountId: serializer.fromJson<String>(json['accountId']),
      userId: serializer.fromJson<String>(json['userId']),
      environmentKey: serializer.fromJson<String>(json['environmentKey']),
      queryHash: serializer.fromJson<String>(json['queryHash']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      createdAtMillis: serializer.fromJson<int>(json['createdAtMillis']),
      updatedAtMillis: serializer.fromJson<int>(json['updatedAtMillis']),
      staleAtMillis: serializer.fromJson<int>(json['staleAtMillis']),
      expiresAtMillis: serializer.fromJson<int>(json['expiresAtMillis']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'featureKey': serializer.toJson<String>(featureKey),
      'role': serializer.toJson<String>(role),
      'accountId': serializer.toJson<String>(accountId),
      'userId': serializer.toJson<String>(userId),
      'environmentKey': serializer.toJson<String>(environmentKey),
      'queryHash': serializer.toJson<String>(queryHash),
      'itemCount': serializer.toJson<int>(itemCount),
      'createdAtMillis': serializer.toJson<int>(createdAtMillis),
      'updatedAtMillis': serializer.toJson<int>(updatedAtMillis),
      'staleAtMillis': serializer.toJson<int>(staleAtMillis),
      'expiresAtMillis': serializer.toJson<int>(expiresAtMillis),
    };
  }

  CacheMetadataEntry copyWith(
          {String? cacheKey,
          String? featureKey,
          String? role,
          String? accountId,
          String? userId,
          String? environmentKey,
          String? queryHash,
          int? itemCount,
          int? createdAtMillis,
          int? updatedAtMillis,
          int? staleAtMillis,
          int? expiresAtMillis}) =>
      CacheMetadataEntry(
        cacheKey: cacheKey ?? this.cacheKey,
        featureKey: featureKey ?? this.featureKey,
        role: role ?? this.role,
        accountId: accountId ?? this.accountId,
        userId: userId ?? this.userId,
        environmentKey: environmentKey ?? this.environmentKey,
        queryHash: queryHash ?? this.queryHash,
        itemCount: itemCount ?? this.itemCount,
        createdAtMillis: createdAtMillis ?? this.createdAtMillis,
        updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
        staleAtMillis: staleAtMillis ?? this.staleAtMillis,
        expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      );
  CacheMetadataEntry copyWithCompanion(CacheMetadataEntriesCompanion data) {
    return CacheMetadataEntry(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      featureKey:
          data.featureKey.present ? data.featureKey.value : this.featureKey,
      role: data.role.present ? data.role.value : this.role,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      userId: data.userId.present ? data.userId.value : this.userId,
      environmentKey: data.environmentKey.present
          ? data.environmentKey.value
          : this.environmentKey,
      queryHash: data.queryHash.present ? data.queryHash.value : this.queryHash,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      createdAtMillis: data.createdAtMillis.present
          ? data.createdAtMillis.value
          : this.createdAtMillis,
      updatedAtMillis: data.updatedAtMillis.present
          ? data.updatedAtMillis.value
          : this.updatedAtMillis,
      staleAtMillis: data.staleAtMillis.present
          ? data.staleAtMillis.value
          : this.staleAtMillis,
      expiresAtMillis: data.expiresAtMillis.present
          ? data.expiresAtMillis.value
          : this.expiresAtMillis,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataEntry(')
          ..write('cacheKey: $cacheKey, ')
          ..write('featureKey: $featureKey, ')
          ..write('role: $role, ')
          ..write('accountId: $accountId, ')
          ..write('userId: $userId, ')
          ..write('environmentKey: $environmentKey, ')
          ..write('queryHash: $queryHash, ')
          ..write('itemCount: $itemCount, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('staleAtMillis: $staleAtMillis, ')
          ..write('expiresAtMillis: $expiresAtMillis')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      cacheKey,
      featureKey,
      role,
      accountId,
      userId,
      environmentKey,
      queryHash,
      itemCount,
      createdAtMillis,
      updatedAtMillis,
      staleAtMillis,
      expiresAtMillis);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheMetadataEntry &&
          other.cacheKey == this.cacheKey &&
          other.featureKey == this.featureKey &&
          other.role == this.role &&
          other.accountId == this.accountId &&
          other.userId == this.userId &&
          other.environmentKey == this.environmentKey &&
          other.queryHash == this.queryHash &&
          other.itemCount == this.itemCount &&
          other.createdAtMillis == this.createdAtMillis &&
          other.updatedAtMillis == this.updatedAtMillis &&
          other.staleAtMillis == this.staleAtMillis &&
          other.expiresAtMillis == this.expiresAtMillis);
}

class CacheMetadataEntriesCompanion
    extends UpdateCompanion<CacheMetadataEntry> {
  final Value<String> cacheKey;
  final Value<String> featureKey;
  final Value<String> role;
  final Value<String> accountId;
  final Value<String> userId;
  final Value<String> environmentKey;
  final Value<String> queryHash;
  final Value<int> itemCount;
  final Value<int> createdAtMillis;
  final Value<int> updatedAtMillis;
  final Value<int> staleAtMillis;
  final Value<int> expiresAtMillis;
  final Value<int> rowid;
  const CacheMetadataEntriesCompanion({
    this.cacheKey = const Value.absent(),
    this.featureKey = const Value.absent(),
    this.role = const Value.absent(),
    this.accountId = const Value.absent(),
    this.userId = const Value.absent(),
    this.environmentKey = const Value.absent(),
    this.queryHash = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.createdAtMillis = const Value.absent(),
    this.updatedAtMillis = const Value.absent(),
    this.staleAtMillis = const Value.absent(),
    this.expiresAtMillis = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetadataEntriesCompanion.insert({
    required String cacheKey,
    required String featureKey,
    required String role,
    required String accountId,
    required String userId,
    required String environmentKey,
    this.queryHash = const Value.absent(),
    this.itemCount = const Value.absent(),
    required int createdAtMillis,
    required int updatedAtMillis,
    required int staleAtMillis,
    required int expiresAtMillis,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        featureKey = Value(featureKey),
        role = Value(role),
        accountId = Value(accountId),
        userId = Value(userId),
        environmentKey = Value(environmentKey),
        createdAtMillis = Value(createdAtMillis),
        updatedAtMillis = Value(updatedAtMillis),
        staleAtMillis = Value(staleAtMillis),
        expiresAtMillis = Value(expiresAtMillis);
  static Insertable<CacheMetadataEntry> custom({
    Expression<String>? cacheKey,
    Expression<String>? featureKey,
    Expression<String>? role,
    Expression<String>? accountId,
    Expression<String>? userId,
    Expression<String>? environmentKey,
    Expression<String>? queryHash,
    Expression<int>? itemCount,
    Expression<int>? createdAtMillis,
    Expression<int>? updatedAtMillis,
    Expression<int>? staleAtMillis,
    Expression<int>? expiresAtMillis,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (featureKey != null) 'feature_key': featureKey,
      if (role != null) 'role': role,
      if (accountId != null) 'account_id': accountId,
      if (userId != null) 'user_id': userId,
      if (environmentKey != null) 'environment_key': environmentKey,
      if (queryHash != null) 'query_hash': queryHash,
      if (itemCount != null) 'item_count': itemCount,
      if (createdAtMillis != null) 'created_at_millis': createdAtMillis,
      if (updatedAtMillis != null) 'updated_at_millis': updatedAtMillis,
      if (staleAtMillis != null) 'stale_at_millis': staleAtMillis,
      if (expiresAtMillis != null) 'expires_at_millis': expiresAtMillis,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CacheMetadataEntriesCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? featureKey,
      Value<String>? role,
      Value<String>? accountId,
      Value<String>? userId,
      Value<String>? environmentKey,
      Value<String>? queryHash,
      Value<int>? itemCount,
      Value<int>? createdAtMillis,
      Value<int>? updatedAtMillis,
      Value<int>? staleAtMillis,
      Value<int>? expiresAtMillis,
      Value<int>? rowid}) {
    return CacheMetadataEntriesCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      featureKey: featureKey ?? this.featureKey,
      role: role ?? this.role,
      accountId: accountId ?? this.accountId,
      userId: userId ?? this.userId,
      environmentKey: environmentKey ?? this.environmentKey,
      queryHash: queryHash ?? this.queryHash,
      itemCount: itemCount ?? this.itemCount,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      updatedAtMillis: updatedAtMillis ?? this.updatedAtMillis,
      staleAtMillis: staleAtMillis ?? this.staleAtMillis,
      expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (featureKey.present) {
      map['feature_key'] = Variable<String>(featureKey.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (environmentKey.present) {
      map['environment_key'] = Variable<String>(environmentKey.value);
    }
    if (queryHash.present) {
      map['query_hash'] = Variable<String>(queryHash.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (createdAtMillis.present) {
      map['created_at_millis'] = Variable<int>(createdAtMillis.value);
    }
    if (updatedAtMillis.present) {
      map['updated_at_millis'] = Variable<int>(updatedAtMillis.value);
    }
    if (staleAtMillis.present) {
      map['stale_at_millis'] = Variable<int>(staleAtMillis.value);
    }
    if (expiresAtMillis.present) {
      map['expires_at_millis'] = Variable<int>(expiresAtMillis.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetadataEntriesCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('featureKey: $featureKey, ')
          ..write('role: $role, ')
          ..write('accountId: $accountId, ')
          ..write('userId: $userId, ')
          ..write('environmentKey: $environmentKey, ')
          ..write('queryHash: $queryHash, ')
          ..write('itemCount: $itemCount, ')
          ..write('createdAtMillis: $createdAtMillis, ')
          ..write('updatedAtMillis: $updatedAtMillis, ')
          ..write('staleAtMillis: $staleAtMillis, ')
          ..write('expiresAtMillis: $expiresAtMillis, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedVehiclesTable cachedVehicles = $CachedVehiclesTable(this);
  late final $CachedHistoryPointsTable cachedHistoryPoints =
      $CachedHistoryPointsTable(this);
  late final $CacheMetadataEntriesTable cacheMetadataEntries =
      $CacheMetadataEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cachedVehicles, cachedHistoryPoints, cacheMetadataEntries];
}

typedef $$CachedVehiclesTableCreateCompanionBuilder = CachedVehiclesCompanion
    Function({
  required String cacheKey,
  required String vehicleId,
  Value<String> name,
  Value<String> plateNumber,
  Value<String> imei,
  Value<String> status,
  Value<String> rawJson,
  Value<int> page,
  Value<int> limit,
  Value<int> total,
  Value<int> sortOrder,
  required int cachedAtMillis,
  required int staleAtMillis,
  required int expiresAtMillis,
  Value<int> rowid,
});
typedef $$CachedVehiclesTableUpdateCompanionBuilder = CachedVehiclesCompanion
    Function({
  Value<String> cacheKey,
  Value<String> vehicleId,
  Value<String> name,
  Value<String> plateNumber,
  Value<String> imei,
  Value<String> status,
  Value<String> rawJson,
  Value<int> page,
  Value<int> limit,
  Value<int> total,
  Value<int> sortOrder,
  Value<int> cachedAtMillis,
  Value<int> staleAtMillis,
  Value<int> expiresAtMillis,
  Value<int> rowid,
});

class $$CachedVehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vehicleId => $composableBuilder(
      column: $table.vehicleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get plateNumber => $composableBuilder(
      column: $table.plateNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imei => $composableBuilder(
      column: $table.imei, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get limit => $composableBuilder(
      column: $table.limit, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis,
      builder: (column) => ColumnFilters(column));
}

class $$CachedVehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vehicleId => $composableBuilder(
      column: $table.vehicleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plateNumber => $composableBuilder(
      column: $table.plateNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imei => $composableBuilder(
      column: $table.imei, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get page => $composableBuilder(
      column: $table.page, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get limit => $composableBuilder(
      column: $table.limit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get total => $composableBuilder(
      column: $table.total, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedVehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedVehiclesTable> {
  $$CachedVehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get plateNumber => $composableBuilder(
      column: $table.plateNumber, builder: (column) => column);

  GeneratedColumn<String> get imei =>
      $composableBuilder(column: $table.imei, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get limit =>
      $composableBuilder(column: $table.limit, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis, builder: (column) => column);

  GeneratedColumn<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis, builder: (column) => column);
}

class $$CachedVehiclesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedVehiclesTable,
    CachedVehicle,
    $$CachedVehiclesTableFilterComposer,
    $$CachedVehiclesTableOrderingComposer,
    $$CachedVehiclesTableAnnotationComposer,
    $$CachedVehiclesTableCreateCompanionBuilder,
    $$CachedVehiclesTableUpdateCompanionBuilder,
    (
      CachedVehicle,
      BaseReferences<_$AppDatabase, $CachedVehiclesTable, CachedVehicle>
    ),
    CachedVehicle,
    PrefetchHooks Function()> {
  $$CachedVehiclesTableTableManager(
      _$AppDatabase db, $CachedVehiclesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedVehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedVehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedVehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> vehicleId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> plateNumber = const Value.absent(),
            Value<String> imei = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<int> limit = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> cachedAtMillis = const Value.absent(),
            Value<int> staleAtMillis = const Value.absent(),
            Value<int> expiresAtMillis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedVehiclesCompanion(
            cacheKey: cacheKey,
            vehicleId: vehicleId,
            name: name,
            plateNumber: plateNumber,
            imei: imei,
            status: status,
            rawJson: rawJson,
            page: page,
            limit: limit,
            total: total,
            sortOrder: sortOrder,
            cachedAtMillis: cachedAtMillis,
            staleAtMillis: staleAtMillis,
            expiresAtMillis: expiresAtMillis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String vehicleId,
            Value<String> name = const Value.absent(),
            Value<String> plateNumber = const Value.absent(),
            Value<String> imei = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<int> page = const Value.absent(),
            Value<int> limit = const Value.absent(),
            Value<int> total = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            required int cachedAtMillis,
            required int staleAtMillis,
            required int expiresAtMillis,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedVehiclesCompanion.insert(
            cacheKey: cacheKey,
            vehicleId: vehicleId,
            name: name,
            plateNumber: plateNumber,
            imei: imei,
            status: status,
            rawJson: rawJson,
            page: page,
            limit: limit,
            total: total,
            sortOrder: sortOrder,
            cachedAtMillis: cachedAtMillis,
            staleAtMillis: staleAtMillis,
            expiresAtMillis: expiresAtMillis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedVehiclesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedVehiclesTable,
    CachedVehicle,
    $$CachedVehiclesTableFilterComposer,
    $$CachedVehiclesTableOrderingComposer,
    $$CachedVehiclesTableAnnotationComposer,
    $$CachedVehiclesTableCreateCompanionBuilder,
    $$CachedVehiclesTableUpdateCompanionBuilder,
    (
      CachedVehicle,
      BaseReferences<_$AppDatabase, $CachedVehiclesTable, CachedVehicle>
    ),
    CachedVehicle,
    PrefetchHooks Function()>;
typedef $$CachedHistoryPointsTableCreateCompanionBuilder
    = CachedHistoryPointsCompanion Function({
  required String cacheKey,
  required String vehicleId,
  Value<String> imei,
  required double latitude,
  required double longitude,
  Value<double?> speedKph,
  Value<double?> heading,
  Value<bool?> ignition,
  required int recordedAtMillis,
  Value<String> rawJson,
  required int cachedAtMillis,
  Value<int> rowid,
});
typedef $$CachedHistoryPointsTableUpdateCompanionBuilder
    = CachedHistoryPointsCompanion Function({
  Value<String> cacheKey,
  Value<String> vehicleId,
  Value<String> imei,
  Value<double> latitude,
  Value<double> longitude,
  Value<double?> speedKph,
  Value<double?> heading,
  Value<bool?> ignition,
  Value<int> recordedAtMillis,
  Value<String> rawJson,
  Value<int> cachedAtMillis,
  Value<int> rowid,
});

class $$CachedHistoryPointsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedHistoryPointsTable> {
  $$CachedHistoryPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vehicleId => $composableBuilder(
      column: $table.vehicleId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imei => $composableBuilder(
      column: $table.imei, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get speedKph => $composableBuilder(
      column: $table.speedKph, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get heading => $composableBuilder(
      column: $table.heading, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ignition => $composableBuilder(
      column: $table.ignition, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get recordedAtMillis => $composableBuilder(
      column: $table.recordedAtMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis,
      builder: (column) => ColumnFilters(column));
}

class $$CachedHistoryPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedHistoryPointsTable> {
  $$CachedHistoryPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vehicleId => $composableBuilder(
      column: $table.vehicleId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imei => $composableBuilder(
      column: $table.imei, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get speedKph => $composableBuilder(
      column: $table.speedKph, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get heading => $composableBuilder(
      column: $table.heading, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ignition => $composableBuilder(
      column: $table.ignition, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get recordedAtMillis => $composableBuilder(
      column: $table.recordedAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawJson => $composableBuilder(
      column: $table.rawJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$CachedHistoryPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedHistoryPointsTable> {
  $$CachedHistoryPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get vehicleId =>
      $composableBuilder(column: $table.vehicleId, builder: (column) => column);

  GeneratedColumn<String> get imei =>
      $composableBuilder(column: $table.imei, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get speedKph =>
      $composableBuilder(column: $table.speedKph, builder: (column) => column);

  GeneratedColumn<double> get heading =>
      $composableBuilder(column: $table.heading, builder: (column) => column);

  GeneratedColumn<bool> get ignition =>
      $composableBuilder(column: $table.ignition, builder: (column) => column);

  GeneratedColumn<int> get recordedAtMillis => $composableBuilder(
      column: $table.recordedAtMillis, builder: (column) => column);

  GeneratedColumn<String> get rawJson =>
      $composableBuilder(column: $table.rawJson, builder: (column) => column);

  GeneratedColumn<int> get cachedAtMillis => $composableBuilder(
      column: $table.cachedAtMillis, builder: (column) => column);
}

class $$CachedHistoryPointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedHistoryPointsTable,
    CachedHistoryPoint,
    $$CachedHistoryPointsTableFilterComposer,
    $$CachedHistoryPointsTableOrderingComposer,
    $$CachedHistoryPointsTableAnnotationComposer,
    $$CachedHistoryPointsTableCreateCompanionBuilder,
    $$CachedHistoryPointsTableUpdateCompanionBuilder,
    (
      CachedHistoryPoint,
      BaseReferences<_$AppDatabase, $CachedHistoryPointsTable,
          CachedHistoryPoint>
    ),
    CachedHistoryPoint,
    PrefetchHooks Function()> {
  $$CachedHistoryPointsTableTableManager(
      _$AppDatabase db, $CachedHistoryPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedHistoryPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedHistoryPointsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedHistoryPointsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> vehicleId = const Value.absent(),
            Value<String> imei = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double?> speedKph = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<bool?> ignition = const Value.absent(),
            Value<int> recordedAtMillis = const Value.absent(),
            Value<String> rawJson = const Value.absent(),
            Value<int> cachedAtMillis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedHistoryPointsCompanion(
            cacheKey: cacheKey,
            vehicleId: vehicleId,
            imei: imei,
            latitude: latitude,
            longitude: longitude,
            speedKph: speedKph,
            heading: heading,
            ignition: ignition,
            recordedAtMillis: recordedAtMillis,
            rawJson: rawJson,
            cachedAtMillis: cachedAtMillis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String vehicleId,
            Value<String> imei = const Value.absent(),
            required double latitude,
            required double longitude,
            Value<double?> speedKph = const Value.absent(),
            Value<double?> heading = const Value.absent(),
            Value<bool?> ignition = const Value.absent(),
            required int recordedAtMillis,
            Value<String> rawJson = const Value.absent(),
            required int cachedAtMillis,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedHistoryPointsCompanion.insert(
            cacheKey: cacheKey,
            vehicleId: vehicleId,
            imei: imei,
            latitude: latitude,
            longitude: longitude,
            speedKph: speedKph,
            heading: heading,
            ignition: ignition,
            recordedAtMillis: recordedAtMillis,
            rawJson: rawJson,
            cachedAtMillis: cachedAtMillis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedHistoryPointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedHistoryPointsTable,
    CachedHistoryPoint,
    $$CachedHistoryPointsTableFilterComposer,
    $$CachedHistoryPointsTableOrderingComposer,
    $$CachedHistoryPointsTableAnnotationComposer,
    $$CachedHistoryPointsTableCreateCompanionBuilder,
    $$CachedHistoryPointsTableUpdateCompanionBuilder,
    (
      CachedHistoryPoint,
      BaseReferences<_$AppDatabase, $CachedHistoryPointsTable,
          CachedHistoryPoint>
    ),
    CachedHistoryPoint,
    PrefetchHooks Function()>;
typedef $$CacheMetadataEntriesTableCreateCompanionBuilder
    = CacheMetadataEntriesCompanion Function({
  required String cacheKey,
  required String featureKey,
  required String role,
  required String accountId,
  required String userId,
  required String environmentKey,
  Value<String> queryHash,
  Value<int> itemCount,
  required int createdAtMillis,
  required int updatedAtMillis,
  required int staleAtMillis,
  required int expiresAtMillis,
  Value<int> rowid,
});
typedef $$CacheMetadataEntriesTableUpdateCompanionBuilder
    = CacheMetadataEntriesCompanion Function({
  Value<String> cacheKey,
  Value<String> featureKey,
  Value<String> role,
  Value<String> accountId,
  Value<String> userId,
  Value<String> environmentKey,
  Value<String> queryHash,
  Value<int> itemCount,
  Value<int> createdAtMillis,
  Value<int> updatedAtMillis,
  Value<int> staleAtMillis,
  Value<int> expiresAtMillis,
  Value<int> rowid,
});

class $$CacheMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CacheMetadataEntriesTable> {
  $$CacheMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get environmentKey => $composableBuilder(
      column: $table.environmentKey,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get itemCount => $composableBuilder(
      column: $table.itemCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMillis => $composableBuilder(
      column: $table.createdAtMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAtMillis => $composableBuilder(
      column: $table.updatedAtMillis,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis,
      builder: (column) => ColumnFilters(column));
}

class $$CacheMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CacheMetadataEntriesTable> {
  $$CacheMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get accountId => $composableBuilder(
      column: $table.accountId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get environmentKey => $composableBuilder(
      column: $table.environmentKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get queryHash => $composableBuilder(
      column: $table.queryHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get itemCount => $composableBuilder(
      column: $table.itemCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMillis => $composableBuilder(
      column: $table.createdAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAtMillis => $composableBuilder(
      column: $table.updatedAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis,
      builder: (column) => ColumnOrderings(column));
}

class $$CacheMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CacheMetadataEntriesTable> {
  $$CacheMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get featureKey => $composableBuilder(
      column: $table.featureKey, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get environmentKey => $composableBuilder(
      column: $table.environmentKey, builder: (column) => column);

  GeneratedColumn<String> get queryHash =>
      $composableBuilder(column: $table.queryHash, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<int> get createdAtMillis => $composableBuilder(
      column: $table.createdAtMillis, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMillis => $composableBuilder(
      column: $table.updatedAtMillis, builder: (column) => column);

  GeneratedColumn<int> get staleAtMillis => $composableBuilder(
      column: $table.staleAtMillis, builder: (column) => column);

  GeneratedColumn<int> get expiresAtMillis => $composableBuilder(
      column: $table.expiresAtMillis, builder: (column) => column);
}

class $$CacheMetadataEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CacheMetadataEntriesTable,
    CacheMetadataEntry,
    $$CacheMetadataEntriesTableFilterComposer,
    $$CacheMetadataEntriesTableOrderingComposer,
    $$CacheMetadataEntriesTableAnnotationComposer,
    $$CacheMetadataEntriesTableCreateCompanionBuilder,
    $$CacheMetadataEntriesTableUpdateCompanionBuilder,
    (
      CacheMetadataEntry,
      BaseReferences<_$AppDatabase, $CacheMetadataEntriesTable,
          CacheMetadataEntry>
    ),
    CacheMetadataEntry,
    PrefetchHooks Function()> {
  $$CacheMetadataEntriesTableTableManager(
      _$AppDatabase db, $CacheMetadataEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CacheMetadataEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CacheMetadataEntriesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetadataEntriesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> featureKey = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String> accountId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> environmentKey = const Value.absent(),
            Value<String> queryHash = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            Value<int> createdAtMillis = const Value.absent(),
            Value<int> updatedAtMillis = const Value.absent(),
            Value<int> staleAtMillis = const Value.absent(),
            Value<int> expiresAtMillis = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheMetadataEntriesCompanion(
            cacheKey: cacheKey,
            featureKey: featureKey,
            role: role,
            accountId: accountId,
            userId: userId,
            environmentKey: environmentKey,
            queryHash: queryHash,
            itemCount: itemCount,
            createdAtMillis: createdAtMillis,
            updatedAtMillis: updatedAtMillis,
            staleAtMillis: staleAtMillis,
            expiresAtMillis: expiresAtMillis,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String featureKey,
            required String role,
            required String accountId,
            required String userId,
            required String environmentKey,
            Value<String> queryHash = const Value.absent(),
            Value<int> itemCount = const Value.absent(),
            required int createdAtMillis,
            required int updatedAtMillis,
            required int staleAtMillis,
            required int expiresAtMillis,
            Value<int> rowid = const Value.absent(),
          }) =>
              CacheMetadataEntriesCompanion.insert(
            cacheKey: cacheKey,
            featureKey: featureKey,
            role: role,
            accountId: accountId,
            userId: userId,
            environmentKey: environmentKey,
            queryHash: queryHash,
            itemCount: itemCount,
            createdAtMillis: createdAtMillis,
            updatedAtMillis: updatedAtMillis,
            staleAtMillis: staleAtMillis,
            expiresAtMillis: expiresAtMillis,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CacheMetadataEntriesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CacheMetadataEntriesTable,
        CacheMetadataEntry,
        $$CacheMetadataEntriesTableFilterComposer,
        $$CacheMetadataEntriesTableOrderingComposer,
        $$CacheMetadataEntriesTableAnnotationComposer,
        $$CacheMetadataEntriesTableCreateCompanionBuilder,
        $$CacheMetadataEntriesTableUpdateCompanionBuilder,
        (
          CacheMetadataEntry,
          BaseReferences<_$AppDatabase, $CacheMetadataEntriesTable,
              CacheMetadataEntry>
        ),
        CacheMetadataEntry,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedVehiclesTableTableManager get cachedVehicles =>
      $$CachedVehiclesTableTableManager(_db, _db.cachedVehicles);
  $$CachedHistoryPointsTableTableManager get cachedHistoryPoints =>
      $$CachedHistoryPointsTableTableManager(_db, _db.cachedHistoryPoints);
  $$CacheMetadataEntriesTableTableManager get cacheMetadataEntries =>
      $$CacheMetadataEntriesTableTableManager(_db, _db.cacheMetadataEntries);
}
