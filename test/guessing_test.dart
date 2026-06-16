import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';

Future<String> _run(List<String> inputs) async {
  final process = await Process.start('dart', ['run', 'bin/guessing.dart']);
  for (final line in inputs) {
    process.stdin.writeln(line);
  }
  await process.stdin.flush();
  await process.stdin.close();
  final out = await process.stdout.transform(utf8.decoder).join();
  await process.exitCode;
  return out;
}

List<num> _numbers(String out) => RegExp(r'-?\d+(?:\.\d+)?')
    .allMatches(out)
    .map((m) => num.parse(m.group(0)!))
    .toList();

bool _has(String out, num value) =>
    _numbers(out).any((n) => (n - value).abs() < 1e-9);

/// The student stores the magic number in their program, so the grader has to
/// know it. The wrong guesses are generated (seeded) so the test isn't tied to
/// specific guesses, and the expected guess count is computed, not hardcoded.
const magic = 42;

void main() {
  test('student.json is filled in', () {
    final info = jsonDecode(File('student.json').readAsStringSync())
        as Map<String, dynamic>;
    for (final field in [
      'classCode',
      'fullName',
      'studentNumber',
      'studentEmail',
      'personalEmail',
      'githubAccount',
    ]) {
      expect(info[field], isNotEmpty, reason: 'Set "$field" in student.json');
    }
  });

  group('Guessing game', () {
    final rng = Random(2026);
    final higherGuess = magic + 1 + rng.nextInt(50); // above the magic number
    final lowerGuess = rng.nextInt(magic); // below the magic number

    test('a guess above the magic number hints to go lower', () async {
      final out = await _run(['$higherGuess', '$magic']);
      expect(out.toLowerCase(), contains('lower'),
          reason: '$higherGuess is above $magic, so the hint should say lower');
    });
    test('a guess below the magic number hints to go higher', () async {
      final out = await _run(['$lowerGuess', '$magic']);
      expect(out.toLowerCase(), contains('higher'),
          reason: '$lowerGuess is below $magic, so the hint should say higher');
    });
    test('reports the number of guesses', () async {
      final guesses = ['$higherGuess', '$lowerGuess', '$magic'];
      final out = await _run(guesses);
      expect(_has(out, guesses.length), isTrue,
          reason: 'it took ${guesses.length} guesses to reach the magic number');
    });
  }, timeout: const Timeout(Duration(seconds: 60)));
}
