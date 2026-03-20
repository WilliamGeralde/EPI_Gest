import 'package:epi_gest_project/data/repositories/entradas_repository.dart';
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/fornecedor_repository.dart';
import 'package:epi_gest_project/domain/models/entradas_model.dart';
import 'package:epi_gest_project/domain/models/filters/entry_filter_model.dart';
import 'package:epi_gest_project/ui/epis/widgets/entries/entry_data_table.dart';
import 'package:epi_gest_project/ui/epis/widgets/entries/entry_drawer.dart';
import 'package:epi_gest_project/ui/epis/widgets/entries/entry_filters.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EntryPage extends StatefulWidget {
  const EntryPage({super.key});

  @override
  State<EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<EntryPage> {
  bool _showFilters = false;
  List<EntradasModel> _allEntries = [];
  List<EntradasModel> _filteredEntries = [];
  EntryFilterModel _appliedFilters = EntryFilterModel.empty();

  List<String> _availableFornecedores = [];
  List<String> _availableProdutos = [];

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final entryRepo = Provider.of<EntradasRepository>(context, listen: false);
      final fornecedorRepo = Provider.of<FornecedorRepository>(
        context,
        listen: false,
      );
      final epiRepo = Provider.of<EpiRepository>(context, listen: false);

      // Carregamento paralelo
      final results = await Future.wait([
        entryRepo.getAllEntradas(),
        fornecedorRepo.getAllFornecedores(),
        epiRepo.getAllEpis(),
      ]);

      final entries = results[0] as List<EntradasModel>;
      final fornecedores = results[1] as List<dynamic>;
      final epis = results[2] as List<dynamic>;

      if (mounted) {
        setState(() {
          _allEntries = entries;
          _filteredEntries = entries;

          _availableFornecedores =
              fornecedores
                  .map((f) => f.nomeFornecedor.toString())
                  .toSet()
                  .toList()
                ..sort();
          _availableProdutos =
              epis.map((e) => e.nomeProduto.toString()).toSet().toList()
                ..sort();

          _applyLocalFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _onApplyFilters(EntryFilterModel filters) {
    setState(() {
      _appliedFilters = filters;
    });
    _applyLocalFilters();
  }

  void _applyLocalFilters() {
    if (_appliedFilters.isEmpty) {
      setState(() => _filteredEntries = List.from(_allEntries));
      return;
    }

    setState(() {
      _filteredEntries = _allEntries.where((entry) {
        bool matches = true;

        if (_appliedFilters.notaFiscal != null &&
            _appliedFilters.notaFiscal!.isNotEmpty) {
          matches =
              matches &&
              entry.nfReferente.toLowerCase().contains(
                _appliedFilters.notaFiscal!.toLowerCase(),
              );
        }

        if (_appliedFilters.fornecedor != null &&
            _appliedFilters.fornecedor!.isNotEmpty) {
          matches =
              matches &&
              _appliedFilters.fornecedor!.contains(
                entry.fornecedorId.nomeFornecedor,
              );
        }

        if (_appliedFilters.produto != null &&
            _appliedFilters.produto!.isNotEmpty) {
          final hasProduct = entry.entradasId.any(
            (item) => _appliedFilters.produto!.contains(item.epi.nomeProduto),
          );
          matches = matches && hasProduct;
        }

        if (_appliedFilters.dataInicio != null) {
          // Normaliza para o início do dia
          final start = DateUtils.dateOnly(_appliedFilters.dataInicio!);
          final entryDate = DateUtils.dateOnly(entry.dataEntrada);
          matches =
              matches &&
              (entryDate.isAtSameMomentAs(start) || entryDate.isAfter(start));
        }

        if (_appliedFilters.dataFim != null) {
          // Normaliza para o fim do dia
          final end = DateUtils.dateOnly(_appliedFilters.dataFim!);
          final entryDate = DateUtils.dateOnly(entry.dataEntrada);
          matches =
              matches &&
              (entryDate.isAtSameMomentAs(end) || entryDate.isBefore(end));
        }

        return matches;
      }).toList();
    });
  }

  void _onClearFilters() {
    setState(() {
      _appliedFilters = EntryFilterModel.empty();
      _filteredEntries = List.from(_allEntries);
    });
  }

  Future<void> _deleteEntry(EntradasModel entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Entrada'),
        content: Text(
          'Tem certeza que deseja excluir a entrada da NF ${entry.nfReferente}?\n\n'
          'ATENÇÃO: O estoque será reduzido e o valor unitário dos produtos será recalculado (estornado).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir e Estornar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final repo = Provider.of<EntradasRepository>(context, listen: false);
        await repo.excluirEntrada(entry.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Entrada excluída e estoque estornado com sucesso.',
              ),
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showNewEntryDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Nova Entrada',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return EntryDrawer(
          onClose: () => Navigator.of(context).pop(),
          onSave: () {
            _loadData();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.08),
                  colorScheme.surface.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                topLeft: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Voltar',
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.input,
                        color: theme.colorScheme.onPrimaryContainer,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entrada de Materiais',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_filteredEntries.length} ${_filteredEntries.length == 1 ? 'entrada registrada' : 'entradas registradas'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Badge(
                      label: Text('${_appliedFilters.activeFiltersCount}'),
                      isLabelVisible: _appliedFilters.activeFiltersCount > 0,
                      child: IconButton.filledTonal(
                        onPressed: _toggleFilters,
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_alt_off
                              : Icons.filter_alt,
                        ),
                        tooltip: _showFilters
                            ? 'Ocultar filtros'
                            : 'Mostrar filtros',
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _showNewEntryDrawer,
                      icon: const Icon(Icons.add),
                      label: const Text('Nova Entrada'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          if (_showFilters)
            EntryFilters(
              appliedFilters: _appliedFilters,
              onApplyFilters: _onApplyFilters,
              onClearFilters: _onClearFilters,
              fornecedor: _availableFornecedores,
              produto: _availableProdutos,
            ),

          Expanded(child: _buildContent(theme)),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_isLoading) {
      return Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), Text('Carregando dados...')],
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_filteredEntries.isEmpty) {
      return BuildEmpty(
        title: 'Nenhuma entrada encontrada',
        subtitle: 'Clique em "Nova Entrada" para começar',
        icon: Icons.input_outlined,
        titleDrawer: 'Nova Entrada',
        drawer: _showNewEntryDrawer,
      );
    }

    return EntryDataTable(entries: _filteredEntries, onDelete: _deleteEntry);
  }
}
