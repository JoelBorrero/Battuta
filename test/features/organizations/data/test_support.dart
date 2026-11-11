import 'dart:async';

import 'package:battuta/core/database/app_database.dart';
import 'package:battuta/features/organizations/data/organization_repertoire_remote_data_source.dart';
import 'package:battuta/features/organizations/data/organizations_local_cache.dart';
import 'package:battuta/features/organizations/data/organizations_remote_data_source.dart';
import 'package:battuta/features/organizations/data/schedules_remote_data_source.dart';
import 'package:battuta/features/organizations/domain/repositories/account_session.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

class MockOrganizationsRemote extends Mock
    implements OrganizationsRemoteDataSource {}

class MockRepertoireRemote extends Mock
    implements OrganizationRepertoireRemoteDataSource {}

class MockSchedulesRemote extends Mock implements SchedulesRemoteDataSource {}

/// A session whose account is changed by the test; [signIn] also emits.
class FakeSession implements AccountSession {
  FakeSession([this._userId]);

  String? _userId;
  final _controller = StreamController<String?>.broadcast();

  @override
  String? get userId => _userId;

  @override
  Stream<String?> get userIdChanges => _controller.stream;

  @override
  Future<void> signOut() async => signIn(null);

  void signIn(String? id) {
    _userId = id;
    _controller.add(id);
  }
}

AppDatabase newMemoryDb() => AppDatabase(NativeDatabase.memory());

OrganizationsLocalCache newCache(AppDatabase db, [AccountSession? session]) =>
    OrganizationsLocalCache(
      db,
      currentAccount: session == null ? null : () => session.userId,
    );
