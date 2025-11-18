import 'dart:io';

void main() {
  final directory = Directory('lib');
  final files = directory.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));
  
  for (final file in files) {
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    bool modified = false;
    
    // Buscar clases privadas que se usan como tipos de retorno o parámetros
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Si encuentra un método que devuelve un tipo privado
      if (line.contains(RegExp(r'\s*_\w+\s+\w+\s*\(')) ||
          line.contains(RegExp(r'\s*_\w+<[^>]+>\s+\w+\s*\(')) ||
          line.contains(RegExp(r'\s*\w+\s+\w+\s*<[^>]*_\w+[^>]*>\([^)]*\)'))) {
        
        print('Found private type in public API:');
        print('  File: ${file.path}');
        print('  Line ${i + 1}: $line');
        print('');
        
        // Aquí podríamos implementar la lógica para corregir automáticamente
        // modificando la línea para hacer el tipo público
      }
    }
  }
  
  print('Finished checking for private types in public APIs.');
  print('Please review the above output and make the necessary changes manually.');
}
