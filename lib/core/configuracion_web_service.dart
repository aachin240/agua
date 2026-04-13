class ConfiguracionWebService {
  static const String host = '192.168.1.5:8093';
  static const String basePath = '/scriptcase/app/agua_potable';

  static Uri loginUri() {
    return Uri.http(host, '$basePath/ws_agua_login/');
  }

  static Uri lecturaUri() {
    return Uri.http(host, '$basePath/ws_agua_lectura/');
  }
}