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

  // dynamic chart data
  List<FlSpot> morningSpots = [];
  List<FlSpot> bedtimeSpots = [];
  int daysCount = 7;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    super.didChangeDependencies();
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
    final pref = await SharedPreferences.getInstance();
    final uid = pref.getString('user_id');
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
    for (var doc in snap.docs) {
      raw[doc['date'] as String] = doc.data() as Map<String, dynamic>;
    }

    final mSpots = <FlSpot>[];
    final bSpots = <FlSpot>[];
    for (var i = 0; i < daysCount; i++) {
      final day = cutoffDate.add(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      final entry = raw[key];
      final mSec = entry != null ? (entry['morningSec'] as num?)?.toInt() ?? 0 : 0;
      final bSec = entry != null ? (entry['bedtimeSec'] as num?)?.toInt() ?? 0 : 0;
      mSpots.add(FlSpot(i + 1.toDouble(), mSec / 60));
      bSpots.add(FlSpot(i + 1.toDouble(), bSec / 60));
    }

    setState(() {
      morningSpots = mSpots;
      bedtimeSpots = bSpots;
    });
  }

  void _logout() async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => login()),
          (route) => false,
    );
  }

  void _launchURL() async {
    const url = 'https://www.heartfulnessinstitute.org/';
    if (await canLaunch(url)) await launch(url, forceWebView: true);
  }

  @override
  Widget build(BuildContext context) {
    final name = profileData?['name'] as String? ?? 'Your Name';
    final avatarUrl = profileData?['user_profile'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => settings_screen()),
                ),
                child: Image.asset(
                  'assets/icons/settings.png',
                  width: 50,
                  height: 50,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 50),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => pickAvatar()),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.35,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF485370), width: 2),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          ClipOval(
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? Image.network(
                              avatarUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              'assets/icons/default_prof.png',
                              width: 70,
                              height: 70,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'WorkSans',
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF485370),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome!',
                  style: TextStyle(
                    fontFamily: 'WorkSans',
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF485370),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'My Progress',
                      style: TextStyle(
                        fontFamily: 'WorkSans',
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF485370),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Row(
                    children: [
                      _ToggleBtn(
                        label: 'This Week',
                        selected: thisWeek,
                        onTap: () => setState(() {
                          thisWeek = true;
                          _loadStats();
                        }),
                      ),
                      const SizedBox(width: 12),
                      _ToggleBtn(
                        label: 'This Month',
                        selected: !thisWeek,
                        onTap: () => setState(() {
                          thisWeek = false;
                          _loadStats();
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: const Color(0xFFF6F4F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: LineChart(
                          LineChartData(
                            backgroundColor: Colors.white,
                            gridData: FlGridData(show: true),
                            borderData: FlBorderData(show: true),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (v, meta) => Text(v.toInt().toString()),
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  getTitlesWidget: (v, meta) => Text(v.toInt().toString()),
                                ),
                              ),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            minY: 0,
                            maxY: 25,
                            lineBarsData: [
                              LineChartBarData(
                                spots: morningSpots,
                                isCurved: true,
                                barWidth: 3,
                                color: const Color(0xFF0F75BC),
                                dotData: FlDotData(show: true),
                              ),
                              LineChartBarData(
                                spots: bedtimeSpots,
                                isCurved: true,
                                barWidth: 3,
                                color: const Color(0xFF333333),
                                dotData: FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF485370) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF485370), width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF485370),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
