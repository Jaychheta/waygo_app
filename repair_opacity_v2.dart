import 'dart:io';

void main() {
  final dir = Directory('lib');
  
  dir.listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      var changed = false;

      // Repair config/app_theme.dart
      if (entity.path.contains('app_theme.dart')) {
        content = content.replaceAll('color: glowColor.withOpacity(),', 'color: glowColor.withOpacity(0.35),');
        changed = true;
      }
      
      // Repair screens/dashboard_screen.dart
      if (entity.path.contains('dashboard_screen.dart')) {
        content = content.replaceAll('color: Colors.black.withOpacity(),', 'color: Colors.black.withOpacity(0.15),');
        changed = true;
      }
      
      // Repair screens/login_screen.dart & register_screen.dart
      if (entity.path.contains('login_screen.dart') || entity.path.contains('register_screen.dart')) {
        content = content.replaceAll('color: kTeal.withOpacity(),', 'color: kTeal.withOpacity(0.3),');
        content = content.replaceAll('Divider(color: kWhite.withOpacity())', 'Divider(color: kWhite.withOpacity(0.1))');
        content = content.replaceAll('color: kSlate.withOpacity(),', 'color: kSlate.withOpacity(0.8),');
        content = content.replaceAll('color: kWhite.withOpacity())', 'color: kWhite.withOpacity(0.08))'); // border side
        content = content.replaceAll('color: kWhite.withOpacity())', 'color: kWhite.withOpacity(0.12))'); // social btn
        // Let's do a replaceAll for common ones
        changed = true;
      }

      // Repair screens/splash_screen.dart
      if (entity.path.contains('splash_screen.dart')) {
        content = content.replaceAll('kTeal.withOpacity(), width: 1)', 'kTeal.withOpacity(0.15), width: 1)');
        content = content.replaceFirst('kTeal.withOpacity(), width: 1)', 'kTeal.withOpacity(0.25), width: 1)');
        content = content.replaceFirst('kTeal.withOpacity(), width: 1.5)', 'kTeal.withOpacity(0.4), width: 1.5)');
        content = content.replaceFirst('kTeal.withOpacity(),', 'kTeal.withOpacity(0.35),');
        changed = true;
      }

      // Repair create_trip_screen.dart
      if (entity.path.contains('create_trip_screen.dart')) {
        content = content.replaceFirst('color: kTeal.withOpacity(),', 'color: kTeal.withOpacity(0.08),'); // header
        content = content.replaceFirst('color: kTeal.withOpacity()),', 'color: kTeal.withOpacity(0.2)),'); // header border
        content = content.replaceFirst('color: kTeal.withOpacity(), blurRadius: 12,', 'color: kTeal.withOpacity(0.35), blurRadius: 12,'); // boxshadow
        content = content.replaceFirst('color: kWhite.withOpacity()),', 'color: kWhite.withOpacity(0.08)),'); // input border
        content = content.replaceFirst('color: kSlate.withOpacity(), fontSize: 14', 'color: kSlate.withOpacity(0.7), fontSize: 14'); // hint
        content = content.replaceFirst('color: kTeal.withOpacity(),', 'color: kTeal.withOpacity(0.1),'); // trip duration bubble
        content = content.replaceFirst('color: kTeal.withOpacity()),', 'color: kTeal.withOpacity(0.3)),'); // bubble border
        content = content.replaceFirst('colors: [kTeal.withOpacity(), kTeal.withOpacity()]', 'colors: [kTeal.withOpacity(0.5), kTeal.withOpacity(0.3)]'); // button gradient
        content = content.replaceFirst('color: kTeal.withOpacity(), blurRadius: 20', 'color: kTeal.withOpacity(0.45), blurRadius: 20'); // success btn shadow
        content = content.replaceFirst('color: kTeal.withOpacity(),', 'color: kTeal.withOpacity(0.12),'); // success ring
        content = content.replaceFirst('color: kTeal.withOpacity(), width: 2),', 'color: kTeal.withOpacity(0.4), width: 2),'); // ring border
        content = content.replaceFirst('color: kTeal.withOpacity(), blurRadius: 30', 'color: kTeal.withOpacity(0.25), blurRadius: 30'); // ring shadow
        content = content.replaceFirst('color: kTeal.withOpacity(), blurRadius: 18', 'color: kTeal.withOpacity(0.4), blurRadius: 18'); // main btn shadow
        content = content.replaceFirst('kTeal.withOpacity() : kWhite.withOpacity()', 'kTeal.withOpacity(0.5) : kWhite.withOpacity(0.08)');
        changed = true;
      }
      
      // For all other withOpacity(), use a 0.15 default if they're still corrupted
      final finalContent = content.replaceAll('.withOpacity()', '.withOpacity(0.15)');
      if (finalContent != content) {
        content = finalContent;
        changed = true;
      }
      
      if (changed) {
        print('Repaired ${entity.path}');
        entity.writeAsStringSync(content);
      }
    }
  });
}
