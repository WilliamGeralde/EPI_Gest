import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/data/constants/appwrite_constants.dart';
import 'package:epi_gest_project/data/repositories/base_repository.dart';
import 'package:epi_gest_project/domain/models/product_technical_registration/categoria_model.dart';

class CategoriaRepository extends BaseRepository<CategoriaModel> {
  CategoriaRepository(TablesDB databases)
      : super(databases, AppwriteConstants.databaseCategoria);

  @override
  CategoriaModel fromMap(Map<String, dynamic> map) {
    return CategoriaModel.fromMap(map);
  }

  Future<List<CategoriaModel>> getAllCategorias() async {
    return await getAll([]);
  }
}
