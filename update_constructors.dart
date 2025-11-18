import 'dart:io';

void main() {
  final directory = Directory('lib');
  final files = directory.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));
  
  for (final file in files) {
    final content = file.readAsStringSync();
    final updatedContent = content.replaceAllMapped(
      RegExp(r'\s*const\s+\w+\s*\(\s*\{Key\? key[^}]*\}\)\s*:\s*super\(key:\s*key\);'),
      (match) => match.group(0)!.replaceAllMapped(
        RegExp(r'\{Key\? key([^}]*)\}'),
        (innerMatch) => '{super.key${innerMatch.group(1)}}',
      ),
    );
    
    if (content != updatedContent) {
      file.writeAsStringSync(updatedContent);
      print('Updated: ${file.path}');
    }
  }
  
  print('Finished updating constructors.');
}
