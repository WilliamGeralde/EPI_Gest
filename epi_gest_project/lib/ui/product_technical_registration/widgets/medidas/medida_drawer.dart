import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/medida_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/medida_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MedidaDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MedidaModel) onSave;
  final MedidaModel? medidaToEdit;
  final bool view;

  const MedidaDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.medidaToEdit,
    this.view = false,
  });

  @override
  State<MedidaDrawer> createState() => _MedidaDrawerState();
}

class _MedidaDrawerState extends State<MedidaDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _status = true;
  bool _isSaving = false;

  bool get _isEditing => widget.medidaToEdit != null && !widget.view;
  bool get _isViewing => widget.view;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) {
      _nomeController.text = widget.medidaToEdit!.nomeMedida;
      _status = widget.medidaToEdit!.status;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final model = MedidaModel(
      id: widget.medidaToEdit?.id,
      nomeMedida: _nomeController.text.trim(),
      status: _status,
    );

    try {
      final repository = Provider.of<MedidaRepository>(context, listen: false);

      if (widget.medidaToEdit != null) {
        await repository.update(widget.medidaToEdit!.id!, model.toMap());
        _showSnack('Unidade atualizada com sucesso!', Colors.green);
      } else {
        await repository.create(model);
        _showSnack('Unidade criada com sucesso!', Colors.green);
      }

      widget.onSave(model);
      widget.onClose();

    } on AppwriteException catch (e) {
      _showSnack('Erro ao salvar: ${e.message}', Colors.red);
    } catch (e) {
      _showSnack('Erro inesperado: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseAddDrawer(
      title: _isViewing ? 'Visualizar Unidade' : _isEditing ? 'Editar Unidade' : 'Nova Unidade',
      subtitle: _isViewing ? 'Detalhes da unidade' : _isEditing ? 'Alterar dados da medida' : 'Preencha os dados para cadastro',
      icon: Icons.straighten_outlined,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      isEditing: _isEditing,
      isViewing: _isViewing,
      widthFactor: 0.4,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            CustomTextField(
              controller: _nomeController,
              label: 'Nome da Unidade',
              hint: 'Ex: Par, Peça, Caixa',
              icon: Icons.label_outline,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}