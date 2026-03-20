import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/riscos_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/riscos_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RiscosDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(RiscosModel) onSave;
  final RiscosModel? riscoToEdit;
  final bool view;

  const RiscosDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.riscoToEdit,
    this.view = false,
  });

  @override
  State<RiscosDrawer> createState() => _RiscosDrawerState();
}

class _RiscosDrawerState extends State<RiscosDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeRiscoController = TextEditingController();
  final _codigoRiscoController = TextEditingController();

  bool get _isEditing => widget.riscoToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) _populateForm();
  }

  void _populateForm() {
    final risco = widget.riscoToEdit!;
    _nomeRiscoController.text = risco.nomeRiscos;
    _codigoRiscoController.text = risco.codigoRiscos;
  }

  @override
  void dispose() {
    _nomeRiscoController.dispose();
    _codigoRiscoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final riscoModel = RiscosModel(
      id: widget.riscoToEdit?.id,
      codigoRiscos: _codigoRiscoController.text.trim(),
      nomeRiscos: _nomeRiscoController.text.trim(),
    );

    try {
      final repository = Provider.of<RiscosRepository>(context, listen: false);

      if (widget.riscoToEdit != null) {
        // Update
        await repository.update(widget.riscoToEdit!.id!, riscoModel.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risco atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create
        await repository.create(riscoModel);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Risco criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSave(riscoModel);
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
      title = 'Visualizar Risco';
      subtitle = 'Informações completas do risco';
    } else if (_isEditing) {
      title = 'Editar Risco';
      subtitle = 'Altere os dados do risco';
    } else {
      title = 'Adicionar Risco';
      subtitle = 'Preencha os dados do novo risco';
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: Icons.warning_outlined,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          CustomTextField(
            controller: _codigoRiscoController,
            label: 'Codigo do Risco',
            hint: 'Ex: QUI01, FIS01, BIO03',
            enabled: isEnabled,
            icon: Icons.qr_code_outlined,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
          CustomTextField(
            controller: _nomeRiscoController,
            label: 'Descrição do Risco',
            hint: 'Ex: Químico, Físico, Biológico, Acidente',
            enabled: isEnabled,
            icon: Icons.warning_amber_outlined,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
        ],
      ),
    );
  }
}