import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/setor_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/setor_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SetorDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(SetorModel) onSave;
  final SetorModel? setorToEdit;
  final bool view;

  const SetorDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.setorToEdit,
    this.view = false,
  });

  @override
  State<SetorDrawer> createState() => _SetorDrawerState();
}

class _SetorDrawerState extends State<SetorDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeSetorController = TextEditingController();
  final _codigoSetorController = TextEditingController();

  bool get _isEditing => widget.setorToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) _populateForm();
  }

  void _populateForm() {
    final setor = widget.setorToEdit!;
    _nomeSetorController.text = setor.nomeSetor;
    _codigoSetorController.text = setor.codigoSetor;
  }

  @override
  void dispose() {
    _nomeSetorController.dispose();
    _codigoSetorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final setorModel = SetorModel(
      id: widget.setorToEdit?.id,
      codigoSetor: _codigoSetorController.text.trim(),
      nomeSetor: _nomeSetorController.text.trim(),
    );

    try {
      final repository = Provider.of<SetorRepository>(context, listen: false);

      if (widget.setorToEdit != null) {
        await repository.update(widget.setorToEdit!.id!, setorModel.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setor atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await repository.create(setorModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Setor criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSave(setorModel);
      widget.onClose();
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title;
    String subtitle;

    if (_isViewing) {
      title = 'Visualizar Setor';
      subtitle = 'Informações completas do Setor';
    } else if (_isEditing) {
      title = 'Editar Setor';
      subtitle = 'Altere os dados do Setor';
    } else {
      title = 'Adicionar Setor';
      subtitle = 'Preencha os dados do novo Setor';
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: Icons.work_outline,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      isEditing: _isEditing,
      isViewing: _isViewing,
      widthFactor: 0.4,
      child: _buildForm(theme),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final isEnabled = !_isViewing;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          CustomTextField(
            controller: _codigoSetorController,
            label: 'Codigo do Setor',
            hint: 'Ex: PROD01, ADM02, RH01',
            icon: Icons.workspaces_outlined,
            enabled: isEnabled,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            controller: _nomeSetorController,
            label: 'Descrição do Setor',
            hint: 'Ex: Produção, Administrativo, RH, Financeiro',
            icon: Icons.work_outline,
            enabled: isEnabled,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
        ],
      ),
    );
  }
}
