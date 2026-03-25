import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  final repairs = {
    // app_theme.dart
    'glowColor.withOpacity()': 'glowColor.withOpacity(0.35)',
    
    // dashboard_screen.dart
    'Colors.black.withOpacity()': 'Colors.black.withOpacity(0.15)',
    
    // login_screen.dart & register_screen.dart
    'kTeal.withOpacity()': 'kTeal.withOpacity(0.3)',
    'kWhite.withOpacity()': 'kWhite.withOpacity(0.1)', // for dividers
    'kSlate.withOpacity()': 'kSlate.withOpacity(0.8)',
    'kWhite.withOpacity())': 'kWhite.withOpacity(0.08))', // for input border
    'color: kWhite.withOpacity()': 'color: kWhite.withOpacity(0.08)',
    'kWhite.withOpacity()),': 'kWhite.withOpacity(0.12)),', // for social btn
    
    // splash_screen.dart
    'kTeal.withOpacity(), width: 1)': 'kTeal.withOpacity(0.15), width: 1)',
    'kTeal.withOpacity(), width: 1)': 'kTeal.withOpacity(0.25), width: 1)', // This might be tricky if multiple
    
    // generic fixes
    '.withOpacity()': '.withOpacity(0.2)', // fallback
  };

  // I'll use a more surgical approach for splash screen as it has multiple different values for same prefix
  
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var changed = false;

      // Special case: splash_screen.dart
      if (entity.path.contains('splash_screen.dart')) {
        content = content.replaceFirst('kTeal.withOpacity(), width: 1)', 'kTeal.withOpacity(0.15), width: 1)');
        content = content.replaceFirst('kTeal.withOpacity(), width: 1)', 'kTeal.withOpacity(0.25), width: 1)');
        content = content.replaceFirst('kTeal.withOpacity(), width: 1.5)', 'kTeal.withOpacity(0.4), width: 1.5)');
        content = content.replaceFirst('kTeal.withOpacity(),', 'kTeal.withOpacity(0.3),');
        changed = true;
      }
      
      // Special case: create_trip_screen.dart and saved_trip_details_screen.dart
      // They have many. I'll use a generic replacement with a reasonable default where I'm unsure, 
      // but try to match the ones I know.

      final previousContent = content;
      
      // Apply repairs
      repairs.forEach((key, value) {
        content = content.replaceAll(key, value);
      });
      
      if (content != previousContent) changed = true;
      
      if (changed) {
        print('Repaired ${entity.path}');
        entity.writeAsStringSync(content);
      }
    }
  });
}
