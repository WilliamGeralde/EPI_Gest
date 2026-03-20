import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/setor_model.dart';

class SetorRepository extends BaseRepository<SetorModel> {
  SetorRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseSetor);

  @override
  SetorModel fromMap(Map<String, dynamic> map) {
    return SetorModel.fromMap(map);
  }

  Future<List<SetorModel>> getAllSetores() async {
    return await getAll([]);
  }
}
