import 'package:flutter/material.dart';

enum ReportType {
  monthlyFinancialStatement,
  memberSavingsReport,
  loanPortfolioReport,
  cdaComplianceReport,
  membershipActivityReport,
}

class ReportDefinition {
  const ReportDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.fileName,
  });

  final ReportType type;
  final String title;
  final String description;
  final IconData icon;
  final String fileName;
}

const availableReports = [
  ReportDefinition(
    type: ReportType.monthlyFinancialStatement,
    title: 'Monthly Financial Statement',
    description: 'Summary of deposits, withdrawals, and loan releases.',
    icon: Icons.description_outlined,
    fileName: 'monthly_financial_statement.pdf',
  ),
  ReportDefinition(
    type: ReportType.memberSavingsReport,
    title: 'Member Savings Report',
    description: 'All member savings balances and transaction history.',
    icon: Icons.description_outlined,
    fileName: 'member_savings_report.pdf',
  ),
  ReportDefinition(
    type: ReportType.loanPortfolioReport,
    title: 'Loan Portfolio Report',
    description: 'Active loans, balances, and aging.',
    icon: Icons.description_outlined,
    fileName: 'loan_portfolio_report.pdf',
  ),
  ReportDefinition(
    type: ReportType.cdaComplianceReport,
    title: 'CDA Compliance Report',
    description: 'Annual cooperative report for CDA submission.',
    icon: Icons.description_outlined,
    fileName: 'cda_compliance_report.pdf',
  ),
  ReportDefinition(
    type: ReportType.membershipActivityReport,
    title: 'Membership Activity Report',
    description: 'New, active, and inactive members.',
    icon: Icons.description_outlined,
    fileName: 'membership_activity_report.pdf',
  ),
];
