import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/buscar_mapeamento_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_mapeamento_funcionario_use_case.dart';

class EmployeeCoreController {
  final SalvarFuncionarioUseCase _salvarFuncionarioUseCase;
  final BuscarMapeamentoFuncionarioUseCase _buscarMapeamentoUseCase;
  final SalvarMapeamentoFuncionarioUseCase _salvarMapeamentoUseCase;

  EmployeeCoreController({
    required SalvarFuncionarioUseCase salvarFuncionarioUseCase,
    required BuscarMapeamentoFuncionarioUseCase buscarMapeamentoUseCase,
    required SalvarMapeamentoFuncionarioUseCase salvarMapeamentoUseCase,
  }) : _salvarFuncionarioUseCase = salvarFuncionarioUseCase,
       _buscarMapeamentoUseCase = buscarMapeamentoUseCase,
       _salvarMapeamentoUseCase = salvarMapeamentoUseCase;

  Future<MapeamentoFuncionarioModel?> buscarMapeamentoAtual(String funcionarioId) {
    return _buscarMapeamentoUseCase(funcionarioId);
  }

  Future<FuncionarioModel> salvarFuncionario({
    required FuncionarioModel funcionario,
    required bool isEditing,
  }) {
    return _salvarFuncionarioUseCase(
      funcionario: funcionario,
      isEditing: isEditing,
    );
  }

  Future<void> sincronizarMapeamento({
    required FuncionarioModel funcionarioSalvo,
    required MapeamentoFuncionarioModel? currentVinculo,
    required String mapeamentoNome,
    required String unidadeNome,
    required List<MapeamentoEpiModel> mapeamentosDisponiveis,
    required List<UnidadeModel> unidadesDisponiveis,
  }) {
    return _salvarMapeamentoUseCase(
      funcionarioSalvo: funcionarioSalvo,
      currentVinculo: currentVinculo,
      mapeamentoNome: mapeamentoNome,
      unidadeNome: unidadeNome,
      mapeamentosDisponiveis: mapeamentosDisponiveis,
      unidadesDisponiveis: unidadesDisponiveis,
    );
  }
}
