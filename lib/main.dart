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

  ThemeData _darkTheme() {
    return ThemeData(
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
      tabBarTheme: const TabBarThemeData(
        labelColor: kAccent,
        unselectedLabelColor: kDim,
        indicatorColor: kAccent,
      ),
      cardTheme: const CardThemeData(color: kCard),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: kText),
        bodySmall: TextStyle(color: kDim),
      ),
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF0891B2),
        surface: Colors.white,
        onSurface: const Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFF1F5F9),
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0891B2),
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Color(0xFF0891B2),
        unselectedLabelColor: Color(0xFF94A3B8),
        indicatorColor: Color(0xFF0891B2),
      ),
      cardTheme: const CardThemeData(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '网络工具箱',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
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
              Tab(text: '批量探测'),
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
            SweepPage(),
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
        color: Theme.of(context).colorScheme.surface,
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
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFE2E8F0),
          ),
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

class _MyIpPageState extends State<MyIpPage> with AutomaticKeepAliveClientMixin {
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

    // 本机网卡 IP（不依赖外部服务）
    try {
      final ifs = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      for (final nic in ifs) {
        for (final addr in nic.addresses) {
          // 跳过 link-local
          if (addr.address.startsWith('169.254.') ||
              addr.address.startsWith('fe80:')) continue;
          out.add({
            '源': '本机 (${nic.name})',
            'IP': addr.address,
            '归属': addr.type == InternetAddressType.IPv4 ? 'IPv4 内网' : 'IPv6',
            'ISP': '本机网卡',
          });
        }
      }
    } catch (e) {
      out.add({'源': '本机', 'IP': '失败', '归属': e.toString().substring(0, 60)});
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
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Map<String, String>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return ListView(
            children: [
              CardBox(
                child: Text(
                  '加载失败: ${snap.error}',
                  style: const TextStyle(color: kBad, fontSize: 13),
                ),
              ),
              CardBox(
                child: ElevatedButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: const Text('重试'),
                ),
              ),
            ],
          );
        }
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

class _IpLookupPageState extends State<IpLookupPage> with AutomaticKeepAliveClientMixin {
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
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
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

class _PingPageState extends State<PingPage> with AutomaticKeepAliveClientMixin {
  final _host = TextEditingController(text: '1.1.1.1');
  String _out = '';
  bool _busy = false;

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _out = '';
    });
    final target = _host.text.trim();
    // 先尝试系统 ping
    try {
      final proc = await Process.run('ping', ['-c', '4', '-W', '5', target])
          .timeout(const Duration(seconds: 25));
      final output = '${proc.stdout}\n${proc.stderr}'.trim();
      // ping 二进制不存在或执行失败时走 TCP 回退
      if (proc.exitCode == 0 && output.isNotEmpty && !output.contains('not found')) {
        setState(() {
          _out = output;
          _busy = false;
        });
        return;
      }
    } catch (_) {
      // 忽略，走 TCP 回退
    }
    // TCP 回退：测 80/443 端口连通性 + 耗时（无需 ping 二进制）
    try {
      final buf = StringBuffer('系统 ping 不可用，改用 TCP 探测:\n\n');
      for (final port in [80, 443]) {
        final sw = Stopwatch()..start();
        try {
          final sock = await Socket.connect(target, port,
              timeout: const Duration(seconds: 5));
          sw.stop();
          buf.writeln('TCP $target:$port 通 (${sw.elapsedMilliseconds}ms)');
          sock.destroy();
        } catch (e) {
          sw.stop();
          buf.writeln('TCP $target:$port 不通 (${sw.elapsedMilliseconds}ms): $e');
        }
      }
      // 再测 ICMP 可达性（Dart 层）
      buf.writeln('\n提示：如需真实 ICMP ping，请在有 root 的设备上使用。');
      setState(() {
        _out = buf.toString();
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _out = '探测失败: $e';
        _busy = false;
      });
    }
  }

  @override
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
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

class _TracePageState extends State<TracePage> with AutomaticKeepAliveClientMixin {
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
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
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

class _PortScanPageState extends State<PortScanPage> with AutomaticKeepAliveClientMixin {
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
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
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

class _DohPageState extends State<DohPage> with AutomaticKeepAliveClientMixin {
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
    @override
  bool get wantKeepAlive => true;

Widget build(BuildContext context) {
    super.build(context);
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

// ============================================================
// 页7：批量存活探测
// ============================================================
class SweepPage extends StatefulWidget {
  const SweepPage({super.key});
  @override
  State<SweepPage> createState() => _SweepPageState();
}

class _SweepPageState extends State<SweepPage> with AutomaticKeepAliveClientMixin {
  final _ips = TextEditingController();
  List<List<String>>? _rows;
  bool _busy = false;
  int _alive = 0;

  Future<String> _probeTcp(String ip, int port) async {
    try {
      final sw = Stopwatch()..start();
      final sock = await Socket.connect(ip, port, timeout: const Duration(seconds: 4));
      sock.destroy();
      return '${sw.elapsedMilliseconds}ms';
    } catch (_) {
      return '✗';
    }
  }

  // TLS 握手探测: TCP 通但 ClientHello 被 RST 时这里会失败
  Future<String> _probeTls(String ip) async {
    try {
      final sw = Stopwatch()..start();
      final sock = await SecureSocket.connect(ip, 443,
          onBadCertificate: (_) => true, timeout: const Duration(seconds: 4));
      sock.destroy();
      return '${sw.elapsedMilliseconds}ms';
    } catch (_) {
      return '✗';
    }
  }

  Future<void> _go() async {
    final lines = _ips.text
        .trim()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return;
    setState(() {
      _busy = true;
      _rows = null;
      _alive = 0;
    });
    final results = <List<String>>[];
    var alive = 0;
    await Future.wait(lines.map((line) async {
      final parts = line.split(RegExp(r'\s+'));
      final ip = parts.first;
      final note = parts.length > 1 ? parts[1] : '';
      final r443 = await _probeTls(ip);       // 443: TLS 握手
      final r443t = await _probeTcp(ip, 443); // 443 纯 TCP 对照
      final r80 = await _probeTcp(ip, 80);
      final ok443 = r443 != '✗';
      final ok80 = r80 != '✗';
      if (ok443 || ok80) alive++;
      final delay = ok443 ? r443 : (ok80 ? r80 : '-');
      results.add([
        ip, note,
        ok443 ? 'TLS 通' : 'TLS ✗',
        r443t != '✗' ? 'TCP 通' : 'TCP ✗',
        ok80 ? '80 通' : '80 ✗',
        delay,
      ]);
    }));
    results.sort((a, b) => a[0].compareTo(b[0]));
    if (mounted) setState(() {
      _rows = results;
      _alive = alive;
      _busy = false;
    });
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: [
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('批量 IP 存活探测', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('每行一个 IP，可加备注，如: 104.244.43.131 美国节点', style: TextStyle(fontSize: 12, color: kDim)),
              const SizedBox(height: 10),
              TextField(
                controller: _ips,
                maxLines: 8,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: '1.2.3.4\n5.6.7.8 备注',
                  filled: true,
                  fillColor: Color(0xFF0B1220),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _busy ? null : _go,
                    child: Text(_busy ? '扫描中…' : '开始扫描'),
                  ),
                  const SizedBox(width: 12),
                  if (_rows != null)
                    Text('存活 $_alive/${_rows!.length}', style: const TextStyle(color: kGood)),
                ],
              ),
            ],
          ),
        ),
        if (_rows != null)
          ResultTable(
            headers: ['IP', '备注', '443-TLS', '443-TCP', '80', '延迟'],
            rows: [
              for (final r in _rows!) [r[0], r[1], r[2], r[3], r[4], r[5]],
            ],
            rowColors: [
              for (final r in _rows!)
                (r[2] == 'TLS 通' || r[4] == '80 通') ? kGood : kBad,
            ],
          ),
      ],
    );
  }
}
