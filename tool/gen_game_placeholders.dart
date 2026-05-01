// Generates 1×1 transparent PNG placeholders for game carousel assets.
// Run from repo root: dart run tool/gen_game_placeholders.dart
import 'dart:convert';
import 'dart:io';

void main() {
  const minimalPngBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
  final bytes = base64Decode(minimalPngBase64);

  final dir = Directory('assets/images/games');
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  const names = <String>[
    'lol_bg.png',
    'valorant_bg.png',
    'cs2_bg.png',
    'dota2_bg.png',
    'lol_logo.png',
    'valorant_logo.png',
    'cs2_logo.png',
    'dota2_logo.png',
  ];

  for (final name in names) {
    File('${dir.path}/$name').writeAsBytesSync(bytes);
  }

  stdout.writeln('Wrote ${names.length} placeholder PNGs to ${dir.path}/');
}
