import 'package:epi_gest_project/data/repositories/organizational_structure/unidade_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/armazem_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/armazem_model.dart';
import 'package:epi_gest_project/ui/product_technical_registration/widgets/armazem/armazem_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArmazemWidget extends StatefulWidget {
  const ArmazemWidget({super.key});

  @override
  State<ArmazemWidget> createState() => ArmazemWidgetState();
}

class ArmazemWidgetState extends State<ArmazemWidget> {
  List<ArmazemModel> _armazem = [];
  List<UnidadeModel> _unidade = [];
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
      final armazemRep = Provider.of<ArmazemRepository>(context, listen: false);
      final unidadRep = Provider.of<UnidadeRepository>(context, listen: false);
      final result = await Future.wait([
        armazemRep.getAllArmazens(),
        unidadRep.getAllUnidades(),
      ]);

      if (mounted) {
        setState(() {
          _armazem = result[0] as List<ArmazemModel>;
          _unidade = result[1] as List<UnidadeModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar armazém: $e';
        });
      }
    }
  }

  void showAddDrawer() => _showDrawer();

  void _showDrawer({ArmazemModel? armazem, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Armazem',
      pageBuilder: (context, _, __) => ArmazemDrawer(
        armazemToEdit: armazem,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (vinculoSalvo) =>  _loadData(),
        availableUnidades: _unidade,
      ),
    );
  }

  Future<void> _toggleStatusArmazem(ArmazemModel armazem) async {
    final novoStatus = !armazem.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o armazem "${armazem.codigoArmazem}"?',
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
      final repository = Provider.of<ArmazemRepository>(context, listen: false);

      await repository.update(armazem.id!, {'status': novoStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Armazem ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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

    if (_armazem.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum armazém cadastrado',
        subtitle: 'Clique em "Novo Armazém" para começar',
        icon: Icons.assignment_ind_outlined,
        titleDrawer: "Novo Armazém",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _armazem.length,
            itemBuilder: (context, index) {
              final armazem = _armazem[index];

              return ItemCard(
                title: armazem.codigoArmazem,
                subtitle: Text(
                  'Unidade vinculada: ${armazem.unidade.nomeUnidade}\nCNPJ: ${armazem.unidade.cnpj}',
                ),
                leadingIcon: Icons.store_mall_directory_outlined,
                isActive: armazem.status,
                onView: () => _showDrawer(armazem: armazem, viewOnly: true),
                onEdit: () => _showDrawer(armazem: armazem),
                onToggleStatus: () => _toggleStatusArmazem(armazem),
              );
            },
          ),
        ),
      ],
    );
  }
}
