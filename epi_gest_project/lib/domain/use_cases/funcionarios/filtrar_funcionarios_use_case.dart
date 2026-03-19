import 'package:epi_gest_project/domain/models/filters/funcionario_filter_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';

class FiltrarFuncionariosUseCase {
  const FiltrarFuncionariosUseCase();

  List<FuncionarioModel> call({
    required List<FuncionarioModel> funcionarios,
    required FuncionarioFilterModel filtros,
    required Map<String, String> mapeamentosPorFuncionario,
  }) {
    if (filtros.isEmpty) {
      return List.from(funcionarios);
    }

    return funcionarios.where((employee) {
      if (filtros.nome != null &&
          !employee.nomeFunc.toLowerCase().contains(
            filtros.nome!.toLowerCase(),
          )) {
        return false;
      }

      if (filtros.matricula != null &&
          !employee.matricula.toLowerCase().contains(
            filtros.matricula!.toLowerCase(),
          )) {
        return false;
      }

      if (filtros.status != null && filtros.status!.isNotEmpty) {
        final isAtivo = filtros.status!.contains('Ativo');
        final isInativo = filtros.status!.contains('Inativo');

        if (isAtivo && !isInativo && !employee.statusAtivo) {
          return false;
        }
        if (isInativo && !isAtivo && employee.statusAtivo) {
          return false;
        }
      }

      if (filtros.dataEntrada != null) {
        final filterDate = filtros.dataEntrada!;
        final employeeDate = employee.dataEntrada;

        if (employeeDate.year != filterDate.year ||
            employeeDate.month != filterDate.month ||
            employeeDate.day != filterDate.day) {
          return false;
        }
      }

      if (filtros.mapeamentos != null && filtros.mapeamentos!.isNotEmpty) {
        final employeeMapping = mapeamentosPorFuncionario[employee.id];

        if (employeeMapping == null ||
            !filtros.mapeamentos!.contains(employeeMapping)) {
          return false;
        }
      }

      return true;
    }).toList();
  }
}
