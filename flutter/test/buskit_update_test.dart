import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/common/buskit_update.dart';

Map<String, Object> manifest() => {
      'product': 'BUSKIT Soporte Remoto',
      'architecture': 'windows-x64',
      'version': '1.5.0-buskit.4',
      'msi': {
        'url':
            'https://sdm.cl/empresas/BUSKIT/soporte-remoto/releases/1.5.0-buskit.4/BUSKIT-Soporte-Remoto.msi',
        'sha256': sha256.convert([1, 2, 3]).toString(),
        'bytes': 3,
      },
    };

void main() {
  test('Solo ofrece una edición BUSKIT posterior, comparando números', () {
    expect(isNewerBuskitVersion('1.5.0-buskit.4', '1.5.0-buskit.4'), isFalse);
    expect(isNewerBuskitVersion('1.5.0-buskit.3', '1.5.0-buskit.4'), isFalse);
    expect(isNewerBuskitVersion('1.5.0-buskit.4', '1.5.0-buskit.3'), isTrue);
    expect(isNewerBuskitVersion('1.5.0-buskit.10', '1.5.0-buskit.9'), isTrue);
    expect(isNewerBuskitVersion('1.6.0-buskit.1', '1.5.0-buskit.10'), isTrue);
  });

  test('Solo acepta el MSI HTTPS de esa edición en el hosting BUSKIT', () {
    expect(
        BuskitRelease.parse(jsonEncode(manifest())).version, '1.5.0-buskit.4');
    for (final url in [
      'http://sdm.cl/empresas/BUSKIT/soporte-remoto/releases/1.5.0-buskit.4/BUSKIT-Soporte-Remoto.msi',
      'https://otro.example/instalador.msi',
      'https://sdm.cl/empresas/BUSKIT/soporte-remoto/BUSKIT-Soporte-Remoto.msi',
      'https://sdm.cl/empresas/BUSKIT/soporte-remoto/releases/1.5.0-buskit.3/BUSKIT-Soporte-Remoto.msi',
    ]) {
      final data = manifest();
      (data['msi'] as Map)['url'] = url;
      expect(
          () => BuskitRelease.parse(jsonEncode(data)), throwsFormatException);
    }
    for (final invalid in ['1.5.0', '../buskit.4', '1.5.0-buskit.4/extra']) {
      final data = manifest()..['version'] = invalid;
      expect(
          () => BuskitRelease.parse(jsonEncode(data)), throwsFormatException);
    }
    for (final invalid in [0, -1, 536870913, '3']) {
      final data = manifest();
      (data['msi'] as Map)['bytes'] = invalid;
      expect(
          () => BuskitRelease.parse(jsonEncode(data)), throwsFormatException);
    }
  });

  test('Rechaza un MSI truncado o alterado antes de instalar', () async {
    final directory =
        await Directory.systemTemp.createTemp('buskit-hash-test-');
    final file = File('${directory.path}/installer.msi');
    final release = BuskitRelease.parse(jsonEncode(manifest()));
    try {
      await file.writeAsBytes([1, 2, 3]);
      await verifyBuskitMsi(file, release);
      await file.writeAsBytes([1, 2]);
      await expectLater(verifyBuskitMsi(file, release), throwsFormatException);
      await file.writeAsBytes([1, 2, 4]);
      await expectLater(verifyBuskitMsi(file, release), throwsFormatException);
    } finally {
      if (await file.exists()) await file.delete();
      await directory.delete();
    }
  });
}
