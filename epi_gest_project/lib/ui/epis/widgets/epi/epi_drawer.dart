import 'dart:io';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/unidade_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/categoria_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/marcas_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/medida_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/categoria_model.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/marcas_model.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/medida_model.dart';
import 'package:epi_gest_project/ui/utils/input_formatters.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/image_picker_widget.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EpiDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function()? onSave;
  final EpiModel? epiToEdit;
  final bool view;

  const EpiDrawer({
    super.key,
    required this.onClose,
    this.onSave,
    this.epiToEdit,
    this.view = false,
  });

  @override
  State<EpiDrawer> createState() => _EpiDrawerState();
}

class _EpiDrawerState extends State<EpiDrawer> {
  final _formKey = GlobalKey<FormState>();

  // Estados
  File? _imageFile;
  String? _imageUrl;
  DateTime? _validadeCA;
  bool _isSaving = false;
  bool _isLoading = true;
  String? _loadingError;

  bool get _isEditing => widget.epiToEdit != null && !widget.view;
  bool get _isAdding => widget.epiToEdit == null && !widget.view;
  bool get _isViewing => widget.view;
  bool get _isEnabled => !_isViewing;

  // Controladores
  late final Map<String, TextEditingController> _controllers;

  // Listas de Dados (Objetos completos)
  List<CategoriaModel> _categorias = [];
  List<MarcasModel> _marcas = [];
  List<MedidaModel> _medidas = [];

  // Listas de Sugestões (Strings para Autocomplete)
  List<String> _sugestaoCategorias = [];
  List<String> _sugestaoMarcas = [];
  List<String> _sugestaoMedidas = [];

  // Keys para botões de adicionar
  final GlobalKey _categoriaButtonKey = GlobalKey();
  final GlobalKey _marcaButtonKey = GlobalKey();
  final GlobalKey _medidaButtonKey = GlobalKey();

  // Controller auxiliar para os modais de criação rápida
  final TextEditingController _newItemNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controllers = {
      'ca': TextEditingController(),
      'nome': TextEditingController(),
      'validadeCA': TextEditingController(),
      'categoria': TextEditingController(),
      'marca': TextEditingController(),
      'unidadeMedida': TextEditingController(),
      'quantidade': TextEditingController(),
      'valor': TextEditingController(),
      'periodicidade': TextEditingController(),
    };

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      final catRepo = Provider.of<CategoriaRepository>(context, listen: false);
      final marcaRepo = Provider.of<MarcasRepository>(context, listen: false);
      final medidaRepo = Provider.of<MedidaRepository>(context, listen: false);
      final unidadeRepo = Provider.of<UnidadeRepository>(
        context,
        listen: false,
      );

      final results = await Future.wait([
        catRepo.getAllCategorias(),
        marcaRepo.getAllMarcas(),
        medidaRepo.getAllMedidas(),
        unidadeRepo.getAllUnidades(),
      ]);

      if (!mounted) return;

      setState(() {
        _categorias = results[0] as List<CategoriaModel>;
        _marcas = results[1] as List<MarcasModel>;
        _medidas = results[2] as List<MedidaModel>;

        _sugestaoCategorias = _categorias.map((e) => e.nomeCategoria).toList();
        _sugestaoMarcas = _marcas.map((e) => e.nomeMarca).toList();
        _sugestaoMedidas = _medidas.map((e) => e.nomeMedida).toList();

        _isLoading = false;
      });

      if (!_isAdding) {
        _populateForm();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingError = "Falha ao carregar dados: $e";
      });
    }
  }

  void _populateForm() {
    final epi = widget.epiToEdit!;

    _controllers['ca']!.text = epi.ca;
    _controllers['nome']!.text = epi.nomeProduto;
    _controllers['quantidade']!.text = epi.estoque.toString();
    _controllers['valor']!.text = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    ).format(epi.valor);
    _controllers['periodicidade']!.text = epi.periodicidade.toString();

    _controllers['categoria']!.text = epi.categoria.nomeCategoria;
    _controllers['marca']!.text = epi.marca.nomeMarca;
    _controllers['unidadeMedida']!.text = epi.medida.nomeMedida;

    _validadeCA = epi.validadeCa;
    _controllers['validadeCA']!.text = DateFormat(
      'dd/MM/yyyy',
    ).format(epi.validadeCa);
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    _newItemNameController.dispose();
    super.dispose();
  }

  // --- Métodos de Salvar ---

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_validadeCA == null) {
      _showErrorSnackBar('A data de validade do CA é obrigatória');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final categoria = _findItemOrThrow(
        _categorias,
        (e) => e.nomeCategoria,
        _controllers['categoria']!.text,
        "Categoria",
      );
      final marca = _findItemOrThrow(
        _marcas,
        (e) => e.nomeMarca,
        _controllers['marca']!.text,
        "Marca",
      );
      final medida = _findItemOrThrow(
        _medidas,
        (e) => e.nomeMedida,
        _controllers['unidadeMedida']!.text,
        "Unidade de Medida",
      );

      String valorText = _controllers['valor']!.text
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(',', '.')
          .trim();
      double valorDouble = double.tryParse(valorText) ?? 0.0;

      final epiToSave = EpiModel(
        id: widget.epiToEdit?.id,
        ca: _controllers['ca']!.text.trim(),
        nomeProduto: _controllers['nome']!.text.trim(),
        validadeCa: _validadeCA!,
        periodicidade: int.tryParse(_controllers['periodicidade']!.text) ?? 0,
        estoque: double.tryParse(_controllers['quantidade']!.text) ?? 0.0,
        valor: valorDouble,
        categoria: categoria,
        marca: marca,
        medida: medida,
      );

      final epiRepository = Provider.of<EpiRepository>(context, listen: false);

      if (_isEditing) {
        await epiRepository.update(epiToSave.id!, epiToSave.toMap());
        _showSuccessSnackBar('EPI atualizado com sucesso!');
      } else {
        await epiRepository.create(epiToSave);
        _showSuccessSnackBar('EPI cadastrado com sucesso!');
      }
      
      widget.onSave?.call();
      widget.onClose();
      

    } on appwrite.AppwriteException catch (e) {
      _showErrorSnackBar("Erro ao salvar: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  T _findItemOrThrow<T>(
    List<T> list,
    String Function(T) nameSelector,
    String value,
    String fieldName,
  ) {
    try {
      return list.firstWhere(
        (item) => nameSelector(item).toLowerCase() == value.toLowerCase(),
      );
    } catch (_) {
      throw Exception(
        "$fieldName inválido(a) ou não cadastrado(a). Crie um novo registro primeiro.",
      );
    }
  }

  // --- Modais de Criação Rápida Melhorados ---

  void _showAddDialog({
    required String title,
    required String label,
    required Future<void> Function(String) onConfirm,
  }) {
    _newItemNameController.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Este item será adicionado aos cadastros do sistema.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _newItemNameController,
              label: label,
              hint: "Digite o nome",
              icon: Icons.edit,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final val = _newItemNameController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  await onConfirm(val);
                  _showSuccessSnackBar('$title criado com sucesso!');
                } catch (e) {
                  _showErrorSnackBar("Erro ao criar: $e");
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCategoria(String nome) async {
    final repo = Provider.of<CategoriaRepository>(context, listen: false);
    final codigo = nome.length > 3
        ? nome.substring(0, 3).toUpperCase()
        : nome.toUpperCase();
    final newItem = await repo.create(
      CategoriaModel(codigoCategoria: codigo, nomeCategoria: nome),
    );
    setState(() {
      _categorias.add(newItem);
      _sugestaoCategorias.add(newItem.nomeCategoria);
      _controllers['categoria']!.text = newItem.nomeCategoria;
    });
  }

  Future<void> _createMarca(String nome) async {
    final repo = Provider.of<MarcasRepository>(context, listen: false);
    final newItem = await repo.create(MarcasModel(nomeMarca: nome));
    setState(() {
      _marcas.add(newItem);
      _sugestaoMarcas.add(newItem.nomeMarca);
      _controllers['marca']!.text = newItem.nomeMarca;
    });
  }

  Future<void> _createMedida(String nome) async {
    final repo = Provider.of<MedidaRepository>(context, listen: false);
    final newItem = await repo.create(MedidaModel(nomeMedida: nome));
    setState(() {
      _medidas.add(newItem);
      _sugestaoMedidas.add(newItem.nomeMedida);
      _controllers['unidadeMedida']!.text = newItem.nomeMedida;
    });
  }

  // --- Helpers UI ---

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _validadeCA ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _validadeCA = picked;
        _controllers['validadeCA']!.text = DateFormat(
          'dd/MM/yyyy',
        ).format(picked);
      });
    }
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title = _isViewing
        ? 'Visualizar EPI'
        : _isEditing
        ? 'Editar EPI'
        : 'Novo EPI';
    String subtitle = _isViewing
        ? 'Informações do ${widget.epiToEdit?.nomeProduto ?? ""}'
        : _isEditing
        ? 'Altere os dados do EPI'
        : 'Preencha os dados do novo EPI';
    IconData icon = _isViewing
        ? Icons.visibility_outlined
        : _isEditing
        ? Icons.edit_outlined
        : Icons.add_box_outlined;

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      isEditing: _isEditing,
      isViewing: _isViewing,
      child: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Column(
        spacing: 16,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), Text('Carregando dados...')],
      );
    }
    if (_loadingError != null) {
      return Center(
        child: Text(
          _loadingError!,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 700) {
            return SingleChildScrollView(child: _buildTwoColumnLayout(theme));
          } else {
            return SingleChildScrollView(
              child: _buildSingleColumnLayout(theme),
            );
          }
        },
      ),
    );
  }

  // --- Layouts Responsivos ---

  Widget _buildTwoColumnLayout(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              ImagePickerWidget(
                imageFile: _imageFile,
                imageUrl: _imageUrl,
                onImagePicked: (file) => setState(() => _imageFile = file),
                onImageRemoved: () => setState(() => _imageFile = null),
                viewOnly: !_isEnabled,
                height: 275,
                width: 325,
              ),
              const SizedBox(height: 24),
              InfoSection(
                title: 'Identificação Técnica',
                icon: Icons.info_outline,
                child: Column(
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _controllers['ca']!,
                            label: 'C.A.',
                            hint: '12345',
                            icon: Icons.verified_user_outlined,
                            enabled: _isEnabled,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Obrigatório' : null,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        Expanded(
                          child: CustomDateField(
                            controller: _controllers['validadeCA']!,
                            label: 'Validade C.A.',
                            hint: 'dd/mm/aaaa',
                            icon: Icons.calendar_today,
                            enabled: _isEnabled,
                            onTap: _selectDate,
                          ),
                        ),
                      ],
                    ),
                    CustomTextField(
                      controller: _controllers['nome']!,
                      label: 'Nome do EPI',
                      hint: 'Ex: Luva de Vaqueta',
                      icon: Icons.label_outline,
                      enabled: _isEnabled,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Coluna Direita: Classificação e Logística
        Expanded(
          child: Column(
            children: [
              InfoSection(
                title: 'Classificação',
                icon: Icons.category_outlined,
                child: Column(
                  spacing: 16,
                  children: [
                    CustomAutocompleteField(
                      controller: _controllers['categoria']!,
                      label: 'Categoria',
                      hint: 'Selecione a categoria',
                      icon: Icons.category,
                      enabled: _isEnabled,
                      suggestions: _sugestaoCategorias,
                      showAddButton: _isEnabled,
                      addButtonKey: _categoriaButtonKey,
                      onAddPressed: () => _showAddDialog(
                        title: 'Nova Categoria',
                        label: 'Nome da Categoria',
                        onConfirm: _createCategoria,
                      ),
                    ),
                    CustomAutocompleteField(
                      controller: _controllers['marca']!,
                      label: 'Marca',
                      hint: 'Selecione a marca',
                      icon: Icons.branding_watermark_outlined,
                      enabled: _isEnabled,
                      suggestions: _sugestaoMarcas,
                      showAddButton: _isEnabled,
                      addButtonKey: _marcaButtonKey,
                      onAddPressed: () => _showAddDialog(
                        title: 'Nova Marca',
                        label: 'Nome da Marca',
                        onConfirm: _createMarca,
                      ),
                    ),
                    CustomAutocompleteField(
                      controller: _controllers['unidadeMedida']!,
                      label: 'Unidade Medida',
                      hint: 'Ex: Par, Peça',
                      icon: Icons.straighten,
                      enabled: _isEnabled,
                      suggestions: _sugestaoMedidas,
                      showAddButton: _isEnabled,
                      addButtonKey: _medidaButtonKey,
                      onAddPressed: () => _showAddDialog(
                        title: 'Nova Medida',
                        label: 'Nome (ex: Par)',
                        onConfirm: _createMedida,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              InfoSection(
                title: 'Estoque e Logística',
                icon: Icons.inventory_2_outlined,
                child: Column(
                  spacing: 16,
                  children: [
                    Row(
                      spacing: 16,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _controllers['quantidade']!,
                            label: 'Estoque Atual',
                            hint: '0',
                            icon: Icons.numbers,
                            enabled: _isEnabled,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: _controllers['valor']!,
                            label: 'Valor Unitário (R\$)',
                            hint: 'R\$ 0.00',
                            icon: Icons.attach_money,
                            enabled: _isEnabled,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CurrencyInputFormatter()
                            ],
                          ),
                        ),
                      ],
                    ),
                    CustomTextField(
                      controller: _controllers['periodicidade']!,
                      label: 'Periodicidade de Troca (dias)',
                      hint: 'Ex: 30',
                      icon: Icons.update,
                      enabled: _isEnabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout(ThemeData theme) {
    return Column(
      spacing: 24,
      children: [
        ImagePickerWidget(
          imageFile: _imageFile,
          imageUrl: _imageUrl,
          onImagePicked: (file) => setState(() => _imageFile = file),
          onImageRemoved: () => setState(() => _imageFile = null),
          viewOnly: !_isEnabled,
          height: 275,
          width: 325,
        ),
        InfoSection(
          title: 'Identificação Técnica',
          icon: Icons.info_outline,
          child: Column(
            spacing: 16,
            children: [
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _controllers['ca']!,
                      label: 'C.A.',
                      hint: '12345',
                      icon: Icons.verified_user_outlined,
                      enabled: _isEnabled,
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Obrigatório' : null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Expanded(
                    child: CustomDateField(
                      controller: _controllers['validadeCA']!,
                      label: 'Validade C.A.',
                      hint: 'dd/mm/aaaa',
                      icon: Icons.calendar_today,
                      enabled: _isEnabled,
                      onTap: _selectDate,
                    ),
                  ),
                ],
              ),
              CustomTextField(
                controller: _controllers['nome']!,
                label: 'Nome do EPI',
                hint: 'Ex: Luva de Vaqueta',
                icon: Icons.label_outline,
                enabled: _isEnabled,
                validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
              ),
            ],
          ),
        ),
        InfoSection(
          title: 'Classificação',
          icon: Icons.category_outlined,
          child: Column(
            spacing: 16,
            children: [
              CustomAutocompleteField(
                controller: _controllers['categoria']!,
                label: 'Categoria',
                hint: 'Selecione a categoria',
                icon: Icons.category,
                enabled: _isEnabled,
                suggestions: _sugestaoCategorias,
                showAddButton: _isEnabled,
                addButtonKey: _categoriaButtonKey,
                onAddPressed: () => _showAddDialog(
                  title: 'Nova Categoria',
                  label: 'Nome da Categoria',
                  onConfirm: _createCategoria,
                ),
              ),
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: CustomAutocompleteField(
                      controller: _controllers['marca']!,
                      label: 'Marca',
                      hint: 'Selecione a marca',
                      icon: Icons.branding_watermark_outlined,
                      enabled: _isEnabled,
                      suggestions: _sugestaoMarcas,
                      showAddButton: _isEnabled,
                      addButtonKey: _marcaButtonKey,
                      onAddPressed: () => _showAddDialog(
                        title: 'Nova Marca',
                        label: 'Nome da Marca',
                        onConfirm: _createMarca,
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomAutocompleteField(
                      controller: _controllers['unidadeMedida']!,
                      label: 'Unidade Medida',
                      hint: 'Ex: Par, Peça',
                      icon: Icons.straighten,
                      enabled: _isEnabled,
                      suggestions: _sugestaoMedidas,
                      showAddButton: _isEnabled,
                      addButtonKey: _medidaButtonKey,
                      onAddPressed: () => _showAddDialog(
                        title: 'Nova Medida',
                        label: 'Nome (ex: Par)',
                        onConfirm: _createMedida,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        InfoSection(
          title: 'Estoque e Logística',
          icon: Icons.inventory_2_outlined,
          child: Column(
            spacing: 16,
            children: [
              Row(
                spacing: 16,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _controllers['quantidade']!,
                      label: 'Estoque Atual',
                      hint: '0',
                      icon: Icons.numbers,
                      enabled: _isEnabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  Expanded(
                    child: CustomTextField(
                      controller: _controllers['valor']!,
                      label: 'Valor Unitário (R\$)',
                      hint: '0.00',
                      icon: Icons.attach_money,
                      enabled: _isEnabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
              CustomTextField(
                controller: _controllers['periodicidade']!,
                label: 'Periodicidade de Troca (dias)',
                hint: 'Ex: 30',
                icon: Icons.update,
                enabled: _isEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
