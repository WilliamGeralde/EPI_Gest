import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/epi_model.dart';

class EpiRepository extends BaseRepository<EpiModel> {
  EpiRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseEpi);

  @override
  EpiModel fromMap(Map<String, dynamic> map) {
    return EpiModel.fromMap(map);
  }

  /// Busca todos os EPIs carregando os relacionamentos
  Future<List<EpiModel>> getAllEpis() async {
    try {
      return await getAll([
        Query.orderAsc('nome_produto'),
        // Seleciona os campos e expande os relacionamentos
        Query.select([
          '*', 
          'marca_id.*', 
          'armazem_id.*', 
          'categoria_id.*', 
          'medida_id.*'
        ]),
      ]);
    } on AppwriteException catch (e) {
      throw Exception('Falha ao carregar EPIs: ${e.message}');
    }
  }

  /// Busca EPIs por Categoria
  Future<List<EpiModel>> getByCategoria(String categoriaId) async {
    return await getAll([
      Query.equal('categoria_id', categoriaId),
      Query.select(['*', 'marca_id.*', 'armazem_id.*', 'categoria_id.*', 'medida_id.*']),
    ]);
  }

  Future<void> updateEstoqueEValor(String epiId, double novoEstoque, double novoValor) async {
    try {
      await update(epiId, {
        'estoque': novoEstoque,
        'valor': novoValor,
      });
    } catch (e) {
      throw Exception('Erro ao atualizar estoque e valor do EPI: $e');
    }
  }
}
