import 'package:epi_gest_project/data/repositories/organizational_structure/riscos_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/riscos_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/widgets/riscos/riscos_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiscosWidget extends StatefulWidget {
  const RiscosWidget({super.key});

  @override
  State<RiscosWidget> createState() => RiscosWidgetState();
}

class RiscosWidgetState extends State<RiscosWidget> {
  List<RiscosModel> _riscos = [];
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
      final repository = Provider.of<RiscosRepository>(context, listen: false);
      final result = await repository.getAllRiscos();

      if (mounted) {
        setState(() {
          _riscos = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar riscos: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({RiscosModel? risco, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Risco',
      pageBuilder: (context, _, __) => RiscosDrawer(
        riscoToEdit: risco,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (savedRisco) {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusRiscos(RiscosModel riscos) async {
    final novoStatus = !riscos.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o riscos "${riscos.nomeRiscos}"?',
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
      final repository = Provider.of<RiscosRepository>(context, listen: false);

      await repository.update(riscos.id!, {'status': novoStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Riscos ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
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

    if (_riscos.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum risco cadastrado',
        subtitle: 'Clique em "Novo Risco" para começar',
        icon: Icons.warning_amber_outlined,
        titleDrawer: "Novo Risco",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _riscos.length,
            itemBuilder: (context, index) {
              final risco = _riscos[index];

              return ItemCard(
                title: risco.nomeRiscos,
                subtitle: Text('Código: ${risco.codigoRiscos}'),
                leadingIcon: Icons.warning_amber_outlined,
                isActive: risco.status,
                onView: () => _showDrawer(risco: risco, viewOnly: true),
                onEdit: () => _showDrawer(risco: risco),
                onToggleStatus: () => _toggleStatusRiscos(risco),
              );
            },
          ),
        ),
      ],
    );
  }
}
