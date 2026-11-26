import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class AtualizadorWindowsHelper {
  AtualizadorWindowsHelper._();

  /// Descompacta o arquivo .zip da atualização usando ferramentas nativas do Windows (tar / PowerShell)
  /// sem necessidade de pacotes externos pesados no pubspec.yaml.
  static Future<bool> extrairPacoteZip({
    required String caminhoZip,
    required String pastaDestino,
  }) async {
    try {
      final dir = Directory(pastaDestino);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      dir.createSync(recursive: true);

      // 1. Tenta extrair com o utilitário nativo tar do Windows (ultrarrápido)
      final resultadoTar = await Process.run(
        'tar',
        ['-xf', caminhoZip, '-C', pastaDestino],
        runInShell: true,
      );

      if (resultadoTar.exitCode == 0) {
        debugPrint('[AtualizadorWindowsHelper] Pacote descompactado com sucesso via tar.');
        return true;
      }

      debugPrint(
        '[AtualizadorWindowsHelper] tar retornou código ${resultadoTar.exitCode}, tentando PowerShell...',
      );

      // 2. Fallback com PowerShell Expand-Archive caso o tar não esteja acessível
      final comandoPs =
          'Expand-Archive -LiteralPath "$caminhoZip" -DestinationPath "$pastaDestino" -Force';
      final resultadoPs = await Process.run(
        'powershell',
        ['-NoProfile', '-NonInteractive', '-Command', comandoPs],
        runInShell: true,
      );

      if (resultadoPs.exitCode == 0) {
        debugPrint('[AtualizadorWindowsHelper] Pacote descompactado com sucesso via PowerShell.');
        return true;
      }

      debugPrint(
        '[AtualizadorWindowsHelper] Falha ao extrair pacote: ${resultadoPs.stderr}',
      );
      return false;
    } catch (e) {
      debugPrint('[AtualizadorWindowsHelper] Erro ao extrair ZIP: $e');
      return false;
    }
  }

  /// Verifica se o diretório onde o executável reside possui permissão de escrita direta
  /// sem necessidade de elevação administrativa (UAC).
  static bool _diretorioEhGravavel(String caminho) {
    try {
      final arquivoTeste = File(
        p.join(caminho, '.nous_perm_test_${DateTime.now().millisecondsSinceEpoch}'),
      );
      arquivoTeste.writeAsStringSync('1');
      arquivoTeste.deleteSync();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Dispara o script de transição em segundo plano e encerra a instância atual do Nous.
  /// O script aguarda a liberação dos arquivos, substitui a pasta do app e reabre o executável.
  static Future<void> aplicarAtualizacaoEReiniciar({
    required String pastaStaging,
    required String caminhoZip,
  }) async {
    final exeAtual = Platform.resolvedExecutable;
    final dirApp = File(exeAtual).parent.path;
    final precisaElevacao = !_diretorioEhGravavel(dirApp);

    // Detecta se os arquivos foram extraídos dentro de uma subpasta intermediária (ex: "Release")
    String origemArquivos = pastaStaging;
    final dirStaging = Directory(pastaStaging);
    if (dirStaging.existsSync()) {
      final subitens = dirStaging.listSync();
      // Se houver apenas 1 diretório e ele contiver o nous.exe, usa a subpasta como raiz
      if (subitens.length == 1 && subitens.first is Directory) {
        final subDir = subitens.first as Directory;
        final temExeDentro = File(p.join(subDir.path, p.basename(exeAtual))).existsSync();
        if (temExeDentro) {
          origemArquivos = subDir.path;
        }
      }
    }

    // Cria a pasta para o script de atualização
    final dirScript = Directory(p.join(dirStaging.parent.path, 'scripts'));
    if (!dirScript.existsSync()) {
      dirScript.createSync(recursive: true);
    }

    final caminhoBat = p.join(dirScript.path, 'aplicar_update.bat');

    // Script batch robusto com robocopy, log de diagnóstico em %TEMP% e tolerância a locks
    final conteudoBat = '''
@echo off
setlocal
set "STAGING=$origemArquivos"
set "APPDIR=$dirApp"
set "APPEXE=$exeAtual"
set "ZIPPATH=$caminhoZip"
set "LOGFILE=%TEMP%\\nous_update.log"

echo [%date% %time%] Iniciando aplicacao de atualizacao... > "%LOGFILE%"
echo STAGING: "%STAGING%" >> "%LOGFILE%"
echo APPDIR: "%APPDIR%" >> "%LOGFILE%"

:: 1. Aguarda 2 segundos para o processo nous.exe liberar todos os locks de arquivos
timeout /t 2 /nobreak >nul

:: Se o executavel ainda estiver em execucao, garante o encerramento
taskkill /F /IM "${p.basename(exeAtual)}" >nul 2>&1
timeout /t 1 /nobreak >nul

:: 2. Copia todos os arquivos novos com robocopy (tentativas automaticas contra locks)
robocopy "%STAGING%" "%APPDIR%" /E /IS /IT /R:5 /W:1 /NP /NFL /NDL /NJH /NJS >> "%LOGFILE%" 2>&1

:: Fallback caso robocopy nao tenha copiado o executavel
if not exist "%APPDIR%\\${p.basename(exeAtual)}" (
    echo Usando fallback xcopy... >> "%LOGFILE%"
    xcopy /s /e /y /q "%STAGING%\\*" "%APPDIR%\\" >> "%LOGFILE%" 2>&1
)

:: 3. Limpa a pasta temporaria de staging e o arquivo compactado
rmdir /s /q "$pastaStaging" >nul 2>&1
if exist "%ZIPPATH%" del /f /q "%ZIPPATH%" >nul 2>&1

:: 4. Inicia o novo executavel atualizado
echo [%date% %time%] Iniciando novo executavel atualizado... >> "%LOGFILE%"
start "" "%APPEXE%"

:: 5. Auto-destroi este script
del /f /q "%~f0" >nul 2>&1
exit
''';

    await File(caminhoBat).writeAsString(conteudoBat, flush: true);

    debugPrint(
      '[AtualizadorWindowsHelper] Disparando script de transição (Elevação necessária: $precisaElevacao)...',
    );

    // Invocação desacoplada sem janela visível (WindowStyle Hidden)
    // Se a pasta do app for protegida (ex: C:\\Program Files), solicita elevação de Administrador (Verb RunAs)
    final comandoElevacao = precisaElevacao ? ' -Verb RunAs' : '';
    final comandoPs =
        'Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$caminhoBat`""$comandoElevacao -WindowStyle Hidden';

    await Process.start(
      'powershell.exe',
      ['-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden', '-Command', comandoPs],
      mode: ProcessStartMode.detached,
    );

    // Breve pausa para garantir despacho no kernel antes de sair
    await Future<void>.delayed(const Duration(milliseconds: 250));

    // Encerra imediatamente o processo atual liberando DLLs e o .exe para substituição
    exit(0);
  }
}
