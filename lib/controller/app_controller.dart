import 'package:flutter/widgets.dart';

import 'auth_controller.dart';
import 'loan_controller.dart';
import 'member_controller.dart';
import 'pdf_report_controller.dart';
import 'report_controller.dart';
import 'savings_controller.dart';

class AppController extends ChangeNotifier {
  AppController() {
    auth.addListener(notifyListeners);
    members.addListener(notifyListeners);
    savings.addListener(notifyListeners);
    loans.addListener(notifyListeners);
  }

  final AuthController auth = AuthController();
  final MemberController members = MemberController();
  final SavingsController savings = SavingsController();
  final LoanController loans = LoanController();
  final ReportController reports = ReportController();
  final PdfReportController pdfReports = PdfReportController();

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
