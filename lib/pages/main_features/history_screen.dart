// lib/history_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const kGreen = Color(0xFF123524);
  static const kText = Color(0xFF0B1215);

  int _tabIndex = 0; // 0=Semua, 1=Dalam Proses, 2=Selesai
  int _expandedIndex = -1;
  String _query = '';

  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Silakan login terlebih dahulu'));
    }

    // Stream semua order user, diurutkan terbaru
    final stream = _db
        .collection('pickup_orders')
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat',
                style: TextStyle(
                  color: kText,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 12),

            // Search + filter
            Row(
              children: [
                Expanded(
                  child: _SearchField(
                    hint: 'Cari',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 10),
                _SquareIconButton(
                  icon: Icons.tune_rounded,
                  onTap: () {
                    // TODO: bottom sheet filter tambahan (tanggal, bank, dll.)
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Tabs
            _Tabs(
              index: _tabIndex,
              onChanged: (i) => setState(() {
                _tabIndex = i;
                if (_tabIndex != 1) _expandedIndex = -1;
              }),
            ),
            const SizedBox(height: 10),

            // List from Firestore
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: stream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Gagal memuat: ${snap.error}'));
                    }
                    final docs = snap.data?.docs ?? [];

                    // Map Firestore -> _HistoryItem
                    final all = docs.map((d) {
                      final m = d.data();
                      final statusStr = (m['status'] as String?) ?? 'requested';
                      final status = _mapStatus(statusStr);
                      final weight = (m['totalWeight'] as num?)?.toDouble() ?? 0.0;
                      final points = (m['totalPoints'] as num?)?.toInt() ?? 0;
                      final bankName = (m['bankName'] as String?) ?? 'Bank Sampah';
                      final createdAt = m['createdAt'];
                      final dateText = _fmtDate(createdAt);

                      final items = (m['items'] as List?) ?? const [];
                      final totalJenis = items.length;

                      final icon = status == _Status.inProgress
                          ? Icons.local_shipping
                          : Icons.assignment_return;

                      return _HistoryItem(
                        id: d.id,
                        icon: icon,
                        title: bankName,
                        weightKg: weight,
                        points: points,
                        dateText: dateText,
                        status: status,
                        totalJenis: totalJenis,
                      );
                    }).toList();

                    // Filter by tab & search query (client-side)
                    List<_HistoryItem> filtered = all.where((e) {
                      if (_tabIndex == 1 && e.status != _Status.inProgress) return false;
                      if (_tabIndex == 2 && e.status != _Status.done) return false;
                      if (_query.isEmpty) return true;
                      return e.title.toLowerCase().contains(_query.toLowerCase());
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text('Belum ada riwayat untuk filter ini'),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final expanded = (_tabIndex == 1 && _expandedIndex == i);

                        return Column(
                          children: [
                            _HistoryCard(
                              item: item,
                              expanded: expanded,
                              onExpandToggle: () {
                                if (_tabIndex != 1) return;
                                setState(() {
                                  _expandedIndex = expanded ? -1 : i;
                                });
                              },
                              onTap: () { // <-- NEW: open tracking page
                                Navigator.pushNamed(
                                  context,
                                  '/pickup/track', // must be registered in routes
                                  arguments: {'orderId': item.id},
                                );
                              },
                            ),
                            if (expanded) ...[
                              const SizedBox(height: 6),
                              const _TimelineBox(), // mock timeline seperti UI awal
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers =====

  static _Status _mapStatus(String s) {
    // Kelompokkan status Firestore ke 2 tab UI:
    // inProgress: requested/assigned/on_route/arrived
    // done: delivered/cancelled
    switch (s) {
      case 'delivered':
      case 'cancelled':
      case 'done':
        return _Status.done;
      case 'requested':
      case 'assigned':
      case 'on_route':
      case 'arrived':
      default:
        return _Status.inProgress;
    }
  }

  static String _fmtDate(dynamic ts) {
    // ts bisa Timestamp, DateTime, atau null
    DateTime? dt;
    if (ts is Timestamp) dt = ts.toDate();
    if (ts is DateTime) dt = ts;
    dt ??= DateTime.now();
    // Format ringan: dd/MM/yyyy · HH:mm
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $hh:$mm';
    // (Kalau mau pakai intl, silakan ganti)
  }
}

/// ===== Models =====
enum _Status { inProgress, done }

class _HistoryItem {
  final String id;
  final IconData icon;
  final String title;
  final double weightKg;
  final int points;
  final String dateText;
  final _Status status;
  final int totalJenis;

  const _HistoryItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.weightKg,
    required this.points,
    required this.dateText,
    required this.status,
    required this.totalJenis,
  });
}

/// ===== Widgets kecil (UI dipertahankan) =====

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  const _SearchField({required this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  border: InputBorder.none,
                  hintStyle:
                  TextStyle(color: Colors.black.withOpacity(.45), fontSize: 14.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _SquareIconButton({required this.icon, this.onTap});

  static const kGreen = _HistoryScreenState.kGreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF1F4F0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.tune_rounded, color: kGreen),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _Tabs({required this.index, required this.onChanged});

  static const kGreen = _HistoryScreenState.kGreen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _TabBtn('Semua', 0, index, onChanged),
            _TabBtn('Dalam Proses', 1, index, onChanged),
            _TabBtn('Selesai', 2, index, onChanged),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 1, color: Colors.black12),
            AnimatedAlign(
              alignment: switch (index) {
                0 => Alignment.centerLeft,
                1 => Alignment.center,
                _ => Alignment.centerRight,
              },
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: MediaQuery.of(context).size.width / 3 - 16,
                height: 3,
                color: kGreen,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String text;
  final int me;
  final int idx;
  final ValueChanged<int> onChanged;
  const _TabBtn(this.text, this.me, this.idx, this.onChanged);

  static const kGreen = _HistoryScreenState.kGreen;

  @override
  Widget build(BuildContext context) {
    final active = me == idx;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(me),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? kGreen : Colors.black54,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final isDone = status == _Status.done;
    final color = isDone ? const Color(0xFFE4F2E6) : const Color(0xFFEFF1EC);
    final textColor = isDone ? Colors.green.shade700 : Colors.black45;
    final label = isDone ? 'Selesai' : 'Dalam Proses';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: textColor, fontSize: 12.5, fontWeight: FontWeight.w600)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;
  final bool expanded;
  final VoidCallback onExpandToggle;
  final VoidCallback? onTap;

  const _HistoryCard({
    required this.item,
    required this.expanded,
    required this.onExpandToggle,
    this.onTap,
  });

  static const kText = _HistoryScreenState.kText;
  static const kGreen = _HistoryScreenState.kGreen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // leading icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: kGreen),
                  ),
                  const SizedBox(width: 12),
                  // title + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: kText)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${item.weightKg.toStringAsFixed(1)}Kg',
                              style: const TextStyle(
                                  color: Colors.deepOrange, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 6),
                            const Text('|'),
                            const SizedBox(width: 6),
                            Text(
                              '${item.points} Rupiah',
                              style: const TextStyle(
                                  color: Colors.deepOrange, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(item.dateText,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(item.status),
                ],
              ),
              const SizedBox(height: 10),
              // total jenis + caret
              Row(
                children: [
                  Text('Total : ${item.totalJenis} Jenis Sampah',
                      style: const TextStyle(color: Colors.black54)),
                  const Spacer(),
                  InkWell(
                    onTap: onExpandToggle,
                    child: Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.black54,
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineBox extends StatelessWidget {
  // Mock timeline seperti UI awal
  final steps = const [
    ('Permintaan penjemputan berhasil dibuat.',
    'Kurir akan menjemput sesuai jadwal yang dipilih.'),
    ('Kurir dalam perjalanan.',
    'Kurir sedang menuju lokasi Anda. Pastikan sampah siap.'),
    ('Kurir sudah sampai di lokasi penjemputan.',
    'Kurir akan mengambil sampah yang sudah Anda siapkan.'),
    ('Kurir menuju bank sampah.',
    'Kurir sedang membawa sampah ke bank sampah.'),
    ('Menunggu konfirmasi.',
    'Sampah ditimbang. Poin dihitung sesuai hasil timbangan.'),
    ('Poin berhasil ditambahkan.', 'Selamat, poin telah masuk ke akun Anda.'),
  ];

  const _TimelineBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 12, top: 10, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: List.generate(steps.length, (i) {
          final title = steps[i].$1;
          final desc = steps[i].$2;
          final isLast = i == steps.length - 1;
          final dotColor = isLast ? Colors.deepOrange : _HistoryScreenState.kGreen;

          return _TimeLineRow(
            title: title,
            desc: desc,
            dotColor: dotColor,
            isLast: isLast,
          );
        }),
      ),
    );
  }
}

class _TimeLineRow extends StatelessWidget {
  final String title;
  final String desc;
  final Color dotColor;
  final bool isLast;
  const _TimeLineRow({
    required this.title,
    required this.desc,
    required this.dotColor,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // rail + dot
        SizedBox(
          width: 26,
          child: Column(
            children: [
              // dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 46,
                  margin: const EdgeInsets.only(top: 2),
                  color: const Color(0xFFD7E0D4),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // texts
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _HistoryScreenState.kText)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
