import 'dart:convert';
import 'dart:io';

import '../../flutter/lib/common/buskit_update.dart';
import '../../flutter/lib/common/buskit_installer_windows.dart';

Future<void> main(List<String> args) async {
  if (Platform.environment['GITHUB_ACTIONS'] != 'true' || !Platform.isWindows) {
    throw StateError(
      'Esta prueba solo se ejecuta en el runner Windows desechable.',
    );
  }
  final file = File(args[0]);
  final brand = jsonDecode(await File('buskit/brand.json').readAsString());
  final release = BuskitRelease.parse(
    jsonEncode({
      'product': brand['name'],
      'architecture': 'windows-x64',
      'version': brand['edition'],
      'msi': {
        'url': buskitManifestUri
            .resolve('releases/${brand['edition']}/BUSKIT-Soporte-Remoto.msi')
            .toString(),
        'sha256': args[1],
        'bytes': int.parse(args[2]),
      },
    }),
  );
  await verifyBuskitMsi(file, release);
  final result = await installBuskitMsi(file);
  stdout.writeln('Instalación desde el cliente: código $result');
  exitCode = result == 3010 ? 0 : result;
}
