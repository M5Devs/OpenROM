// OpenROM CLI — Universal ROM Compression Suite
// M5 Dev | GPL v3

import 'dart:convert';
import 'dart:io';
import 'package:args/args.dart';
import 'package:openrom_core/openrom_core.dart';
import 'package:path/path.dart' as p;

final _progressStdout = stdout;

void _renderProgress(String label, double pct, {int width = 28}) {
  final filled = (width * pct / 100).toInt();
  final bar = '█' * filled + '░' * (width - filled);
  final line = '\r  \x1B[36m$bar\x1B[0m \x1B[33m${pct.toStringAsFixed(1).padLeft(5)}%\x1B[0m  \x1B[90m$label\x1B[0m';
  _progressStdout.write(line);
}

void _clearProgress() {
  _progressStdout.write('\r${' ' * 80}\r');
}

void _jsonPrint(Map<String, dynamic> obj) {
  print(jsonEncode(obj));
}

ArgParser buildParser() {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'single input ROM file')
    ..addOption('folder', abbr: 'f', help: 'convert all supported ROMs in a folder')
    ..addOption('detect', help: 'detect file format and info')
    ..addOption('convert', help: 'single file to convert (alias for --input)')
    ..addMultiOption('compress', help: 'file(s) to compress into ZIP/7Z')
    ..addMultiOption('extract', help: 'file(s) to extract from ZIP/7Z')
    ..addMultiOption('m3u', help: 'disc file(s) to generate an M3U playlist for')
    ..addOption('generate-cue', help: 'generate CUE file for a BIN file')
    ..addOption('merge-bins', help: 'merge multi-track BIN files referenced by CUE')
    ..addOption('detect-header', help: 'detect copier header on ROM file')
    ..addOption('tool-path', help: 'get resolved path for a tool')
    ..addOption('remove-header', help: 'remove copier header from ROM file')
    ..addOption('import-dat', help: 'import a No-Intro or Redump DAT file into OpenROM')
    ..addOption('scan-roms', help: 'scan a ROM folder against imported DATs and show matches')
    ..addOption('rename-roms', help: 'rename ROMs in a folder to canonical DAT names')

    // Dreamcast DCP patch
    ..addOption('dcp', help: 'apply a Dreamcast DCP patch (.dcp) to an extracted disc directory')
    ..addOption('disc-dir', help: 'extracted Dreamcast disc directory (used with --dcp)')

    // IP.BIN editor
    ..addOption('read-ipbin', help: 'read and display IP.BIN fields from a standalone IP.BIN or GDI')
    ..addOption('read-gdi', help: 'read and display GDI tracks')
    ..addOption('write-ipbin', help: 'IP.BIN file to modify')
    ..addOption('set-title', help: 'set game title in IP.BIN')
    ..addOption('set-region', help: 'set region code (e.g. JUE)')
    ..addFlag('set-vga', negatable: false, help: 'enable VGA in IP.BIN')
    ..addFlag('region-free', negatable: false, help: 'enable all regions in IP.BIN')

    // Options
    ..addOption('format', abbr: 'F', help: 'output format: CHD, CSO, ECM, ISO, BIN, BIN/CUE, XISO, ZIP, 7Z')
    ..addOption('force-platform', help: 'override automatic platform detection')
    ..addFlag('list-dats', negatable: false, help: 'list all imported DAT files')
    ..addFlag('dry-run', negatable: false, help: 'simulate rename without actually renaming files')
    ..addFlag('json', negatable: false, help: 'output results/progress in JSON format')
    ..addOption('output', abbr: 'o', help: 'output directory or file path')
    ..addOption('compression', abbr: 'c', defaultsTo: 'Normal', help: 'compression level: Normal | High | Max')
    ..addOption('level', defaultsTo: 'normal', help: 'compression level for ZIP tools: fast | normal | ultra')
    ..addFlag('delete-source', negatable: false, help: 'delete source file(s) after successful operation')
    ..addFlag('no-backup', negatable: false, help: 'do not keep a .bak backup file when removing header')
    ..addFlag('absolute', negatable: false, help: 'use absolute file paths in M3U playlist')
    ..addFlag('verify', negatable: false, help: 'verify CHD integrity after conversion')
    ..addFlag('verify-only', negatable: false, help: 'verify an existing CHD file without converting')
    ..addFlag('list-formats', negatable: false, help: 'print supported conversion formats and exit')
    ..addFlag('quiet', abbr: 'q', negatable: false, help: 'suppress per-job log output')
    ..addFlag('version', abbr: 'v', negatable: false, help: 'show version');

  return parser;
}

int main(List<String> args) {
  if (args.isEmpty) {
    print('OpenROM CLI — Universal ROM Toolkit\nUsage: openrom [options]');
    return 0;
  }

  final parser = buildParser();
  final ArgResults results;
  try {
    results = parser.parse(args);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    return 2;
  }

  if (results['version'] == true) {
    String ver = 'v3.0.0';
    try {
      final vf = File(p.join(Directory.current.path, 'VERSION'));
      if (vf.existsSync()) ver = 'v${vf.readAsStringSync().trim()}';
    } catch (_) {}
    print('OpenROM $ver');
    return 0;
  }

  final isJson = results['json'] == true;

  if (results['tool-path'] != null) {
    final pStr = getToolPath(results['tool-path'] as String);
    if (isJson) {
      _jsonPrint({'path': pStr});
    } else {
      print(pStr);
    }
    return 0;
  }

  if (results['detect'] != null) {
    final info = detectFile(results['detect'] as String);
    info['filepath'] = results['detect'];
    info['filename'] = p.basename(results['detect'] as String);
    if (isJson) {
      _jsonPrint(info);
    } else {
      print('File: ${info['filename']}');
      print('  Format: ${info['format']}');
      print('  Platform: ${info['platform']}');
      print('  Size: ${info['size_str']}');
      print('  Valid targets: ${(info['valid_targets'] as List).join(', ')}');
    }
    return info.containsKey('error') ? 2 : 0;
  }

  if (results['list-formats'] == true) {
    print('\nSupported conversions:\n');
    conversionMap.forEach((src, targets) {
      print('  ${src.padRight(8)}  →  ${targets.join(', ')}');
    });
    return 0;
  }

  if (results['verify-only'] == true) {
    final file = (results['input'] ?? results['convert']) as String?;
    if (file == null) {
      if (isJson) {
        _jsonPrint({'type': 'error', 'message': '--verify-only requires --input FILE'});
      } else {
        print('Error: --verify-only requires --input FILE');
      }
      return 2;
    }
    final ok = verifyChd(file, onLog: (msg) {
      if (isJson) {
        _jsonPrint({'type': 'log', 'message': msg});
      } else {
        print('  $msg');
      }
    });
    if (isJson) {
      _jsonPrint({'type': 'done', 'success': ok});
    } else {
      print(ok ? '✅ CHD is valid.' : '❌ CHD verification failed.');
    }
    return ok ? 0 : 1;
  }

  if ((results['compress'] as List<String>).isNotEmpty) {
    final files = results['compress'] as List<String>;
    final fmt = (results['format'] as String?) ?? 'zip';
    final level = results['level'] as String;
    final del = results['delete-source'] == true;
    final outDir = results['output'] as String?;

    int failed = 0;

    for (final file in files) {
      final job = CompressionJob(
        filepath: file,
        outputDir: outDir ?? p.dirname(p.canonicalize(file)),
        format: fmt,
        level: level,
        deleteSource: del,
      );
      final compressor = Compressor(
        onLog: (msg) {
          if (isJson) _jsonPrint({'type': 'log', 'message': msg});
        },
        onProgress: (j, pct) {
          if (isJson) {
            _jsonPrint({'type': 'progress', 'file': p.basename(j.filepath), 'percent': pct});
          } else {
            _renderProgress(p.basename(j.filepath), pct);
          }
        },
      );

      final ok = compressor.compress(job);
      if (!isJson) _clearProgress();
      if (ok) {
        if (isJson) _jsonPrint({'type': 'done', 'success': true});
      } else {
        failed++;
        if (isJson) _jsonPrint({'type': 'done', 'success': false, 'error': job.error});
      }
    }
    return failed == 0 ? 0 : 1;
  }

  if ((results['extract'] as List<String>).isNotEmpty) {
    final files = results['extract'] as List<String>;
    final del = results['delete-source'] == true;
    final outDir = results['output'] as String?;

    int failed = 0;

    for (final file in files) {
      final job = CompressionJob(
        filepath: file,
        outputDir: outDir ?? p.dirname(p.canonicalize(file)),
        format: 'extract',
        deleteSource: del,
      );
      final compressor = Compressor(
        onLog: (msg) {
          if (isJson) _jsonPrint({'type': 'log', 'message': msg});
        },
        onProgress: (j, pct) {
          if (isJson) {
            _jsonPrint({'type': 'progress', 'file': p.basename(j.filepath), 'percent': pct});
          } else {
            _renderProgress(p.basename(j.filepath), pct);
          }
        },
      );

      final ok = compressor.extract(job);
      if (!isJson) _clearProgress();
      if (ok) {
        if (isJson) _jsonPrint({'type': 'done', 'success': true});
      } else {
        failed++;
        if (isJson) _jsonPrint({'type': 'done', 'success': false, 'error': job.error});
      }
    }
    return failed == 0 ? 0 : 1;
  }

  if ((results['m3u'] as List<String>).isNotEmpty) {
    final discFiles = results['m3u'] as List<String>;
    final out = results['output'] as String? ?? p.dirname(p.canonicalize(discFiles.first));
    final rel = results['absolute'] != true;
    try {
      final m3uFile = generateM3u(discFiles: discFiles, outputPath: out, relative: rel);
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': true, 'output': m3uFile});
      } else {
        print('✅ Created M3U playlist: $m3uFile');
      }
      return 0;
    } catch (e) {
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': false, 'error': e.toString()});
      } else {
        print('❌ Failed to generate M3U — $e');
      }
      return 2;
    }
  }

  if (results['generate-cue'] != null) {
    final file = results['generate-cue'] as String;
    final out = results['output'] as String?;
    try {
      final mode = detectBinMode(file);
      final cueFile = generateCue(file, outputDir: out);
      if (isJson) {
        _jsonPrint({
          'type': 'done',
          'success': true,
          'output': cueFile,
          'detected_mode': mode,
        });
      } else {
        print('Detected mode: $mode');
        print('✅ Created CUE: $cueFile');
      }
      return 0;
    } catch (e) {
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': false, 'error': e.toString()});
      } else {
        print('❌ Failed to generate CUE — $e');
      }
      return 2;
    }
  }

  if (results['merge-bins'] != null) {
    final cue = results['merge-bins'] as String;
    final out = results['output'] as String?;
    try {
      final tracks = parseCue(cue);
      final res = mergeBins(
        cue,
        outputDir: out,
        onProgress: (pct) {
          if (isJson) {
            _jsonPrint({'type': 'progress', 'file': p.basename(cue), 'percent': pct});
          } else {
            _renderProgress(p.basename(cue), pct);
          }
        },
      );
      if (!isJson) _clearProgress();
      if (isJson) {
        _jsonPrint({
          'type': 'done',
          'success': true,
          'merged_bin': res.mergedBinPath,
          'merged_cue': res.mergedCuePath,
          'tracks_count': tracks.length,
        });
      } else {
        print('✅ Merged: ${res.mergedBinPath}');
      }
      return 0;
    } catch (e) {
      if (!isJson) _clearProgress();
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': false, 'error': e.toString()});
      } else {
        print('❌ Failed to merge BINs — $e');
      }
      return 2;
    }
  }

  if (results['detect-header'] != null) {
    final file = results['detect-header'] as String;
    final res = detectHeader(file);
    if (res == null) {
      if (isJson) {
        _jsonPrint({
          'type': 'done',
          'success': false,
          'error': 'No header detected or unsupported format',
        });
      } else {
        print('No copier header detected or file format unsupported.');
      }
      return 1;
    }
    if (isJson) {
      _jsonPrint({
        'type': 'done',
        'success': true,
        'system': res['system'],
        'header_size': res['header_size'],
        'has_header': res['has_header'],
        'confidence': res['confidence'],
      });
    } else {
      print('System: ${res['system']}');
      print('Header Found: ${res['has_header']} (${res['header_size']} bytes)');
      print('Confidence: ${res['confidence']}');
    }
    return 0;
  }

  if (results['remove-header'] != null) {
    final file = results['remove-header'] as String;
    final out = results['output'] as String?;
    final noBak = results['no-backup'] == true;
    try {
      final cleanRom = removeHeader(file, outputDir: out, backup: !noBak);
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': true, 'output': cleanRom});
      } else {
        print('✅ Clean ROM: $cleanRom');
      }
      return 0;
    } catch (e) {
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': false, 'error': e.toString()});
      } else {
        print('❌ Failed to remove header — $e');
      }
      return 2;
    }
  }

  if (results['import-dat'] != null) {
    final dat = results['import-dat'] as String;
    try {
      final info = importDat(dat);
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': true, ...info});
      } else {
        print('✅ Imported: ${info['name']}');
      }
      return 0;
    } catch (e) {
      if (isJson) {
        _jsonPrint({'type': 'done', 'success': false, 'error': e.toString()});
      } else {
        print('❌ $e');
      }
      return 2;
    }
  }

  if (results['list-dats'] == true) {
    final dats = listDats();
    if (isJson) {
      _jsonPrint({'type': 'done', 'success': true, 'dats': dats});
    } else {
      if (dats.isEmpty) {
        print('No DATs imported yet.');
      } else {
        print('Imported DATs:');
        for (final d in dats) {
          print('  ${d['name']} (Source: ${d['source']}, Games: ${d['game_count']})');
        }
      }
    }
    return 0;
  }

  if (results['scan-roms'] != null) {
    final folder = results['scan-roms'] as String;
    final dats = listDats();
    if (dats.isEmpty) {
      if (isJson) {
        _jsonPrint({'type': 'error', 'message': 'No DATs imported.'});
      } else {
        print('No DATs imported.');
      }
      return 2;
    }
    final datPaths = dats.map((d) => d['stored_path'] as String).toList();
    scanFolder(
      folder,
      datPaths,
      onProgress: (fname, pct) {
        if (isJson) {
          _jsonPrint({'type': 'progress', 'file': fname, 'percent': pct});
        } else {
          _renderProgress(fname, pct);
        }
      },
      onResult: (r) {
        if (!isJson) _clearProgress();
        if (r.error.isNotEmpty) {
          if (isJson) {
            _jsonPrint({'type': 'result', 'file': r.filename, 'matched': false, 'error': r.error});
          } else {
            print('  ✗ ${r.filename} (${r.error})');
          }
        } else if (r.matched) {
          if (isJson) {
            _jsonPrint({
              'type': 'result',
              'file': r.filename,
              'matched': true,
              'canonical_name': r.canonicalName,
              'crc32': r.crc32,
              'suggested_filename': r.suggestedFilename,
            });
          } else {
            print('  ✅ ${r.filename} -> ${r.suggestedFilename}');
          }
        } else {
          if (isJson) {
            _jsonPrint({'type': 'result', 'file': r.filename, 'matched': false, 'crc32': r.crc32});
          } else {
            print('  ? ${r.filename} [${r.crc32}]');
          }
        }
      },
    );
    return 0;
  }

  if (results['rename-roms'] != null) {
    final folder = results['rename-roms'] as String;
    final dry = results['dry-run'] == true;
    final dats = listDats();
    if (dats.isEmpty) {
      if (isJson) {
        _jsonPrint({'type': 'error', 'message': 'No DATs imported.'});
      } else {
        print('No DATs imported.');
      }
      return 2;
    }
    final datPaths = dats.map((d) => d['stored_path'] as String).toList();
    final scanResults = scanFolder(folder, datPaths);
    final renames = renameRoms(scanResults, dryRun: dry);
    for (final r in renames) {
      final oldF = p.basename(r.originalPath);
      final newF = p.basename(r.newPath);
      if (isJson) {
        _jsonPrint({
          'type': 'rename',
          'from': oldF,
          'to': newF,
          'success': r.success,
          'dry_run': dry,
          'error': r.error,
        });
      } else {
        print('  ${dry ? "[DRY] " : ""}$oldF -> $newF');
      }
    }
    return 0;
  }

  if (results['dcp'] != null) {
    final dcp = results['dcp'] as String;
    final discDir = results['disc-dir'] as String?;
    if (discDir == null) {
      if (isJson) {
        _jsonPrint({'type': 'error', 'message': '--disc-dir is required with --dcp'});
      } else {
        stderr.writeln('--disc-dir is required with --dcp');
      }
      return 1;
    }
    final patcher = DcpPatcher(
      onLog: (msg) {
        if (isJson) _jsonPrint({'type': 'log', 'message': msg});
      },
    );
    final res = patcher.apply(
      dcpPath: dcp,
      discDir: discDir,
      outputDir: (results['output'] as String?) ?? p.join(discDir, 'patched'),
    );
    if (isJson) {
      _jsonPrint({
        'type': 'done',
        'success': res['success'],
        'files_patched': res['files_patched'] ?? 0,
        'ipbin_replaced': res['ipbin_replaced'] ?? false,
        'error': res['error'],
      });
    } else {
      print(res['success'] == true ? '✅ DCP applied.' : '❌ DCP failed: ${res['error']}');
    }
    return res['success'] == true ? 0 : 1;
  }

  if (results['read-ipbin'] != null) {
    final file = results['read-ipbin'] as String;
    final fields = readIpbin(file);
    if (isJson) {
      final clean = Map<String, dynamic>.from(fields)..removeWhere((k, v) => k.startsWith('_'));
      _jsonPrint({'type': 'done', 'success': true, 'fields': clean});
    } else {
      fields.forEach((k, v) {
        if (!k.startsWith('_')) print('  $k: $v');
      });
    }
    return 0;
  }

  if (results['read-gdi'] != null) {
    final file = results['read-gdi'] as String;
    final tracks = parseGdi(file);
    print(jsonEncode(tracks.map((t) => t.toJson()).toList()));
    return 0;
  }

  if (results['write-ipbin'] != null) {
    final file = results['write-ipbin'] as String;
    var fields = readIpbin(file);
    if (results['set-title'] != null) {
      final title = results['set-title'] as String;
      fields['product_name'] = title.length > 16 ? title.substring(0, 16) : title;
      fields['product_name_2'] = title.length > 16 ? title.substring(16, title.length > 32 ? 32 : title.length) : '';
    }
    if (results['set-region'] != null) {
      final reg = (results['set-region'] as String).toUpperCase();
      final regList = <String>[];
      if (reg.contains('J')) regList.add('Japan');
      if (reg.contains('U')) regList.add('USA');
      if (reg.contains('E')) regList.add('Europe');
      fields['regions'] = regList;
    }
    if (results['region-free'] == true) {
      fields = setRegionFree(fields);
    }
    if (results['set-vga'] == true) {
      fields = setVgaEnabled(fields);
    }
    final out = (results['output'] as String?) ?? file;
    writeIpbin(fields, out);
    if (isJson) {
      _jsonPrint({'type': 'done', 'success': true, 'output': out});
    } else {
      print('✅ IP.BIN written to: $out');
    }
    return 0;
  }

  final inputFile = (results['input'] ?? results['convert']) as String?;
  final folder = results['folder'] as String?;

  if (inputFile == null && folder == null) {
    if (isJson) {
      _jsonPrint({'type': 'error', 'message': 'Provide --input FILE or --folder DIR'});
    } else {
      print('Error: Provide --input FILE or --folder DIR');
    }
    return 2;
  }

  final targetFmt = results['format'] as String?;
  final forcePlat = results['force-platform'] as String?;
  final compLevel = results['compression'] as String;
  final verifyVal = results['verify'] == true;
  final outputDir = results['output'] as String?;

  final jobs = <ConversionJob>[];

  if (inputFile != null) {
    final job = ConversionJob(
      filepath: inputFile,
      outputDir: outputDir ?? p.dirname(p.canonicalize(inputFile)),
      targetFormat: targetFmt ?? 'CHD',
      compression: compLevel,
      verify: verifyVal,
      forcePlatform: forcePlat,
    );
    jobs.add(job);
  } else if (folder != null) {
    final items = detectFolder(folder);
    for (final item in items) {
      final job = ConversionJob(
        filepath: item['filepath'] as String,
        outputDir: outputDir ?? folder,
        targetFormat: targetFmt ?? 'CHD',
        compression: compLevel,
        verify: verifyVal,
        forcePlatform: forcePlat,
      );
      jobs.add(job);
    }
  }

  if (jobs.isEmpty) {
    return 2;
  }

  final converter = Converter(
    onLogCb: (msg) {
      if (isJson) _jsonPrint({'type': 'log', 'message': msg});
    },
    onProgress: (job, pct) {
      if (isJson) {
        _jsonPrint({
          'type': 'progress',
          'file': p.basename(job.filepath),
          'percent': pct,
        });
      } else {
        _renderProgress(p.basename(job.filepath), pct);
      }
    },
  );

  int failed = 0;

  for (final job in jobs) {
    final ok = converter.convert(job);
    if (!isJson) _clearProgress();
    if (ok) {
      if (isJson) _jsonPrint({'type': 'done', 'success': true});
    } else {
      failed++;
      if (isJson) _jsonPrint({'type': 'done', 'success': false, 'error': job.error});
    }
  }

  return failed == 0 ? 0 : 1;
}
