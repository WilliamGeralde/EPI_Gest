import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/marcas_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/marcas_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MarcasDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MarcasModel) onSave;
  final MarcasModel? marcaToEdit;
  final bool view;

  const MarcasDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.marcaToEdit,
    this.view = false,
  });

  @override
  State<MarcasDrawer> createState() => _MarcasDrawerState();
}

class _MarcasDrawerState extends State<MarcasDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  bool _status = true;
  bool _isSaving = false;

  bool get _isEditing => widget.marcaToEdit != null && !widget.view;
  bool get _isViewing => widget.view;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) {
      _nomeController.text = widget.marcaToEdit!.nomeMarca;
      _status = widget.marcaToEdit!.status;
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

    final model = MarcasModel(
      id: widget.marcaToEdit?.id,
      nomeMarca: _nomeController.text.trim(),
      status: _status,
    );

    try {
      final repository = Provider.of<MarcasRepository>(context, listen: false);

      if (widget.marcaToEdit != null) {
        await repository.update(widget.marcaToEdit!.id!, model.toMap());
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
      title: _isViewing ? 'Visualizar Marca' : _isEditing ? 'Editar Marca' : 'Nova Marca',
      subtitle: _isViewing ? 'Detalhes da marca' : _isEditing ? 'Alterar dados da marca' : 'Preencha os dados para cadastro',
      icon: Icons.branding_watermark_outlined,
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
              label: 'Nome da Marca',
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