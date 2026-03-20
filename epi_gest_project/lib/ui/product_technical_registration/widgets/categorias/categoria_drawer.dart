import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/categoria_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/categoria_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoriaDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(CategoriaModel) onSave;
  final CategoriaModel? categoriaToEdit;
  final bool view;

  const CategoriaDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.categoriaToEdit,
    this.view = false,
  });

  @override
  State<CategoriaDrawer> createState() => _CategoriaDrawerState();
}

class _CategoriaDrawerState extends State<CategoriaDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _codController = TextEditingController();
  bool _status = true;
  bool _isSaving = false;

  bool get _isEditing => widget.categoriaToEdit != null && !widget.view;
  bool get _isViewing => widget.view;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) {
      _nomeController.text = widget.categoriaToEdit!.nomeCategoria;
      _codController.text = widget.categoriaToEdit!.codigoCategoria;
      _status = widget.categoriaToEdit!.status;
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

    final model = CategoriaModel(
      id: widget.categoriaToEdit?.id,
      codigoCategoria: _codController.text.trim(),
      nomeCategoria: _nomeController.text.trim(),
      status: _status,
    );

    try {
      final repository = Provider.of<CategoriaRepository>(context, listen: false);

      if (widget.categoriaToEdit != null) {
        await repository.update(widget.categoriaToEdit!.id!, model.toMap());
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
      title: _isViewing ? 'Visualizar Categoria' : _isEditing ? 'Editar Categoria' : 'Nova Categoria',
      subtitle: _isViewing ? 'Detalhes da categoria' : _isEditing ? 'Alterar dados da categoria' : 'Preencha os dados para cadastro',
      icon: Icons.category_outlined,
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
              controller: _codController,
              label: 'Codigo da Categoria',
              hint: 'Ex: Cap-01, Luv-02',
              icon: Icons.qr_code,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            CustomTextField(
              controller: _nomeController,
              label: 'Nome da Categoria',
              hint: 'Ex: Luva, Botina, Capacete',
              icon: Icons.category_outlined,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}