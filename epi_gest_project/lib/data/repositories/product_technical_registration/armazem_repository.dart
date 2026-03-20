import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/armazem_model.dart';

class ArmazemRepository extends BaseRepository<ArmazemModel> {
  ArmazemRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseLocalArmazem);

  @override
  ArmazemModel fromMap(Map<String, dynamic> map) {
    return ArmazemModel.fromMap(map);
  }

  Future<List<ArmazemModel>> getAllArmazens() async {
    // Traz os dados populando a unidade (relationship) se configurado no Appwrite
    return await getAll([
      Query.orderAsc('codigo_armazem'),
      Query.select(['*', 'unidade_id.*']) 
    ]);
  }
}
