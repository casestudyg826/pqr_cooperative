import 'dart:async';

import 'package:flutter/widgets.dart';

import '../backend/backend_api.dart';
import '../backend/supabase_backend_api.dart';
import 'auth_controller.dart';
import 'loan_controller.dart';
import 'member_controller.dart';
import 'pdf_report_controller.dart';
import 'report_controller.dart';
import 'savings_controller.dart';

class AppController extends ChangeNotifier {
  AppController({BackendApi? backend})
    : backend = backend ?? SupabaseBackendApi.fromEnvironment() {
    auth = AuthController(this.backend, _requireSessionToken);
    members = MemberController(this.backend, _requireSessionToken);
    savings = SavingsController(this.backend, _requireSessionToken);
    loans = LoanController(this.backend, _requireSessionToken);

    auth.addListener(notifyListeners);
    members.addListener(notifyListeners);
    savings.addListener(notifyListeners);
    loans.addListener(notifyListeners);
  }

  final BackendApi backend;
  late final AuthController auth;
  late final MemberController members;
  late final SavingsController savings;
  late final LoanController loans;
  final ReportController reports = ReportController();
  final PdfReportController pdfReports = PdfReportController();
  final List<BackupRun> _backupRuns = [];

  List<BackupRun> get backupRuns => List.unmodifiable(_backupRuns);

  Future<bool> login(String username, String password) async {
    final loggedIn = await auth.login(username, password);
    if (!loggedIn) {
      return false;
    }

    await _loadAuthenticatedSnapshot();
    return true;
  }

  Future<bool> signUpMember({
    required String fullName,
    required String address,
    required String phone,
    required String username,
    required String password,
  }) async {
    final signedUp = await auth.signUpMember(
      fullName: fullName,
      address: address,
      phone: phone,
      username: username,
      password: password,
    );
    if (!signedUp) {
      return false;
    }

    await _loadAuthenticatedSnapshot();
    return true;
  }

  void logout() {
    final token = auth.sessionToken;
    auth.logout();
    members.replaceAll([]);
    savings.replaceAll([]);
    loans.replaceAll([]);
    _backupRuns.clear();
    notifyListeners();

    if (token != null) {
      unawaited(backend.logout(token));
    }
  }

  Future<BackupRun> runBackup() async {
    final backup = await backend.runBackup(_requireSessionToken());
    _backupRuns.insert(0, backup);
    notifyListeners();
    return backup;
  }

  Future<void> _loadAuthenticatedSnapshot() async {
    final snapshot = await backend.bootstrap(_requireSessionToken());
    auth.replaceUsers(snapshot.users);
    members.replaceAll(snapshot.members);
    savings.replaceAll(snapshot.savingsTransactions);
    loans.replaceAll(snapshot.loans);
    _backupRuns
      ..clear()
      ..addAll(snapshot.backupRuns);
    notifyListeners();
  }

  String _requireSessionToken() {
    final token = auth.sessionToken;
    if (token == null) {
      throw const BackendException('Please sign in again.');
    }
    return token;
  }

  @override
  void dispose() {
    auth.removeListener(notifyListeners);
    members.removeListener(notifyListeners);
    savings.removeListener(notifyListeners);
    loans.removeListener(notifyListeners);
    auth.dispose();
    members.dispose();
    savings.dispose();
    loans.dispose();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    required AppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
