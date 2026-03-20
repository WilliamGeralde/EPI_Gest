import 'package:epi_gest_project/data/repositories/product_technical_registration/fornecedor_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/fornecedor_model.dart';
import 'package:epi_gest_project/ui/product_technical_registration/widgets/fornecedores/fornecedores_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FornecedoresWidget extends StatefulWidget {
  const FornecedoresWidget({super.key});

  @override
  State<FornecedoresWidget> createState() => FornecedoresWidgetState();
}

class FornecedoresWidgetState extends State<FornecedoresWidget> {
  List<FornecedorModel> _items = [];
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
      final repo = Provider.of<FornecedorRepository>(context, listen: false);
      final result = await repo.getAllFornecedores();

      if (mounted) {
        setState(() {
          _items = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro: $e';
        });
      }
    }
  }

  void showAddDrawer() => _showDrawer();

  void _showDrawer({FornecedorModel? item, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Fornecedor',
      pageBuilder: (context, _, __) => FornecedoresDrawer(
        fornecedorToEdit: item,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (_) => _loadData(),
      ),
    );
  }

  Future<void> _toggleStatusFornecedor(FornecedorModel fornecedor) async {
    final novoStatus = !fornecedor.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o fornecedor "${fornecedor.nomeFornecedor}"?',
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
      final repository = Provider.of<FornecedorRepository>(context, listen: false);

      await repository.update(fornecedor.id!, {'status': novoStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Fornecedor ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text("Tentar Novamente"),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return BuildEmpty(
        title: 'Nenhuma fornecedor cadastrado',
        subtitle: 'Clique em "Novo Fornecedor" para começar',
        icon: Icons.business_outlined,
        titleDrawer: "Novo Fornecedor",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (ctx, index) {
              final item = _items[index];
              return ItemCard(
                title: item.nomeFornecedor,
                subtitle: Text('CNPJ: ${item.cnpj}'),
                leadingIcon: Icons.business_outlined,
                isActive: item.status,
                onView: () => _showDrawer(item: item, viewOnly: true),
                onEdit: () => _showDrawer(item: item),
                onToggleStatus: () => _toggleStatusFornecedor(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
