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

  /// Verifica se o diretório onde o executável reside possui restrição de escrita ou é protegido pelo sistema (ex: Program Files)
  static bool estaEmPastaProtegida(String caminho) {
    final lower = caminho.toLowerCase();
    if (lower.contains('program files') || lower.contains('archivos de programa')) {
      return true;
    }
    return !_diretorioEhGravavel(caminho);
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

  /// Executa o instalador executável oficial do Nous (Inno Setup) e encerra a aplicação
  /// atual para permitir que o instalador substitua os binários sem travas de DLLs.
  static Future<void> executarInstaladorExe(String caminhoExe) async {
    try {
      // Dispara o instalador de forma totalmente desanexada
      await Process.start(
        caminhoExe,
        [],
        mode: ProcessStartMode.detached,
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
    } catch (e) {
      debugPrint('[AtualizadorWindowsHelper] Erro ao iniciar instalador: $e');
      // Fallback via shell
      Process.run('cmd.exe', ['/c', 'start', '', caminhoExe]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      exit(0);
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

    final caminhoPs1 = p.join(dirScript.path, 'aplicar_update.ps1');

    // Script PowerShell nativo robusto:
    // - Usa Start-Sleep (sem erro de redirecionamento de entrada do timeout do cmd)
    // - Aguarda liberação do nous.exe com retry de até 15 segundos
    // - Copia com Robocopy e faz fallback seguro
    // - Inicia o novo nous.exe desanexado
    // - Grava log completo em %TEMP%\nous_update.log
    final nomeExe = p.basename(exeAtual);
    final conteudoPs1 = '''
\$logFile = "\$env:TEMP\\nous_update.log"
"[" + (Get-Date).ToString() + "] Iniciando aplicacao de atualizacao do Nous..." | Out-File -FilePath \$logFile -Encoding utf8

\$staging = "$origemArquivos".Replace('/', '\\')
\$appDir = "$dirApp".Replace('/', '\\')
\$appExe = "$exeAtual".Replace('/', '\\')
\$zipPath = "$caminhoZip".Replace('/', '\\')

"STAGING: \$staging" | Out-File -FilePath \$logFile -Append -Encoding utf8
"APPDIR: \$appDir" | Out-File -FilePath \$logFile -Append -Encoding utf8
"APPEXE: \$appExe" | Out-File -FilePath \$logFile -Append -Encoding utf8

# 1. Aguarda e garante o encerramento do processo anterior
Start-Sleep -Seconds 2
Stop-Process -Name "$nomeExe".Replace(".exe", "") -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. Copia os arquivos novos da pasta de staging para a pasta do app
"[" + (Get-Date).ToString() + "] Copiando arquivos com Robocopy..." | Out-File -FilePath \$logFile -Append -Encoding utf8
& robocopy "\$staging" "\$appDir" /E /IS /IT /R:5 /W:1 /NP /NFL /NDL /NJH /NJS *>> \$logFile

# Fallback com Copy-Item caso algum arquivo principal tenha ficado
if (-not (Test-Path "\$appExe")) {
    "[" + (Get-Date).ToString() + "] Fallback com Copy-Item..." | Out-File -FilePath \$logFile -Append -Encoding utf8
    Copy-Item -Path "\$staging\\*" -Destination "\$appDir" -Recurse -Force -ErrorAction SilentlyContinue
}

# 3. Limpa arquivos temporarios
Remove-Item -Path "$pastaStaging" -Recurse -Force -ErrorAction SilentlyContinue
if (Test-Path "\$zipPath") {
    Remove-Item -Path "\$zipPath" -Force -ErrorAction SilentlyContinue
}

# 4. Inicia o novo aplicativo atualizado
"[" + (Get-Date).ToString() + "] Iniciando novo executavel: \$appExe" | Out-File -FilePath \$logFile -Append -Encoding utf8
Start-Process -FilePath "\$appExe"

# 5. Remove este script
Remove-Item -Path \$MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
''';

    await File(caminhoPs1).writeAsString(conteudoPs1, flush: true);

    debugPrint(
      '[AtualizadorWindowsHelper] Disparando script de transição PowerShell (Elevação necessária: $precisaElevacao)...',
    );

    // Invocação desacoplada sem janela (WindowStyle Hidden)
    // Se a pasta do app for protegida (ex: C:\Program Files), executa como Administrador (RunAs)
    final argsProcess = <String>[
      '-NoProfile',
      '-ExecutionPolicy',
      'Bypass',
      if (precisaElevacao) ...['-Command', 'Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList \'-NoProfile -ExecutionPolicy Bypass -File "$caminhoPs1"\'']
      else ...['-WindowStyle', 'Hidden', '-File', caminhoPs1],
    ];

    await Process.start(
      'powershell.exe',
      argsProcess,
      mode: ProcessStartMode.detached,
    );

    // Breve pausa para garantir despacho no kernel antes de sair
    await Future<void>.delayed(const Duration(milliseconds: 300));

    // Encerra imediatamente o processo atual liberando DLLs e o .exe para substituição
    exit(0);
  }
}
