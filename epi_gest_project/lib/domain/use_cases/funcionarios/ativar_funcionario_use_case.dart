import 'package:epi_gest_project/domain/repositories/funcionarios/funcionario_repository_contract.dart';

class AtivarFuncionarioUseCase {
  final FuncionarioRepositoryContract _repository;

  AtivarFuncionarioUseCase(this._repository);

  Future<void> call(String funcionarioId) {
    return _repository.activateEmployee(funcionarioId);
  }
}
