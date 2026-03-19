import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/vinculo_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/mapeamento_epi_repository_contract.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/unidade_repository_contract.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/vinculo_repository_contract.dart';

class DadosAuxiliaresFuncionarioResult {
  final List<TurnoModel> turnos;
  final List<VinculoModel> vinculos;
  final List<MapeamentoEpiModel> mapeamentos;
  final List<UnidadeModel> unidades;

  const DadosAuxiliaresFuncionarioResult({
    required this.turnos,
    required this.vinculos,
    required this.mapeamentos,
    required this.unidades,
  });
}

class CarregarDadosAuxiliaresFuncionarioUseCase {
  final TurnoRepositoryContract _turnoRepository;
  final VinculoRepositoryContract _vinculoRepository;
  final MapeamentoEpiRepositoryContract _mapeamentoRepository;
  final UnidadeRepositoryContract _unidadeRepository;

  CarregarDadosAuxiliaresFuncionarioUseCase(
    this._turnoRepository,
    this._vinculoRepository,
    this._mapeamentoRepository,
    this._unidadeRepository,
  );

  Future<DadosAuxiliaresFuncionarioResult> call() async {
    final results = await Future.wait([
      _turnoRepository.getAllTurnos(),
      _vinculoRepository.getAllVinculos(),
      _mapeamentoRepository.getAllMapeamentos(),
      _unidadeRepository.getAllUnidades(),
    ]);

    return DadosAuxiliaresFuncionarioResult(
      turnos: results[0] as List<TurnoModel>,
      vinculos: results[1] as List<VinculoModel>,
      mapeamentos: results[2] as List<MapeamentoEpiModel>,
      unidades: results[3] as List<UnidadeModel>,
    );
  }
}
