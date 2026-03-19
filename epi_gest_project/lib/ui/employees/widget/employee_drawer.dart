import 'package:epi_gest_project/data/services/organizational_structure/mapeamento_epi_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/turno_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/unidade_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/vinculo_repository.dart';
import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/ui/employees/controllers/employee_core_controller.dart';
import 'package:epi_gest_project/ui/employees/widget/employee_form_sections.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/image_picker_widget.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:provider/provider.dart';

class EmployeeDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function()? onSave;
  final FuncionarioModel? employeeToEdit;
  final bool view;

  const EmployeeDrawer({
    super.key,
    required this.onClose,
    this.onSave,
    this.employeeToEdit,
    this.view = false,
  });

  @override
  State<EmployeeDrawer> createState() => _EmployeeDrawerState();
}

class _EmployeeDrawerState extends State<EmployeeDrawer>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  File? _imageFile;
  String? _imagemPath;
  DateTime? _dataEntrada;
  DateTime? _dataDesligamento;
  DateTime? _dataRetornoFerias;
  bool _statusAtivo = true;
  bool _statusFerias = false;
  bool get _isEditing => widget.employeeToEdit != null && !widget.view;
  bool get _isAdding => widget.employeeToEdit == null && !widget.view;
  bool get _isViewing => widget.view;

  late final Map<String, TextEditingController> _controllers;

  final Map<String, GlobalKey> _overlayKeys = {
    'turno': GlobalKey(),
    'vinculo': GlobalKey(),
  };

  List<TurnoModel> _turnosDisponiveis = [];
  List<VinculoModel> _vinculosDisponiveis = [];
  List<MapeamentoEpiModel> _mapeamentosDisponiveis = [];
  List<UnidadeModel> _unidadesDisponiveis = [];

  MapeamentoFuncionarioModel? _currentVinculo;

  List<String> _turnosSugestoes = [];
  List<String> _vinculosSugestoes = [];
  List<String> _mapeamentosSugestoes = [];
  List<String> _unidadesSugestoes = [];

  TimeOfDay _tempEntrada = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _tempSaida = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _tempAlmocoInicio = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _tempAlmocoFim = const TimeOfDay(hour: 13, minute: 0);

  bool _isLoading = true;
  String? _loadingError;

  final Map<String, List<String>> _suggestions = {
    'funcionarios': [
      'João Silva',
      'Maria Santos',
      'Pedro Oliveira',
      'Ana Costa',
      'Carlos Souza',
    ],
  };

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'id': TextEditingController(),
      'matricula': TextEditingController(),
      'nome': TextEditingController(),
      'telefone': TextEditingController(),
      'email': TextEditingController(),
      'lider': TextEditingController(),
      'gestor': TextEditingController(),
      'vinculo': TextEditingController(),
      'turno': TextEditingController(),
      'dataEntrada': TextEditingController(),
      'dataDesligamento': TextEditingController(),
      'motivoDesligamento': TextEditingController(),
      'dataRetornoFerias': TextEditingController(),
      'newTurnoNome': TextEditingController(),
      'newVinculoNome': TextEditingController(),
      'mapeamento': TextEditingController(),
      'unidade': TextEditingController(),
    };

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    try {
      final turnoRepo = Provider.of<TurnoRepository>(context, listen: false);
      final vinculoRepo = Provider.of<VinculoRepository>(
        context,
        listen: false,
      );
      final mapRepo = Provider.of<MapeamentoEpiRepository>(
        context,
        listen: false,
      );
      final unitRepo = Provider.of<UnidadeRepository>(context, listen: false);
      final coreController = Provider.of<EmployeeCoreController>(
        context,
        listen: false,
      );

      final results = await Future.wait([
        turnoRepo.getAllTurnos(),
        vinculoRepo.getAllVinculos(),
        mapRepo.getAllMapeamentos(),
        unitRepo.getAllUnidades(),
      ]);

      if (!mounted) return;

      if ((_isEditing || _isViewing) && widget.employeeToEdit?.id != null) {
        _currentVinculo = await coreController.buscarMapeamentoAtual(
          widget.employeeToEdit!.id!,
        );
      }

      setState(() {
        _turnosDisponiveis = results[0] as List<TurnoModel>;
        _vinculosDisponiveis = results[1] as List<VinculoModel>;
        final allMappings = results[2] as List<MapeamentoEpiModel>;

        _mapeamentosDisponiveis = allMappings.where((m) {
          final isCurrent = _currentVinculo?.mapeamento.id == m.id;
          return m.status == true || isCurrent;
        }).toList();

        _unidadesDisponiveis = results[3] as List<UnidadeModel>;

        _turnosSugestoes = _turnosDisponiveis.map((t) => t.turno).toList();
        _vinculosSugestoes = _vinculosDisponiveis
            .map((v) => v.nomeVinculo)
            .toList();
        _mapeamentosSugestoes = _mapeamentosDisponiveis
            .map((m) => m.nomeMapeamento)
            .toList();
        _unidadesSugestoes = _unidadesDisponiveis
            .map((u) => u.nomeUnidade)
            .toList();

        if (_currentVinculo != null) {
          _controllers['mapeamento']!.text =
              _currentVinculo!.mapeamento.nomeMapeamento;
          _controllers['unidade']!.text = _currentVinculo!.unidade.nomeUnidade;
        }

        _isLoading = false;
        _loadingError = null;
      });

      if (!_isAdding) {
        _populateFormForEdit();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadingError = "Falha ao carregar dados: ${e.toString()}";
      });
    }
  }

  void _populateFormForEdit() {
    final employee = widget.employeeToEdit!;
    _controllers['id']!.text = employee.id!;
    _controllers['matricula']!.text = employee.matricula;
    _controllers['nome']!.text = employee.nomeFunc;
    _controllers['telefone']!.text = employee.telefone;
    _controllers['email']!.text = employee.email;
    _controllers['lider']!.text = employee.lider;
    _controllers['gestor']!.text = employee.gestor;
    _controllers['vinculo']!.text = employee.vinculo.nomeVinculo;
    _controllers['turno']!.text = employee.turno.turno;
    _controllers['dataEntrada']!.text = DateFormat(
      'dd/MM/yyyy',
    ).format(employee.dataEntrada);
    _controllers['dataRetornoFerias']!.text = employee.dataRetornoFerias != null
        ? DateFormat('dd/MM/yyyy').format(employee.dataRetornoFerias!)
        : '';
    _controllers['dataDesligamento']!.text = employee.dataDesligamento != null
        ? DateFormat('dd/MM/yyyy').format(employee.dataDesligamento!)
        : '';
    _controllers['motivoDesligamento']!.text =
        employee.motivoDesligamento ?? '';

    setState(() {
      _dataEntrada = employee.dataEntrada;
      _dataDesligamento = employee.dataDesligamento;
      _dataRetornoFerias = employee.dataRetornoFerias;
      _statusAtivo = employee.statusAtivo;
      _statusFerias = employee.statusFerias;
      _imagemPath = employee.imagemPath;
    });
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  void _showVinculoModal() {
    _controllers['newVinculoNome']!.clear();
    _controllers['newVinculoNome']!.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                          'Adicionar Novo Vínculo',
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
                      controller: _controllers['newVinculoNome']!,
                      label: 'Nome do Vinculo',
                      hint: 'Ex: CLT, Estágio, PJ',
                      icon: Icons.assignment_ind_outlined,
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
                              _createVinculo(context);
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
        );
      },
    );
  }

  Future<void> _createVinculo(BuildContext dialogContext) async {
    final nome = _controllers['newVinculoNome']!.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Nome obrigatório")));
      return;
    }

    final repo = Provider.of<VinculoRepository>(context, listen: false);
    try {
      Navigator.pop(dialogContext); // Fecha modal
      setState(() => _isLoading = true); // Mostra loading no drawer

      final novoVinculo = VinculoModel(nomeVinculo: nome);

      final created = await repo.create(novoVinculo);

      setState(() {
        _vinculosDisponiveis.add(created);
        _vinculosSugestoes.add(created.nomeVinculo);
        _controllers['vinculo']!.text =
            created.nomeVinculo; // Seleciona automaticamente
        _isLoading = false;
      });
      _showSuccessSnackBar('Vínculo criado com sucesso!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erro ao criar vínculo: $e");
    }
  }

  void _showTurnoTrabalhoModal() {
    _controllers['newTurnoNome']!.clear();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                          'Adicionar Novo Turno de Trabalho',
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
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          spacing: 24,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CustomTextField(
                              controller: _controllers['newTurnoNome']!,
                              label: 'Nome do Turno',
                              hint: 'Nome do Turno',
                              icon: Icons.work_outline,
                            ),
                            InfoSection(
                              title: 'Horários da Jornada',
                              icon: Icons.schedule_outlined,
                              child: Column(
                                spacing: 16,
                                children: [
                                  CustomTimeField(
                                    label: 'Horário de Entrada',
                                    time: _tempEntrada.format(context),
                                    enabled: true,
                                    onTap: () => _selectTimeModal(
                                      context,
                                      _tempEntrada,
                                      (time) =>
                                          setState(() => _tempEntrada = time),
                                    ),
                                  ),
                                  CustomTimeField(
                                    label: 'Horário de Saída',
                                    time: _tempSaida.format(context),
                                    enabled: true,
                                    onTap: () => _selectTimeModal(
                                      context,
                                      _tempSaida,
                                      (time) =>
                                          setState(() => _tempSaida = time),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InfoSection(
                              title: 'Intervalo de Almoço',
                              icon: Icons.restaurant_outlined,
                              child: Column(
                                spacing: 16,
                                children: [
                                  CustomTimeField(
                                    label: 'Início do Almoço',
                                    time: _tempAlmocoInicio.format(context),
                                    enabled: true,
                                    onTap: () => _selectTimeModal(
                                      context,
                                      _tempAlmocoInicio,
                                      (time) => setState(
                                        () => _tempAlmocoInicio = time,
                                      ),
                                    ),
                                  ),
                                  CustomTimeField(
                                    label: 'Fim do Almoço',
                                    time: _tempAlmocoFim.format(context),
                                    enabled: true,
                                    onTap: () => _selectTimeModal(
                                      context,
                                      _tempAlmocoFim,
                                      (time) =>
                                          setState(() => _tempAlmocoFim = time),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              _createTurno(context);
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
        );
      },
    );
  }

  Future<void> _selectTimeModal(
    BuildContext context,
    TimeOfDay initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null && picked != initialTime) {
      setState(() {
        onTimeSelected(picked);
      });
    }
  }

  Future<void> _createTurno(BuildContext dialogContext) async {
    final nome = _controllers['newTurnoNome']!.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Nome obrigatório")));
      return;
    }

    final repo = Provider.of<TurnoRepository>(context, listen: false);
    try {
      Navigator.pop(dialogContext);
      setState(() => _isLoading = true);

      final novoTurno = TurnoModel(
        turno: nome,
        horaEntrada: _tempEntrada.format(context),
        horaSaida: _tempSaida.format(context),
        inicioAlmoco: _tempAlmocoInicio.format(context),
        fimAlomoco: _tempAlmocoFim.format(context),
      );

      final created = await repo.create(novoTurno);

      setState(() {
        _turnosDisponiveis.add(created);
        _turnosSugestoes.add(created.turno);
        _controllers['turno']!.text = created.turno;
        _isLoading = false;
      });
      _showSuccessSnackBar('Turno criado com sucesso!');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar("Erro ao criar turno: $e");
    }
  }

  Future<void> _selectDate(
    String field,
    Function(DateTime) onDateSelected,
  ) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        locale: const Locale('pt', 'BR'),
        builder: (context, child) {
          return Theme(
            data: Theme.of(
              context,
            ).copyWith(colorScheme: Theme.of(context).colorScheme),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setState(() {
          onDateSelected(picked);
          _controllers[field]!.text = DateFormat('dd/MM/yyyy').format(picked);
        });
      }
    } catch (e) {
      debugPrint('Erro ao selecionar data: $e');
    }
  }

  void _selectDateEntrada() =>
      _selectDate('dataEntrada', (date) => _dataEntrada = date);
  void _selectDateDesligamento() =>
      _selectDate('dataDesligamento', (date) => _dataDesligamento = date);
  void _selectDateRetornoFerias() =>
      _selectDate('dataRetornoFerias', (date) => _dataRetornoFerias = date);

  void _onImagePicked(File image) {
    setState(() {
      _imageFile = image;
      _imagemPath = image.path;
    });
  }

  void _onImageRemoved() {
    setState(() {
      _imageFile = null;
      _imagemPath = null;
    });
    _showSuccessSnackBar('Imagem removida');
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataEntrada == null) {
      _showErrorSnackBar('Selecione a data de entrada');
      return;
    }

    final selectedTurnoNome = _controllers['turno']!.text.trim();
    final selectedVinculoNome = _controllers['vinculo']!.text.trim();

    TurnoModel? turnoSelecionado;
    try {
      turnoSelecionado = _turnosDisponiveis.firstWhere(
        (t) => t.turno == selectedTurnoNome,
      );
    } catch (_) {
      _showErrorSnackBar('Turno inválido. Selecione ou crie um novo.');
      return;
    }

    VinculoModel? vinculoSelecionado;
    try {
      vinculoSelecionado = _vinculosDisponiveis.firstWhere(
        (v) => v.nomeVinculo == selectedVinculoNome,
      );
    } catch (_) {
      _showErrorSnackBar('Vínculo inválido. Selecione ou crie um novo.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final coreController = Provider.of<EmployeeCoreController>(
        context,
        listen: false,
      );

      final employee = FuncionarioModel(
        id: _isEditing ? widget.employeeToEdit!.id : null,
        matricula: _controllers['matricula']!.text.trim(),
        nomeFunc: _controllers['nome']!.text.trim(),
        dataEntrada: _dataEntrada!,
        telefone: _controllers['telefone']!.text.trim(),
        email: _controllers['email']!.text.trim(),
        turno: TurnoModel(
          id: turnoSelecionado.id,
          turno: turnoSelecionado.turno,
          horaEntrada: turnoSelecionado.horaEntrada,
          horaSaida: turnoSelecionado.horaSaida,
          inicioAlmoco: turnoSelecionado.inicioAlmoco,
          fimAlomoco: turnoSelecionado.fimAlomoco,
        ),
        vinculo: VinculoModel(
          id: vinculoSelecionado.id,
          nomeVinculo: vinculoSelecionado.nomeVinculo,
        ),
        lider: _controllers['lider']!.text.trim(),
        gestor: _controllers['gestor']!.text.trim(),
        statusAtivo: _statusAtivo,
        statusFerias: _statusFerias,
        dataRetornoFerias: _dataRetornoFerias,
        dataDesligamento: _dataDesligamento,
        motivoDesligamento: _controllers['motivoDesligamento']!.text.trim(),
      );

      final savedEmployee = await coreController.salvarFuncionario(
        funcionario: employee,
        isEditing: _isEditing,
      );

      final mapText = _controllers['mapeamento']!.text.trim();
      final unitText = _controllers['unidade']!.text.trim();

      await coreController.sincronizarMapeamento(
        funcionarioSalvo: savedEmployee,
        currentVinculo: _currentVinculo,
        mapeamentoNome: mapText,
        unidadeNome: unitText,
        mapeamentosDisponiveis: _mapeamentosDisponiveis,
        unidadesDisponiveis: _unidadesDisponiveis,
      );

      _showSuccessSnackBar('Dados salvos com sucesso!');
      if (mounted) Navigator.of(context).pop();
      widget.onSave?.call();
    } catch (e) {
      _showErrorSnackBar('Erro inesperado: ${e.toString()}');
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
    String title;
    String subtitle;
    IconData icon;

    if (_isViewing) {
      title = 'Visualizar Funcionário';
      subtitle = 'Informações de ${widget.employeeToEdit?.nomeFunc ?? ""}';
      icon = Icons.visibility_outlined;
    } else if (_isEditing) {
      title = 'Editar Funcionário';
      subtitle = 'Altere os dados do funcionário';
      icon = Icons.person_search_outlined;
    } else {
      title = 'Adicionar Funcionário';
      subtitle = 'Preencha os dados do novo funcionário';
      icon = Icons.person_add_alt_1_outlined;
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onClose: widget.onClose,
      onSave: _handleSave,
      isEditing: _isEditing,
      isViewing: _isViewing,
      formKey: _formKey,
      isSaving: _isSaving,
      child: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando dados...'),
        ],
      );
    }

    if (_loadingError != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Ocorreu um Erro',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _loadingError!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _loadingError = null;
                });
                _loadInitialData();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(child: _buildForm(theme));
  }

  Widget _buildForm(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useTwoColumns = constraints.maxWidth > 700;
          return useTwoColumns
              ? _buildTwoColumnLayout(theme)
              : _buildSingleColumnLayout(theme);
        },
      ),
    );
  }

  Widget _buildTwoColumnLayout(ThemeData theme) {
    final bool isEnabled = !_isViewing;

    return Row(
      spacing: 24,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            spacing: 32,
            children: [
              ImagePickerWidget(
                imageFile: _imageFile,
                imageUrl: _imagemPath,
                onImagePicked: _onImagePicked,
                onImageRemoved: _onImageRemoved,
                viewOnly: _isViewing,
                height: 210,
                width: 275,
              ),
              // HIERARQUIA ABAIXO DA IMAGEM
              InfoSection(
                title: 'Hierarquia',
                icon: Icons.people_outline,
                child: HierarchySection(
                  liderController: _controllers['lider']!,
                  gestorController: _controllers['gestor']!,
                  funcionariosSugeridos: _suggestions['funcionarios']!,
                  enabled: isEnabled,
                ),
              ),
              // CONTATO ABAIXO DA HIERARQUIA
              InfoSection(
                title: 'Contato',
                icon: Icons.contact_phone_outlined,
                child: ContactSection(
                  telefoneController: _controllers['telefone']!,
                  emailController: _controllers['email']!,
                  enabled: isEnabled,
                ),
              ),
              if (!_statusAtivo) ...[
                InfoSection(
                  title: 'Desligamento',
                  icon: Icons.logout_outlined,
                  child: TerminationSection(
                    dataDesligamentoController:
                        _controllers['dataDesligamento']!,
                    motivoDesligamentoController:
                        _controllers['motivoDesligamento']!,
                    onSelectDateDesligamento: _selectDateDesligamento,
                    enabled: isEnabled,
                  ),
                ),
              ],
            ],
          ),
        ),

        Expanded(
          child: Column(
            spacing: 32,
            children: [
              InfoSection(
                title: 'Informações Básicas',
                icon: Icons.info_outlined,
                child: BasicInfoSection(
                  matriculaController: _controllers['matricula']!,
                  nomeController: _controllers['nome']!,
                  dataEntradaController: _controllers['dataEntrada']!,
                  onSelectDateEntrada: _selectDateEntrada,
                  enabled: isEnabled,
                ),
              ),
              InfoSection(
                title: 'Condições de Trabalho',
                icon: Icons.settings_outlined,
                child: WorkConditionsSection(
                  enabled: isEnabled,
                  vinculoController: _controllers['vinculo']!,
                  turnoController: _controllers['turno']!,
                  vinculosSugeridos: _vinculosSugestoes,
                  turnosSugeridos: _turnosSugestoes,
                  vinculoButtonKey: _overlayKeys['vinculo']!,
                  turnoButtonKey: _overlayKeys['turno']!,
                  onAddVinculo: _showVinculoModal,
                  onAddTurno: _showTurnoTrabalhoModal,
                ),
              ),
              InfoSection(
                title: 'Mapeamento do Funcionário',
                icon: Icons.assignment_ind_outlined,
                child: MappingSection(
                  mapeamentoController: _controllers['mapeamento']!,
                  unidadeController: _controllers['unidade']!,
                  mapeamentosSugeridos: _mapeamentosSugestoes,
                  unidadesSugeridas: _unidadesSugestoes,
                  enabled: isEnabled,
                ),
              ),
              InfoSection(
                title: 'Status',
                icon: Icons.info_outlined,
                child: StatusSection(
                  enabled: isEnabled,
                  statusAtivo: _statusAtivo,
                  statusFerias: _statusFerias,
                  dataRetornoFerias: _dataRetornoFerias,
                  onStatusAtivoChanged: (value) =>
                      setState(() => _statusAtivo = value),
                  onStatusFeriasChanged: (value) =>
                      setState(() => _statusFerias = value),
                  onSelectDateRetornoFerias: _selectDateRetornoFerias,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleColumnLayout(ThemeData theme) {
    final bool isEnabled = !_isViewing;

    return Column(
      spacing: 32,
      children: [
        ImagePickerWidget(
          imageFile: _imageFile,
          imageUrl: _imagemPath,
          onImagePicked: _onImagePicked,
          onImageRemoved: _onImageRemoved,
          viewOnly: _isViewing,
          height: 200,
          width: 300,
        ),
        InfoSection(
          title: 'Informações Básicas',
          icon: Icons.info_outlined,
          child: BasicInfoSection(
            enabled: isEnabled,
            matriculaController: _controllers['matricula']!,
            nomeController: _controllers['nome']!,
            dataEntradaController: _controllers['dataEntrada']!,
            onSelectDateEntrada: _selectDateEntrada,
          ),
        ),
        InfoSection(
          title: 'Contato',
          icon: Icons.contact_phone_outlined,
          child: ContactSection(
            enabled: isEnabled,
            telefoneController: _controllers['telefone']!,
            emailController: _controllers['email']!,
          ),
        ),
        InfoSection(
          title: 'Hierarquia',
          icon: Icons.people_outline,
          child: HierarchySection(
            enabled: isEnabled,
            liderController: _controllers['lider']!,
            gestorController: _controllers['gestor']!,
            funcionariosSugeridos: _suggestions['funcionarios']!,
          ),
        ),
        InfoSection(
          title: 'Condições de Trabalho',
          icon: Icons.settings_outlined,
          child: WorkConditionsSection(
            enabled: isEnabled,
            vinculoController: _controllers['vinculo']!,
            turnoController: _controllers['turno']!,
            vinculosSugeridos: _vinculosSugestoes,
            turnosSugeridos: _turnosSugestoes,
            vinculoButtonKey: _overlayKeys['vinculo']!,
            turnoButtonKey: _overlayKeys['turno']!,
            onAddVinculo: _showVinculoModal,
            onAddTurno: _showTurnoTrabalhoModal,
          ),
        ),
        InfoSection(
          title: 'Mapeamento do Funcionário',
          icon: Icons.assignment_ind_outlined,
          child: MappingSection(
            mapeamentoController: _controllers['mapeamento']!,
            unidadeController: _controllers['unidade']!,
            mapeamentosSugeridos: _mapeamentosSugestoes,
            unidadesSugeridas: _unidadesSugestoes,
            enabled: isEnabled,
          ),
        ),
        InfoSection(
          title: 'Status',
          icon: Icons.info_outlined,
          child: StatusSection(
            enabled: isEnabled,
            statusAtivo: _statusAtivo,
            statusFerias: _statusFerias,
            dataRetornoFerias: _dataRetornoFerias,
            onStatusAtivoChanged: (value) =>
                setState(() => _statusAtivo = value),
            onStatusFeriasChanged: (value) =>
                setState(() => _statusFerias = value),
            onSelectDateRetornoFerias: _selectDateRetornoFerias,
          ),
        ),
        if (!_statusAtivo) ...[
          InfoSection(
            title: 'Desligamento',
            icon: Icons.logout_outlined,
            child: TerminationSection(
              enabled: isEnabled,
              dataDesligamentoController: _controllers['dataDesligamento']!,
              motivoDesligamentoController: _controllers['motivoDesligamento']!,
              onSelectDateDesligamento: _selectDateDesligamento,
            ),
          ),
        ],
      ],
    );
  }
}
