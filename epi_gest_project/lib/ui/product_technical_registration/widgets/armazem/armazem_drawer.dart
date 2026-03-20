import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/armazem_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/armazem_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ArmazemDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(ArmazemModel) onSave;
  final ArmazemModel? armazemToEdit;
  final bool view;

  final List<UnidadeModel> availableUnidades;

  const ArmazemDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.armazemToEdit,
    this.view = false,
    required this.availableUnidades,
  });

  @override
  State<ArmazemDrawer> createState() => _ArmazemDrawerState();
}

class _ArmazemDrawerState extends State<ArmazemDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _unidadeController = TextEditingController();
  bool _status = true;
  bool _isSaving = false;

  List<UnidadeModel> _unidades = [];

  bool get _isEditing => widget.armazemToEdit != null && !widget.view;
  bool get _isViewing => widget.view;

  @override
  void initState() {
    super.initState();
    _unidades = List.from(widget.availableUnidades);
    if (_isEditing || _isViewing) {
      _nomeController.text = widget.armazemToEdit!.codigoArmazem;
      _unidadeController.text = widget.armazemToEdit!.unidade.nomeUnidade;
      _status = widget.armazemToEdit!.status;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _unidadeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final unidadeObj = _unidades
        .where((u) => u.nomeUnidade == _unidadeController.text)
        .firstOrNull;
    if (unidadeObj == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unidade inválida.')));
      return;
    }

    setState(() => _isSaving = true);

    final model = ArmazemModel(
      id: widget.armazemToEdit?.id,
      codigoArmazem: _nomeController.text.trim(),
      unidade: unidadeObj,
      status: _status,
    );

    try {
      final repository = Provider.of<ArmazemRepository>(context, listen: false);

      if (widget.armazemToEdit != null) {
        await repository.update(widget.armazemToEdit!.id!, model.toMap());
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
          ? 'Visualizar Armazém'
          : (_isEditing ? 'Editar Armazém' : 'Novo Armazém'),
      subtitle: _isViewing
          ? 'Detalhes do Armazém'
          : _isEditing
          ? 'Alterar dados do armazém'
          : 'Preencha os dados para cadastro',
      icon: Icons.store_mall_directory_outlined,
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
          spacing: 20,
          children: [
            CustomTextField(
              controller: _nomeController,
              label: 'Código/Nome do Armazém',
              hint: 'Ex: Almoxarifado Central, Estante A',
              icon: Icons.label,
              enabled: !_isViewing,
              validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
            ),
            CustomAutocompleteField(
              controller: _unidadeController,
              label: 'Unidade Física',
              hint: 'Selecione a unidade',
              icon: Icons.business,
              suggestions: _unidades.map((u) => u.nomeUnidade).toList(),
              enabled: !_isViewing,
            ),
          ],
        ),
      ),
    );
  }
}
