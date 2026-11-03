import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class Options {
  String res = 'best'; // best, 4320, 2160, 1440, 1080, 720, 480
  String codec = 'auto'; // auto, av01, vp9, h265, h264
  String container = 'mp4'; // mp4, mkv, webm
  bool audioOnly = false;
  String audioFmt = 'mp3'; // mp3, m4a, opus, flac, wav
  bool cookies = false; // Windows: Chrome çerezleri (Instagram girişi)
}

class VideoInfo {
  final String title, thumb, uploader;
  final int duration;
  VideoInfo(this.title, this.thumb, this.uploader, this.duration);
  factory VideoInfo.fromMap(Map m) => VideoInfo(
      '${m['title'] ?? 'Başlıksız'}', '${m['thumbnail'] ?? ''}',
      '${m['uploader'] ?? ''}', ((m['duration'] ?? 0) as num).toInt());
  String get time {
    final h = duration ~/ 3600, m = duration % 3600 ~/ 60, s = duration % 60;
    String t(int x) => x.toString().padLeft(2, '0');
    return h > 0 ? '$h:${t(m)}:${t(s)}' : '$m:${t(s)}';
  }
}

class Progress {
  final double percent;
  final String speed, eta;
  final bool done;
  Progress({this.percent = 0, this.speed = '', this.eta = '', this.done = false});
}

/// yt-dlp argümanları. -S = tercih sırası: önce en yüksek çözünürlük, sonra seçilen codec.
List<String> buildArgs(Options o, {required bool windows}) {
  final a = <String>['--no-playlist', '--newline', '--embed-metadata', '--windows-filenames',
    '-o', '%(title).150B [%(height)sp].%(ext)s'];
  if (windows) {
    a.addAll(['--progress-template', 'download:%(progress._percent_str)s|%(progress._speed_str)s|%(progress._eta_str)s']);
    if (o.cookies) a.addAll(['--cookies-from-browser', 'chrome']);
  }
  if (o.audioOnly) {
    a.addAll(['-f', 'ba/b', '-x', '--audio-format', o.audioFmt, '--audio-quality', '0']);
  } else {
    final cap = o.res == 'best' ? 'res' : 'res:${o.res}';
    final sort = o.codec == 'auto' ? cap : '$cap,vcodec:${o.codec}';
    a.addAll(['-f', 'bv*+ba/b', '-S', sort, '--merge-output-format', o.container]);
  }
  return a;
}

abstract class Engine {
  static Engine create() => Platform.isAndroid ? AndroidEngine() : WindowsEngine();
  String get outDir;
  Future<void> init();
  Future<VideoInfo> info(String url, Options o);
  Stream<Progress> download(String url, Options o);
  Future<void> cancel();
  Future<String> update();
}

class WindowsEngine extends Engine {
  Process? _p;
  String get _tools => '${File(Platform.resolvedExecutable).parent.path}\\tools';
  String get _yt => '$_tools\\yt-dlp.exe';
  @override String get outDir => '${Platform.environment['USERPROFILE']}\\Downloads\\TetraTurk';

  @override
  Future<void> init() async {
    if (!File(_yt).existsSync()) {
      throw Exception('tools\\yt-dlp.exe bulunamadı. setup_windows.ps1 dosyasını çalıştırın.');
    }
    Directory(outDir).createSync(recursive: true);
  }

  @override
  Future<VideoInfo> info(String url, Options o) async {
    final r = await Process.run(_yt, ['-J', '--no-playlist', if (o.cookies) ...['--cookies-from-browser', 'chrome'], url],
        stdoutEncoding: utf8, stderrEncoding: utf8);
    if (r.exitCode != 0) throw Exception('${r.stderr}'.trim().split('\n').last);
    return VideoInfo.fromMap(jsonDecode(r.stdout as String));
  }

  @override
  Stream<Progress> download(String url, Options o) async* {
    final p = _p = await Process.start(_yt,
        [...buildArgs(o, windows: true), '--ffmpeg-location', _tools, '-P', outDir, url]);
    final err = StringBuffer();
    p.stderr.transform(utf8.decoder).listen(err.write);
    await for (final l in p.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
      if (!l.startsWith('download:')) continue;
      final s = l.substring(9).split('|');
      yield Progress(percent: (double.tryParse(s[0].replaceAll('%', '').trim()) ?? 0) / 100,
          speed: s.length > 1 ? s[1].trim() : '', eta: s.length > 2 ? s[2].trim() : '');
    }
    if (await p.exitCode != 0) throw Exception(err.toString().trim().split('\n').last);
    yield Progress(percent: 1, done: true);
  }

  @override Future<void> cancel() async => _p?.kill();

  @override
  Future<String> update() async {
    final r = await Process.run(_yt, ['-U'], stdoutEncoding: utf8);
    return '${r.stdout}'.trim().split('\n').last;
  }
}

class AndroidEngine extends Engine {
  static const _ch = MethodChannel('tetraturk/engine');
  StreamController<Progress>? _sc;
  AndroidEngine() {
    _ch.setMethodCallHandler((c) async {
      if (c.method == 'progress') {
        final m = Map.from(c.arguments as Map);
        final p = (m['p'] as num).toDouble();
        if (p >= 0) _sc?.add(Progress(percent: p / 100, eta: '${m['eta']} sn'));
      }
    });
  }
  @override String get outDir => 'İndirilenler/TetraTurk';
  @override Future<void> init() => _ch.invokeMethod('init');
  @override
  Future<VideoInfo> info(String url, Options o) async =>
      VideoInfo.fromMap(Map.from(await _ch.invokeMethod('info', {'url': url})));

  @override
  Stream<Progress> download(String url, Options o) {
    final sc = _sc = StreamController<Progress>();
    _ch.invokeMethod('download', {'url': url, 'args': buildArgs(o, windows: false)}).then(
        (_) { sc.add(Progress(percent: 1, done: true)); sc.close(); },
        onError: (e) { sc.addError(e is PlatformException ? (e.message ?? 'Hata') : e); sc.close(); });
    return sc.stream;
  }
  @override Future<void> cancel() => _ch.invokeMethod('cancel');
  @override Future<String> update() async => '${await _ch.invokeMethod('update')}';
}
