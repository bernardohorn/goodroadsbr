import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../categories/presentation/controllers/categories_providers.dart';
import '../controllers/reports_providers.dart';

const _statusOptions = {'PENDENTE': 'Pendente', 'EM_ANDAMENTO': 'Em andamento', 'RESOLVIDA': 'Resolvida', 'CANCELADA': 'Cancelada'};

/// Tela 8/10 do desktop: exportação de relatórios, em CSV (separador ';' e
/// BOM UTF-8, compatível com Excel) ou PDF (tabela paginada, pronta para
/// impressão/anexo).
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String? _status;
  String? _categoryId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _format = 'csv';
  bool _isExporting;
  String? _message;

  _ReportsPageState() : _isExporting = false;

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
  }

  Future<void> _export() async {
    setState(() {
      _isExporting = true;
      _message = null;
    });

    final result = await ref.read(exportReportUseCaseProvider)(
      format: _format,
      status: _status,
      categoryId: _categoryId,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );

    if (!mounted) return;

    await result.fold(
      (failure) async => setState(() => _message = failure.message),
      (bytes) async {
        final isPdf = _format == 'pdf';
        final suggestedName = 'ocorrencias-${DateFormat('yyyy-MM-dd').format(DateTime.now())}.${isPdf ? 'pdf' : 'csv'}';
        final location = await getSaveLocation(
          suggestedName: suggestedName,
          acceptedTypeGroups: [
            isPdf
                ? const XTypeGroup(label: 'PDF', extensions: ['pdf'])
                : const XTypeGroup(label: 'CSV', extensions: ['csv']),
          ],
        );
        if (location == null) return;
        final file = XFile.fromData(bytes, mimeType: isPdf ? 'application/pdf' : 'text/csv', name: suggestedName);
        await file.saveTo(location.path);
        if (mounted) setState(() => _message = 'Relatório salvo em ${location.path}');
      },
    );

    if (mounted) setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Relatórios', subtitle: 'Exporte ocorrências filtradas em CSV ou PDF.'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filtros', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(labelText: 'Status'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Todos')),
                              for (final entry in _statusOptions.entries) DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                            ],
                            onChanged: (value) => setState(() => _status = value),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: categoriesAsync.when(
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => const Text('Erro ao carregar categorias'),
                            data: (categories) => DropdownButtonFormField<String>(
                              initialValue: _categoryId,
                              decoration: const InputDecoration(labelText: 'Categoria'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todas')),
                                for (final c in categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
                              ],
                              onChanged: (value) => setState(() => _categoryId = value),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isFrom: true),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_dateFrom == null ? 'Data inicial' : dateFormat.format(_dateFrom!)),
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(isFrom: false),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(_dateTo == null ? 'Data final' : dateFormat.format(_dateTo!)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Formato', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'csv', label: Text('CSV'), icon: Icon(Icons.table_chart_outlined)),
                        ButtonSegment(value: 'pdf', label: Text('PDF'), icon: Icon(Icons.picture_as_pdf_outlined)),
                      ],
                      selected: {_format},
                      onSelectionChanged: (selection) => setState(() => _format = selection.first),
                    ),
                    const SizedBox(height: 24),
                    if (_message != null) ...[
                      Text(_message!, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: 'Exportar ${_format.toUpperCase()}',
                      icon: Icons.download,
                      isLoading: _isExporting,
                      onPressed: _export,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
