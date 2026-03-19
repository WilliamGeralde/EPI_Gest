import 'package:epi_gest_project/domain/repositories/funcionarios/funcionario_repository_contract.dart';

class InativarFuncionarioUseCase {
  final FuncionarioRepositoryContract _repository;

  InativarFuncionarioUseCase(this._repository);

  Future<void> call(String funcionarioId, {String? motivo}) {
    return _repository.inactivateEmployee(funcionarioId, motivo: motivo);
  }
}
