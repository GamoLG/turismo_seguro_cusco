import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('Archivo coverage/lcov.info no encontrado. Ejecuta primero: flutter test --coverage');
    exit(1);
  }

  final lines = file.readAsLinesSync();
  String currentFile = '';
  int currentLF = 0;
  int currentLH = 0;
  int totalLF = 0;
  int totalLH = 0;

  print('\n=== REPORTE DE COBERTURA DE CÓDIGO (FLUTTER TEST --COVERAGE) ===');
  print('--------------------------------------------------------------------------------');
  print('${'Archivo'.padRight(50)} | ${'Líneas Cubiertas'.padRight(16)} | % Cobertura');
  print('--------------------------------------------------------------------------------');

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentFile = line.substring(3).replaceAll('\\', '/');
    } else if (line.startsWith('LF:')) {
      currentLF = int.parse(line.substring(3));
      totalLF += currentLF;
    } else if (line.startsWith('LH:')) {
      currentLH = int.parse(line.substring(3));
      totalLH += currentLH;
      final pct = currentLF > 0 ? (currentLH / currentLF) * 100 : 0.0;
      print('${currentFile.padRight(50)} | ${(currentLH.toString() + '/' + currentLF.toString()).padRight(16)} | ${pct.toStringAsFixed(1)}%');
    }
  }

  print('--------------------------------------------------------------------------------');
  final totalPct = totalLF > 0 ? (totalLH / totalLF) * 100 : 0.0;
  print('${'TOTAL GENERAL'.padRight(50)} | ${(totalLH.toString() + '/' + totalLF.toString()).padRight(16)} | ${totalPct.toStringAsFixed(2)}%');
  print('================================================================================\n');

  if (totalPct >= 90.0) {
    print('✅ Criterio superado: Cobertura superior al 90% requerido.\n');
  } else {
    print('❌ Alerta: Cobertura inferior al 90% requerido.\n');
  }
}
