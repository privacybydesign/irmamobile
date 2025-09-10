import 'package:vcmrtd/vcmrtd.dart';

class DataGroupConfig {
  final dynamic tag;
  final String name;
  final double progressIncrement;
  final Future<DataGroup> Function(Passport) readFunction;

  DataGroupConfig({
    required this.tag,
    required this.name,
    required this.progressIncrement,
    required this.readFunction,
  });
}
