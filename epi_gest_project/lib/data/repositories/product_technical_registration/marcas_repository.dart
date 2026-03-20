import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/marcas_model.dart';

class MarcasRepository extends BaseRepository<MarcasModel> {
  MarcasRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseMarcas);

  @override
  MarcasModel fromMap(Map<String, dynamic> map) {
    return MarcasModel.fromMap(map);
  }

  Future<List<MarcasModel>> getAllMarcas() async {
    return await getAll([Query.orderAsc('nome_marca')]);
  }
}
