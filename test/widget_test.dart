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

void configureDesktopView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 900);
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

  testWidgets('savings tab shows private member accounts', (tester) async {
    configureDesktopView(tester);
    await tester.pumpWidget(buildTestApp());
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Savings'));
    await tester.pumpAndSettle();

    expect(find.text('Savings Accounts'), findsOneWidget);
    expect(find.text('Member accounts'), findsOneWidget);
    expect(find.text('Maria Santos'), findsWidgets);
    expect(find.text('Juan Dela Cruz'), findsWidgets);
    expect(find.text('Ana Reyes'), findsWidgets);
    expect(find.text('Account transaction history'), findsOneWidget);
  });
}
