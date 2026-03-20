import 'package:epi_gest_project/data/repositories/organizational_structure/cargo_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/cargo_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/widgets/cargo/cargo_drawer.dart';
import 'package:epi_gest_project/ui/widgets/build_empty.dart';
import 'package:epi_gest_project/ui/widgets/create_type_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CargoWidget extends StatefulWidget {
  const CargoWidget({super.key});

  @override
  State<CargoWidget> createState() => CargoWidgetState();
}

class CargoWidgetState extends State<CargoWidget> {
  List<CargoModel> _cargos = [];
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
      final repository = Provider.of<CargoRepository>(context, listen: false);
      final result = await repository.getAllCargos();

      if (mounted) {
        setState(() {
          _cargos = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erro ao carregar cargos: $e';
        });
      }
    }
  }

  void showAddDrawer() {
    _showDrawer();
  }

  void _showDrawer({CargoModel? cargo, bool viewOnly = false}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gerenciar Cargos',
      pageBuilder: (context, _, __) => CargoDrawer(
        cargoToEdit: cargo,
        view: viewOnly,
        onClose: () => Navigator.of(context).pop(),
        onSave: (savedRole) {
          _loadData();
        },
      ),
    );
  }

  Future<void> _toggleStatusCargo(CargoModel cargo) async {
    final novoStatus = !cargo.status;
    final acao = novoStatus ? 'ativar' : 'inativar';

    if (!novoStatus) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Inativação'),
          content: Text(
            'Tem certeza que deseja inativar o cargo "${cargo.nomeCargo}"?',
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
      final repository = Provider.of<CargoRepository>(context, listen: false);

      await repository.update(cargo.id!, {'status': novoStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cargo ${novoStatus ? 'ativado' : 'inativado'} com sucesso!',
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

    if (_cargos.isEmpty) {
      return BuildEmpty(
        title: 'Nenhum cargo cadastrado',
        subtitle: 'Clique em "Novo Cargo" para começar',
        icon: Icons.badge_outlined,
        titleDrawer: "Novo Cargo",
        drawer: _showDrawer,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _cargos.length,
            itemBuilder: (context, index) {
              final cargo = _cargos[index];

              return ItemCard(
                title: cargo.nomeCargo,
                subtitle: Text('Código: ${cargo.codigoCargo}'),
                leadingIcon: Icons.badge_outlined,
                isActive: cargo.status,
                onView: () => _showDrawer(cargo: cargo, viewOnly: true),
                onEdit: () => _showDrawer(cargo: cargo),
                onToggleStatus: () => _toggleStatusCargo(cargo),
              );
            },
          ),
        ),
      ],
    );
  }
}