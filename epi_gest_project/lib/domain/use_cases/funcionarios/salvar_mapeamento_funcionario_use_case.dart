import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/mapeamento_funcionario_repository_contract.dart';

class SalvarMapeamentoFuncionarioUseCase {
  final MapeamentoFuncionarioRepositoryContract _repository;

  SalvarMapeamentoFuncionarioUseCase(this._repository);

  Future<void> call({
    required FuncionarioModel funcionarioSalvo,
    required MapeamentoFuncionarioModel? currentVinculo,
    required String mapeamentoNome,
    required String unidadeNome,
    required List<MapeamentoEpiModel> mapeamentosDisponiveis,
    required List<UnidadeModel> unidadesDisponiveis,
  }) async {
    final hasMapeamento = mapeamentoNome.isNotEmpty;
    final hasUnidade = unidadeNome.isNotEmpty;

    if (hasMapeamento && hasUnidade) {
      final mapObj = mapeamentosDisponiveis.firstWhere(
        (m) => m.nomeMapeamento == mapeamentoNome,
        orElse: () => throw Exception('Mapeamento invalido selecionado.'),
      );

      final unitObj = unidadesDisponiveis.firstWhere(
        (u) => u.nomeUnidade == unidadeNome,
        orElse: () => throw Exception('Unidade invalida selecionada.'),
      );

      if (currentVinculo?.id != null) {
        await _repository.updateRelation(currentVinculo!.id!, {
          'mapeamento_id': mapObj.id,
          'unidade_id': unitObj.id,
        });
        return;
      }

      final newVinculo = MapeamentoFuncionarioModel(
        funcionario: funcionarioSalvo,
        mapeamento: mapObj,
        unidade: unitObj,
      );

      await _repository.createRelation(newVinculo);
      return;
    }

    if (currentVinculo?.id != null && (!hasMapeamento || !hasUnidade)) {
      await _repository.deleteRelation(currentVinculo!.id!);
    }
  }
}
