import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/riscos_model.dart';

class RiscosRepository extends BaseRepository<RiscosModel> {
  RiscosRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseRiscos);

  @override
  RiscosModel fromMap(Map<String, dynamic> map) {
    return RiscosModel.fromMap(map);
  }

  Future<List<RiscosModel>> getAllRiscos() async {
    return await getAll([]);
  }
}
