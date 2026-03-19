import 'package:epi_gest_project/domain/models/organizational_structure/unidade_model.dart';

abstract class UnidadeRepositoryContract {
  Future<List<UnidadeModel>> getAllUnidades();

  Future<UnidadeModel> createUnidade(UnidadeModel unidade);

  Future<UnidadeModel> updateUnidade(UnidadeModel unidade);

  Future<void> updateUnidadeStatus(String rowId, bool status);
}
