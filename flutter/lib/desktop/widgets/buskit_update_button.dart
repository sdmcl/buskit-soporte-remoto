import 'package:flutter/material.dart';

import '../../buskit_brand.dart';
import '../../common/buskit_update.dart';
import '../../common/buskit_installer_windows.dart';

final _updates = _BuskitUpdates();

class _BuskitUpdates extends ChangeNotifier {
  BuskitRelease? release;
  bool busy = false;
  String status = '';
  DateTime? checkedAt;

  Future<void> check({bool force = false}) async {
    if (busy ||
        (!force &&
            checkedAt != null &&
            DateTime.now().difference(checkedAt!) <
                const Duration(minutes: 10))) {
      return;
    }
    busy = true;
    status = 'Buscando actualizaciones…';
    notifyListeners();
    try {
      final latest = await checkBuskitRelease();
      release =
          isNewerBuskitVersion(latest.version, buskitEdition) ? latest : null;
      status = release == null ? 'Tienes la última versión.' : '';
      checkedAt = DateTime.now();
    } catch (_) {
      release = null;
      status =
          'No se pudo comprobar la versión. Revisa la conexión e inténtalo de nuevo.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> install() async {
    final selected = release;
    if (busy || selected == null) return;
    busy = true;
    status = 'Descargando…';
    notifyListeners();
    try {
      final file = await downloadBuskitMsi(selected, (progress) {
        status = 'Descargando ${(progress * 100).floor()} %';
        notifyListeners();
      });
      status = 'Instalando… Acepta el permiso de Windows si se solicita.';
      notifyListeners();
      final result = await installBuskitMsi(file);
      if (result != 0 && result != 3010) {
        throw Exception('Windows Installer terminó con el código $result.');
      }
      release = null;
      status = result == 3010
          ? 'Instalación terminada. Reinicia Windows cuando puedas.'
          : 'Instalación terminada. Vuelve a abrir BUSKIT Soporte Remoto.';
    } catch (error) {
      status = 'No se completó la actualización: $error';
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

class BuskitUpdateButton extends StatefulWidget {
  final bool showStatus;
  const BuskitUpdateButton({Key? key, this.showStatus = false})
      : super(key: key);

  @override
  State<BuskitUpdateButton> createState() => _BuskitUpdateButtonState();
}

class _BuskitUpdateButtonState extends State<BuskitUpdateButton>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Home and Settings share one download and one version check.
    Future.microtask(_updates.check);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _updates.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _confirmInstall() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actualizar a ${_updates.release!.version}'),
        content: const Text('Se descargará y verificará el instalador. '
            'Durante la instalación se cerrarán BUSKIT y sus conexiones abiertas. '
            'Windows puede pedir permiso de administrador. No se reiniciará el PC automáticamente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Actualizar')),
        ],
      ),
    );
    if (confirmed == true) await _updates.install();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _updates,
        builder: (context, _) {
          final available = _updates.release != null;
          if (!widget.showStatus && !available) return const SizedBox.shrink();
          return Column(mainAxisSize: MainAxisSize.min, children: [
            TextButton.icon(
              icon: Icon(available ? Icons.system_update_alt : Icons.refresh,
                  size: 18),
              label: Text(
                  available
                      ? 'Actualizar a ${_updates.release!.version}'
                      : 'Buscar actualizaciones',
                  textAlign: TextAlign.center),
              onPressed: _updates.busy
                  ? null
                  : available
                      ? _confirmInstall
                      : () => _updates.check(force: true),
            ),
            if (_updates.status.isNotEmpty)
              Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_updates.status, textAlign: TextAlign.center)),
          ]);
        },
      );
}
