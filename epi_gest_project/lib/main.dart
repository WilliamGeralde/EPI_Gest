import 'package:appwrite/appwrite.dart';
import 'package:epi_gest_project/config/theme_notifier.dart';
import 'package:epi_gest_project/data/services/entradas_epi_repository.dart';
import 'package:epi_gest_project/data/services/entradas_repository.dart';
import 'package:epi_gest_project/data/services/epi_repository.dart';
import 'package:epi_gest_project/data/services/ficha_entrega_repository.dart';
import 'package:epi_gest_project/data/services/funcionarios/ficha_epi_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/cargo_repository.dart';
import 'package:epi_gest_project/data/services/product_technical_registration/armazem_repository.dart';
import 'package:epi_gest_project/data/services/product_technical_registration/categoria_repository.dart';
import 'package:epi_gest_project/data/services/funcionarios/funcionario_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/mapeamento_epi_repository.dart';
import 'package:epi_gest_project/data/services/funcionarios/mapeamento_funcionario_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/turno_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/riscos_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/setor_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/unidade_repository.dart';
import 'package:epi_gest_project/data/services/organizational_structure/vinculo_repository.dart';
import 'package:epi_gest_project/data/services/product_technical_registration/fornecedor_repository.dart';
import 'package:epi_gest_project/data/services/product_technical_registration/marcas_repository.dart';
import 'package:epi_gest_project/data/services/product_technical_registration/medida_repository.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/funcionario_repository_contract.dart';
import 'package:epi_gest_project/domain/repositories/funcionarios/mapeamento_funcionario_repository_contract.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/ativar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/buscar_mapeamento_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/carregar_dados_funcionarios_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/filtrar_funcionarios_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/inativar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_funcionario_use_case.dart';
import 'package:epi_gest_project/domain/use_cases/funcionarios/salvar_mapeamento_funcionario_use_case.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:epi_gest_project/ui/home/home_page.dart';
import 'package:epi_gest_project/ui/employees/controllers/employee_core_controller.dart';
import 'package:epi_gest_project/ui/employees/controllers/employees_page_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  Client client = Client();
  final databases = TablesDB(client);
  client
      .setEndpoint('https://nyc.cloud.appwrite.io/v1')
      .setProject('68ac56f3001bcef1296e')
      .setLocale('pt_BR');
  runApp(
    MultiProvider(
      providers: [
        Provider<FuncionarioRepository>(create: (_) => FuncionarioRepository(databases)),
        Provider<VinculoRepository>(create: (_) => VinculoRepository(databases)),
        Provider<TurnoRepository>(create: (_) => TurnoRepository(databases)),
        Provider<MapeamentoFuncionarioRepository>(create: (_) => MapeamentoFuncionarioRepository(databases)),
        ProxyProvider<FuncionarioRepository, FuncionarioRepositoryContract>(
          update: (context, repository, previous) => repository,
        ),
        ProxyProvider<MapeamentoFuncionarioRepository, MapeamentoFuncionarioRepositoryContract>(
          update: (context, repository, previous) => repository,
        ),
        ProxyProvider2<
            FuncionarioRepositoryContract,
            MapeamentoFuncionarioRepositoryContract,
            CarregarDadosFuncionariosUseCase>(
          update: (context, funcionarioRepository, mapeamentoRepository, previous) =>
              CarregarDadosFuncionariosUseCase(
            funcionarioRepository,
            mapeamentoRepository,
          ),
        ),
        Provider<FiltrarFuncionariosUseCase>(
          create: (_) => const FiltrarFuncionariosUseCase(),
        ),
        ProxyProvider<FuncionarioRepositoryContract, InativarFuncionarioUseCase>(
          update: (context, repository, previous) =>
              InativarFuncionarioUseCase(repository),
        ),
        ProxyProvider<FuncionarioRepositoryContract, AtivarFuncionarioUseCase>(
          update: (context, repository, previous) =>
              AtivarFuncionarioUseCase(repository),
        ),
        ProxyProvider<FuncionarioRepositoryContract, SalvarFuncionarioUseCase>(
          update: (context, repository, previous) =>
              SalvarFuncionarioUseCase(repository),
        ),
        ProxyProvider<
            MapeamentoFuncionarioRepositoryContract,
            BuscarMapeamentoFuncionarioUseCase>(
          update: (context, repository, previous) =>
              BuscarMapeamentoFuncionarioUseCase(repository),
        ),
        ProxyProvider<
            MapeamentoFuncionarioRepositoryContract,
            SalvarMapeamentoFuncionarioUseCase>(
          update: (context, repository, previous) =>
              SalvarMapeamentoFuncionarioUseCase(repository),
        ),
        ProxyProvider4<
            CarregarDadosFuncionariosUseCase,
            FiltrarFuncionariosUseCase,
            InativarFuncionarioUseCase,
            AtivarFuncionarioUseCase,
            EmployeesPageController>(
          update: (
            context,
            carregarDadosUseCase,
            filtrarFuncionariosUseCase,
            inativarFuncionarioUseCase,
            ativarFuncionarioUseCase,
            previous,
          ) =>
              EmployeesPageController(
            carregarDadosUseCase: carregarDadosUseCase,
            filtrarFuncionariosUseCase: filtrarFuncionariosUseCase,
            inativarFuncionarioUseCase: inativarFuncionarioUseCase,
            ativarFuncionarioUseCase: ativarFuncionarioUseCase,
          ),
        ),
        ProxyProvider3<
            SalvarFuncionarioUseCase,
            BuscarMapeamentoFuncionarioUseCase,
            SalvarMapeamentoFuncionarioUseCase,
            EmployeeCoreController>(
          update: (
            context,
            salvarFuncionarioUseCase,
            buscarMapeamentoUseCase,
            salvarMapeamentoUseCase,
            previous,
          ) =>
              EmployeeCoreController(
            salvarFuncionarioUseCase: salvarFuncionarioUseCase,
            buscarMapeamentoUseCase: buscarMapeamentoUseCase,
            salvarMapeamentoUseCase: salvarMapeamentoUseCase,
          ),
        ),
        Provider<EpiRepository>(create: (_) => EpiRepository(databases)),

        Provider<EntradasEpiRepository>(create: (_) => EntradasEpiRepository(databases)),
        ProxyProvider2<EpiRepository, EntradasEpiRepository, EntradasRepository>(
          update: (context, epiRepo, entradasEpiRepo, previous) => 
              EntradasRepository(
            databases,
            epiRepo,
            entradasEpiRepo,
          ),
        ),

        Provider<FichaEpiRepository>(create: (_) => FichaEpiRepository(databases)),
        ProxyProvider2<FichaEpiRepository, EpiRepository, FichaEntregaRepository>(
          update: (context, fichaEpiRepo, epiRepo, previous) => 
              FichaEntregaRepository(
            databases,
            fichaEpiRepo,
            epiRepo,
          ),
        ),

        // Repositórios da Estrutura Organizacional
        Provider<UnidadeRepository>(create: (_) => UnidadeRepository(databases)),
        Provider<SetorRepository>(create: (_) => SetorRepository(databases)),
        Provider<CargoRepository>(create: (_) => CargoRepository(databases)),
        Provider<RiscosRepository>(create: (_) => RiscosRepository(databases)),
        Provider<MapeamentoEpiRepository>(create: (_) => MapeamentoEpiRepository(databases)),
        Provider<CategoriaRepository>(create: (_) => CategoriaRepository(databases)),

        Provider<MarcasRepository>(create: (_) => MarcasRepository(databases)),
        Provider<MedidaRepository>(create: (_) => MedidaRepository(databases)),
        Provider<FornecedorRepository>(create: (_) => FornecedorRepository(databases)),
        Provider<ArmazemRepository>(create: (_) => ArmazemRepository(databases)),

        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          title: 'EPI Gest',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}
