import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/vinculo_controller.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VinculoDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(VinculoModel) onSave;
  final VinculoModel? vinculoToEdit;
  final bool view;

  const VinculoDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.vinculoToEdit,
    this.view = false,
  });

  @override
  State<VinculoDrawer> createState() => _VinculoDrawerState();
}

class _VinculoDrawerState extends State<VinculoDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeVinculoController = TextEditingController();

  bool get _isEditing => widget.vinculoToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final vinculo = widget.vinculoToEdit!;
    _nomeVinculoController.text = vinculo.nomeVinculo;
  }

  @override
  void dispose() {
    _nomeVinculoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final vinculoModel = VinculoModel(
      id: widget.vinculoToEdit?.id,
      nomeVinculo: _nomeVinculoController.text.trim(),
    );

    try {
      final controller = Provider.of<VinculoController>(context, listen: false);
      final vinculoSalvo = await controller.salvarVinculo(
        vinculo: vinculoModel,
        isEditing: _isEditing,
      );

      if (_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vinculo atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vinculo criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSave(vinculoSalvo);
      widget.onClose();
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
      title = 'Visualizar Vínculo';
      subtitle = 'Informações completas do vínculo';
    } else if (_isEditing) {
      title = 'Editar Vínculo';
      subtitle = 'Altere os dados do vínculo';
    } else {
      title = 'Adicionar Vínculo';
      subtitle = 'Preencha os dados do novo vínculo';
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: Icons.assignment_ind_outlined,
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
        children: [
          CustomTextField(
            controller: _nomeVinculoController,
            label: 'Descrição do Vínculo',
            hint: 'Ex: CLT, Pessoa Jurídica, Estagiário, Terceirizado',
            enabled: isEnabled,
            icon: Icons.work_history_outlined,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
        ],
      ),
    );
  }
}
