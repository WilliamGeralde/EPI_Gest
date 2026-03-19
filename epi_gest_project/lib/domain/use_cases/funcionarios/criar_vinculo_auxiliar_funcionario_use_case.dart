import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class CriarVinculoAuxiliarFuncionarioUseCase {
  final VinculoRepositoryContract _repository;

  CriarVinculoAuxiliarFuncionarioUseCase(this._repository);

  Future<VinculoModel> call(String nomeVinculo) {
    final nomeNormalizado = nomeVinculo.trim();
    if (nomeNormalizado.isEmpty) {
      throw Exception('Nome de vinculo obrigatorio.');
    }

    return _repository.createVinculo(
      VinculoModel(nomeVinculo: nomeNormalizado),
    );
  }
}
