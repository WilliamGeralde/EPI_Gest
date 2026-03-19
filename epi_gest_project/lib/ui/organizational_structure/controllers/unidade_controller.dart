import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/atualizar_status_unidade_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/carregar_unidades_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/organizational_structure/salvar_unidade_use_case.dart';

class UnidadeController {
  final CarregarUnidadesUseCase _carregarUnidadesUseCase;
  final SalvarUnidadeUseCase _salvarUnidadeUseCase;
  final AtualizarStatusUnidadeUseCase _atualizarStatusUnidadeUseCase;

  UnidadeController({
    required CarregarUnidadesUseCase carregarUnidadesUseCase,
    required SalvarUnidadeUseCase salvarUnidadeUseCase,
    required AtualizarStatusUnidadeUseCase atualizarStatusUnidadeUseCase,
  }) : _carregarUnidadesUseCase = carregarUnidadesUseCase,
       _salvarUnidadeUseCase = salvarUnidadeUseCase,
       _atualizarStatusUnidadeUseCase = atualizarStatusUnidadeUseCase;

  Future<List<UnidadeModel>> carregarUnidades() {
    return _carregarUnidadesUseCase();
  }

  List<UnidadeModel> ordenarUnidades(List<UnidadeModel> unidades) {
    final sorted = List<UnidadeModel>.from(unidades);
    sorted.sort((a, b) {
      if (a.tipoUnidade == 'Matriz' && b.tipoUnidade != 'Matriz') {
        return -1;
      }
      if (a.tipoUnidade != 'Matriz' && b.tipoUnidade == 'Matriz') {
        return 1;
      }
      return a.nomeUnidade.compareTo(b.nomeUnidade);
    });
    return sorted;
  }

  Future<UnidadeModel> salvarUnidade({
    required UnidadeModel unidade,
    required bool isEditing,
  }) {
    return _salvarUnidadeUseCase(unidade: unidade, isEditing: isEditing);
  }

  Future<void> atualizarStatusUnidade(String unidadeId, bool status) {
    return _atualizarStatusUnidadeUseCase(unidadeId, status);
  }
}
