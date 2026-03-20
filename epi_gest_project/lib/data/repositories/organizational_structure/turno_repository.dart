import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/turno_model.dart';
import 'package:epi_gest_project/domain/repositories/organizational_structure/turno_repository_contract.dart';

class TurnoRepository extends BaseRepository<TurnoModel> implements TurnoRepositoryContract {
  TurnoRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseTurno);

  @override
  TurnoModel fromMap(Map<String, dynamic> map) {
    return TurnoModel.fromMap(map);
  }

  @override
  Future<List<TurnoModel>> getAllTurnos() async {
    return await getAll([]);
  }

  @override
  Future<TurnoModel> createTurno(TurnoModel turno) {
    return create(turno);
  }

  @override
  Future<TurnoModel> updateTurno(TurnoModel turno) {
    final id = turno.id;
    if (id == null || id.isEmpty) {
      throw Exception('Turno sem id para atualizacao.');
    }

    return update(id, turno.toMap());
  }

  @override
  Future<void> updateTurnoStatus(String rowId, bool status) async {
    await update(rowId, {'status': status});
  }
}
