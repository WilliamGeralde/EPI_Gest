import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/filters/epi_filter_model.dart';
import 'package:epi_gest_project/ui/epis/widgets/entries/entry_page.dart';
import 'package:epi_gest_project/ui/epis/widgets/epi/epi_data_table.dart';
import 'package:epi_gest_project/ui/epis/widgets/epi/epi_drawer.dart';
import 'package:epi_gest_project/ui/epis/widgets/epi/epi_filters.dart';
import 'package:epi_gest_project/ui/epis/widgets/inventory/inventory_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EpiPage extends StatefulWidget {
  const EpiPage({super.key});

  @override
  State<EpiPage> createState() => _EpiPageState();
}

class _EpiPageState extends State<EpiPage> {
  bool _showFilters = false;

  late Future<void> _loadEpisFuture;

  // Listas de dados
  List<EpiModel> _allEpis = [];
  List<EpiModel> _filteredEpis = [];

  List<String> _categories = [];
  List<String> _suppliers = [];

  // Estado do Filtro
  EpiFilterModel _appliedFilters = EpiFilterModel.empty();

  @override
  void initState() {
    super.initState();
    _loadEpisFuture = _loadEpis();
  }

  Future<void> _loadEpis() async {
    try {
      final epiRepo = Provider.of<EpiRepository>(context, listen: false);

      // Busca os dados
      final epis = await epiRepo.getAllEpis();

      // Extrai dados únicos para os filtros
      final categoriesSet = <String>{};
      final suppliersSet =
          <String>{}; // Se o filtro usar Marcas, podemos adaptar aqui

      for (var epi in epis) {
        categoriesSet.add(epi.categoria.nomeCategoria);
        suppliersSet.add(
          epi.marca.nomeMarca,
        ); // Usando Marca como "Supplier" visualmente no filtro se necessário, ou ajuste conforme lógica de negócio
      }

      if (mounted) {
        setState(() {
          _allEpis = epis;
          _categories = categoriesSet.toList()..sort();
          _suppliers = suppliersSet.toList()..sort();

          // Reaplica filtros se existirem
          _applyFilters(_appliedFilters, updateState: false);
        });
      }
    } on AppwriteException catch (e) {
      throw Exception('Falha ao carregar EPIs: ${e.message}');
    } catch (e) {
      throw Exception('Ocorreu um erro inesperado: ${e.toString()}');
    }
  }

  void _reloadData() {
    setState(() {
      _loadEpisFuture = _loadEpis();
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _applyFilters(EpiFilterModel filters, {bool updateState = true}) {
    void performFilter() {
      _appliedFilters = filters;

      if (filters.isEmpty) {
        _filteredEpis = List.from(_allEpis);
        return;
      }

      _filteredEpis = _allEpis.where((epi) {
        if (filters.nome != null &&
            filters.nome!.isNotEmpty &&
            !epi.nomeProduto.toLowerCase().contains(
              filters.nome!.toLowerCase(),
            )) {
          return false;
        }

        if (filters.ca != null &&
            filters.ca!.isNotEmpty &&
            !epi.ca.toLowerCase().contains(filters.ca!.toLowerCase())) {
          return false;
        }

        if (filters.categorias != null &&
            filters.categorias!.isNotEmpty &&
            !filters.categorias!.contains(epi.categoria.nomeCategoria)) {
          return false;
        }

        if (filters.marcas != null &&
            filters.marcas!.isNotEmpty &&
            !filters.marcas!.contains(epi.marca.nomeMarca)) {
          return false;
        }

        if (filters.validades != null && filters.validades!.isNotEmpty) {
          bool matchesValidity = false;
          final now = DateTime.now();

          for (var status in filters.validades!) {
            if (status == 'Vencido' && now.isAfter(epi.validadeCa)) {
              matchesValidity = true;
            } else if (status == 'À Vencer') {
              final diff = epi.validadeCa.difference(now).inDays;
              if (diff > 0 && diff <= 30) matchesValidity = true;
            } else if (status == 'No Prazo') {
              final diff = epi.validadeCa.difference(now).inDays;
              if (diff > 30) matchesValidity = true;
            }
          }
          if (!matchesValidity) return false;
        }

        if (filters.quantidade != null) {
          final qtdFilter = filters.quantidade!;
          final op = filters.quantidadeOperador ?? '=';
          bool matchesQtd = false;

          switch (op) {
            case '>': matchesQtd = epi.estoque > qtdFilter; break;
            case '<': matchesQtd = epi.estoque < qtdFilter; break;
            case '>=': matchesQtd = epi.estoque >= qtdFilter; break;
            case '<=': matchesQtd = epi.estoque <= qtdFilter; break;
            case '=': 
            default: matchesQtd = epi.estoque == qtdFilter; break;
          }
          if (!matchesQtd) return false;
        }

        if (filters.valor != null) {
          final valorFilter = filters.valor!;
          final op = filters.valorOperador ?? '=';
          bool matchesValor = false;

          switch (op) {
            case '>': matchesValor = epi.valor > valorFilter; break;
            case '<': matchesValor = epi.valor < valorFilter; break;
            case '>=': matchesValor = epi.valor >= valorFilter; break;
            case '<=': matchesValor = epi.valor <= valorFilter; break;
            case '=': 
            default:
              matchesValor = (epi.valor - valorFilter).abs() < 0.01; 
              break;
          }
          if (!matchesValor) return false;
        }

        return true;
      }).toList();
    }

    if (updateState) {
      setState(performFilter);
    } else {
      performFilter();
    }
  }

  void _clearFilters() {
    setState(() {
      _appliedFilters = EpiFilterModel.empty();
      _filteredEpis = List.from(_allEpis);
    });
  }

  void _showAddEpiDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Adicionar EPI',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => EpiDrawer(
        onClose: () => Navigator.of(context).pop(),
        onSave: () {
          _reloadData();
        },
      ),
    );
  }

  void _showEditEpiDrawer(EpiModel epi) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Editar EPI',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => EpiDrawer(
        epiToEdit: epi,
        onClose: () => Navigator.of(context).pop(),
        onSave: () {
          _reloadData();
        },
      ),
    );
  }

  void _showViewEpiDrawer(EpiModel epi) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Visualizar EPI',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => EpiDrawer(
        epiToEdit: epi,
        view: true,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _navigateToEntryScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EntryPage())
    );
    
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme),
          const Divider(height: 1),
          if (_showFilters)
            EpiFilters(
              appliedFilters: _appliedFilters,
              categories: _categories,
              suppliers: _suppliers,
              onApplyFilters: (filters) => _applyFilters(filters),
              onClearFilters: _clearFilters,
            ),
          Expanded(
            child: FutureBuilder(
              future: _loadEpisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    spacing: 16,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('Carregando dados...'),
                    ],
                  );
                }
                if (snapshot.hasError) {
                  return _buildErrorState(theme, snapshot.error.toString());
                }
                if (_filteredEpis.isEmpty) {
                  return _buildEmptyState(theme);
                }

                return EpiDataTable(
                  epis: _filteredEpis,
                  onView: _showViewEpiDrawer,
                  onEdit: _showEditEpiDrawer,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estoque de EPIs',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_filteredEpis.length} ${_filteredEpis.length == 1 ? 'item' : 'itens'} no estoque${_appliedFilters.activeFiltersCount > 0 ? ' (filtrado)' : ''}',
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
              Badge.count(
                count: _appliedFilters.activeFiltersCount,
                isLabelVisible: _appliedFilters.activeFiltersCount > 0,
                child: IconButton.filledTonal(
                  onPressed: _toggleFilters,
                  icon: Icon(
                    _showFilters ? Icons.filter_alt_off : Icons.filter_alt,
                  ),
                  tooltip: _showFilters ? 'Ocultar filtros' : 'Mostrar filtros',
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _navigateToEntryScreen,
                icon: const Icon(Icons.assignment_add),
                label: const Text('Realizar Entrada'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const InventoryListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.inventory_outlined),
                label: const Text('Realizar Inventário'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _showAddEpiDrawer,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar EPI'),
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
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum EPI encontrado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _appliedFilters.activeFiltersCount > 0
                ? 'Tente ajustar os filtros'
                : 'Adicione novos EPIs ao estoque para começar',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_appliedFilters.activeFiltersCount > 0) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpar Filtros'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Falha ao carregar dados',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _reloadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
