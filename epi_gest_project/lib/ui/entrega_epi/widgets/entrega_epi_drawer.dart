import 'package:epi_gest_project/data/repositories/ficha_entrega_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/ficha_entrega_model.dart';
import 'package:epi_gest_project/domain/models/ficha_epi_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/ui/entrega_epi/entrega_epi_page.dart'; // Import necessário para EpiStatusEnum e EpiStatusData
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExchangeDrawerContent extends StatefulWidget {
  final MapeamentoFuncionarioModel mapFunc;
  final VoidCallback onCloseDrawer;
  final Function()? onSave;
  final Map<String, EpiStatusData> epiStatusMap;

  const ExchangeDrawerContent({
    super.key,
    required this.mapFunc,
    required this.onCloseDrawer,
    this.onSave,
    required this.epiStatusMap,
  });

  @override
  State<ExchangeDrawerContent> createState() => _ExchangeDrawerContentState();
}

class _ExchangeDrawerContentState extends State<ExchangeDrawerContent> {
  final _formKey = GlobalKey<FormState>();
  final _responsavelController = TextEditingController();
  final _observacaoController = TextEditingController();

  final Map<String, _DeliveryItemState> _selectedItems = {};

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _autoSelectItems();
  }

  @override
  void dispose() {
    _responsavelController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  void _autoSelectItems() {
    for (var epi in widget.mapFunc.mapeamento.epis) {
      if (epi.id == null) continue;

      final statusData = widget.epiStatusMap[epi.id];

      // Se não tem estoque, não seleciona automaticamente
      if (epi.estoque <= 0) continue;

      if (statusData != null) {
        if (statusData.status == EpiStatusEnum.pendente) {
          // Correção: Define motivo para item novo/pendente
          _selectedItems[epi.id!] = _DeliveryItemState(
            epi: epi,
            isExchange: false,
            reason: 'Primeira Entrega / Admissão',
            quantity: 1,
          );
        } else if (statusData.status == EpiStatusEnum.vencido) {
          // Correção: Define motivo para item vencido
          _selectedItems[epi.id!] = _DeliveryItemState(
            epi: epi,
            isExchange: true, 
            reason: 'Vencimento Natural',
            quantity: 1,
          );
        }
      }
    }
  }

  void _toggleSelection(EpiModel epi) {
    setState(() {
      if (_selectedItems.containsKey(epi.id)) {
        _selectedItems.remove(epi.id);
      } else {
        final statusData = widget.epiStatusMap[epi.id];
        final isPendente = statusData?.status == EpiStatusEnum.pendente;

        String defaultReason;
        bool isExchange;

        if (isPendente) {
          defaultReason = 'Primeira Entrega / Admissão';
          isExchange = false;
        } else if (statusData?.status == EpiStatusEnum.vencido) {
          defaultReason = 'Vencimento Natural';
          isExchange = true;
        } else {
          // Se está em dia, sugere motivo de avaria
          defaultReason = 'Dano/Avaria';
          isExchange = true;
        }

        _selectedItems[epi.id!] = _DeliveryItemState(
          epi: epi,
          isExchange: isExchange,
          reason: defaultReason,
          quantity: 1,
        );
      }
    });
  }

  void _updateItemReason(String epiId, String newReason) {
    setState(() {
      if (_selectedItems.containsKey(epiId)) {
        _selectedItems[epiId]!.reason = newReason;
      }
    });
  }

  Future<void> _handleSave() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um EPI para entregar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final fichaEntregaRepo = Provider.of<FichaEntregaRepository>(
        context,
        listen: false,
      );

      List<FichaEpiModel> itensParaSalvar = [];

      for (var itemState in _selectedItems.values) {
        final epi = itemState.epi;

        if (epi.estoque < itemState.quantity) {
          throw Exception('Estoque insuficiente para ${epi.nomeProduto}');
        }

        final validade = DateTime.now().add(Duration(days: epi.periodicidade));

        final fichaEpi = FichaEpiModel(
          epi: epi,
          validadeEpi: validade,
          valor: epi.valor,
          quantidade: itemState.quantity,
          motivo: itemState.reason,
        );

        itensParaSalvar.add(fichaEpi);
      }

      final fichaEntrega = FichaEntregaModel(
        mapeamentoFuncionario: widget.mapFunc,
        fichaEpi: [],
        status: true,
      );

      await fichaEntregaRepo.registrarEntregaCompleta(
        entregaHeader: fichaEntrega,
        itensParaSalvar: itensParaSalvar,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega registrada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSave?.call();
        widget.onCloseDrawer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final requiredEpis = widget.mapFunc.mapeamento.epis;

    return BaseAddDrawer(
      title: 'Realizar Entrega de EPI',
      subtitle: widget.mapFunc.funcionario.nomeFunc,
      icon: Icons.inventory,
      onClose: widget.onCloseDrawer,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      isEditing: true,
      widthFactor: 0.6,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoSection(
              title: 'Dados da Entrega',
              icon: Icons.description_outlined,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _responsavelController,
                    label: 'Responsável pela Entrega',
                    hint: 'Nome do técnico/gestor',
                    icon: Icons.person_outline,
                    validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _observacaoController,
                    label: 'Observações Gerais',
                    hint: 'Opcional',
                    icon: Icons.note_alt_outlined,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Selecione os itens para entregar:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requiredEpis.length,
              itemBuilder: (context, index) {
                final epi = requiredEpis[index];
                final bool isSelected = _selectedItems.containsKey(epi.id);
                final bool hasStock = epi.estoque > 0;

                return _buildEpiSelectionCard(theme, epi, isSelected, hasStock);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpiSelectionCard(
    ThemeData theme,
    EpiModel epi,
    bool isSelected,
    bool hasStock,
  ) {
    final statusData = widget.epiStatusMap[epi.id];
    final itemState = _selectedItems[epi.id];

    String statusLabel = '';
    Color statusColor = Colors.grey;

    if (statusData != null) {
      switch (statusData.status) {
        case EpiStatusEnum.pendente:
          statusLabel = 'Pendente';
          statusColor = Colors.orange;
          break;
        case EpiStatusEnum.vencido:
          statusLabel = 'Vencido';
          statusColor = Colors.red;
          break;
        case EpiStatusEnum.aVencer:
          statusLabel = 'À Vencer';
          statusColor = Colors.amber;
          break;
        case EpiStatusEnum.emDia:
          statusLabel = 'Em Dia';
          statusColor = Colors.green;
          break;
      }
    }

    return Card(
      elevation: isSelected ? 4 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: hasStock ? () => _toggleSelection(epi) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // --- NOVO: Símbolo de Checkbox Visual ---
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 16,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  
                  // Conteúdo do Card
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          epi.nomeProduto,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'CA: ${epi.ca} | Estoque: ${epi.estoque.toInt()}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (!hasStock)
                          Text(
                            'Sem estoque disponível',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Badge de Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              if (isSelected) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Motivo: ',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: itemState?.reason, // Vincula o valor selecionado
                        isDense: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        // --- CORREÇÃO: Adicionada opção 'Primeira Entrega / Admissão' ---
                        items: const [
                          DropdownMenuItem(
                            value: 'Primeira Entrega / Admissão',
                            child: Text('Primeira Entrega / Admissão'),
                          ),
                          DropdownMenuItem(
                            value: 'Vencimento Natural',
                            child: Text('Vencimento Natural'),
                          ),
                          DropdownMenuItem(
                            value: 'Dano/Avaria',
                            child: Text('Dano / Avaria'),
                          ),
                          DropdownMenuItem(
                            value: 'Perda/Extravio',
                            child: Text('Perda / Extravio'),
                          ),
                          DropdownMenuItem(
                            value: 'Solicitação Func.',
                            child: Text('Solicitação do Func.'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            _updateItemReason(epi.id!, val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryItemState {
  final EpiModel epi;
  final bool isExchange;
  String reason;
  int quantity;

  _DeliveryItemState({
    required this.epi,
    required this.isExchange,
    required this.reason,
    this.quantity = 1,
  });
}