import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/funcionario_repository_contract.dart';

class SalvarFuncionarioUseCase {
  final FuncionarioRepositoryContract _repository;

  SalvarFuncionarioUseCase(this._repository);

  Future<FuncionarioModel> call({
    required FuncionarioModel funcionario,
    required bool isEditing,
  }) {
    if (isEditing) {
      return _repository.updateFuncionario(funcionario);
    }

    return _repository.createFuncionario(funcionario);
  }
}
