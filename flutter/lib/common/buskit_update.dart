import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../buskit_brand.dart';

final buskitManifestUri = Uri.parse(buskitDownloadUrl).resolve('latest.json');

List<int> _versionParts(String version) {
  final match = RegExp(r'^(\d{1,5})\.(\d{1,5})\.(\d{1,5})-buskit\.(\d{1,5})$')
      .firstMatch(version);
  if (match == null) throw const FormatException('Versión BUSKIT no válida.');
  return List.generate(4, (index) => int.parse(match.group(index + 1)!));
}

bool isNewerBuskitVersion(String available, String installed) {
  final remote = _versionParts(available);
  final local = _versionParts(installed);
  for (var index = 0; index < remote.length; index++) {
    if (remote[index] != local[index]) return remote[index] > local[index];
  }
  return false;
}

class BuskitRelease {
  final String version;
  final Uri uri;
  final String sha256Hex;
  final int bytes;

  const BuskitRelease._(this.version, this.uri, this.sha256Hex, this.bytes);

  factory BuskitRelease.parse(String body) {
    final data = jsonDecode(body);
    if (data is! Map ||
        data['product'] != buskitName ||
        data['architecture'] != 'windows-x64' ||
        data['version'] is! String ||
        data['msi'] is! Map) {
      throw const FormatException('Manifiesto BUSKIT no válido.');
    }
    final version = data['version'] as String;
    _versionParts(version);
    final msi = data['msi'] as Map;
    final expected = buskitManifestUri
        .resolve('releases/$version/BUSKIT-Soporte-Remoto.msi');
    if (msi['url'] != expected.toString() ||
        msi['sha256'] is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(msi['sha256']) ||
        msi['bytes'] is! int ||
        msi['bytes'] < 1 ||
        msi['bytes'] > 512 * 1024 * 1024) {
      throw const FormatException('Datos del instalador no válidos.');
    }
    return BuskitRelease._(version, expected,
        (msi['sha256'] as String).toLowerCase(), msi['bytes'] as int);
  }
}

Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri).timeout(const Duration(seconds: 30));
  request.followRedirects = false;
  request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
  final response = await request.close().timeout(const Duration(seconds: 30));
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('El servidor respondió ${response.statusCode}.');
  }
  return response;
}

Future<BuskitRelease> checkBuskitRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  try {
    final response = await _get(
        client,
        buskitManifestUri.replace(queryParameters: {
          'check': '${DateTime.now().millisecondsSinceEpoch}'
        }));
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      bytes.addAll(chunk);
      if (bytes.length > 64 * 1024) {
        throw const FormatException('Manifiesto demasiado grande.');
      }
    }
    return BuskitRelease.parse(utf8.decode(bytes));
  } finally {
    client.close(force: true);
  }
}

Future<void> verifyBuskitMsi(File file, BuskitRelease release) async {
  if (await file.length() != release.bytes ||
      (await sha256.bind(file.openRead()).first).toString() !=
          release.sha256Hex) {
    throw const FormatException(
        'El instalador no coincide con la versión publicada. Vuelve a descargarlo.');
  }
}

Future<File> downloadBuskitMsi(
    BuskitRelease release, void Function(double) onProgress) async {
  final directory = await Directory.systemTemp.createTemp('buskit-update-');
  final file = File('${directory.path}/BUSKIT-Soporte-Remoto.msi');
  final client = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 30);
  try {
    final response = await _get(client, release.uri);
    if (response.contentLength != -1 &&
        response.contentLength != release.bytes) {
      throw const FormatException('Tamaño del instalador incorrecto.');
    }
    final output = await file.open(mode: FileMode.write);
    var received = 0;
    try {
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > release.bytes) {
          throw const FormatException('Tamaño del instalador incorrecto.');
        }
        await output.writeFrom(chunk);
        onProgress(received / release.bytes);
      }
    } finally {
      await output.close();
    }
    await verifyBuskitMsi(file, release);
    return file;
  } catch (_) {
    if (await file.exists()) await file.delete();
    await directory.delete();
    rethrow;
  } finally {
    client.close(force: true);
  }
}
