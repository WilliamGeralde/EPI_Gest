import 'package:epi_gest_project/domain/models/funcionarios/funcionario_model.dart';
import 'package:epi_gest_project/domain/models/funcionarios/mapeamento_funcionario_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/buscar_mapeamento_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/carregar_dados_auxiliares_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/criar_turno_auxiliar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/criar_vinculo_auxiliar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_mapeamento_funcionario_use_case.dart';

class EmployeeCoreController {
  final SalvarFuncionarioUseCase _salvarFuncionarioUseCase;
  final BuscarMapeamentoFuncionarioUseCase _buscarMapeamentoUseCase;
  final SalvarMapeamentoFuncionarioUseCase _salvarMapeamentoUseCase;
  final CarregarDadosAuxiliaresFuncionarioUseCase
      _carregarDadosAuxiliaresUseCase;
  final CriarVinculoAuxiliarFuncionarioUseCase _criarVinculoUseCase;
  final CriarTurnoAuxiliarFuncionarioUseCase _criarTurnoUseCase;

  EmployeeCoreController({
    required SalvarFuncionarioUseCase salvarFuncionarioUseCase,
    required BuscarMapeamentoFuncionarioUseCase buscarMapeamentoUseCase,
    required SalvarMapeamentoFuncionarioUseCase salvarMapeamentoUseCase,
    required CarregarDadosAuxiliaresFuncionarioUseCase
        carregarDadosAuxiliaresUseCase,
    required CriarVinculoAuxiliarFuncionarioUseCase criarVinculoUseCase,
    required CriarTurnoAuxiliarFuncionarioUseCase criarTurnoUseCase,
  }) : _salvarFuncionarioUseCase = salvarFuncionarioUseCase,
       _buscarMapeamentoUseCase = buscarMapeamentoUseCase,
       _salvarMapeamentoUseCase = salvarMapeamentoUseCase,
       _carregarDadosAuxiliaresUseCase = carregarDadosAuxiliaresUseCase,
       _criarVinculoUseCase = criarVinculoUseCase,
       _criarTurnoUseCase = criarTurnoUseCase;

  Future<DadosAuxiliaresFuncionarioResult> carregarDadosAuxiliares() {
    return _carregarDadosAuxiliaresUseCase();
  }

  List<MapeamentoEpiModel> filtrarMapeamentosDisponiveis({
    required List<MapeamentoEpiModel> mapeamentos,
    required MapeamentoFuncionarioModel? currentVinculo,
  }) {
    return mapeamentos.where((mapeamento) {
      final isCurrent = currentVinculo?.mapeamento.id == mapeamento.id;
      return mapeamento.status == true || isCurrent;
    }).toList();
  }

  Future<VinculoModel> criarVinculo(String nomeVinculo) {
    return _criarVinculoUseCase(nomeVinculo);
  }

  Future<TurnoModel> criarTurno({
    required String nomeTurno,
    required String horaEntrada,
    required String horaSaida,
    required String inicioAlmoco,
    required String fimAlmoco,
  }) {
    return _criarTurnoUseCase(
      nomeTurno: nomeTurno,
      horaEntrada: horaEntrada,
      horaSaida: horaSaida,
      inicioAlmoco: inicioAlmoco,
      fimAlmoco: fimAlmoco,
    );
  }

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
