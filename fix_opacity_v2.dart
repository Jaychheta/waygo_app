import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  // Pattern 1: Correct replacement for withValues(alpha: x.x)
  final withValuesRegex = RegExp(r'\.withValues\(alpha:\s*([0-9.]+)\)');
  
  // Pattern 2: Fix for the already corrupted withOpacity() which was withValues(...)
  // Wait, if it's already withOpacity(), I need to know what value it had.
  // Actually, did I lose the value?
  // PowerShell replacement -replace '\.withValues\(alpha: ([0-9.]+)\)', '.withOpacity($1)' 
  // If `($1)` was empty, it means the group was empty or something.
  
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      var newContent = content.replaceAllMapped(withValuesRegex, (match) {
        return '.withOpacity(${match.group(1)})';
      });
      if (newContent != content) {
        print('Fixed withValues in ${entity.path}');
        entity.writeAsStringSync(newContent);
      }
    }
  });
}
