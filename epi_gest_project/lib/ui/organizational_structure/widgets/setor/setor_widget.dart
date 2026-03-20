import 'package:epi_gest_project/data/repositories/organizational_structure/setor_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/setor_model.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'setor_drawer.dart';

class SetorWidget extends StatefulWidget {
  const SetorWidget({super.key});

  @override
  State<SetorWidget> createState() => SetorWidgetState();
}

class SetorWidgetState extends State<SetorWidget> {
  List<SetorModel> _setores = [];
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
      final repository = Provider.of<SetorRepository>(context, listen: false);
      final result = await repository.getAllSetores();

      if (mounted) {
        setState(() {
          _setores = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar setores: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({SetorModel? setor, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Departamento',
      pageBuilder: (context, _, __) => SetorDrawer(
        setorToEdit: setor,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (savedSetor) {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusSetor(SetorModel setor) async {
    final novoStatus = !setor.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o setor "${setor.nomeSetor}"?',
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
      final repository = Provider.of<SetorRepository>(context, listen: false);

      await repository.update(setor.id!, {'status': novoStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Setor ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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

    if (_setores.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum setor cadastrado',
        subtitle: 'Clique em "Novo Setor" para começar',
        icon: Icons.work_outline,
        titleDrawer: "Novo Setor",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _setores.length,
            itemBuilder: (context, index) {
              final setor = _setores[index];

              return ItemCard(
                title: setor.nomeSetor,
                subtitle: Text('Código: ${setor.codigoSetor}'),
                leadingIcon: Icons.work_outline,
                isActive: setor.status,
                onView: () => _showDrawer(setor: setor, viewOnly: true),
                onEdit: () => _showDrawer(setor: setor),
                onToggleStatus: () => _toggleStatusSetor(setor),
              );
            },
          ),
        ),
      ],
    );
  }
}
