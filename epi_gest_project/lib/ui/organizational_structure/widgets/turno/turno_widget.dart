import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/turno_controller.dart';
import 'package:epi_gest_project/ui/organizational_structure/widgets/turno/turno_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TurnoWidget extends StatefulWidget {
  const TurnoWidget({super.key});

  @override
  State<TurnoWidget> createState() => TurnoWidgetState();
}

class TurnoWidgetState extends State<TurnoWidget> {
  List<TurnoModel> _turnos = [];
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
      final controller = Provider.of<TurnoController>(context, listen: false);
      final result = await controller.carregarTurnos();

      if (mounted) {
        setState(() {
          _turnos = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar turnos: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({TurnoModel? turno, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Turno',
      pageBuilder: (context, _, __) => TurnoDrawer(
        turnoToEdit: turno,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (turnoSalvo) {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusTurno(TurnoModel turno) async {
    final novoStatus = !turno.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o turno "${turno.turno}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Inativar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      final controller = Provider.of<TurnoController>(context, listen: false);
      await controller.atualizarStatusTurno(turno.id!, novoStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Turno ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
          ),
          backgroundColor: novoStatus ? Colors.green : Colors.orange,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao $acao: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      return Column(
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
      );
    }

    if (_turnos.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum turno cadastrado',
        subtitle: 'Clique em "Novo Turno" para começar',
        icon: Icons.access_time_outlined,
        titleDrawer: "Novo Turno",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _turnos.length,
            itemBuilder: (context, index) {
              final turno = _turnos[index];
              return ItemCard(
                title: turno.turno,
                subtitle: Text('${turno.horaEntrada} - ${turno.horaSaida}'),
                leadingIcon: Icons.access_time_outlined,
                isActive: turno.status,
                onView: () => _showDrawer(turno: turno, viewOnly: true),
                onEdit: () => _showDrawer(turno: turno),
                onToggleStatus: () => _toggleStatusTurno(turno),
              );
            },
          ),
        ),
      ],
    );
  }
}
