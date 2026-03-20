import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/entradas_model.dart';
import 'package:epi_gest_project/domain/models/entradas_epi_model.dart';
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/entradas_epi_repository.dart';

class EntradasRepository extends BaseRepository<EntradasModel> {
  final EpiRepository _epiRepository;
  final EntradasEpiRepository _entradasEpiRepository;

  EntradasRepository(
    TablesDB databases,
    this._epiRepository,
    this._entradasEpiRepository,
  ) : super(databases, AppwriteConstants.databaseEntradas);

  @override
  EntradasModel fromMap(Map<String, dynamic> map) {
    return EntradasModel.fromMap(map);
  }

  Future<List<EntradasModel>> getAllEntradas() async {
    return await getAll([
      Query.orderDesc('data_entrada'),
      Query.select([
        '*',
        'fornecedor_id.*',
        'entradas_epi_id.*',
        'entradas_epi_id.epi_id.*',
      ]),
    ]);
  }

  Future<void> registrarEntradaCompleta({
    required EntradasModel entradaHeader,
    required List<EntradasEpiModel> itens,
  }) async {
    List<String> idsItensSalvos = [];

    try {
      for (var item in itens) {
        final epiAtual = await _epiRepository.get(item.epi.id!, [
          Query.select([
            '*',
            'marca_id.*',
            'armazem_id.*',
            'categoria_id.*',
            'medida_id.*',
          ]),
        ]);

        final double valorTotalEstoqueAtual = epiAtual.estoque * epiAtual.valor;
        final double valorTotalEntrada = item.quantidade * item.valor;
        final double novoEstoque = epiAtual.estoque + item.quantidade;

        double novoValorUnitario = 0.0;
        if (novoEstoque > 0) {
          novoValorUnitario =
              (valorTotalEstoqueAtual + valorTotalEntrada) / novoEstoque;
        }

        final itemSalvo = await _entradasEpiRepository.create(item);
        idsItensSalvos.add(itemSalvo.id!);

        await _epiRepository.updateEstoqueEValor(
          epiAtual.id!,
          novoEstoque,
          novoValorUnitario,
        );
      }

      final mapHeader = entradaHeader.toMap();
      mapHeader['entradas_epi_id'] = idsItensSalvos;

      await databases.createRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: ID.unique(),
        data: mapHeader,
      );
    } catch (e) {
      throw Exception('Erro ao registrar entrada: $e');
    }
  }

  Future<void> excluirEntrada(String entradaId) async {
    try {
      final entrada = await get(entradaId, [
        Query.select([
          '*',
          'fornecedor_id.*',
          'entradas_epi_id.*',
          'entradas_epi_id.epi_id.*',
        ]),
      ]);

      for (var item in entrada.entradasId) {
        if (item.epi.id == null) continue;

        final epiAtual = await _epiRepository.get(item.epi.id!, [
          Query.select([
            '*',
            'marca_id.*',
            'armazem_id.*',
            'categoria_id.*',
            'medida_id.*',
          ]),
        ]);

        // Matemática Reversa do Preço Médio:
        // ValorTotalAtual = EstoqueAtual * ValorUnitarioAtual
        // ValorDaEntradaQueSeraRemovida = QtdEntrada * ValorCompraNaEpoca
        // NovoValorTotal = ValorTotalAtual - ValorDaEntradaQueSeraRemovida
        // NovoEstoque = EstoqueAtual - QtdEntrada

        final double valorTotalAtual = epiAtual.estoque * epiAtual.valor;
        final double valorEntradaParaRemover = item.quantidade * item.valor;

        final double novoEstoque = epiAtual.estoque - item.quantidade;
        final double novoValorTotal = valorTotalAtual - valorEntradaParaRemover;

        double novoValorUnitario = 0.0;

        if (novoEstoque > 0) {
          final safeValorTotal = novoValorTotal < 0 ? 0.0 : novoValorTotal;
          novoValorUnitario = safeValorTotal / novoEstoque;
        }

        await _epiRepository.updateEstoqueEValor(
          epiAtual.id!,
          novoEstoque < 0 ? 0 : novoEstoque,
          novoValorUnitario,
        );

        if (item.id != null) {
          await _entradasEpiRepository.delete(item.id!);
        }
      }

      await delete(entradaId);
    } catch (e) {
      throw Exception('Erro ao excluir entrada e reverter estoque: $e');
    }
  }
}
