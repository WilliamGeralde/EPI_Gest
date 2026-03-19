import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/atualizar_status_vinculo_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/carregar_vinculos_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/salvar_vinculo_use_case.dart';

class VinculoController {
  final CarregarVinculosUseCase _carregarVinculosUseCase;
  final SalvarVinculoUseCase _salvarVinculoUseCase;
  final AtualizarStatusVinculoUseCase _atualizarStatusVinculoUseCase;

  VinculoController({
    required CarregarVinculosUseCase carregarVinculosUseCase,
    required SalvarVinculoUseCase salvarVinculoUseCase,
    required AtualizarStatusVinculoUseCase atualizarStatusVinculoUseCase,
  }) : _carregarVinculosUseCase = carregarVinculosUseCase,
       _salvarVinculoUseCase = salvarVinculoUseCase,
       _atualizarStatusVinculoUseCase = atualizarStatusVinculoUseCase;

  Future<List<VinculoModel>> carregarVinculos() {
    return _carregarVinculosUseCase();
  }

  Future<VinculoModel> salvarVinculo({
    required VinculoModel vinculo,
    required bool isEditing,
  }) {
    return _salvarVinculoUseCase(vinculo: vinculo, isEditing: isEditing);
  }

  Future<void> atualizarStatusVinculo(String vinculoId, bool status) {
    return _atualizarStatusVinculoUseCase(vinculoId, status);
  }
}
