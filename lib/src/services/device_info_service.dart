import 'package:flutter/services.dart';

class DeviceInfoService {
  static const MethodChannel _channel = MethodChannel(
    'br.dev.yago.climapp/device',
  );

  Future<String> getDeviceCountry() async {
    try {
      final String? countryCode = await _channel.invokeMethod(
        'getDeviceCountry',
      );
      return countryCode ?? "Deu Ruim";
    } on PlatformException catch (_) {
      return "Deu Ruim";
    }
  }
}
