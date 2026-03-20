import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/data/repositories/epi_repository.dart';
import 'package:epi_gest_project/data/repositories/funcionarios/ficha_epi_repository.dart';
import 'package:epi_gest_project/domain/models/ficha_entrega_model.dart';
import 'package:epi_gest_project/domain/models/ficha_epi_model.dart';

class FichaEntregaRepository extends BaseRepository<FichaEntregaModel> {
  final FichaEpiRepository _fichaEpiRepository;
  final EpiRepository _epiRepository;
  
  FichaEntregaRepository(
    TablesDB databases,
    this._fichaEpiRepository,
    this._epiRepository,
  ) : super(databases, AppwriteConstants.databaseFichaEntrega);

  @override
  FichaEntregaModel fromMap(Map<String, dynamic> map) {
    return FichaEntregaModel.fromMap(map);
  }

  Future<List<FichaEntregaModel>> getAllEntregas() async {
    try {
      return await getAll([
        Query.orderDesc('\$createdAt'),
        Query.select([
          '*',
          'mapeamento_funcionario_id.*',
          'mapeamento_funcionario_id.funcionario_id.*',
          'ficha_epi_id.*',
          'ficha_epi_id.epi_id.*',
        ]),
      ]);
    } catch (e) {
      throw Exception('Erro ao buscar histórico de entregas: $e');
    }
  }

  Future<List<FichaEntregaModel>> getAllEntregasAtivas() async {
    try {
      return await getAll([
        Query.orderDesc('\$createdAt'),
        Query.select([
          '*',
          'mapeamento_funcionario_id.*',
          'mapeamento_funcionario_id.funcionario_id.*',
          'ficha_epi_id.*',
          'ficha_epi_id.epi_id.*',
        ]),
        Query.equal('status', true),
      ]);
    } catch (e) {
      throw Exception('Erro ao buscar histórico de entregas: $e');
    }
  }

  Future<List<FichaEntregaModel>> getByFuncionario(String mapFuncId) async {
    try {
      return await getAll([
        Query.equal('mapeamento_funcionario_id', mapFuncId),
        Query.orderDesc('\$createdAt'),
        Query.select([
          '*',
          'mapeamento_funcionario_id.unidade_id.*',
          'mapeamento_funcionario_id.funcionario_id.*',
          'ficha_epi_id.*',
          'ficha_epi_id.epi_id.*',
        ]),
      ]);
    } catch (e) {
      throw Exception('Erro ao buscar entregas do funcionário: $e');
    }
  }

  Future<void> registrarEntregaCompleta({
    required FichaEntregaModel entregaHeader,
    required List<FichaEpiModel> itensParaSalvar,
  }) async {
    List<String> idsFichaEpiSalvos = [];

    try {
      for (var fichaEpi in itensParaSalvar) {
        final epiId = fichaEpi.epi.id!;
        
        // Usamos a quantidade diretamente do modelo agora
        final quantidadeBaixa = fichaEpi.quantidade;

        // A. Validação de Estoque (Segurança de Backend)
        final epiAtual = await _epiRepository.get(epiId, []);
        
        if (epiAtual.estoque < quantidadeBaixa) {
           throw Exception(
             'Estoque insuficiente para ${epiAtual.nomeProduto}. '
             'Atual: ${epiAtual.estoque}, Solicitado: $quantidadeBaixa'
           );
        }

        final itemSalvo = await _fichaEpiRepository.create(fichaEpi);
        idsFichaEpiSalvos.add(itemSalvo.id!);

        // C. Atualizar Estoque
        final novoEstoque = epiAtual.estoque - quantidadeBaixa;
        await _epiRepository.updateEstoqueEValor(
          epiId,
          novoEstoque < 0 ? 0 : novoEstoque, // Proteção contra negativo
          epiAtual.valor, // Mantém valor unitário atual
        );
      }

      // Passo 2: Criar Cabeçalho da Entrega
      final mapHeader = entregaHeader.toMap();
      
      // Substitui a lista de objetos pelos IDs recém criados para o vínculo
      mapHeader['ficha_epi_id'] = idsFichaEpiSalvos;

      await databases.createRow(
        databaseId: AppwriteConstants.databaseId,
        tableId: tableId,
        rowId: ID.unique(),
        data: mapHeader,
      );
      
    } catch (e) {
      throw Exception('Erro ao processar transação de entrega: $e');
    }
  }
}
