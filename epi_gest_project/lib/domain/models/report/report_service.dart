import 'dart:io';
import 'package:epi_gest_project/domain/models/report/report_type.dart';

abstract class ReportService {
  Future<File> generateReport(ReportRequest request);
  Future<void> shareReport(File file);
  Future<void> printReport(File file);
}
