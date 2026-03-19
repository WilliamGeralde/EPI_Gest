import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';

abstract class MapeamentoFuncionarioRepositoryContract {
  Future<List<MapeamentoFuncionarioModel>> getAllRelations();

  Future<MapeamentoFuncionarioModel?> getByFuncionarioId(String funcionarioId);

  Future<MapeamentoFuncionarioModel> createRelation(
    MapeamentoFuncionarioModel relation,
  );

  Future<MapeamentoFuncionarioModel> updateRelation(
    String relationId,
    Map<String, dynamic> data,
  );

  Future<void> deleteRelation(String relationId);
}
