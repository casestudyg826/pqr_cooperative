import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pqr_cooperative/controller/app_controller.dart';
import 'package:pqr_cooperative/main.dart';

Widget buildTestApp() {
  return AppScope(
    controller: AppController(),
    child: const PqrCooperativeApp(),
  );
}

void configureDesktopView(
  WidgetTester tester, {
  Size size = const Size(1200, 900),
}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('app launches to login screen', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.text('PQR Cooperative'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('administrator can log in and see dashboard', (tester) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Operational overview'), findsOneWidget);
    expect(find.text('Total Members'), findsOneWidget);
    expect(find.text('Total Savings'), findsOneWidget);
  });

  testWidgets('administrator can add a member', (tester) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addMemberButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('memberNameField')),
      'Carlo Mendoza',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Phone'),
      '0920 555 1000',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Address'),
      'Cebu City',
    );
    await tester.tap(find.byKey(const Key('saveMemberButton')));
    await tester.pumpAndSettle();

    expect(find.text('Carlo Mendoza'), findsOneWidget);
  });

  testWidgets('members table shows loan details', (tester) async {
    configureDesktopView(tester, size: const Size(2600, 900));
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();

    expect(find.text('Loan Applied'), findsOneWidget);
    expect(find.text('Loan Status'), findsOneWidget);
    expect(find.text('Outstanding'), findsOneWidget);
    expect(find.text('Yes (1)'), findsWidgets);
  });

  testWidgets('members table action buttons stay on one row', (tester) async {
    configureDesktopView(tester, size: const Size(2600, 900));
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();

    final viewTopLeft = tester.getTopLeft(
      find.byKey(const Key('viewMember_m001')),
    );
    final editTopLeft = tester.getTopLeft(
      find.byKey(const Key('editMember_m001')),
    );
    final deleteTopLeft = tester.getTopLeft(
      find.byKey(const Key('deleteMember_m001')),
    );

    expect(editTopLeft.dy, closeTo(viewTopLeft.dy, 0.1));
    expect(deleteTopLeft.dy, closeTo(viewTopLeft.dy, 0.1));
    expect(editTopLeft.dx, greaterThan(viewTopLeft.dx));
    expect(deleteTopLeft.dx, greaterThan(editTopLeft.dx));
  });

  testWidgets('administrator can delete a member', (tester) async {
    configureDesktopView(tester, size: const Size(850, 900));
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deleteMember_m003')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Ana Reyes'), findsNothing);
  });

  testWidgets('reports tab shows available PDF reports', (tester) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(find.text('Available Reports'), findsOneWidget);
    expect(find.text('Monthly Financial Statement'), findsOneWidget);
    expect(find.text('Member Savings Report'), findsOneWidget);
    expect(find.text('Loan Portfolio Report'), findsOneWidget);
    expect(find.text('CDA Compliance Report'), findsOneWidget);
    expect(find.text('Membership Activity Report'), findsOneWidget);
    expect(find.text('Generate'), findsNWidgets(5));
  });

  testWidgets('loans tab separates decisions and repayment options', (
    tester,
  ) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Loans'));
    await tester.pumpAndSettle();

    expect(find.text('Pending applications'), findsOneWidget);
    expect(find.text('Active loans'), findsOneWidget);
    expect(find.text('Closed records'), findsOneWidget);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Save payment'), findsOneWidget);
  });

  testWidgets('savings tab shows private member accounts', (tester) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Savings'));
    await tester.pumpAndSettle();

    expect(find.text('Savings Accounts'), findsOneWidget);
    expect(find.text('Member accounts'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Search accounts by name, code, or phone'),
      findsOneWidget,
    );
    expect(find.text('Maria Santos'), findsWidgets);
    expect(find.text('Juan Dela Cruz'), findsWidgets);
    expect(find.text('Ana Reyes'), findsWidgets);
    expect(find.text('Account transaction history'), findsOneWidget);
  });
}
