// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_riverpod_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supportTicketNotifierHash() =>
    r'3039360bb3155c8bec3adf1d11fcd220a3a73316';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$SupportTicketNotifier
    extends BuildlessAutoDisposeNotifier<SupportTicketState> {
  late final SupportRole role;

  SupportTicketState build(
    SupportRole role,
  );
}

/// See also [SupportTicketNotifier].
@ProviderFor(SupportTicketNotifier)
const supportTicketNotifierProvider = SupportTicketNotifierFamily();

/// See also [SupportTicketNotifier].
class SupportTicketNotifierFamily extends Family<SupportTicketState> {
  /// See also [SupportTicketNotifier].
  const SupportTicketNotifierFamily();

  /// See also [SupportTicketNotifier].
  SupportTicketNotifierProvider call(
    SupportRole role,
  ) {
    return SupportTicketNotifierProvider(
      role,
    );
  }

  @override
  SupportTicketNotifierProvider getProviderOverride(
    covariant SupportTicketNotifierProvider provider,
  ) {
    return call(
      provider.role,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'supportTicketNotifierProvider';
}

/// See also [SupportTicketNotifier].
class SupportTicketNotifierProvider extends AutoDisposeNotifierProviderImpl<
    SupportTicketNotifier, SupportTicketState> {
  /// See also [SupportTicketNotifier].
  SupportTicketNotifierProvider(
    SupportRole role,
  ) : this._internal(
          () => SupportTicketNotifier()..role = role,
          from: supportTicketNotifierProvider,
          name: r'supportTicketNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$supportTicketNotifierHash,
          dependencies: SupportTicketNotifierFamily._dependencies,
          allTransitiveDependencies:
              SupportTicketNotifierFamily._allTransitiveDependencies,
          role: role,
        );

  SupportTicketNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.role,
  }) : super.internal();

  final SupportRole role;

  @override
  SupportTicketState runNotifierBuild(
    covariant SupportTicketNotifier notifier,
  ) {
    return notifier.build(
      role,
    );
  }

  @override
  Override overrideWith(SupportTicketNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: SupportTicketNotifierProvider._internal(
        () => create()..role = role,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        role: role,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<SupportTicketNotifier, SupportTicketState>
      createElement() {
    return _SupportTicketNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupportTicketNotifierProvider && other.role == role;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, role.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SupportTicketNotifierRef
    on AutoDisposeNotifierProviderRef<SupportTicketState> {
  /// The parameter `role` of this provider.
  SupportRole get role;
}

class _SupportTicketNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<SupportTicketNotifier,
        SupportTicketState> with SupportTicketNotifierRef {
  _SupportTicketNotifierProviderElement(super.provider);

  @override
  SupportRole get role => (origin as SupportTicketNotifierProvider).role;
}

String _$newTicketFormNotifierHash() =>
    r'15070e039566842fca4b3c171309551256576973';

abstract class _$NewTicketFormNotifier
    extends BuildlessAutoDisposeNotifier<NewTicketState> {
  late final SupportRole role;

  NewTicketState build(
    SupportRole role,
  );
}

/// See also [NewTicketFormNotifier].
@ProviderFor(NewTicketFormNotifier)
const newTicketFormNotifierProvider = NewTicketFormNotifierFamily();

/// See also [NewTicketFormNotifier].
class NewTicketFormNotifierFamily extends Family<NewTicketState> {
  /// See also [NewTicketFormNotifier].
  const NewTicketFormNotifierFamily();

  /// See also [NewTicketFormNotifier].
  NewTicketFormNotifierProvider call(
    SupportRole role,
  ) {
    return NewTicketFormNotifierProvider(
      role,
    );
  }

  @override
  NewTicketFormNotifierProvider getProviderOverride(
    covariant NewTicketFormNotifierProvider provider,
  ) {
    return call(
      provider.role,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'newTicketFormNotifierProvider';
}

/// See also [NewTicketFormNotifier].
class NewTicketFormNotifierProvider extends AutoDisposeNotifierProviderImpl<
    NewTicketFormNotifier, NewTicketState> {
  /// See also [NewTicketFormNotifier].
  NewTicketFormNotifierProvider(
    SupportRole role,
  ) : this._internal(
          () => NewTicketFormNotifier()..role = role,
          from: newTicketFormNotifierProvider,
          name: r'newTicketFormNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$newTicketFormNotifierHash,
          dependencies: NewTicketFormNotifierFamily._dependencies,
          allTransitiveDependencies:
              NewTicketFormNotifierFamily._allTransitiveDependencies,
          role: role,
        );

  NewTicketFormNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.role,
  }) : super.internal();

  final SupportRole role;

  @override
  NewTicketState runNotifierBuild(
    covariant NewTicketFormNotifier notifier,
  ) {
    return notifier.build(
      role,
    );
  }

  @override
  Override overrideWith(NewTicketFormNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NewTicketFormNotifierProvider._internal(
        () => create()..role = role,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        role: role,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<NewTicketFormNotifier, NewTicketState>
      createElement() {
    return _NewTicketFormNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewTicketFormNotifierProvider && other.role == role;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, role.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NewTicketFormNotifierRef
    on AutoDisposeNotifierProviderRef<NewTicketState> {
  /// The parameter `role` of this provider.
  SupportRole get role;
}

class _NewTicketFormNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<NewTicketFormNotifier,
        NewTicketState> with NewTicketFormNotifierRef {
  _NewTicketFormNotifierProviderElement(super.provider);

  @override
  SupportRole get role => (origin as NewTicketFormNotifierProvider).role;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
