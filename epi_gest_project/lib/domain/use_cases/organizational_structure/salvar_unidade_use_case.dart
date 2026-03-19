import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/unidade_repository_contract.dart';

class SalvarUnidadeUseCase {
  final UnidadeRepositoryContract _repository;

  SalvarUnidadeUseCase(this._repository);

  Future<UnidadeModel> call({
    required UnidadeModel unidade,
    required bool isEditing,
  }) {
    if (isEditing) {
      return _repository.updateUnidade(unidade);
    }

    return _repository.createUnidade(unidade);
  }
}
