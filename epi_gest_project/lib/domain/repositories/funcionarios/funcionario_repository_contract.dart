import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';

abstract class FuncionarioRepositoryContract {
  Future<List<FuncionarioModel>> getAllFuncionarios();

  Future<FuncionarioModel> createFuncionario(FuncionarioModel funcionario);

  Future<FuncionarioModel> updateFuncionario(FuncionarioModel funcionario);

  Future<void> inactivateEmployee(String rowId, {String? motivo});

  Future<void> activateEmployee(String rowId);
}
