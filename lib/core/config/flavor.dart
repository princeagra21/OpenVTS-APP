import 'package:open_vts/core/config/app_config.dart';

class AppFlavor {
  const AppFlavor._();

  static AppEnvironment currentEnvironment() => AppConfig.fromDartDefine().environment;
}
