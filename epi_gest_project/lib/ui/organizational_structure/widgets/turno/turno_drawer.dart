import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/ui/organizational_structure/controllers/turno_controller.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TurnoDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function(TurnoModel) onSave;
  final TurnoModel? turnoToEdit;
  final bool view;

  const TurnoDrawer({
    super.key,
    required this.onClose,
    required this.onSave,
    this.turnoToEdit,
    this.view = false,
  });

  @override
  State<TurnoDrawer> createState() => _TurnoDrawerState();
}

class _TurnoDrawerState extends State<TurnoDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _turnoController = TextEditingController();

  // Estado para os horários
  final _entradaController = TextEditingController();
  final _saidaController = TextEditingController();
  final _almocoInicioController = TextEditingController();
  final _almocoFimController = TextEditingController();

  bool get _isEditing => widget.turnoToEdit != null && !widget.view;
  bool get _isAdding => widget.turnoToEdit == null && !widget.view;
  bool get _isViewing => widget.view;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (_isEditing || _isViewing) _populateForm();
    if (_isAdding) _populateTime();
  }

  void _populateTime() {
    _entradaController.text = "08:00";
    _saidaController.text = "18:00";
    _almocoInicioController.text = "12:00";
    _almocoFimController.text = "13:00";
  }

  void _populateForm() {
    final turno = widget.turnoToEdit!;
    _turnoController.text = turno.turno;
    _entradaController.text = turno.horaEntrada;
    _saidaController.text = turno.horaSaida;
    _almocoInicioController.text = turno.inicioAlmoco;
    _almocoFimController.text = turno.fimAlomoco;
  }

  @override
  void dispose() {
    _turnoController.dispose();
    _entradaController.dispose();
    _saidaController.dispose();
    _almocoInicioController.dispose();
    _almocoFimController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final turnoModel = TurnoModel(
      id: widget.turnoToEdit?.id,
      turno: _turnoController.text.trim(),
      horaEntrada: _entradaController.text.trim(),
      horaSaida: _saidaController.text.trim(),
      inicioAlmoco: _almocoInicioController.text.trim(),
      fimAlomoco: _almocoFimController.text.trim(),
    );

    try {
      final controller = Provider.of<TurnoController>(context, listen: false);
      final turnoSalvo = await controller.salvarTurno(
        turno: turnoModel,
        isEditing: _isEditing,
      );

      if (_isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turno atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turno criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSave(turnoSalvo);
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

  Future<void> _selectTimeModal(
    BuildContext context,
    String initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final time = initialTime.split(":");
    final correctedTime = TimeOfDay(
      hour: int.parse(time[0]),
      minute: int.parse(time[1]),
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: correctedTime,
    );
    if (picked != null && picked != correctedTime) {
      setState(() {
        onTimeSelected(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String title;
    String subtitle;

    if (_isViewing) {
      title = 'Visualizar Turno';
      subtitle = 'Informações completas do turno';
    } else if (_isEditing) {
      title = 'Editar Turno';
      subtitle = 'Altere os dados do turno';
    } else {
      title = 'Adicionar Turno';
      subtitle = 'Preencha os dados do novo turno';
    }

    return BaseAddDrawer(
      title: title,
      subtitle: subtitle,
      icon: Icons.access_time_outlined,
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
        spacing: 20,
        children: [
          CustomTextField(
            controller: _turnoController,
            label: 'Nome do Turno',
            hint: 'Ex: Turno Administrativo, Turno Produção, Manhã, Tarde',
            enabled: isEnabled,
            icon: Icons.work_outline,
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
          ),
          InfoSection(
            title: 'Horários da Jornada',
            icon: Icons.schedule_outlined,
            child: Column(
              spacing: 20,
              children: [
                CustomTimeField(
                  label: 'Horário de Entrada',
                  time: _entradaController.text,
                  enabled: isEnabled,
                  onTap: () => _selectTimeModal(
                    context,
                    _entradaController.text,
                    (time) => _entradaController.text = time.format(context),
                  ),
                ),
                CustomTimeField(
                  label: 'Horário de Saída',
                  time: _saidaController.text,
                  enabled: isEnabled,
                  onTap: () => _selectTimeModal(
                    context,
                    _saidaController.text,
                    (time) => _saidaController.text = time.format(context),
                  ),
                ),
              ],
            ),
          ),
          InfoSection(
            title: 'Intervalo de Almoço',
            icon: Icons.restaurant_outlined,
            child: Column(
              spacing: 20,
              children: [
                CustomTimeField(
                  label: 'Início do Almoço',
                  time: _almocoInicioController.text,
                  enabled: isEnabled,
                  onTap: () => _selectTimeModal(
                    context,
                    _almocoInicioController.text,
                    (time) =>
                        _almocoInicioController.text = time.format(context),
                  ),
                ),
                CustomTimeField(
                  label: 'Fim do Almoço',
                  time: _almocoFimController.text,
                  enabled: isEnabled,
                  onTap: () => _selectTimeModal(
                    context,
                    _almocoFimController.text,
                    (time) =>
                        _almocoFimController.text = time.format(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
