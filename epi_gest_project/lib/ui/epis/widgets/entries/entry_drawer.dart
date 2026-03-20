import 'package:epi_gest_project/data/repositories/entradas_repository.dart';
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/product_technical_registration/fornecedor_repository.dart';
import 'package:epi_gest_project/domain/models/entradas_epi_model.dart';
import 'package:epi_gest_project/domain/models/entradas_model.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/fornecedor_model.dart';
import 'package:epi_gest_project/ui/utils/input_formatters.dart';
import 'package:epi_gest_project/ui/widgets/base_drawer.dart';
import 'package:epi_gest_project/ui/widgets/form_fields.dart';
import 'package:epi_gest_project/ui/widgets/info_section.dart';
import 'package:epi_gest_project/ui/widgets/search_selection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EntryDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final Function()? onSave;
  final EntradasModel? entradaToView;
  final bool view;

  const EntryDrawer({
    super.key,
    required this.onClose,
    this.onSave,
    this.entradaToView,
    this.view = false,
  });

  @override
  State<EntryDrawer> createState() => _EntryDrawerState();
}

class _EntryDrawerState extends State<EntryDrawer> {
  final _formKey = GlobalKey<FormState>();

  // Controllers Gerais
  final _notaFiscalController = TextEditingController();
  final _dataEntregaController = TextEditingController();
  
  // Controllers Fornecedor
  final _fornecedorNomeController = TextEditingController();
  final _fornecedorCnpjController = TextEditingController();

  // Controllers Item (Apenas para modo Adicionar)
  final _produtoDescricaoController = TextEditingController();
  final _caController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _quantidadeAtualConstroller = TextEditingController();
  final _valorUnitarioController = TextEditingController();

  // Estado
  FornecedorModel? _selectedFornecedor;
  EpiModel? _tempSelectedEpi;
  
  // Lista unificada para exibição (usada tanto no Add quanto no View)
  // Estrutura: { 'epiModel': EpiModel?, 'descricao': String, 'ca': String, 'quantidade': int, 'valorUnitario': double, 'valorTotal': double }
  final List<Map<String, dynamic>> _items = [];
  
  bool _isSaving = false;
  bool get _isViewing => widget.view;
  bool get _isEnabled => !_isViewing;

  @override
  void initState() {
    super.initState();
    if (_isViewing && widget.entradaToView != null) {
      _populateForm();
    } else {
      _dataEntregaController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    }
  }

  void _populateForm() {
    final entrada = widget.entradaToView!;
    
    // Cabeçalho
    _notaFiscalController.text = entrada.nfReferente;
    _dataEntregaController.text = DateFormat('dd/MM/yyyy').format(entrada.dataEntrada);
    _fornecedorNomeController.text = entrada.fornecedorId.nomeFornecedor;
    _fornecedorCnpjController.text = entrada.fornecedorId.cnpj;
    _selectedFornecedor = entrada.fornecedorId;

    // Itens
    for (var item in entrada.entradasId) {
      _items.add({
        'epiModel': item.epi,
        'descricao': item.epi.nomeProduto,
        'ca': item.epi.ca,
        'quantidade': item.quantidade,
        'valorUnitario': item.valor,
        'valorTotal': item.quantidade * item.valor,
      });
    }
  }

  @override
  void dispose() {
    _notaFiscalController.dispose();
    _dataEntregaController.dispose();
    _fornecedorNomeController.dispose();
    _fornecedorCnpjController.dispose();
    _produtoDescricaoController.dispose();
    _caController.dispose();
    _quantidadeController.dispose();
    _quantidadeAtualConstroller.dispose();
    _valorUnitarioController.dispose();
    super.dispose();
  }

  // --- Lógica de Seleção e Busca (Apenas modo Add) ---

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dataEntregaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _searchSupplier() async {
    final repo = Provider.of<FornecedorRepository>(context, listen: false);
    final suppliers = await repo.getAllFornecedores();

    if (!mounted) return;

    final selected = await showDialog<FornecedorModel>(
      context: context,
      builder: (context) => SearchSelectionDialog<FornecedorModel>(
        title: 'Selecionar Fornecedor',
        searchHint: 'Buscar por nome ou CNPJ...',
        items: suppliers,
        searchFilter: (item, query) =>
            item.nomeFornecedor.toLowerCase().contains(query) ||
            item.cnpj.contains(query),
        itemBuilder: (context, item, onSelect) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.business)),
            title: Text(item.nomeFornecedor),
            subtitle: Text('CNPJ: ${item.cnpj}'),
            onTap: onSelect,
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedFornecedor = selected;
        _fornecedorNomeController.text = selected.nomeFornecedor;
        _fornecedorCnpjController.text = selected.cnpj;
      });
    }
  }

  Future<void> _searchProduct() async {
    final repo = Provider.of<EpiRepository>(context, listen: false);
    final products = await repo.getAllEpis();

    if (!mounted) return;

    final selected = await showDialog<EpiModel>(
      context: context,
      builder: (context) => SearchSelectionDialog<EpiModel>(
        title: 'Selecionar Produto',
        searchHint: 'Buscar por nome ou CA...',
        items: products,
        searchFilter: (item, query) =>
            item.nomeProduto.toLowerCase().contains(query) ||
            item.ca.contains(query),
        itemBuilder: (context, item, onSelect) {
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
            title: Text(item.nomeProduto),
            subtitle: Text('CA: ${item.ca} | Estoque Atual: ${item.estoque}'),
            onTap: onSelect,
          );
        },
      ),
    );

    if (selected != null) {
      setState(() {
        _tempSelectedEpi = selected;
        _produtoDescricaoController.text = selected.nomeProduto;
        _caController.text = selected.ca;
        _valorUnitarioController.text = NumberFormat.currency(
          locale: 'pt_BR',
          symbol: 'R\$',
        ).format(selected.valor);
        _quantidadeAtualConstroller.text = selected.estoque.toString();
        _quantidadeController.clear();
      });
    }
  }

  void _addItemToList() {
    if (_tempSelectedEpi == null || _quantidadeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um produto e quantidade')),
      );
      return;
    }

    final qtd = int.tryParse(_quantidadeController.text) ?? 0;
    
    // Limpeza de moeda
    String valorLimpo = _valorUnitarioController.text
        .replaceAll('R\$', '')
        .replaceAll('.', '')
        .replaceAll(',', '.')
        .trim();
    final valor = double.tryParse(valorLimpo) ?? 0.0;

    if (qtd <= 0) return;

    setState(() {
      _items.add({
        'epiModel': _tempSelectedEpi,
        'descricao': _tempSelectedEpi!.nomeProduto,
        'ca': _tempSelectedEpi!.ca,
        'quantidade': qtd,
        'valorUnitario': valor,
        'valorTotal': qtd * valor,
      });

      // Limpar campos de entrada do item
      _tempSelectedEpi = null;
      _produtoDescricaoController.clear();
      _caController.clear();
      _quantidadeController.clear();
      _quantidadeAtualConstroller.clear();
      _valorUnitarioController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  // --- Salvar ---

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _items.isEmpty || _selectedFornecedor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os dados e adicione itens')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Converter lista visual para Models
      final List<EntradasEpiModel> itensParaSalvar = _items.map((p) {
        return EntradasEpiModel(
          epi: p['epiModel'] as EpiModel,
          quantidade: p['quantidade'] as int,
          valor: p['valorUnitario'] as double,
        );
      }).toList();

      // 2. Criar Header
      final header = EntradasModel(
        nfReferente: _notaFiscalController.text,
        fornecedorId: _selectedFornecedor!,
        entradasId: [],
        dataEntrada: DateFormat('dd/MM/yyyy').parse(_dataEntregaController.text),
      );

      // 3. Persistir
      final repo = Provider.of<EntradasRepository>(context, listen: false);
      await repo.registrarEntradaCompleta(
        entradaHeader: header,
        itens: itensParaSalvar,
      );

      if (widget.onSave != null) widget.onSave!();
      widget.onClose();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalValue = _items.fold<double>(
      0, 
      (sum, item) => sum + (item['valorTotal'] as double)
    );
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return BaseAddDrawer(
      title: _isViewing ? 'Detalhes da Entrada' : 'Nova Entrada',
      subtitle: _isViewing 
          ? 'Nota Fiscal: ${_notaFiscalController.text}' 
          : 'Registre a entrada de novos materiais',
      icon: _isViewing ? Icons.description_outlined : Icons.input_rounded,
      onClose: widget.onClose,
      onSave: _handleSave,
      formKey: _formKey,
      isSaving: _isSaving,
      isViewing: _isViewing,
      widthFactor: 0.6,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 24,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoSection(
              title: 'Dados da Nota Fiscal',
              icon: Icons.receipt_long_outlined,
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _notaFiscalController,
                      label: 'Número da NF',
                      hint: '000.000',
                      icon: Icons.confirmation_number_outlined,
                      enabled: _isEnabled,
                      validator: (v) => v?.isEmpty ?? true ? 'Obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDateField(
                      controller: _dataEntregaController,
                      label: 'Data de Entrada',
                      hint: 'dd/mm/aaaa',
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectDate,
                      enabled: _isEnabled,
                    ),
                  ),
                ],
              ),
            ),
            InfoSection(
              title: 'Fornecedor',
              icon: Icons.business_outlined,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _fornecedorNomeController,
                      label: 'Fornecedor',
                      hint: 'Selecione o fornecedor',
                      icon: Icons.store_outlined,
                      enabled: false, // Sempre read-only, preenchido pela busca
                    ),
                  ),
                  if (_isEnabled) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: _searchSupplier,
                      icon: const Icon(Icons.search),
                      tooltip: 'Buscar Fornecedor',
                    ),
                  ],
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _fornecedorCnpjController,
                      label: 'CNPJ',
                      hint: '',
                      icon: Icons.badge_outlined,
                      enabled: false,
                    ),
                  ),
                ],
              ),
            ),
            if (_isEnabled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _produtoDescricaoController,
                            label: 'Produto',
                            hint: 'Selecione...',
                            icon: Icons.search,
                            enabled: false, // Preenchido pela busca
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _searchProduct,
                          icon: const Icon(Icons.search),
                          tooltip: 'Buscar Produto',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _caController,
                            label: 'CA',
                            hint: '',
                            icon: Icons.verified_outlined,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _quantidadeAtualConstroller,
                            label: 'Qnt. Atual',
                            hint: '',
                            icon: Icons.inventory_2_outlined,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _quantidadeController,
                            label: 'Qnt. na nota',
                            hint: '0',
                            icon: Icons.numbers,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _valorUnitarioController,
                            label: 'Valor (R\$)',
                            hint: '0,00',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            inputFormatters: [CurrencyInputFormatter()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _addItemToList,
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Adicionar Item'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Itens da Nota (${_items.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: ${currency.format(totalValue)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (_items.isEmpty)
              Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Nenhum item adicionado',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.inventory_2, size: 18, color: theme.colorScheme.primary),
                      ),
                      title: Text(item['descricao'], style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('CA: ${item['ca']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${item['quantidade']} un x ${currency.format(item['valorUnitario'])}'),
                              Text(
                                currency.format(item['valorTotal']),
                                style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                              ),
                            ],
                          ),
                          if (_isEnabled) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}