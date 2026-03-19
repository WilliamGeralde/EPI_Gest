import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';

abstract class UnidadeRepositoryContract {
  Future<List<UnidadeModel>> getAllUnidades();
}
