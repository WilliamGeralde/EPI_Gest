import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/cargo_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/mapeamento_epi_repository.dart';
import 'package:epi_gest_project/data/repositories/funcionarios/mapeamento_funcionario_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/riscos_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/setor_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/cargo_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/riscos_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/setor_model.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'epi_mapping_drawer.dart';

class EpiMapingWidget extends StatefulWidget {
  const EpiMapingWidget({super.key});

  @override
  State<EpiMapingWidget> createState() => EpiMapingWidgetState();
}

class EpiMapingWidgetState extends State<EpiMapingWidget> {
  List<MapeamentoEpiModel> _mapeamentos = [];
  bool _isLoading = true;
  String? _error;

  List<SetorModel> _availableSectors = [];
  List<CargoModel> _availableRoles = [];
  List<RiscosModel> _availableRisks = [];
  List<EpiModel> _availableCategories = [];

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
      final mapRepo = Provider.of<MapeamentoEpiRepository>(
        context,
        listen: false,
      );
      final setorRepo = Provider.of<SetorRepository>(context, listen: false);
      final cargoRepo = Provider.of<CargoRepository>(context, listen: false);
      final riscoRepo = Provider.of<RiscosRepository>(context, listen: false);
      final epiRep = Provider.of<EpiRepository>(context, listen: false);

      final results = await Future.wait([
        mapRepo.getAllMapeamentos(),
        setorRepo.getAllSetores(),
        cargoRepo.getAllCargos(),
        riscoRepo.getAllRiscos(),
        epiRep.getAllEpis(),
      ]);

      if (mounted) {
        setState(() {
          _mapeamentos = results[0] as List<MapeamentoEpiModel>;
          _availableSectors = results[1] as List<SetorModel>;
          _availableRoles = results[2] as List<CargoModel>;
          _availableRisks = results[3] as List<RiscosModel>;
          _availableCategories = results[4] as List<EpiModel>;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar dados: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({MapeamentoEpiModel? mapping, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Mapeamento',
      pageBuilder: (context, _, __) => EpiMappingDrawer(
        mappingToEdit: mapping,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (_) => _loadData(),
        availableSectors: _availableSectors,
        availableRoles: _availableRoles,
        availableRisks: _availableRisks,
        availableEpis: _availableCategories,
      ),
    );
  }

  Future<void> _toggleStatus(MapeamentoEpiModel map) async {
    final repo = Provider.of<MapeamentoEpiRepository>(context, listen: false);
    final vinculoRepo = Provider.of<MapeamentoFuncionarioRepository>(
      context,
      listen: false,
    );

    if (!map.status) {
      try {
        await repo.ativarMapeamento(map.id!);
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapeamento ativado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        _showErrorSnackBar('Erro ao ativar: $e');
      }
      return;
    }

    try {
      final count = await vinculoRepo.countByMapeamentoId(map.id!);

      if (!mounted) return;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _InactivationDialog(
          mapeamentoName: map.nomeMapeamento,
          affectedCount: count,
          availableMappings: _mapeamentos
              .where((m) => m.id != map.id && m.status)
              .toList(),
        ),
      );

      if (result != null && result['confirm'] == true) {
        final String? replacementId = result['replacementId'];

        await vinculoRepo.handleMapeamentoInactivation(map.id!, replacementId);

        await repo.inativarMapeamento(map.id!);

        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              replacementId != null
                  ? 'Mapeamento inativado e funcionários migrados.'
                  : 'Mapeamento inativado e vínculos removidos.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erro no processo de inativação: $e');
    }
  }

  void _showErrorSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
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
          spacing: 16,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            Text(_error!),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar Novamente"),
            ),
          ],
        ),
      );
    }

    if (_mapeamentos.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum mapeamento cadastrado',
        subtitle: 'Clique em "Novo Mapeamento" para começar',
        icon: Icons.map_outlined,
        titleDrawer: "Novo Mapeamento",
        drawer: _showDrawer,
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _mapeamentos.length,
            itemBuilder: (context, index) {
              final map = _mapeamentos[index];

              return ItemCard(
                title: map.nomeMapeamento,
                subtitle:
                    Text('Riscos: ${map.riscos.length} | EPIs vinculados: ${map.epis.length}\nCód: ${map.codigoMapeamento}'),
                leadingIcon: Icons.assignment_turned_in,
                isActive: map.status,
                onView: () => _showDrawer(mapping: map, viewOnly: true),
                onEdit: () => _showDrawer(mapping: map),
                onToggleStatus: () => _toggleStatus(map),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InactivationDialog extends StatefulWidget {
  final String mapeamentoName;
  final int affectedCount;
  final List<MapeamentoEpiModel> availableMappings;

  const _InactivationDialog({
    required this.mapeamentoName,
    required this.affectedCount,
    required this.availableMappings,
  });

  @override
  State<_InactivationDialog> createState() => _InactivationDialogState();
}

class _InactivationDialogState extends State<_InactivationDialog> {
  String? _selectedReplacementId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          const Text('Inativar Mapeamento'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Você está prestes a inativar "${widget.mapeamentoName}".',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.affectedCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Existem ${widget.affectedCount} funcionários vinculados a este mapeamento.',
                      style: const TextStyle(fontSize: 13, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'O que deseja fazer com os vínculos existentes?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReplacementId,
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'Selecione uma ação...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    'Remover vínculos (Deixar sem mapeamento)',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                ...widget.availableMappings.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text('Substituir por: ${m.nomeMapeamento}'),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedReplacementId = value;
                });
              },
            ),
          ] else
            const Text('Nenhum funcionário será afetado.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'confirm': false}),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'confirm': true,
            'replacementId': _selectedReplacementId,
          }),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
          child: const Text('Confirmar Inativação'),
        ),
      ],
    );
  }
}
