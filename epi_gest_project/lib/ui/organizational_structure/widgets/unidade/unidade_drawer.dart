import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/unidade_controller.dart';
import 'package:epi_gest_project/ui/utils/input_formatters.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UnidadeDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(UnidadeModel) onSave;
  final UnidadeModel? unidadeToEdit;
  final bool view;

  const UnidadeDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.unidadeToEdit,
    this.view = false,
  });

  @override
  State<UnidadeDrawer> createState() => _UnidadeDrawerState();
}

class _UnidadeDrawerState extends State<UnidadeDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _tipoUnidadeController = TextEditingController();

  bool _statusController = true;

  bool get _isEditing => widget.unidadeToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) _populateForm();
  }

  void _populateForm() {
    final u = widget.unidadeToEdit!;
    _nomeController.text = u.nomeUnidade;
    _cnpjController.text = u.cnpj;
    _enderecoController.text = u.endereco;
    _tipoUnidadeController.text = u.tipoUnidade;
    _statusController = u.status;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _enderecoController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final unitModel = UnidadeModel(
      id: widget.unidadeToEdit?.id,
      nomeUnidade: _nomeController.text.trim(),
      cnpj: _cnpjController.text.trim(),
      endereco: _enderecoController.text.trim(),
      tipoUnidade: _tipoUnidadeController.text.trim(),
      status: _statusController,
    );

    try {
      final controller = Provider.of<UnidadeController>(context, listen: false);
      final unidadeSalva = await controller.salvarUnidade(
        unidade: unitModel,
        isEditing: _isEditing,
      );

      if (_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unidade atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unidade criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSave(unidadeSalva);
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
      title = "Visualizar Unidade";
      subtitle = "Informações completas da unidade";
    } else if (_isEditing) {
      title = "Editar Unidade";
      subtitle = "Altere os dados da unidade";
    } else {
      title = "Adicionar Unidade";
      subtitle = "Preencha os dados da nova unidade";
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: Icons.business_outlined,
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
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            controller: _nomeController,
            label: 'Nome da Unidade',
            hint: 'Filial de Araras',
            enabled: isEnabled,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            icon: Icons.business_outlined,
          ),
          CustomTextField(
            controller: _enderecoController,
            label: 'Endereço Completo',
            hint: '',
            enabled: isEnabled,
            maxLines: 2,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
            icon: Icons.location_on_outlined,
          ),
          Row(
            spacing: 15,
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cnpjController,
                  label: 'CNPJ',
                  hint: '00.000.000/0000-00',
                  enabled: isEnabled,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    CnpjInputFormatter()
                  ],
                ),
              ),
              Expanded(
                child: CustomAutocompleteField(
                  controller: _tipoUnidadeController,
                  label: 'Tipo de Unidade',
                  hint: 'Selecione uma unidade',
                  icon: Icons.category_outlined,
                  suggestions: ['Matriz', 'Filial'],
                  enabled: isEnabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
