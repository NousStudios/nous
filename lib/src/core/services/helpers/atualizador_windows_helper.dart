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

  /// Dispara o script de transição em segundo plano e encerra a instância atual do Nous.
  /// O script aguarda a liberação dos arquivos, substitui a pasta do app e reabre o executável.
  static Future<void> aplicarAtualizacaoEReiniciar({
    required String pastaStaging,
    required String caminhoZip,
  }) async {
    final exeAtual = Platform.resolvedExecutable;
    final dirApp = File(exeAtual).parent.path;

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

    // Script batch com tolerância a locks de arquivos e reinício garantido
    final conteudoBat = '''
@echo off
setlocal
set "STAGING=$origemArquivos"
set "APPDIR=$dirApp"
set "APPEXE=$exeAtual"
set "ZIPPATH=$caminhoZip"

:: Aguarda 2 segundos para o processo nous.exe liberar todos os locks de arquivos
timeout /t 2 /nobreak >nul

:: Se o nous.exe ainda estiver na memoria, aguarda mais um instante
taskkill /F /IM "${p.basename(exeAtual)}" >nul 2>&1
timeout /t 1 /nobreak >nul

:: Copia todos os arquivos novos por cima da pasta do aplicativo
xcopy /s /e /y /q "%STAGING%\\*" "%APPDIR%\\" >nul 2>&1

:: Limpa a pasta temporaria de staging e o arquivo compactado
rmdir /s /q "$pastaStaging" >nul 2>&1
if exist "%ZIPPATH%" del /f /q "%ZIPPATH%" >nul 2>&1

:: Inicia o novo executavel atualizado
start "" "%APPEXE%"

:: Auto-destroi este script
del /f /q "%~f0" >nul 2>&1
exit
''';

    await File(caminhoBat).writeAsString(conteudoBat, flush: true);

    debugPrint(
      '[AtualizadorWindowsHelper] Disparando script de transição em modo detached...',
    );

    // Executa em modo desacoplado para que continue rodando mesmo após a saída do Flutter
    await Process.start(
      'cmd.exe',
      ['/c', caminhoBat],
      mode: ProcessStartMode.detached,
    );

    // Encerra imediatamente o processo atual liberando DLLs e o .exe para substituição
    exit(0);
  }
}
