import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hfn_work/auth_screen/login.dart';
import 'package:hfn_work/main.dart';
import 'package:hfn_work/main_screen/user_screen/avater_select/pick_avater.dart';
import 'package:hfn_work/main_screen/user_screen/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class profile_screen extends StatefulWidget {
  @override
  _profile_screen createState() => _profile_screen();
}

class _profile_screen extends State<profile_screen> with RouteAware {
  Map<String, dynamic>? profileData;
  bool thisWeek = true;
  List<FlSpot> morningSpots = [];
  List<FlSpot> bedtimeSpots = [];
  int daysCount = 7;
  double _chartStep = 5;
  double _chartMaxY = 25;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void didPopNext() {
    _loadUser();
    _loadStats();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('user').doc(uid).get();
      if (doc.exists) setState(() => profileData = doc.data());
    }
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('user_id');
    if (uid == null) return;

    daysCount = thisWeek ? 7 : 30;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysCount - 1));
    final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoffDate);

    final snap = await FirebaseFirestore.instance
        .collection('listeningStats')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: cutoffStr)
        .get();

    final raw = <String, Map<String, dynamic>>{};
    for (var d in snap.docs) {
      raw[d['date'] as String] = d.data() as Map<String, dynamic>;
    }

    final mSpots = <FlSpot>[];
    final bSpots = <FlSpot>[];
    if (thisWeek) {
      for (int i = 0; i < 7; i++) {
        final key = DateFormat('yyyy-MM-dd').format(cutoffDate.add(Duration(days: i)));
        mSpots.add(FlSpot(i + 1, (raw[key]?['morningSec'] as num? ?? 0) / 60));
        bSpots.add(FlSpot(i + 1, (raw[key]?['bedtimeSec'] as num? ?? 0) / 60));
      }
    } else {
      final weeksCount = (30 / 7).ceil().clamp(1, 4);
      for (int w = 0; w < weeksCount; w++) {
        double sumM = 0, sumB = 0;
        for (int d = w * 7; d < (w + 1) * 7 && d < daysCount; d++) {
          final key = DateFormat('yyyy-MM-dd').format(cutoffDate.add(Duration(days: d)));
          sumM += raw[key]?['morningSec'] as num? ?? 0;
          sumB += raw[key]?['bedtimeSec'] as num? ?? 0;
        }
        mSpots.add(FlSpot(w + 1, sumM / 60));
        bSpots.add(FlSpot(w + 1, sumB / 60));
      }
    }
    final allYs = [...mSpots.map((e) => e.y), ...bSpots.map((e) => e.y)];
    final maxY = allYs.isEmpty ? 0.0 : allYs.reduce((a, b) => a > b ? a : b);
    final step = (maxY / 5).ceilToDouble().clamp(1.0, double.infinity);
    setState(() {
      morningSpots = mSpots;
      bedtimeSpots = bSpots;
      _chartStep = step;
      _chartMaxY = step * 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get name with better fallback logic
    String name = 'Your Name';
    if (profileData != null) {
      // Try to get name from SSO login
      if (profileData!['name'] != null && profileData!['name'].toString().isNotEmpty) {
        name = profileData!['name'].toString();
      }
      // Fallback to username for regular login
      else if (profileData!['userName'] != null && profileData!['userName'].toString().isNotEmpty) {
        name = profileData!['userName'].toString();
      }
      // Fallback to email username part
      else if (profileData!['email'] != null && profileData!['email'].toString().isNotEmpty) {
        name = profileData!['email'].toString().split('@')[0];
      }
    }
    
    final avatarUrl = profileData?['user_profile'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => settings_screen()),
                    ),
                    child: Image.asset('assets/icons/settings.png', width: 32, height: 32),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.35,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF485370), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => pickAvatar()),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(avatarUrl, width: 100, height: 100, fit: BoxFit.cover)
                            : Image.asset('assets/icons/default_prof.png', width: 100, height: 100),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(fontFamily: 'WorkSans', fontSize: 22, fontWeight: FontWeight.w500, color: Color(0xFF485370))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'My Progress',
                style: TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF485370),
                ),
              ),
            ),
            _legend(),
            _toggles(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: const Color(0xFFF6F4F5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LineChart(
                      LineChartData(
                        backgroundColor: Colors.white,
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            axisNameWidget: thisWeek ? const Text('Days') : const Text('Weeks'),
                            axisNameSize: 16,
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: 28,
                              getTitlesWidget: (value, titleMeta) => Text(value.toInt().toString()),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: _chartStep,
                              reservedSize: 32,
                              getTitlesWidget: (value, titleMeta) => Text(value.toInt().toString()),
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        minY: 0,
                        maxY: _chartMaxY,
                        lineBarsData: [
                          LineChartBarData(spots: morningSpots, isCurved: true, barWidth: 3, color: const Color(0xFF0F75BC), dotData: FlDotData(show: true)),
                          LineChartBarData(spots: bedtimeSpots, isCurved: true, barWidth: 3, color: const Color(0xFF333333), dotData: FlDotData(show: true)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _labelBox(Color c, String text) => Row(
    children: [
      Container(width: 12, height: 12, color: c),
      const SizedBox(width: 4),
      Text(text, style: TextStyle(color: c)),
    ],
  );

  Widget _toggles() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleBtn(label: 'This Week', selected: thisWeek, onTap: () {
          setState(() => thisWeek = true);
          _loadStats();
        }),
        const SizedBox(width: 12),
        _ToggleBtn(label: 'This Month', selected: !thisWeek, onTap: () {
          setState(() => thisWeek = false);
          _loadStats();
        }),
      ],
    ),
  );

  Widget _legend() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      children: [
        _labelBox(const Color(0xFF0F75BC), 'Morning'),
        const SizedBox(width: 16),
        _labelBox(const Color(0xFF333333), 'Bedtime'),
      ],
    ),
  );
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF485370) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF485370), width: 1.5),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF485370),
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ),
      );
}