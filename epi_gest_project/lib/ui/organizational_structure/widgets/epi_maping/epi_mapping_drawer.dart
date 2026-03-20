import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/cargo_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/mapeamento_epi_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/riscos_repository.dart';
import 'package:epi_gest_project/data/repositories/organizational_structure/setor_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/cargo_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/riscos_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/setor_model.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EpiMappingDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(MapeamentoEpiModel)? onSave;
  final MapeamentoEpiModel? mappingToEdit;
  final bool view;

  final List<SetorModel> availableSectors;
  final List<CargoModel> availableRoles;
  final List<RiscosModel> availableRisks;
  final List<EpiModel> availableEpis;

  const EpiMappingDrawer({
    super.key,
    required this.onClose,
    this.onSave,
    this.mappingToEdit,
    this.view = false,
    required this.availableSectors,
    required this.availableRoles,
    required this.availableRisks,
    required this.availableEpis,
  });

  @override
  State<EpiMappingDrawer> createState() => _EpiMappingDrawerState();
}

class _EpiMappingDrawerState extends State<EpiMappingDrawer> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _codigoController = TextEditingController();
  final _nomeController = TextEditingController();
  final _setorController = TextEditingController();
  final _cargoController = TextEditingController();

  List<String> _selectedRiskNames = [];

  // Keys para botões de adicionar
  final GlobalKey _setorButtonKey = GlobalKey();
  final _nomeSetorController = TextEditingController();
  final _codigoSetorController = TextEditingController();

  final GlobalKey _cargoButtonKey = GlobalKey();
  final _nomeCargoController = TextEditingController();
  final _codigoCargoController = TextEditingController();

  final GlobalKey _riskButtonKey = GlobalKey();
  final GlobalKey _riskKey = GlobalKey();
  final GlobalKey _epiKey = GlobalKey();

  late List<SetorModel> _setores = [];
  late List<CargoModel> _cargos = [];
  List<RiscosModel> _riscos = [];

  List<String> _setoresSugestoes = [];
  List<String> _cargosSugestoes = [];

  List<String> _selectedRiskIds = [];
  List<String> _selectedEpisIds = [];

  bool _statusAtivo = true;
  bool _isSaving = false;

  bool get _isEditing => widget.mappingToEdit != null && !widget.view;
  bool get _isViewing => widget.view;
  bool get _isEnabled => !_isViewing;

  @override
  void initState() {
    super.initState();
    _setores = List.from(widget.availableSectors);
    _cargos = List.from(widget.availableRoles);
    _riscos = List.from(widget.availableRisks);

    if (widget.mappingToEdit != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final map = widget.mappingToEdit!;
    _codigoController.text = map.codigoMapeamento;
    _nomeController.text = map.nomeMapeamento;
    _statusAtivo = map.status;

    _setorController.text = map.setor.nomeSetor;
    _cargoController.text = map.cargo.nomeCargo;

    _selectedRiskIds = map.riscos.map((r) => r.nomeRiscos).toList();
    _selectedEpisIds = map.epis
        .map((c) => c.nomeProduto)
        .toList();
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nomeController.dispose();
    _setorController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  void _showAddSetorDialog() {
    _nomeSetorController.clear();
    _codigoSetorController.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adicionar Novo Setor',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  CustomTextField(
                    controller: _codigoSetorController,
                    label: 'Código do Setor',
                    hint: 'Ex: ADM',
                    icon: Icons.workspaces_outlined,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  CustomTextField(
                    controller: _nomeSetorController,
                    label: 'Nome do Cargo',
                    hint: 'Ex: Administrativo',
                    icon: Icons.work_outline,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _createSetor(context);
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Adicionar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createSetor(BuildContext dialogContext) async {
    final nome = _nomeSetorController.text.trim();
    final codigo = _codigoSetorController.text.trim();

    final repo = Provider.of<SetorRepository>(context, listen: false);
    try {
      Navigator.pop(dialogContext);

      final novoSetor = SetorModel(codigoSetor: codigo, nomeSetor: nome);

      final created = await repo.create(novoSetor);

      setState(() {
        _setores.add(created);
        _setoresSugestoes.add(created.nomeSetor);
        _nomeSetorController.text = created.nomeSetor;
      });
      _showSuccessSnackBar('Setor criado com sucesso!');
    } catch (e) {
      _showErrorSnackBar("Erro ao criar setor: $e");
    }
  }

  void _showAddCargoDialog() {
    _nomeCargoController.clear();
    _codigoCargoController.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 20,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adicionar Novo Cargo',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  CustomTextField(
                    controller: _codigoCargoController,
                    label: 'Código do Cargo',
                    hint: 'Ex: ANL01, GER02, ASSIS01, OP03',
                    icon: Icons.qr_code_outlined,
                  ),
                  CustomTextField(
                    controller: _nomeCargoController,
                    label: 'Descrição do Cargo',
                    hint: 'Ex: Analista, Gerente, Assistente, Operador',
                    icon: Icons.work_outline,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            _createCargo(context);
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Adicionar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createCargo(BuildContext dialogContext) async {
    final nome = _nomeCargoController.text.trim();
    final codigo = _codigoCargoController.text.trim();

    final repo = Provider.of<CargoRepository>(context, listen: false);
    try {
      Navigator.pop(dialogContext);

      final novoCargo = CargoModel(codigoCargo: codigo, nomeCargo: nome);

      final created = await repo.create(novoCargo);

      setState(() {
        _cargos.add(created);
        _cargosSugestoes.add(created.nomeCargo);
        _nomeCargoController.text = created.nomeCargo;
      });
      _showSuccessSnackBar('Cargo criado com sucesso!');
    } catch (e) {
      _showErrorSnackBar("Erro ao criar cargo: $e");
    }
  }

  void _showAddRiscoDialog() {
    final nomeController = TextEditingController();
    final codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar Novo Risco'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: codigoController,
              decoration: const InputDecoration(
                labelText: 'Código',
                hintText: 'Ex: QUI-01',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Risco',
                hintText: 'Ex: Químico',
              ),
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
              if (nomeController.text.isNotEmpty &&
                  codigoController.text.isNotEmpty) {
                try {
                  final repo = Provider.of<RiscosRepository>(
                    context,
                    listen: false,
                  );
                  final novo = RiscosModel(
                    codigoRiscos: codigoController.text.trim(),
                    nomeRiscos: nomeController.text.trim(),
                  );
                  final created = await repo.create(novo);

                  setState(() {
                    _riscos.add(created);
                    _selectedRiskNames.add(
                      created.nomeRiscos,
                    ); // Já seleciona o novo
                  });
                  Navigator.pop(ctx);
                  _showSuccessSnackBar('Risco criado com sucesso!');
                } catch (e) {
                  _showErrorSnackBar('Erro ao criar risco: $e');
                }
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final setorObj = _setores
        .where(
          (s) =>
              s.nomeSetor.toLowerCase() ==
              _setorController.text.trim().toLowerCase(),
        )
        .firstOrNull;

    final cargoObj = _cargos
        .where(
          (c) =>
              c.nomeCargo.toLowerCase() ==
              _cargoController.text.trim().toLowerCase(),
        )
        .firstOrNull;

    if (setorObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Setor inválido. Selecione da lista ou crie um novo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (cargoObj == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cargo inválido. Selecione da lista ou crie um novo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = Provider.of<MapeamentoEpiRepository>(context, listen: false);

      final riscosObj = widget.availableRisks
          .where((r) => _selectedRiskIds.contains(r.nomeRiscos))
          .toList();

      final epiObj = widget.availableEpis
          .where((c) => _selectedEpisIds.contains(c.nomeProduto))
          .toList();

      final newMapping = MapeamentoEpiModel(
        id: widget.mappingToEdit?.id,
        codigoMapeamento: _codigoController.text.trim(),
        nomeMapeamento: "${setorObj.nomeSetor} - ${cargoObj.nomeCargo}",
        cargo: cargoObj,
        setor: setorObj,
        riscos: riscosObj,
        epis: epiObj,
        status: _statusAtivo,
      );

      if (widget.mappingToEdit != null) {
        await repo.update(newMapping.id!, newMapping.toMap());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapeamento atualizado!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await repo.create(newMapping);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mapeamento criado!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (widget.onSave != null) widget.onSave!(newMapping);
      widget.onClose();
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.message}'),
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

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseAddDrawer(
      title: _isViewing
          ? 'Visualizar Mapeamento'
          : _isEditing
          ? 'Editar Mapeamento'
          : 'Novo Mapeamento',
      subtitle: _isViewing
          ? 'Informações completas do mapeamento'
          : _isEditing
          ? 'Alterar os dados do Mapeamento'
          : 'Preencha os dados para cadastro do mapeamento',
      icon: Icons.assignment_turned_in_outlined,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      widthFactor: 0.5,
      child: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        spacing: 24,
        children: [
          InfoSection(
            title: 'Identificação',
            icon: Icons.info_outline,
            child: Column(
              spacing: 16,
              children: [
                Row(
                  spacing: 16,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _codigoController,
                        label: 'Código do Mapeamento',
                        hint: 'Ex: MAP-001',
                        icon: Icons.qr_code,
                        enabled: _isEnabled,
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Obrigatório' : null,
                      ),
                    ),
                    Expanded(
                      child: CustomSwitchField(
                        value: _statusAtivo,
                        onChanged: (val) => setState(() => _statusAtivo = val),
                        label: 'Status do Mapeamento',
                        activeText: 'Ativo',
                        inactiveText: 'Inativo',
                        enabled: _isEnabled,
                        icon: Icons.assignment_turned_in_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          InfoSection(
            title: 'Vínculo Organizacional',
            icon: Icons.business,
            child: Column(
              spacing: 16,
              children: [
                CustomAutocompleteField(
                  controller: _setorController,
                  label: 'Setor / Departamento',
                  hint: 'Selecione ou adicione um setor',
                  icon: Icons.work_outline,
                  suggestions: _setores.map((s) => s.nomeSetor).toList(),
                  showAddButton: _isEnabled,
                  enabled: _isEnabled,
                  addButtonKey: _setorButtonKey,
                  onAddPressed: _showAddSetorDialog,
                ),

                CustomAutocompleteField(
                  controller: _cargoController,
                  label: 'Cargo / Função',
                  hint: 'Selecione ou adicione um cargo',
                  icon: Icons.badge_outlined,
                  suggestions: _cargos.map((c) => c.nomeCargo).toList(),
                  showAddButton: _isEnabled,
                  enabled: _isEnabled,
                  addButtonKey: _cargoButtonKey,
                  onAddPressed: _showAddCargoDialog,
                ),
              ],
            ),
          ),
          InfoSection(
            title: 'Riscos e EPIs',
            icon: Icons.warning_amber_rounded,
            child: Column(
              spacing: 16,
              children: [
                CustomMultiSelectField(
                  label: 'Riscos Ocupacionais',
                  hint: 'Selecione os riscos',
                  icon: Icons.warning_outlined,
                  selectedItems: _selectedRiskIds,
                  buttonKey: _riskKey,
                  enabled: _isEnabled,
                  showAddButton: _isEnabled,
                  addButtonKey: _riskButtonKey,
                  onAddPressed: _showAddRiscoDialog,
                  onTap: () {
                    _showMultiSelectDialog(
                      title: 'Selecione os Riscos',
                      items: widget.availableRisks
                          .map((r) => r.nomeRiscos)
                          .toList(),
                      selected: _selectedRiskIds,
                      onConfirm: (list) =>
                          setState(() => _selectedRiskIds = list),
                    );
                  },
                ),
                CustomMultiSelectField(
                  label: 'EPI Necessários',
                  hint: 'Selecione os epis',
                  icon: Icons.archive_outlined,
                  selectedItems: _selectedEpisIds,
                  buttonKey: _epiKey,
                  enabled: _isEnabled,
                  onTap: () {
                    _showMultiSelectDialog(
                      title: 'Selecione os Epis',
                      items: widget.availableEpis
                          .map((c) => c.nomeProduto)
                          .toList(),
                      selected: _selectedEpisIds,
                      onConfirm: (list) =>
                          setState(() => _selectedEpisIds = list),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMultiSelectDialog({
    required String title,
    required List<String> items,
    required List<String> selected,
    required Function(List<String>) onConfirm,
  }) {
    List<String> tempSelected = List.from(selected);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 400,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return CheckboxListTile(
                      title: Text(item),
                      value: tempSelected.contains(item),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true)
                            tempSelected.add(item);
                          else
                            tempSelected.remove(item);
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    onConfirm(tempSelected);
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
