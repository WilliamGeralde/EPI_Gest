import 'package:epi_gest_project/domain/models/organizational_structure/mapeamento_epi_model.dart';

abstract class MapeamentoEpiRepositoryContract {
  Future<List<MapeamentoEpiModel>> getAllMapeamentos();
}
