import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/cargo_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/cargo_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CargoDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(CargoModel) onSave;
  final CargoModel? cargoToEdit;
  final bool view;

  const CargoDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.cargoToEdit,
    this.view = false,
  });

  @override
  State<CargoDrawer> createState() => _CargoDrawerState();
}

class _CargoDrawerState extends State<CargoDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCargoController = TextEditingController();
  final _codigoCargoController = TextEditingController();

  bool get _isEditing => widget.cargoToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) _populateForm();
  }

  void _populateForm() {
    final cargo = widget.cargoToEdit!;
    _nomeCargoController.text = cargo.nomeCargo;
    _codigoCargoController.text = cargo.codigoCargo;
  }

  @override
  void dispose() {
    _nomeCargoController.dispose();
    _codigoCargoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final cargoModel = CargoModel(
      id: widget.cargoToEdit?.id,
      codigoCargo: _codigoCargoController.text.trim(),
      nomeCargo: _nomeCargoController.text.trim(),
    );

    try {
      final repository = Provider.of<CargoRepository>(context, listen: false);
      
      if (widget.cargoToEdit != null) {
        await repository.update(widget.cargoToEdit!.id!, cargoModel.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cargo atualizado com sucesso!'), backgroundColor: Colors.green),
        );
      } else {
        await repository.create(cargoModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cargo criado com sucesso!'), backgroundColor: Colors.green),
        );
      }

      widget.onSave(cargoModel);
      widget.onClose();
      
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BaseAddDrawer(
      title: _isViewing ? 'Visualizar Cargo' : _isEditing ? 'Editar Cargo' : 'Novo Cargo',
      subtitle: _isViewing ? 'Informações completas do cargo' : _isEditing ? 'Alterar dados do cargo' : 'Preencha os dados para cadastro',
      icon: Icons.badge_outlined,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isEditing: _isEditing,
      isViewing: _isViewing,
      isSaving: _isSaving,
      widthFactor: 0.4,
      child: _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final isEnabled = !_isViewing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          CustomTextField(
            controller: _codigoCargoController,
            label: 'Código do Cargo',
            hint: 'Ex: ANL01, GER02, ASSIS01, OP03',
            enabled: isEnabled,
            icon: Icons.qr_code_outlined,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            controller: _nomeCargoController,
            label: 'Descrição do Cargo',
            hint: 'Ex: Analista, Gerente, Assistente, Operador',
            enabled: isEnabled,
            icon: Icons.work_outline,
            validator: (v) => (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
        ],
      ),
    );
  }
}