import 'package:epi_gest_project/domain/repositories/organizational_structure/unidade_repository_contract.dart';

class AtualizarStatusUnidadeUseCase {
  final UnidadeRepositoryContract _repository;

  AtualizarStatusUnidadeUseCase(this._repository);

  Future<void> call(String unidadeId, bool status) {
    return _repository.updateUnidadeStatus(unidadeId, status);
  }
}
