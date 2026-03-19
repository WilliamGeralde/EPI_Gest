import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/funcionario_repository_contract.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/mapeamento_funcionario_repository_contract.dart';

class DadosFuncionariosResult {
  final List<FuncionarioModel> funcionarios;
  final Map<String, String> mapeamentosPorFuncionario;
  final List<String> mapeamentosDisponiveis;

  const DadosFuncionariosResult({
    required this.funcionarios,
    required this.mapeamentosPorFuncionario,
    required this.mapeamentosDisponiveis,
  });
}

class CarregarDadosFuncionariosUseCase {
  final FuncionarioRepositoryContract _funcionarioRepository;
  final MapeamentoFuncionarioRepositoryContract _mapeamentoRepository;

  CarregarDadosFuncionariosUseCase(
    this._funcionarioRepository,
    this._mapeamentoRepository,
  );

  Future<DadosFuncionariosResult> call() async {
    final results = await Future.wait([
      _funcionarioRepository.getAllFuncionarios(),
      _mapeamentoRepository.getAllRelations(),
    ]);

    final funcionarios = results[0] as List<FuncionarioModel>;
    final mapeamentos = results[1] as List<MapeamentoFuncionarioModel>;

    final mappingMap = <String, String>{};
    final mappingNames = <String>{};

    for (final map in mapeamentos) {
      final funcionarioId = map.funcionario.id;
      if (funcionarioId == null || funcionarioId.isEmpty) {
        continue;
      }

      mappingMap[funcionarioId] = map.mapeamento.nomeMapeamento;
      mappingNames.add(map.mapeamento.nomeMapeamento);
    }

    final sortedMappingNames = mappingNames.toList()..sort();

    return DadosFuncionariosResult(
      funcionarios: funcionarios,
      mapeamentosPorFuncionario: mappingMap,
      mapeamentosDisponiveis: sortedMappingNames,
    );
  }
}
