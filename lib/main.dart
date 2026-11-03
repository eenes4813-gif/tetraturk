import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'engine.dart';

void main() => runApp(const TetraTurkApp());

class TetraTurkApp extends StatelessWidget {
  const TetraTurkApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
        title: 'TetraTürk',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: const Color(0xFFD7263D), useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: const Color(0xFFD7263D), brightness: Brightness.dark, useMaterial3: true),
        home: const Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _url = TextEditingController();
  final _e = Engine.create();
  final o = Options();
  final history = <String>[];
  VideoInfo? info;
  Progress? pr;
  bool busy = false, ready = false;
  String status = '';

  @override
  void initState() {
    super.initState();
    _e.init().then((_) => setState(() => ready = true)).catchError((e) => setState(() => status = '$e'));
  }

  Future<void> _analyze() async {
    if (_url.text.trim().isEmpty) return;
    setState(() { busy = true; status = 'Çözümleniyor…'; info = null; });
    try {
      final i = await _e.info(_url.text.trim(), o);
      setState(() { info = i; status = ''; });
    } catch (x) {
      setState(() => status = 'Hata: $x');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> _download() async {
    setState(() { busy = true; status = 'İndiriliyor…'; pr = null; });
    try {
      await for (final p in _e.download(_url.text.trim(), o)) { setState(() => pr = p); }
      history.insert(0, '${info?.title ?? _url.text}\n${_e.outDir}');
      setState(() => status = 'Tamamlandı. Dosya: ${_e.outDir}');
    } catch (x) {
      setState(() => status = 'Hata: $x');
    } finally {
      setState(() => busy = false);
    }
  }

  Widget _dd(String label, String v, Map<String, String> items, ValueChanged<String> on) => SizedBox(
        width: 210,
        child: DropdownButtonFormField<String>(
          value: v,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: [for (final e in items.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
          onChanged: busy ? null : (x) => setState(() => on(x!)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('TetraTürk', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .5)),
        actions: [
          IconButton(
            tooltip: 'İndirme motorunu güncelle',
            icon: const Icon(Icons.system_update_alt),
            onPressed: busy ? null : () async {
              setState(() => status = 'Motor güncelleniyor…');
              try { final s = await _e.update(); setState(() => status = 'Motor: $s'); }
              catch (x) { setState(() => status = 'Hata: $x'); }
            },
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _url,
                  decoration: InputDecoration(
                    labelText: 'Video bağlantısı (YouTube, Instagram…)',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_paste),
                      tooltip: 'Yapıştır',
                      onPressed: () async {
                        final d = await Clipboard.getData('text/plain');
                        if (d?.text != null) setState(() => _url.text = d!.text!);
                      },
                    ),
                  ),
                  onSubmitted: (_) => _analyze(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: busy || !ready ? null : _analyze, child: const Text('Çözümle')),
            ]),
            if (info != null) ...[
              const SizedBox(height: 16),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Row(children: [
                  if (info!.thumb.isNotEmpty)
                    Image.network(info!.thumb, width: 160, height: 100, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 160, height: 100)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(info!.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${info!.uploader}  ${info!.time}', style: TextStyle(color: cs.onSurfaceVariant)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Video'), icon: Icon(Icons.movie)),
                ButtonSegment(value: true, label: Text('Yalnızca ses'), icon: Icon(Icons.music_note)),
              ],
              selected: {o.audioOnly},
              onSelectionChanged: busy ? null : (s) => setState(() => o.audioOnly = s.first),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: o.audioOnly
                ? [_dd('Ses biçimi', o.audioFmt,
                    {'mp3': 'MP3', 'm4a': 'M4A (AAC)', 'opus': 'Opus', 'flac': 'FLAC (kayıpsız)', 'wav': 'WAV'},
                    (v) => o.audioFmt = v)]
                : [
                    _dd('Çözünürlük', o.res,
                        {'best': 'En yüksek', '4320': '8K (4320p)', '2160': '4K (2160p)', '1440': '1440p',
                         '1080': '1080p', '720': '720p', '480': '480p'}, (v) => o.res = v),
                    _dd('Video kodeği', o.codec,
                        {'auto': 'Otomatik', 'av01': 'AV1', 'vp9': 'VP9', 'h265': 'H.265 (HEVC)', 'h264': 'H.264 (AVC)'},
                        (v) => o.codec = v),
                    _dd('Kapsayıcı', o.container, {'mp4': 'MP4', 'mkv': 'MKV', 'webm': 'WebM'}, (v) => o.container = v),
                  ]),
            if (!o.audioOnly)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Seçilen kodek videoda yoksa yt-dlp en yakın yüksek kaliteyi seçer.',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ),
            if (_e is WindowsEngine)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Instagram girişi için Chrome çerezlerini kullan'),
                value: o.cookies,
                onChanged: busy ? null : (v) => setState(() => o.cookies = v),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: busy || !ready || _url.text.trim().isEmpty ? null : _download,
                  icon: const Icon(Icons.download),
                  label: const Text('İndir'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              ),
              if (busy && pr != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _e.cancel, child: const Text('İptal')),
              ],
            ]),
            if (pr != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: pr!.percent, minHeight: 8),
              const SizedBox(height: 4),
              Text('%${(pr!.percent * 100).toStringAsFixed(1)}   ${pr!.speed}   ${pr!.eta}'),
            ],
            if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(status)),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('İndirme geçmişi', style: Theme.of(context).textTheme.titleMedium),
              for (final h in history) ListTile(dense: true, leading: const Icon(Icons.check_circle), title: Text(h)),
            ],
          ]),
        ),
      ),
    );
  }
}
