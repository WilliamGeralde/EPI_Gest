import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/vinculo_controller.dart';
import 'package:epi_gest_project/ui/organizational_structure/widgets/vinculo/vinculo_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VinculoWidget extends StatefulWidget {
  const VinculoWidget({super.key});

  @override
  State<VinculoWidget> createState() => VinculoWidgetState();
}

class VinculoWidgetState extends State<VinculoWidget> {
  List<VinculoModel> _vinculos = [];
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
      final controller = Provider.of<VinculoController>(context, listen: false);
      final result = await controller.carregarVinculos();

      if (mounted) {
        setState(() {
          _vinculos = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar vinculos: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({VinculoModel? vinculo, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Vínculo',
      pageBuilder: (context, _, __) => VinculoDrawer(
        vinculoToEdit: vinculo,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (vinculoSalvo) {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusVinculo(VinculoModel vinculo) async {
    final novoStatus = !vinculo.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o vinculo "${vinculo.nomeVinculo}"?',
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
      final controller = Provider.of<VinculoController>(context, listen: false);
      await controller.atualizarStatusVinculo(vinculo.id!, novoStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vinculo ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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

    if (_vinculos.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum vínculo cadastrado',
        subtitle: 'Clique em "Novo Vinculo" para começar',
        icon: Icons.assignment_ind_outlined,
        titleDrawer: "Novo Vinculo",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _vinculos.length,
            itemBuilder: (context, index) {
              final vinculo = _vinculos[index];

              return ItemCard(
                title: vinculo.nomeVinculo,
                leadingIcon: Icons.badge_outlined,
                isActive: vinculo.status,
                onView: () => _showDrawer(vinculo: vinculo, viewOnly: true),
                onEdit: () => _showDrawer(vinculo: vinculo),
                onToggleStatus: () => _toggleStatusVinculo(vinculo),
              );
            },
          ),
        ),
      ],
    );
  }
}
