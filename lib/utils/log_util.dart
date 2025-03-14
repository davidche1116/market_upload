import 'package:logger/logger.dart';

class LogUtil {
  static StreamOutput streamOutput = StreamOutput();

  static MemoryOutput memoryOutput = MemoryOutput();

  static Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: MultiOutput([ConsoleOutput(), streamOutput, memoryOutput]),
  );
}
