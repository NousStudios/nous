import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Definições Win32 para User32.dll
typedef _FindWindowWNative = IntPtr Function(
    Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);
typedef _FindWindowWDart = int Function(
    Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName);

typedef _GetForegroundWindowNative = IntPtr Function();
typedef _GetForegroundWindowDart = int Function();

typedef _GetSystemMetricsNative = Int32 Function(Int32 nIndex);
typedef _GetSystemMetricsDart = int Function(int nIndex);

typedef _GetWindowLongPtrWNative = IntPtr Function(IntPtr hWnd, Int32 nIndex);
typedef _GetWindowLongPtrWDart = int Function(int hWnd, int nIndex);

typedef _SetWindowLongPtrWNative = IntPtr Function(
    IntPtr hWnd, Int32 nIndex, IntPtr dwNewLong);
typedef _SetWindowLongPtrWDart = int Function(
    int hWnd, int nIndex, int dwNewLong);

typedef _SetWindowPosNative = Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter,
    Int32 X, Int32 Y, Int32 cx, Int32 cy, Uint32 uFlags);
typedef _SetWindowPosDart = int Function(
    int hWnd, int hWndInsertAfter, int X, int Y, int cx, int cy, int uFlags);

typedef _ShowWindowNative = Int32 Function(IntPtr hWnd, Int32 nCmdShow);
typedef _ShowWindowDart = int Function(int hWnd, int nCmdShow);

typedef _IsZoomedNative = Int32 Function(IntPtr hWnd);
typedef _IsZoomedDart = int Function(int hWnd);

final class RECT extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

typedef _GetWindowRectNative = Int32 Function(IntPtr hWnd, Pointer<RECT> lpRect);
typedef _GetWindowRectDart = int Function(int hWnd, Pointer<RECT> lpRect);

class JanelaWindowsService {
  static const int _gwlStyle = -16;
  static const int _wsOverlappedWindow = 0x00CF0000;
  static const int _wsPopup = 0x80000000;
  static const int _wsVisible = 0x10000000;
  static const int _wsMaximize = 0x01000000;

  static const int _smCxScreen = 0;
  static const int _smCyScreen = 1;

  static const int _swpNoMove = 0x0002;
  static const int _swpNoSize = 0x0001;
  static const int _swpFrameChanged = 0x0020;
  static const int _swpShowWindow = 0x0040;
  static const int _swMaximize = 3;
  static const int _swRestore = 9;

  static bool _emTelaCheia = false;
  static bool _estavaMaximizado = false;
  static int _estiloAnterior = 0;
  static int _prevLeft = 100;
  static int _prevTop = 100;
  static int _prevWidth = 1000;
  static int _prevHeight = 700;

  static DynamicLibrary? _user32;

  static DynamicLibrary? get _lib {
    if (!Platform.isWindows) return null;
    try {
      _user32 ??= DynamicLibrary.open('user32.dll');
      return _user32;
    } catch (_) {
      return null;
    }
  }

  static int _obterHwnd() {
    final lib = _lib;
    if (lib == null) return 0;

    try {
      final findWindow =
          lib.lookupFunction<_FindWindowWNative, _FindWindowWDart>('FindWindowW');
      final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
      final hwnd = findWindow(className, nullptr);
      calloc.free(className);
      if (hwnd != 0) return hwnd;

      final getForeground = lib.lookupFunction<_GetForegroundWindowNative,
          _GetForegroundWindowDart>('GetForegroundWindow');
      return getForeground();
    } catch (_) {
      return 0;
    }
  }

  static bool get emTelaCheia => _emTelaCheia;

  static void alternarTelaCheia([bool? forcarAtivo]) {
    if (!Platform.isWindows) return;

    final novoEstado = forcarAtivo ?? !_emTelaCheia;
    if (novoEstado == _emTelaCheia) return;

    if (novoEstado) {
      ativarTelaCheia();
    } else {
      desativarTelaCheia();
    }
  }

  static void ativarTelaCheia() {
    if (!Platform.isWindows) return;
    final lib = _lib;
    if (lib == null) return;

    final hwnd = _obterHwnd();
    if (hwnd == 0) return;

    try {
      final getWindowLong =
          lib.lookupFunction<_GetWindowLongPtrWNative, _GetWindowLongPtrWDart>(
              'GetWindowLongPtrW');
      final setWindowLong =
          lib.lookupFunction<_SetWindowLongPtrWNative, _SetWindowLongPtrWDart>(
              'SetWindowLongPtrW');
      final getSystemMetrics = lib.lookupFunction<_GetSystemMetricsNative,
          _GetSystemMetricsDart>('GetSystemMetrics');
      final setWindowPos =
          lib.lookupFunction<_SetWindowPosNative, _SetWindowPosDart>(
              'SetWindowPos');
      final getWindowRect = lib.lookupFunction<_GetWindowRectNative,
          _GetWindowRectDart>('GetWindowRect');
      final isZoomed =
          lib.lookupFunction<_IsZoomedNative, _IsZoomedDart>('IsZoomed');

      // Verifica se a janela já estava maximizada pelo Windows antes do F11
      _estavaMaximizado = isZoomed(hwnd) != 0;
      _estiloAnterior = getWindowLong(hwnd, _gwlStyle);

      // Se não estava maximizada, salva o retângulo de restauração
      if (!_estavaMaximizado) {
        final rectPtr = calloc<RECT>();
        if (getWindowRect(hwnd, rectPtr) != 0) {
          _prevLeft = rectPtr.ref.left;
          _prevTop = rectPtr.ref.top;
          _prevWidth = rectPtr.ref.right - rectPtr.ref.left;
          _prevHeight = rectPtr.ref.bottom - rectPtr.ref.top;
        }
        calloc.free(rectPtr);
      }

      // Obtém resolução total do monitor
      final screenWidth = getSystemMetrics(_smCxScreen);
      final screenHeight = getSystemMetrics(_smCyScreen);

      // Aplica estilo sem bordas (fullscreen total)
      final novoEstilo =
          (_estiloAnterior & ~_wsOverlappedWindow & ~_wsMaximize) |
              _wsPopup |
              _wsVisible;
      setWindowLong(hwnd, _gwlStyle, novoEstilo);

      // Posiciona cobrindo 100% da tela do Windows
      setWindowPos(
        hwnd,
        0, // HWND_TOP
        0,
        0,
        screenWidth,
        screenHeight,
        _swpFrameChanged | _swpShowWindow,
      );

      _emTelaCheia = true;
    } catch (_) {
      // Fallback seguro caso Win32 falhe
    }
  }

  static void desativarTelaCheia() {
    if (!Platform.isWindows) return;
    final lib = _lib;
    if (lib == null) return;

    final hwnd = _obterHwnd();
    if (hwnd == 0) return;

    try {
      final setWindowLong =
          lib.lookupFunction<_SetWindowLongPtrWNative, _SetWindowLongPtrWDart>(
              'SetWindowLongPtrW');
      final setWindowPos =
          lib.lookupFunction<_SetWindowPosNative, _SetWindowPosDart>(
              'SetWindowPos');
      final showWindow =
          lib.lookupFunction<_ShowWindowNative, _ShowWindowDart>('ShowWindow');

      // Restaura estilo original da janela do Windows
      final estiloRestaurar = _estiloAnterior != 0
          ? (_estiloAnterior & ~_wsPopup)
          : (_wsOverlappedWindow | _wsVisible);
      setWindowLong(hwnd, _gwlStyle, estiloRestaurar);

      if (_estavaMaximizado) {
        // Se a janela estava maximizada antes do F11, restaura como MAXIMIZADA
        showWindow(hwnd, _swMaximize);
        setWindowPos(
          hwnd,
          0,
          0,
          0,
          0,
          0,
          _swpFrameChanged | _swpNoMove | _swpNoSize | _swpShowWindow,
        );
      } else {
        // Restaura posição e tamanho anteriores da janela livre
        setWindowPos(
          hwnd,
          0, // HWND_TOP
          _prevLeft,
          _prevTop,
          _prevWidth > 200 ? _prevWidth : 1000,
          _prevHeight > 200 ? _prevHeight : 700,
          _swpFrameChanged | _swpShowWindow,
        );
        showWindow(hwnd, _swRestore);
      }

      _emTelaCheia = false;
    } catch (_) {
      // Fallback seguro
    }
  }
}
