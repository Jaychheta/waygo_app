import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'\.withValues\(alpha:\s*([0-9.]+)\)');
  
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (regex.hasMatch(content)) {
        print('Fixing ${entity.path}');
        final newContent = content.replaceAllMapped(regex, (match) {
          return '.withOpacity(${match.group(1)})';
        });
        entity.writeAsStringSync(newContent);
      }
    }
  });
}
