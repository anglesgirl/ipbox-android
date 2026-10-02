import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const kBg = Color(0xFF0F1626);
const kCard = Color(0xFF151F35);
const kAccent = Color(0xFF22D3EE);
const kGood = Color(0xFF34D399);
const kBad = Color(0xFFF87171);
const kText = Color(0xFFE2E8F0);
const kDim = Color(0xFF64748B);

void main() => runApp(const NetBoxApp());

class NetBoxApp extends StatelessWidget {
  const NetBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '网络工具箱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: ColorScheme.dark(
          primary: kAccent,
          surface: kCard,
          onSurface: kText,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: kBg, elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B1220),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: kDim),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccent,
            foregroundColor: const Color(0xFF0B1220),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: kAccent,
          unselectedLabelColor: kDim,
          indicatorColor: kAccent,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('网络工具箱'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: Text('ipip.net 免费替代',
                    style: TextStyle(fontSize: 12, color: kDim)),
              ),
            )
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '我的IP'),
              Tab(text: 'IP查询'),
              Tab(text: 'Ping'),
              Tab(text: '路由追踪'),
              Tab(text: '端口扫描'),
              Tab(text: 'DoH解析'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MyIpPage(),
            IpLookupPage(),
            PingPage(),
            TracePage(),
            PortScanPage(),
            DohPage(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 通用：网络请求 + 卡片 UI
// ============================================================
Future<Map<String, dynamic>> httpJson(String url,
    {String method = 'GET', Map<String, String>? body, Duration timeout = const Duration(seconds: 8)}) async {
  final uri = Uri.parse(url);
  http.Response resp;
  if (method == 'POST' && body != null) {
    resp = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(timeout);
  } else {
    resp = await http
        .get(uri, headers: const {'User-Agent': 'NetBox/1.0'})
        .timeout(timeout);
  }
  return jsonDecode(resp.body) as Map<String, dynamic>;
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: padding,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class ResultTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<Color>? rowColors;
  const ResultTable({super.key, required this.headers, required this.rows, this.rowColors});

  @override
  Widget build(BuildContext context) {
    return CardBox(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(const Color(0xFF1E293B)),
          columnSpacing: 22,
          columns: [for (final h in headers) DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))],
          rows: [
            for (var i = 0; i < rows.length; i++)
              DataRow(
                color: rowColors != null ? WidgetStatePropertyAll(rowColors![i % rowColors!.length]) : null,
                cells: [for (final c in rows[i]) DataCell(Text(c, style: const TextStyle(fontSize: 13)))],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 页1：我的 IP
// ============================================================
class MyIpPage extends StatefulWidget {
  const MyIpPage({super.key});
  @override
  State<MyIpPage> createState() => _MyIpPageState();
}

class _MyIpPageState extends State<MyIpPage> {
  Future<List<Map<String, String>>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, String>>> _load() async {
    final out = <Map<String, String>>[];
    Future<void> add(String name, Future<Map<String, String>> Function() f) async {
      try {
        out.add(await f());
      } catch (e) {
        out.add({'源': name, 'IP': '失败', '归属': e.toString().substring(0, 60)});
      }
    }

    await Future.wait([
      add('ip-api.com', () async {
        final d = await httpJson('http://ip-api.com/json/?lang=zh-CN&fields=status,query,country,regionName,city,isp,as,lat,lon');
        return {
          '源': 'ip-api.com',
          'IP': (d['query'] ?? '?').toString(),
          '归属': '${d['country']} ${d['regionName']} ${d['city']}',
          'ISP': '${d['isp']} ${d['as']} ${d['lat']},${d['lon']}',
        };
      }),
      add('ipwho.is', () async {
        final d = await httpJson('https://ipwho.is/');
        return {
          '源': 'ipwho.is',
          'IP': (d['ip'] ?? '?').toString(),
          '归属': '${d['country']} ${d['region']} ${d['city']}',
          'ISP': '${d['connection']['isp']} AS${d['connection']['asn']}',
        };
      }),
      add('ip.sb', () async {
        final d = await httpJson('https://api.ip.sb/geoip');
        return {
          '源': 'ip.sb',
          'IP': (d['ip'] ?? '?').toString(),
          '归属': '${d['country']} ${d['region']} ${d['city']}',
          'ISP': '${d['isp']} AS${d['asn']}',
        };
      }),
      add('Cloudflare', () async {
        final resp = await http
            .get(Uri.parse('https://cloudflare.com/cdn-cgi/trace'), headers: const {'User-Agent': 'NetBox/1.0'})
            .timeout(const Duration(seconds: 8));
        final kv = <String, String>{};
        for (final line in resp.body.split('\n')) {
          final i = line.indexOf('=');
          if (i > 0) kv[line.substring(0, i)] = line.substring(i + 1);
        }
        return {
          '源': 'Cloudflare',
          'IP': kv['ip'] ?? '?',
          '归属': '${kv['loc']} (Cloudflare 边缘 ${kv['colo']})',
          'ISP': kv['warp'] == 'on' ? 'WARP' : '直连',
        };
      }),
    ]);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        final rows = snap.data ?? [];
        return ListView(
          children: [
            CardBox(
              child: Row(
                children: [
                  const Icon(Icons.refresh, color: kAccent, size: 20),
                  const SizedBox(width: 8),
                  const Text('刷新出口 IP', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text('多源交叉验证', style: TextStyle(fontSize: 12, color: kDim)),
                  TextButton(onPressed: () => setState(() => _future = _load()), child: const Text('刷新')),
                ],
              ),
            ),
            ResultTable(
              headers: ['源', 'IP', '归属地', 'ISP/ASN'],
              rows: [for (final r in rows) [r['源']!, r['IP']!, r['归属']!, r['ISP']!]],
              rowColors: [for (final r in rows) r['IP'] == '失败' ? kBad : kText],
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// 页2：IP 查询
// ============================================================
class IpLookupPage extends StatefulWidget {
  const IpLookupPage({super.key});
  @override
  State<IpLookupPage> createState() => _IpLookupPageState();
}

class _IpLookupPageState extends State<IpLookupPage> {
  final _ctrl = TextEditingController(text: '8.8.8.8\n1.1.1.1\n223.5.5.5');
  List<List<String>>? _rows;
  bool _busy = false;
  final Map<String, List<String>> _cache = {};

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _rows = null;
    });
    final ips = _ctrl.text
        .split(RegExp(r'[\s,，;；]+'))
        .where((s) => RegExp(r'^[\d.:a-fA-F]+$').hasMatch(s))
        .toList();
    if (ips.isEmpty) return;
    final todo = ips.where((i) => !_cache.containsKey(i)).toList();
    final out = <List<String>>[];
    for (var i = 0; i < todo.length; i += 100) {
      final batch = todo.sublist(i, (i + 100) > todo.length ? todo.length : i + 100);
      try {
        final resp = await http
            .post(Uri.parse('http://ip-api.com/batch?lang=zh-CN&fields=query,status,country,regionName,city,isp,as'),
                headers: {'Content-Type': 'application/json'}, body: jsonEncode(batch))
            .timeout(const Duration(seconds: 10));
        final data = jsonDecode(resp.body) as List;
        for (final item in data) {
          final m = item as Map<String, dynamic>;
          final row = m['status'] == 'success'
              ? [m['query'].toString(), m['country'].toString(), m['regionName'].toString(), m['city'].toString(), m['isp'].toString(), m['as'].toString()]
              : [m['query'].toString(), '查询失败', '', '', '', ''];
          _cache[row[0]] = row;
        }
      } catch (e) {
        for (final ip in batch) {
          _cache[ip] = [ip, '接口错误', '', '', '', ''];
        }
      }
    }
    for (final ip in ips) {
      out.add(_cache[ip]!);
    }
    if (mounted) setState(() {
      _busy = false;
      _rows = out;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('输入 IP（每行一个或逗号分隔，最多 100 条/次）',
                  style: TextStyle(fontSize: 13, color: kDim)),
              const SizedBox(height: 8),
              TextField(controller: _ctrl, maxLines: 5, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _busy ? null : _go, child: Text(_busy ? '查询中…' : '查询归属')),
              ),
            ],
          ),
        ),
        if (_rows != null)
          ResultTable(
            headers: ['IP', '国家', '省份', '城市', 'ISP', 'ASN'],
            rows: _rows!,
          ),
      ],
    );
  }
}

// ============================================================
// 页3：Ping
// ============================================================
class PingPage extends StatefulWidget {
  const PingPage({super.key});
  @override
  State<PingPage> createState() => _PingPageState();
}

class _PingPageState extends State<PingPage> {
  final _host = TextEditingController(text: '1.1.1.1');
  String _out = '';
  bool _busy = false;

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _out = '';
    });
    try {
      final proc = await Process.run('ping', ['-c', '4', '-W', '5', _host.text.trim()])
          .timeout(const Duration(seconds: 25));
      setState(() {
        _out = '${proc.stdout}\n${proc.stderr}';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _out = 'ping 执行失败: $e\n（部分设备需授予应用「网络」权限）';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CardBox(
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _host,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(labelText: '目标主机/域名'),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(onPressed: _busy ? null : _go, child: Text(_busy ? 'Ping中…' : '开始 Ping')),
            ],
          ),
        ),
        CardBox(
          child: SelectableText(
            _out.isEmpty ? '等待执行…' : _out,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: kGood),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 页4：路由追踪（Android 无 traceroute，用 DoH 解析替代）
// ============================================================
class TracePage extends StatefulWidget {
  const TracePage({super.key});
  @override
  State<TracePage> createState() => _TracePageState();
}

class _TracePageState extends State<TracePage> {
  final _host = TextEditingController(text: 'archiveofourown.org');
  List<List<String>>? _rows;
  bool _busy = false;

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _rows = null;
    });
    final host = _host.text.trim();
    try {
      // Android 系统一般无 traceroute，用 DoH 解析出全部 IP 作为替代
      final d = await httpJson('https://1.12.12.12/dns-query?name=$host&type=1',
          timeout: const Duration(seconds: 8));
      final answers = (d['Answer'] as List?) ?? [];
      final rows = <List<String>>[
        ['DNS', '1.12.12.12 (DNSPod)', 'A 记录解析结果'],
      ];
      for (final a in answers) {
        final m = a as Map<String, dynamic>;
        rows.add(['A', m['TTL'].toString(), m['data'].toString()]);
      }
      // 每个 IP 查归属
      for (final r in rows.skip(1)) {
        final ip = r[2];
        try {
          final g = await httpJson('http://ip-api.com/json/$ip?lang=zh-CN&fields=country,regionName,city,isp');
          r.add('${g['country']} ${g['regionName']} ${g['city']} · ${g['isp']}');
        } catch (_) {
          r.add('归属查询失败');
        }
      }
      if (rows.length == 1) rows.add(['提示', '', '无 A 记录或查询失败']);
      setState(() {
        _rows = rows;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _rows = [
          ['提示', '', '', 'DoH 解析失败: ${e.toString().substring(0, 60)}'],
        ];
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Android 系统不带 traceroute 命令，此页改用 DoH 解析目标全部 A 记录 + 逐 IP 归属地（等效替代）',
                  style: TextStyle(fontSize: 12, color: kDim)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _host,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(labelText: '目标域名/IP'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: _busy ? null : _go, child: Text(_busy ? '解析中…' : '开始解析')),
                ],
              ),
            ],
          ),
        ),
        if (_rows != null)
          ResultTable(headers: ['类型', 'TTL', 'IP', '归属地/ISP'], rows: _rows!),
      ],
    );
  }
}

// ============================================================
// 页5：端口扫描
// ============================================================
class PortScanPage extends StatefulWidget {
  const PortScanPage({super.key});
  @override
  State<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends State<PortScanPage> {
  final _host = TextEditingController(text: '1.1.1.1');
  final _ports = TextEditingController(text: '22,53,80,443,8080,8443,3306,3389');
  List<List<String>>? _rows;
  bool _busy = false;

  static const names = {
    21: 'FTP', 22: 'SSH', 23: 'Telnet', 25: 'SMTP', 53: 'DNS', 80: 'HTTP',
    110: 'POP3', 143: 'IMAP', 443: 'HTTPS', 445: 'SMB', 853: 'DoT',
    993: 'IMAPS', 995: 'POP3S', 1080: 'Socks', 1433: 'MSSQL', 1521: 'Oracle',
    3306: 'MySQL', 3389: 'RDP', 5432: 'PostgreSQL', 5900: 'VNC', 6379: 'Redis',
    8080: 'HTTP-Proxy', 8443: 'HTTPS-Alt', 27017: 'MongoDB',
  };

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _rows = null;
    });
    final host = _host.text.trim();
    final ports = _ports.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    final results = <List<String>>[];
    await Future.wait(ports.map((p) async {
      try {
        final sock = await Socket.connect(host, p, timeout: const Duration(seconds: 3));
        sock.destroy();
        results.add([p.toString(), names[p] ?? '', '开放']);
      } catch (_) {
        results.add([p.toString(), names[p] ?? '', '关闭']);
      }
    }));
    results.sort((a, b) => int.parse(a[0]).compareTo(int.parse(b[0])));
    if (mounted) setState(() {
      _rows = results;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CardBox(
          child: Column(
            children: [
              TextField(
                controller: _host,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '目标 IP/域名'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ports,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '端口（逗号分隔）'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _busy ? null : _go, child: Text(_busy ? '扫描中…' : '开始扫描')),
              ),
            ],
          ),
        ),
        if (_rows != null)
          ResultTable(
            headers: ['端口', '服务', '状态'],
            rows: _rows!,
            rowColors: [for (final r in _rows!) r[2] == '开放' ? kGood : kDim],
          ),
      ],
    );
  }
}

// ============================================================
// 页6：DoH 解析
// ============================================================
class DohPage extends StatefulWidget {
  const DohPage({super.key});
  @override
  State<DohPage> createState() => _DohPageState();
}

class _DohPageState extends State<DohPage> {
  final _name = TextEditingController(text: 'archiveofourown.org');
  final _doh = TextEditingController(text: 'https://1.12.12.12/dns-query');
  String _type = 'A';
  List<List<String>>? _rows;
  String? _summary;
  bool _busy = false;

  static const types = ['A', 'AAAA', 'CNAME', 'MX', 'NS', 'TXT', 'HTTPS(ECH/SVCB)', 'SOA'];
  static const typeNum = {
    'A': 1, 'AAAA': 28, 'CNAME': 5, 'MX': 15, 'NS': 2, 'TXT': 16,
    'HTTPS(ECH/SVCB)': 65, 'SOA': 6,
  };

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _rows = null;
      _summary = null;
    });
    final url = '${_doh.text.trim()}?name=${_name.text.trim()}&type=${typeNum[_type]}';
    try {
      final d = await httpJson(url, timeout: const Duration(seconds: 10));
      final answers = (d['Answer'] as List?) ?? [];
      final rows = <List<String>>[
        for (final a in answers)
          [
            (a as Map)['type'].toString(),
            (a)['TTL'].toString(),
            (a)['data'].toString(),
          ]
      ];
      setState(() {
        _rows = rows;
        _summary = rows.isEmpty ? '无该类型记录' : '${rows.length} 条记录';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _rows = null;
        _summary = '查询失败: ${e.toString().substring(0, 70)}';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CardBox(
          child: Column(
            children: [
              TextField(
                controller: _name,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(labelText: '域名'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: kCard,
                decoration: const InputDecoration(labelText: '记录类型'),
                items: [for (final t in types) DropdownMenuItem(value: t, child: Text(t))],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _doh,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(labelText: 'DoH 端点（可自定义，填你的 gateway 查 ECH）'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _busy ? null : _go, child: Text(_busy ? '解析中…' : '解析')),
              ),
            ],
          ),
        ),
        if (_summary != null)
          CardBox(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(_summary!, style: const TextStyle(color: kAccent, fontSize: 13)),
          ),
        if (_rows != null) ResultTable(headers: ['类型', 'TTL', '记录数据'], rows: _rows!),
      ],
    );
  }
}
