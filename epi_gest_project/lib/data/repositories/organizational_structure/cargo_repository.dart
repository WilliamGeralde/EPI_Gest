import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/organizational_structure/cargo_model.dart';

class CargoRepository extends BaseRepository<CargoModel> {
  CargoRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseCargo);

  @override
  CargoModel fromMap(Map<String, dynamic> map) {
    return CargoModel.fromMap(map);
  }

  Future<List<CargoModel>> getAllCargos() async {
    return await getAll([]);
  }
}
