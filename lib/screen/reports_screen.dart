import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../controller/app_controller.dart';
import '../module/report_definition.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType? _generatingType;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final summary = app.reports.buildSummary(
      members: app.members,
      savings: app.savings,
      loans: app.loans,
    );
    final exposure = app.reports.loanExposureByStatus(app.loans);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generated from current local member, savings, and loan records.',
          ),
          const SizedBox(height: 20),
          _AvailableReportsCard(
            generatingType: _generatingType,
            onGenerate: _generateReport,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final financial = _ReportCard(
                title: 'Financial Summary',
                rows: [
                  _ReportRow('Total savings', _money(summary.totalSavings)),
                  _ReportRow(
                    'Loan principal',
                    _money(summary.totalLoanPrincipal),
                  ),
                  _ReportRow(
                    'Expected interest',
                    _money(summary.totalLoanInterest),
                  ),
                  _ReportRow(
                    'Repayments collected',
                    _money(summary.totalRepayments),
                  ),
                  _ReportRow(
                    'Outstanding exposure',
                    _money(summary.outstandingLoans),
                  ),
                ],
              );
              final compliance = _ReportCard(
                title: 'CDA Compliance Snapshot',
                rows: [
                  _ReportRow('Registered members', '${summary.totalMembers}'),
                  _ReportRow('Active members', '${summary.activeMembers}'),
                  _ReportRow(
                    'Pending loan applications',
                    '${summary.pendingLoans}',
                  ),
                  _ReportRow('Active loans', '${summary.activeLoans}'),
                  _ReportRow('Overdue loans', '${summary.overdueLoans}'),
                ],
              );

              if (!isWide) {
                return Column(
                  children: [financial, const SizedBox(height: 16), compliance],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: financial),
                  const SizedBox(width: 16),
                  Expanded(child: compliance),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _ReportCard(
            title: 'Loan Exposure by Status',
            rows: [
              for (final entry in exposure.entries)
                _ReportRow(_title(entry.key), _money(entry.value)),
            ],
          ),
          const SizedBox(height: 16),
          _ReportCard(
            title: 'Report Notes',
            rows: const [
              _ReportRow('Storage mode', 'Local in-memory prototype'),
              _ReportRow('External banking integration', 'Not included'),
              _ReportRow('Backup', 'Simulated from backup screen'),
              _ReportRow('Data quality', 'Depends on staff-entered records'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(ReportDefinition definition) async {
    final app = AppScope.of(context);
    setState(() => _generatingType = definition.type);

    try {
      final bytes = await app.pdfReports.buildReport(
        definition: definition,
        members: app.members,
        savings: app.savings,
        loans: app.loans,
        reports: app.reports,
      );
      await Printing.sharePdf(bytes: bytes, filename: definition.fileName);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${definition.title} PDF generated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to generate PDF: $error')));
    } finally {
      if (mounted) {
        setState(() => _generatingType = null);
      }
    }
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _title(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _AvailableReportsCard extends StatelessWidget {
  const _AvailableReportsCard({
    required this.generatingType,
    required this.onGenerate,
  });

  final ReportType? generatingType;
  final ValueChanged<ReportDefinition> onGenerate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Reports',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 920;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    for (final report in availableReports)
                      SizedBox(
                        width: twoColumns
                            ? (constraints.maxWidth - 14) / 2
                            : constraints.maxWidth,
                        child: _AvailableReportTile(
                          report: report,
                          isGenerating: generatingType == report.type,
                          onGenerate: () => onGenerate(report),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableReportTile extends StatelessWidget {
  const _AvailableReportTile({
    required this.report,
    required this.isGenerating,
    required this.onGenerate,
  });

  final ReportDefinition report;
  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 560;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E4DD)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReportIdentity(report: report),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _GenerateButton(
                      isGenerating: isGenerating,
                      onGenerate: onGenerate,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _ReportIdentity(report: report)),
                  const SizedBox(width: 14),
                  _GenerateButton(
                    isGenerating: isGenerating,
                    onGenerate: onGenerate,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ReportIdentity extends StatelessWidget {
  const _ReportIdentity({required this.report});

  final ReportDefinition report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EFE9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(report.icon, color: const Color(0xFF235347)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.isGenerating, required this.onGenerate});

  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isGenerating ? null : onGenerate,
      icon: isGenerating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download),
      label: Text(isGenerating ? 'Generating' : 'Generate'),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.rows});

  final String title;
  final List<_ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(row.label)),
                    const SizedBox(width: 12),
                    Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow {
  const _ReportRow(this.label, this.value);

  final String label;
  final String value;
}
