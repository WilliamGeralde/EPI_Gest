import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/mapeamento_funcionario_repository_contract.dart';

class BuscarMapeamentoFuncionarioUseCase {
  final MapeamentoFuncionarioRepositoryContract _repository;

  BuscarMapeamentoFuncionarioUseCase(this._repository);

  Future<MapeamentoFuncionarioModel?> call(String funcionarioId) {
    return _repository.getByFuncionarioId(funcionarioId);
  }
}
