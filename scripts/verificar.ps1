$ErrorActionPreference = 'Stop'

Write-Host '=== 1/2 Executando flutter analyze ===' -ForegroundColor Cyan
flutter analyze --no-pub lib/ test/
if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

Write-Host '=== 2/2 Executando flutter test ===' -ForegroundColor Cyan
flutter test --no-pub
exit $LASTEXITCODE
