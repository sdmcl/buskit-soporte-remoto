import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// Uses Windows Installer directly; no command shell or background service.
Future<int> installBuskitMsi(File file) async {
  if (!Platform.isWindows || !await file.exists()) {
    throw const FileSystemException('No se encontró el instalador de Windows.');
  }
  final process = using<int>((arena) {
    final systemDirectory = arena<Uint16>(32768).cast<Utf16>();
    final length = GetSystemDirectory(systemDirectory, 32768);
    if (length == 0 || length >= 32768) {
      throw const FileSystemException('No se encontró Windows Installer.');
    }
    final path = file.absolute.path;
    if (path.contains('"') || path.contains('\n') || path.contains('\r')) {
      throw const FormatException('Ruta del instalador no válida.');
    }
    final info = arena<SHELLEXECUTEINFO>();
    info.ref
      ..cbSize = sizeOf<SHELLEXECUTEINFO>()
      // SEE_MASK_NOCLOSEPROCESS | SEE_MASK_NOASYNC (shellapi.h).
      ..fMask = 0x00000040 | 0x00000100
      ..lpVerb = 'runas'.toNativeUtf16(allocator: arena)
      ..lpFile = '${systemDirectory.toDartString()}\\msiexec.exe'
          .toNativeUtf16(allocator: arena)
      ..lpParameters =
          '/i "$path" /passive /norestart REBOOT=ReallySuppress /L*v "$path.log"'
              .toNativeUtf16(allocator: arena)
      ..nShow = SHOW_WINDOW_CMD.SW_SHOWNORMAL;
    if (ShellExecuteEx(info) == 0) {
      final error = GetLastError();
      throw OSError(
          error == WIN32_ERROR.ERROR_CANCELLED
              ? 'Instalación cancelada. Puedes volver a pulsar Actualizar.'
              : 'No se pudo iniciar Windows Installer.',
          error);
    }
    if (info.ref.hProcess == 0) {
      throw const OSError('Windows no devolvió el proceso del instalador.');
    }
    return info.ref.hProcess;
  });
  try {
    while (true) {
      final wait = WaitForSingleObject(process, 0);
      if (wait == WAIT_EVENT.WAIT_OBJECT_0) break;
      if (wait != WAIT_EVENT.WAIT_TIMEOUT) {
        throw OSError('No se pudo consultar el instalador.', GetLastError());
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return using<int>((arena) {
      final code = arena<Uint32>();
      if (GetExitCodeProcess(process, code) == 0) {
        throw OSError('No se pudo comprobar la instalación.', GetLastError());
      }
      return code.value;
    });
  } finally {
    CloseHandle(process);
  }
}
