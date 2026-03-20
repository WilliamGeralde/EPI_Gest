import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/fornecedor_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/fornecedor_model.dart';
import 'package:epi_gest_project/ui/utils/input_formatters.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FornecedoresDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(FornecedorModel) onSave;
  final FornecedorModel? fornecedorToEdit;
  final bool view;

  const FornecedoresDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.fornecedorToEdit,
    this.view = false,
  });

  @override
  State<FornecedoresDrawer> createState() => _FornecedoresDrawerState();
}

class _FornecedoresDrawerState extends State<FornecedoresDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _enderecoController = TextEditingController();
  bool _status = true;
  bool _isSaving = false;

  bool get _isEditing => widget.fornecedorToEdit != null && !widget.view;
  bool get _isViewing => widget.view;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) {
      _nomeController.text = widget.fornecedorToEdit!.nomeFornecedor;
      _cnpjController.text = widget.fornecedorToEdit!.cnpj;
      _enderecoController.text = widget.fornecedorToEdit!.endereco;
      _status = widget.fornecedorToEdit!.status;
    }
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

    final model = FornecedorModel(
      id: widget.fornecedorToEdit?.id,
      nomeFornecedor: _nomeController.text.trim(),
      cnpj: _cnpjController.text.trim(),
      endereco: _enderecoController.text.trim(),
      status: _status,
    );

    try {
      final repository = Provider.of<FornecedorRepository>(
        context,
        listen: false,
      );

      if (widget.fornecedorToEdit != null) {
        await repository.update(widget.fornecedorToEdit!.id!, model.toMap());
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return BaseAddDrawer(
      title: _isViewing
          ? 'Visualizar Fornecedor'
          : _isEditing
          ? 'Editar Fornecedor'
          : 'Novo Fornecedor',
      subtitle: _isViewing
          ? 'Detalhes do fornecedor'
          : _isEditing
          ? 'Alterar dados do fornecedor'
          : 'Preencha os dados para cadastro',
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
              label: 'Nome do Fornecedor',
              hint: 'Ex: Whirlpool',
              icon: Icons.business_outlined,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            CustomTextField(
              controller: _cnpjController,
              label: 'CNPJ',
              hint: '00.000.000/0000-00',
              icon: Icons.badge_outlined,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
              inputFormatters: [
                CnpjInputFormatter()
              ],
            ),
            CustomTextField(
              controller: _enderecoController,
              label: 'Endereço Completo',
              hint: '',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              enabled: !_isViewing,
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
          ],
        ),
      ),
    );
  }
}
