import 'dart:convert';

import 'package:http/http.dart' as http;

import 'backend_api.dart';
import 'memory_backend_api.dart';
import '../module/app_user.dart';
import '../module/loan.dart';
import '../module/member.dart';
import '../module/repayment.dart';
import '../module/savings_transaction.dart';

class SupabaseBackendApi implements BackendApi {
  SupabaseBackendApi({
    required String supabaseUrl,
    String functionSlug = 'pqr-api',
    http.Client? client,
  }) : _endpoint = Uri.parse(
         '${supabaseUrl.replaceAll(RegExp(r'/$'), '')}/functions/v1/$functionSlug/',
       ),
       _client = client ?? http.Client();

  static BackendApi fromEnvironment() {
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const functionSlug = String.fromEnvironment(
      'SUPABASE_FUNCTION_SLUG',
      defaultValue: 'pqr-api',
    );

    if (supabaseUrl.isEmpty) {
      return MemoryBackendApi.seeded();
    }

    return SupabaseBackendApi(
      supabaseUrl: supabaseUrl,
      functionSlug: functionSlug,
    );
  }

  final Uri _endpoint;
  final http.Client _client;

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final data = await _request(
      'POST',
      'login',
      body: {'username': username, 'password': password},
    );
    return AuthResult(
      token: data['token'].toString(),
      user: AppUser.fromJson(Map<String, dynamic>.from(data['user'] as Map)),
    );
  }

  @override
  Future<void> logout(String sessionToken) async {
    await _request('POST', 'logout', sessionToken: sessionToken);
  }

  @override
  Future<BackendSnapshot> bootstrap(String sessionToken) async {
    final data = await _request('GET', 'bootstrap', sessionToken: sessionToken);
    return BackendSnapshot.fromJson(data);
  }

  @override
  Future<AppUser> addUser(
    String sessionToken, {
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final data = await _request(
      'POST',
      'users',
      sessionToken: sessionToken,
      body: {
        'display_name': displayName,
        'username': username,
        'password': password,
        'role': role.name,
      },
    );
    return AppUser.fromJson(data);
  }

  @override
  Future<AppUser> updateUser(
    String sessionToken, {
    required String id,
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final data = await _request(
      'PATCH',
      'users/$id',
      sessionToken: sessionToken,
      body: {
        'display_name': displayName,
        'username': username,
        'password': password,
        'role': role.name,
      },
    );
    return AppUser.fromJson(data);
  }

  @override
  Future<Member> addMember(
    String sessionToken, {
    required String fullName,
    required String address,
    required String phone,
  }) async {
    final data = await _request(
      'POST',
      'members',
      sessionToken: sessionToken,
      body: {'full_name': fullName, 'address': address, 'phone': phone},
    );
    return Member.fromJson(data);
  }

  @override
  Future<Member> updateMember(String sessionToken, Member member) async {
    final data = await _request(
      'PATCH',
      'members/${member.id}',
      sessionToken: sessionToken,
      body: {
        'full_name': member.fullName,
        'address': member.address,
        'phone': member.phone,
        'status': member.status.name,
      },
    );
    return Member.fromJson(data);
  }

  @override
  Future<void> deleteMember(String sessionToken, String memberId) async {
    await _request('DELETE', 'members/$memberId', sessionToken: sessionToken);
  }

  @override
  Future<SavingsTransaction> recordSavingsTransaction(
    String sessionToken, {
    required String memberId,
    required SavingsTransactionType type,
    required double amount,
    required String note,
  }) async {
    final data = await _request(
      'POST',
      'savings-transactions',
      sessionToken: sessionToken,
      body: {
        'member_id': memberId,
        'type': type.name,
        'amount': amount,
        'note': note,
      },
    );
    return SavingsTransaction.fromJson(data);
  }

  @override
  Future<Loan> addLoan(
    String sessionToken, {
    required String memberId,
    required double principal,
    required double annualInterestRate,
    required int termMonths,
  }) async {
    final data = await _request(
      'POST',
      'loans',
      sessionToken: sessionToken,
      body: {
        'member_id': memberId,
        'principal': principal,
        'annual_interest_rate': annualInterestRate,
        'term_months': termMonths,
      },
    );
    return Loan.fromJson(data);
  }

  @override
  Future<Loan> updateLoanStatus(
    String sessionToken, {
    required String loanId,
    required LoanStatus status,
  }) async {
    final data = await _request(
      'PATCH',
      'loans/$loanId/status',
      sessionToken: sessionToken,
      body: {'status': status.name},
    );
    return Loan.fromJson(data);
  }

  @override
  Future<LoanRepaymentResult> recordLoanPayment(
    String sessionToken, {
    required String loanId,
    required double amount,
    required String note,
  }) async {
    final data = await _request(
      'POST',
      'loans/$loanId/repayments',
      sessionToken: sessionToken,
      body: {'amount': amount, 'note': note},
    );
    final repayment = Repayment.fromJson(
      Map<String, dynamic>.from(data['repayment'] as Map),
    );
    final loan = Loan.fromJson(
      Map<String, dynamic>.from(data['loan'] as Map),
      repayments: [repayment],
    );
    return LoanRepaymentResult(loan: loan, repayment: repayment);
  }

  @override
  Future<BackupRun> runBackup(String sessionToken) async {
    final data = await _request('POST', 'backups', sessionToken: sessionToken);
    return BackupRun.fromJson(data);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    String? sessionToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.send(
      http.Request(method, _endpoint.resolve(path))
        ..headers.addAll({
          'Content-Type': 'application/json',
          if (sessionToken != null) 'Authorization': 'Bearer $sessionToken',
        })
        ..body = body == null ? '' : jsonEncode(body),
    );

    final text = await response.stream.bytesToString();
    final decoded = text.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(text) as Map);

    if (response.statusCode >= 400) {
      throw BackendException(
        (decoded['error'] ?? 'Backend request failed.').toString(),
      );
    }

    return decoded;
  }
}
