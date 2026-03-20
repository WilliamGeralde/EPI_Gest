import 'package:epi_gest_project/data/repositories/ficha_entrega_repository.dart';
import 'package:epi_gest_project/data/repositories/funcionarios/mapeamento_funcionario_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/ficha_entrega_model.dart';
import 'package:epi_gest_project/domain/models/ficha_epi_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/ui/entrega_epi/widgets/entrega_epi_drawer.dart';
import 'package:epi_gest_project/ui/entrega_epi/widgets/ficha_epi_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum EpiStatusEnum { pendente, vencido, aVencer, emDia }

class EpiStatusData {
  final EpiStatusEnum status;
  final FichaEpiModel? ultimaFicha;
  final DateTime? validade;

  EpiStatusData({required this.status, this.ultimaFicha, this.validade});
}

class ExchangePage extends StatefulWidget {
  const ExchangePage({super.key});

  @override
  State<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends State<ExchangePage> {
  List<MapeamentoFuncionarioModel> _funcionariosComMapeamento = [];
  List<FichaEntregaModel> _fichasEntrega = [];
  List<MapeamentoFuncionarioModel> _filteredList = [];

  late Future<void> _loadExchangeFuture;

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Novos filtros de status
  final Set<EpiStatusEnum> _selectedStatusFilters = {};

  @override
  void initState() {
    super.initState();
    _loadExchangeFuture = _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  EpiStatusData _calcularStatusEpi(
    String epiId,
    List<FichaEntregaModel> historico,
  ) {
    final now = DateTime.now();

    final List<FichaEpiModel> entregasDesteEpi = [];

    for (var entrega in historico) {
      if (!entrega.status) continue;

      for (var item in entrega.fichaEpi) {
        if (item.epi.id == epiId) {
          entregasDesteEpi.add(item);
        }
      }
    }

    if (entregasDesteEpi.isEmpty) {
      return EpiStatusData(status: EpiStatusEnum.pendente);
    }

    // Ordena para garantir que pegamos a mais recente baseada na data de validade ou criação
    // Assumindo que a ordem da lista já vem do banco (createdAt desc), pegamos o first.
    final ultimaEntrega = entregasDesteEpi.first;

    if (ultimaEntrega.validadeEpi.isBefore(now)) {
      return EpiStatusData(
        status: EpiStatusEnum.vencido,
        ultimaFicha: ultimaEntrega,
        validade: ultimaEntrega.validadeEpi,
      );
    } else if (ultimaEntrega.validadeEpi.difference(now).inDays <= 30) {
      return EpiStatusData(
        status: EpiStatusEnum.aVencer,
        ultimaFicha: ultimaEntrega,
        validade: ultimaEntrega.validadeEpi,
      );
    } else {
      return EpiStatusData(
        status: EpiStatusEnum.emDia,
        ultimaFicha: ultimaEntrega,
        validade: ultimaEntrega.validadeEpi,
      );
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      final mapFuncRepo = Provider.of<MapeamentoFuncionarioRepository>(
        context,
        listen: false,
      );
      final fichaRepo = Provider.of<FichaEntregaRepository>(
        context,
        listen: false,
      );

      final results = await Future.wait([
        mapFuncRepo.getAllRelations(),
        fichaRepo.getAllEntregasAtivas(),
      ]);

      if (mounted) {
        setState(() {
          _funcionariosComMapeamento =
              results[0] as List<MapeamentoFuncionarioModel>;
          _fichasEntrega = results[1] as List<FichaEntregaModel>;
          _filteredList = _funcionariosComMapeamento;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredList = _funcionariosComMapeamento.where((mapFunc) {
        final func = mapFunc.funcionario;

        // 1. Filtro de Texto
        final searchLower = _searchQuery.toLowerCase();
        final matchesSearch =
            _searchQuery.isEmpty ||
            func.nomeFunc.toLowerCase().contains(searchLower) ||
            func.matricula.toLowerCase().contains(searchLower);

        if (!matchesSearch) return false;

        // 2. Filtro de Status
        if (_selectedStatusFilters.isEmpty) {
          return true; // Se nenhum filtro selecionado, mostra todos
        }

        // Calcula os status deste funcionário
        final historico = _fichasEntrega
            .where((f) => f.mapeamentoFuncionario.id == mapFunc.id)
            .toList();

        final Set<EpiStatusEnum> employeeStatuses = {};

        for (var epi in mapFunc.mapeamento.epis) {
          if (epi.id != null) {
            final statusData = _calcularStatusEpi(epi.id!, historico);
            employeeStatuses.add(statusData.status);
          }
        }

        // Verifica se o funcionário atende a ALGUM dos filtros selecionados
        bool matchesStatus = false;

        if (_selectedStatusFilters.contains(EpiStatusEnum.pendente) &&
            employeeStatuses.contains(EpiStatusEnum.pendente)) {
          matchesStatus = true;
        }
        if (_selectedStatusFilters.contains(EpiStatusEnum.vencido) &&
            employeeStatuses.contains(EpiStatusEnum.vencido)) {
          matchesStatus = true;
        }
        if (_selectedStatusFilters.contains(EpiStatusEnum.aVencer) &&
            employeeStatuses.contains(EpiStatusEnum.aVencer)) {
          matchesStatus = true;
        }
        if (_selectedStatusFilters.contains(EpiStatusEnum.emDia)) {
          final bool isFullyCompliant =
              !employeeStatuses.contains(EpiStatusEnum.pendente) &&
              !employeeStatuses.contains(EpiStatusEnum.vencido) &&
              !employeeStatuses.contains(EpiStatusEnum.aVencer);
          if (isFullyCompliant) matchesStatus = true;
        }

        return matchesStatus;
      }).toList();
    });
  }

  void _toggleStatusFilter(EpiStatusEnum status) {
    setState(() {
      if (_selectedStatusFilters.contains(status)) {
        _selectedStatusFilters.remove(status);
      } else {
        _selectedStatusFilters.add(status);
      }
      _applyFilters();
    });
  }

  void _openDeliveryDrawer(MapeamentoFuncionarioModel mapFunc) {
    final historicoFuncionario = _fichasEntrega
        .where((f) => f.mapeamentoFuncionario.id == mapFunc.id)
        .toList();

    final Map<String, EpiStatusData> statusMap = {};

    for (var epi in mapFunc.mapeamento.epis) {
      if (epi.id != null) {
        statusMap[epi.id!] = _calcularStatusEpi(epi.id!, historicoFuncionario);
      }
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Registrar Entrega',
      pageBuilder: (context, _, __) => ExchangeDrawerContent(
        mapFunc: mapFunc,
        onCloseDrawer: () => Navigator.of(context).pop(),
        epiStatusMap: statusMap,
        onSave: () {
          _reloadData();
        },
      ),
    );
  }

  void _reloadData() {
    setState(() {
      _loadExchangeFuture = _loadData();
    });
  }

  Future<void> _generateFichaEpiDocument(
    MapeamentoFuncionarioModel mapFunc,
  ) async {
    // 1. Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Buscar histórico completo do funcionário
      final repo = Provider.of<FichaEntregaRepository>(context, listen: false);
      final historico = await repo.getByFuncionario(mapFunc.id!); 

      if (!mounted) return;
      Navigator.pop(context); // Fechar loading

      if (historico.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum histórico de entrega encontrado para este funcionário.')),
        );
        return;
      }

      // 3. Navegar para a tela de pré-visualização (PDF Preview)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FichaEpiPreviewPage(
            mapFunc: mapFunc,
            historico: historico,
          ),
        ),
      );

    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context); // Fecha loading se erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados da ficha: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        _buildHeader(theme, colorScheme),
        const Divider(height: 1),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: theme.colorScheme.surface,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar funcionário por Nome ou Matrícula...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder(
            future: _loadExchangeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando dados...'),
                  ],
                );
              }

              return _buildContent(theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required EpiStatusEnum status,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _selectedStatusFilters.contains(status);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _toggleStatusFilter(status),
      avatar: Icon(
        icon,
        color: isSelected ? color : color.withValues(alpha: 0.7),
        size: 18,
      ),
      checkmarkColor: color,
      showCheckmark: false,
      selectedColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme) {
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
      ),
      child: Column(
        children: [
          Row(
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
                      Icons.swap_horiz_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entrega de EPIs',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Gestão de entregas e status de conformidade',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  if (_selectedStatusFilters.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStatusFilters.clear();
                          _applyFilters();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Limpar'),
                    ),
                  ],
                  const SizedBox(width: 12),
                  _buildFilterChip(
                    label: 'Pendentes',
                    status: EpiStatusEnum.pendente,
                    color: Colors.orange,
                    icon: Icons.priority_high_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Vencidos',
                    status: EpiStatusEnum.vencido,
                    color: Colors.red,
                    icon: Icons.error_outline_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'À Vencer',
                    status: EpiStatusEnum.aVencer,
                    color: Colors.amber.shade800,
                    icon: Icons.access_time_filled_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    label: 'Regularizados',
                    status: EpiStatusEnum.emDia,
                    color: Colors.green,
                    icon: Icons.check_circle_rounded,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_funcionariosComMapeamento.isEmpty) {
      return const Center(
        child: Text("Nenhum funcionário com mapeamento encontrado."),
      );
    }

    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Nenhum funcionário encontrado com os filtros atuais',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final mapFunc = _filteredList[index];

        final historicoFuncionario = _fichasEntrega
            .where((f) => f.mapeamentoFuncionario.id == mapFunc.id)
            .toList();

        final Map<String, EpiStatusData> statusMap = {};
        for (var epi in mapFunc.mapeamento.epis) {
          if (epi.id != null) {
            statusMap[epi.id!] = _calcularStatusEpi(
              epi.id!,
              historicoFuncionario,
            );
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _EmployeeDeliveryCard(
            mapFunc: mapFunc,
            epiStatusMap: statusMap,
            onDeliverPressed: () => _openDeliveryDrawer(mapFunc),
            onGenerateFichaPressed: () => _generateFichaEpiDocument(mapFunc),
          ),
        );
      },
    );
  }
}

// ... _EmployeeDeliveryCard permanece inalterado ...
class _EmployeeDeliveryCard extends StatelessWidget {
  final MapeamentoFuncionarioModel mapFunc;
  final Map<String, EpiStatusData> epiStatusMap;
  final VoidCallback onDeliverPressed;
  final VoidCallback onGenerateFichaPressed;

  const _EmployeeDeliveryCard({
    required this.mapFunc,
    required this.epiStatusMap,
    required this.onDeliverPressed,
    required this.onGenerateFichaPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    int pendenteCount = 0;
    int vencidoCount = 0;
    int aVencerCount = 0;

    for (var statusData in epiStatusMap.values) {
      switch (statusData.status) {
        case EpiStatusEnum.pendente:
          pendenteCount++;
          break;
        case EpiStatusEnum.vencido:
          vencidoCount++;
          break;
        case EpiStatusEnum.aVencer:
          aVencerCount++;
          break;
        case EpiStatusEnum.emDia:
          break;
      }
    }

    final bool hasCriticalIssues = pendenteCount > 0 || vencidoCount > 0;
    final bool hasWarnings = aVencerCount > 0;
    final bool isAllOk = !hasCriticalIssues && !hasWarnings;

    String buttonLabel;
    IconData buttonIcon;
    Color statusColor;
    String statusMessage;

    if (hasCriticalIssues) {
      buttonLabel = "Regularizar";
      buttonIcon = Icons.warning_amber_rounded;
      statusColor = Colors.red;
      statusMessage = '${pendenteCount + vencidoCount} itens irregulares';
    } else if (hasWarnings) {
      buttonLabel = "Trocar EPIs";
      buttonIcon = Icons.swap_horiz_rounded;
      statusColor = Colors.orange;
      statusMessage = '$aVencerCount itens a vencer';
    } else {
      buttonLabel = "Nova Entrega";
      buttonIcon = Icons.inventory_rounded;
      statusColor = Colors.green;
      statusMessage = 'Situação Regularizada';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: colorScheme.primaryContainer,
              child: Text(
                mapFunc.funcionario.nomeFunc.isNotEmpty
                    ? mapFunc.funcionario.nomeFunc[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (!isAllOk)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.circle, size: 14, color: statusColor),
                ),
              ),
          ],
        ),
        title: Text(
          mapFunc.funcionario.nomeFunc,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mat: ${mapFunc.funcionario.matricula} • ${mapFunc.mapeamento.cargo.nomeCargo}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              statusMessage,
              style: theme.textTheme.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.history_edu),
              tooltip: 'Gerar Ficha de EPI',
              onPressed: onGenerateFichaPressed,
              style: IconButton.styleFrom(
                foregroundColor: colorScheme.secondary,
              ),
            ),
            FilledButton.icon(
              onPressed: onDeliverPressed,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel),
              style: FilledButton.styleFrom(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                foregroundColor: statusColor,
                elevation: 0,
              ),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status dos EPIs (${mapFunc.mapeamento.nomeMapeamento})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...mapFunc.mapeamento.epis.map((epi) {
                  final statusData =
                      epiStatusMap[epi.id] ??
                      EpiStatusData(status: EpiStatusEnum.pendente);

                  return _buildDetailedEpiRow(context, epi, statusData);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedEpiRow(
    BuildContext context,
    EpiModel epi,
    EpiStatusData statusData,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String subText;

    switch (statusData.status) {
      case EpiStatusEnum.pendente:
        statusText = 'Pendente';
        statusColor = Colors.orange;
        statusIcon = Icons.priority_high_rounded;
        subText = 'Requer entrega imediata';
        break;
      case EpiStatusEnum.vencido:
        statusText = 'Vencido';
        statusColor = Colors.red;
        statusIcon = Icons.history_toggle_off_rounded;
        subText = statusData.validade != null
            ? 'Venceu em: ${dateFormat.format(statusData.validade!)}'
            : 'Data desconhecida';
        break;
      case EpiStatusEnum.aVencer:
        statusText = 'À Vencer';
        statusColor = Colors.amber.shade800;
        statusIcon = Icons.access_time_filled_rounded;
        subText = statusData.validade != null
            ? 'Vence em: ${dateFormat.format(statusData.validade!)}'
            : '';
        break;
      case EpiStatusEnum.emDia:
        statusText = 'Em Dia';
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        subText = statusData.validade != null
            ? 'Válido até: ${dateFormat.format(statusData.validade!)}'
            : '';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  epi.nomeProduto,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text('CA: ${epi.ca}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (subText.isNotEmpty)
                Text(
                  subText,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
