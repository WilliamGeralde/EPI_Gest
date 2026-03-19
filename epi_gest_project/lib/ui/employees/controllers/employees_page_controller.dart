import 'package:epi_gest_project/domain/models/filters/funcionario_filter_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/ativar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/carregar_dados_funcionarios_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/filtrar_funcionarios_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/inativar_funcionario_use_case.dart';

class EmployeesPageController {
  final CarregarDadosFuncionariosUseCase _carregarDadosUseCase;
  final FiltrarFuncionariosUseCase _filtrarFuncionariosUseCase;
  final InativarFuncionarioUseCase _inativarFuncionarioUseCase;
  final AtivarFuncionarioUseCase _ativarFuncionarioUseCase;

  EmployeesPageController({
    required CarregarDadosFuncionariosUseCase carregarDadosUseCase,
    required FiltrarFuncionariosUseCase filtrarFuncionariosUseCase,
    required InativarFuncionarioUseCase inativarFuncionarioUseCase,
    required AtivarFuncionarioUseCase ativarFuncionarioUseCase,
  }) : _carregarDadosUseCase = carregarDadosUseCase,
       _filtrarFuncionariosUseCase = filtrarFuncionariosUseCase,
       _inativarFuncionarioUseCase = inativarFuncionarioUseCase,
       _ativarFuncionarioUseCase = ativarFuncionarioUseCase;

  Future<DadosFuncionariosResult> carregarDados() {
    return _carregarDadosUseCase();
  }

  List<FuncionarioModel> aplicarFiltros({
    required List<FuncionarioModel> funcionarios,
    required FuncionarioFilterModel filtros,
    required Map<String, String> mapeamentosPorFuncionario,
  }) {
    return _filtrarFuncionariosUseCase(
      funcionarios: funcionarios,
      filtros: filtros,
      mapeamentosPorFuncionario: mapeamentosPorFuncionario,
    );
  }

  Future<void> inativarFuncionario(String funcionarioId, {String? motivo}) {
    return _inativarFuncionarioUseCase(funcionarioId, motivo: motivo);
  }

  Future<void> ativarFuncionario(String funcionarioId) {
    return _ativarFuncionarioUseCase(funcionarioId);
  }
}
