import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/unidade_controller.dart';
import 'package:epi_gest_project/ui/organizational_structure/widgets/unidade/unidade_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnidadeWidget extends StatefulWidget {
  const UnidadeWidget({super.key});

  @override
  State<UnidadeWidget> createState() => UnidadeWidgetState();
}

class UnidadeWidgetState extends State<UnidadeWidget> {
  List<UnidadeModel> _unidades = [];
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
      final controller = Provider.of<UnidadeController>(context, listen: false);
      final result = await controller.carregarUnidades();
      final unidadesOrdenadas = controller.ordenarUnidades(result);

      if (mounted) {
        setState(() {
          _unidades = unidadesOrdenadas;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar unidades: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({UnidadeModel? unidade, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Unidades',
      pageBuilder: (context, _, __) => UnidadeDrawer(
        unidadeToEdit: unidade,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (savedUnidade) async {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusUnidade(UnidadeModel unidade) async {
    final novoStatus = !unidade.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o unidade "${unidade.nomeUnidade}"?',
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
      final controller = Provider.of<UnidadeController>(context, listen: false);
      await controller.atualizarStatusUnidade(unidade.id!, novoStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unidade ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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

    if (_unidades.isEmpty) {
      return BuildEmpty(
        title: 'Nenhuma unidade cadastrada',
        subtitle: 'Clique em "Nova Unidade" para começar',
        icon: Icons.business_outlined,
        titleDrawer: 'Nova Unidade',
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _unidades.length,
            itemBuilder: (context, index) {
              final unidade = _unidades[index];
              final isMatriz = unidade.tipoUnidade == "Matriz";

              return ItemCard(
                title: unidade.nomeUnidade,
                subtitle: Row(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isMatriz
                            ? Colors.blue.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        unidade.tipoUnidade,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMatriz
                              ? Colors.blue.shade800
                              : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text('CNPJ: ${unidade.cnpj}'),
                  ],
                ),
                leadingIcon: isMatriz ? Icons.business : Icons.business_center,
                isActive: unidade.status,
                onView: () => _showDrawer(unidade: unidade, viewOnly: true),
                onEdit: () => _showDrawer(unidade: unidade),
                onToggleStatus: () => _toggleStatusUnidade(unidade),
              );
            },
          ),
        ),
      ],
    );
  }
}
