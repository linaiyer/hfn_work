import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hfn_work/notification/push_notification_handler.dart';

class notification_settings extends StatefulWidget {
  @override
  _notification_settings createState() => _notification_settings();
}

class _notification_settings extends State<notification_settings> {
  TimeOfDay? _morningTime;
  TimeOfDay? _bedtimeTime;
  final LocalNotification _notifier = LocalNotification();

  @override
  void initState() {
    super.initState();
    _loadTimes();
  }

  Future<void> _loadTimes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _morningTime = TimeOfDay(
        hour: prefs.getInt('morning_hour') ?? 8,
        minute: prefs.getInt('morning_minute') ?? 0,
      );
      _bedtimeTime = TimeOfDay(
        hour: prefs.getInt('bed_hour') ?? 20,
        minute: prefs.getInt('bed_minute') ?? 0,
      );
    });
  }

  Future<void> _pickTime({
    required String keyHour,
    required String keyMinute,
    required TimeOfDay? current,
    required Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) {
        final ThemeData base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: const Color(0xFF0F75BC),
              onPrimary: Colors.white,
              surface: const Color(0xFFF6F4F5),
              onSurface: Colors.black,
            ),
            timePickerTheme: base.timePickerTheme.copyWith(
              backgroundColor: const Color(0xFFF6F4F5),
              hourMinuteColor: MaterialStateColor.resolveWith(
                    (states) => states.contains(MaterialState.selected)
                    ? const Color(0xFF0F75BC)
                    : Colors.transparent,
              ),
              hourMinuteTextColor: MaterialStateColor.resolveWith(
                    (states) => states.contains(MaterialState.selected)
                    ? Colors.white
                    : Colors.black,
              ),
              dialHandColor: const Color(0xFF0F75BC),
              dialBackgroundColor: const Color(0xFFF6F4F5),
              entryModeIconColor: const Color(0xFF0F75BC),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(keyHour, picked.hour);
      await prefs.setInt(keyMinute, picked.minute);
      onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F4F5),
        elevation: 0,
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontFamily: 'WorkSans',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF485370),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF485370)),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text(
              'Morning Reminder',
              style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF485370),
              ),
            ),
            subtitle: Text(
              _morningTime?.format(context) ?? 'Not set',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.edit, color: Color(0xFF485370)),
            onTap: () => _pickTime(
              keyHour: 'morning_hour',
              keyMinute: 'morning_minute',
              current: _morningTime,
              onPicked: (t) {
                setState(() => _morningTime = t);
                _notifier.scheduleDaily(
                  1,
                  'HFN For Work Morning Reminder',
                  'Have you logged in to practice your morning meditation today?',
                  t,
                );
              },
            ),
          ),
          ListTile(
            title: const Text(
              'Bedtime Reminder',
              style: TextStyle(
                fontFamily: 'WorkSans',
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF485370),
              ),
            ),
            subtitle: Text(
              _bedtimeTime?.format(context) ?? 'Not set',
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.edit, color: Color(0xFF485370)),
            onTap: () => _pickTime(
              keyHour: 'bed_hour',
              keyMinute: 'bed_minute',
              current: _bedtimeTime,
              onPicked: (t) {
                setState(() => _bedtimeTime = t);
                _notifier.scheduleDaily(
                  2,
                  'HFN For Work Bedtime Reminder',
                  'Have you logged in to practice your bedtime meditation today?',
                  t,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
