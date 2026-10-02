import 'dart:convert';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gobuddy/data/preferences.dart';
import 'package:gobuddy/models/calendar_model.dart';
import 'package:gobuddy/services/end_points.dart';
import 'package:gobuddy/services/repository.dart';
import 'package:gobuddy/utils/util_class.dart';
import 'package:intl/intl.dart';

import '../../utils/config.dart';

class JobCalendarScreen extends StatefulWidget {
  @override
  _JobCalendarScreenState createState() => _JobCalendarScreenState();
}

class _JobCalendarScreenState extends State<JobCalendarScreen> {
  DateTime currentDate = DateTime.now();
DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  int selectedDay = DateTime.now().day; // Currently selected day
  String? ProviderId;
  GetCalendarModel? pushintoModel;
List<Orders> getoders = [];
List<Calendar> getcalendar = [];
List<Vacations> getvacations = [];

bool isLoading = true;
bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;
    _isInit = true;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('provider_id')) {
      ProviderId = args['provider_id']?.toString();
    }
    if (ProviderId == null || ProviderId!.isEmpty) {
      final userDataStr = Preferences.getUserDetails();
      if (userDataStr != null && userDataStr.isNotEmpty) {
        try {
          final userData = json.decode(userDataStr);
          ProviderId = (userData['user_id'] ?? userData['id'])?.toString();
        } catch (_) {}
      }
    }
    _getCalendarDetails();
  }




 Future<void> _getCalendarDetails() async {

  bool internet = await UtilClass.checkInternet();
  if (!internet) {
    UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
    return;
  }

  try {
    final response = await Repository.postApiService(
      EndPoints.getCalendarOverveiwDetails,
      {
        'provider_id': ProviderId,
        'month': selectedMonth.month,
        'year': selectedMonth.year,
      },
    );

    // Ensure response is Map<String, dynamic>
    Map<String, dynamic> jsonResponse =
        response is String ? json.decode(response) : response;

    if (jsonResponse["status"] == "valid") {
      pushintoModel = GetCalendarModel.fromJson(jsonResponse);

      setState(() {
        // Assign lists properly
        getoders = pushintoModel!.jobs!.orders ?? [];
        getcalendar = pushintoModel!.jobs!.calendar ?? [];

        final List<Vacations> combinedVacations = List.from(pushintoModel!.jobs!.vacations ?? []);
        for (var c in (pushintoModel!.jobs!.calendar ?? [])) {
          if (c.date != null) {
            final alreadyIn = combinedVacations.any((v) => v.date == c.date);
            if (!alreadyIn) {
              combinedVacations.add(
                Vacations(
                  date: c.date,
                  startTime: c.startTime,
                  endTime: c.endTime,
                ),
              );
            } else if (c.startTime != null || c.endTime != null) {
              final idx = combinedVacations.indexWhere((v) => v.date == c.date);
              if (idx != -1 && (combinedVacations[idx].startTime == null || combinedVacations[idx].startTime!.isEmpty)) {
                combinedVacations[idx] = Vacations(
                  date: c.date,
                  startTime: c.startTime,
                  endTime: c.endTime,
                );
              }
            }
          }
        }
        getvacations = combinedVacations;
      });
    } else {
      UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse["message"] ?? "Failed to fetch calendar");
    }
  } catch (e) {
    print("Error fetching calendar: $e");
    UtilClass.showAlertDialog(context: context, message: "Something went wrong");
  }
}




  List<Map<String, dynamic>> getOrdersForDisplay() =>
      List<Map<String, dynamic>>.from(getoders);

  // ======== CALENDAR ========
Widget buildCalendarDay(int day) {
  final isCurrentMonth = selectedMonth.month == currentDate.month &&
      selectedMonth.year == currentDate.year;

  final isSelected = day == selectedDay && isCurrentMonth;

  final isToday = day == currentDate.day &&
      selectedMonth.month == currentDate.month &&
      selectedMonth.year == currentDate.year;

  // Only show green dot if today or in this month
  final showGreenDot = isToday || isCurrentMonth;

  return GestureDetector(
    onTap: () {
      if (isCurrentMonth) {
        setState(() {
          selectedDay = day;
        });
      }
    },
    child: Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.all(2),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Frosted blur ring for today's date
          if (isToday)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF4285F4).withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),

          // Solid selection background if tapped/selected
          if (isSelected)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4),
                borderRadius: BorderRadius.circular(20),
              ),
            ),

          // Day number
          Text(
            day.toString(),
            style: TextStyle(
              color: isCurrentMonth
                  ? (isSelected ? Colors.white : Colors.black)
                  : Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Green dot for today or any day in current month
          if (showGreenDot)
            const Positioned(
              bottom: 6,
              child: _StatusDot(color: Colors.green),
            ),
        ],
      ),
    ),
  );
}

Widget buildCalendar() {
  final daysInMonth =
      DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

  List<Widget> dayWidgets = [];

  // Current month days only
  for (int day = 1; day <= daysInMonth; day++) {
    dayWidgets.add(buildCalendarDay(day));
  }

  return GridView.count(
    crossAxisCount: 7, // 7 days a week
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: dayWidgets,
  );
}
Widget buildJobCard(Orders job) {
  if (job.scheduleDate == null) return const SizedBox();

  final DateTime jobDate = DateTime.parse(job.scheduleDate!);
  final dayNumber = jobDate.day;
  final dayLabel = DateFormat('EEE').format(jobDate); // e.g., "Mon"

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        _DateChip(day: dayLabel, number: dayNumber, accent: Colors.green),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceName ?? 'Unknown Service',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.location_pin, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    job.scheduleTime ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget buildVacationCard(Vacations v) {
  if (v.date == null) return const SizedBox();

  DateTime vacDate;
  try {
    vacDate = DateTime.parse(v.date!);
  } catch (_) {
    vacDate = DateTime.now();
  }
  final dayNumber = vacDate.day;
  final dayLabel = DateFormat('EEE').format(vacDate);

  final isFullDay = (v.startTime == null && v.endTime == null) ||
      (v.startTime == '00:00:00' && (v.endTime == '23:59:59' || v.endTime == null));
  final timeLabel = isFullDay
      ? 'Full day'
      : '${v.startTime ?? ''} - ${v.endTime ?? ''}';

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          spreadRadius: 1,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _DateChip(day: dayLabel, number: dayNumber, accent: Colors.red),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'On Vacation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      timeLabel,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Action Buttons: Edit and Delete
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF4285F4), size: 22),
              tooltip: 'Edit Vacation',
              onPressed: () => _editVacation(v),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
              tooltip: 'Delete Vacation',
              onPressed: () => _deleteVacation(v.date),
            ),
          ],
        ),
      ],
    ),
  );
}

  // ======== VACATION ACTIONS: DELETE & EDIT ========

  Future<void> _deleteVacation(String? date) async {
    if (date == null || date.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text("Delete Vacation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel / delete your vacation on $date?",
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!await UtilClass.checkInternet()) {
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);

    try {
      final response = await Repository.postApiService(
        EndPoints.deleteVacation,
        {
          'provider_id': ProviderId ?? '',
          'date': date,
        },
      );

      UtilClass.hideProgress();

      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : (response as Map<String, dynamic>);

      if (jsonResponse['status'] == 'valid' ||
          jsonResponse['status'] == true ||
          jsonResponse['status'] == 1 ||
          jsonResponse['status'] == '1') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(jsonResponse['message'] ?? 'Vacation deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _getCalendarDetails();
      } else {
        if (!mounted) return;
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse['message'] ?? 'Failed to delete vacation',
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "Failed to delete vacation: $e");
    }
  }

  Future<void> _editVacation(Vacations vacation) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Edit Vacation (${vacation.date ?? ''})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.all_inclusive, color: Color(0xFF4285F4)),
                  title: const Text("Set Full Day"),
                  subtitle: const Text("Mark as unavailable the entire day"),
                  onTap: () => Navigator.of(ctx).pop("full"),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time, color: Colors.orange),
                  title: const Text("Set Custom Time Slot"),
                  subtitle: const Text("Pick specific from and to time"),
                  onTap: () => Navigator.of(ctx).pop("time"),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Delete Vacation", style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.of(ctx).pop("delete"),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (action == "full") {
      await _setFullDayVacation(vacation);
    } else if (action == "time") {
      await _pickVacationTime(vacation);
    } else if (action == "delete") {
      await _deleteVacation(vacation.date);
    }
  }

  Future<void> _setFullDayVacation(Vacations vacation) async {
    if (vacation.date == null || vacation.date!.isEmpty) return;

    if (!await UtilClass.checkInternet()) {
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);

    try {
      final response = await Repository.postApiService(
        EndPoints.setVacation,
        {
          'provider_id': ProviderId ?? '',
          'start_date': vacation.date!,
          'end_date': vacation.date!,
        },
      );

      UtilClass.hideProgress();

      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : (response as Map<String, dynamic>);

      if (jsonResponse['status'] == 'valid' ||
          jsonResponse['status'] == true ||
          jsonResponse['status'] == 1 ||
          jsonResponse['status'] == '1') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vacation updated to Full Day'),
            backgroundColor: Colors.green,
          ),
        );
        _getCalendarDetails();
      } else {
        if (!mounted) return;
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse['message'] ?? 'Failed to update vacation',
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "Failed to update vacation: $e");
    }
  }

  Future<void> _updateVacationTime(Vacations vacation, TimeOfDay start, TimeOfDay end) async {
    if (vacation.date == null || vacation.date!.isEmpty) return;

    if (!await UtilClass.checkInternet()) {
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "No Internet Connection");
      return;
    }

    UtilClass.showProgress(context: context);

    try {
      final startTimeStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

      final response = await Repository.postApiService(
        EndPoints.setTime,
        {
          'provider_id': ProviderId ?? '',
          'date': vacation.date!,
          'start_time': startTimeStr,
          'end_time': endTimeStr,
        },
      );

      UtilClass.hideProgress();

      final Map<String, dynamic> jsonResponse =
          response is String ? json.decode(response) : (response as Map<String, dynamic>);

      if (jsonResponse['status'] == 'valid' ||
          jsonResponse['status'] == true ||
          jsonResponse['status'] == 1 ||
          jsonResponse['status'] == '1') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vacation time updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _getCalendarDetails();
      } else {
        if (!mounted) return;
        UtilClass.showAlertDialog(
          context: context,
          message: jsonResponse['message'] ?? 'Failed to update vacation time',
        );
      }
    } catch (e) {
      UtilClass.hideProgress();
      if (!mounted) return;
      UtilClass.showAlertDialog(context: context, message: "Failed to update vacation time: $e");
    }
  }

  // ======== TIME RANGE PICKER (Cupertino wheels) ========
  Future<void> _pickVacationTime(Vacations vacation) async {
    TimeOfDay initialStart = _parseTimeOfDay(vacation.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay initialEnd = _parseTimeOfDay(vacation.endTime) ?? const TimeOfDay(hour: 17, minute: 0);

    TimeOfDay start = initialStart;
    TimeOfDay end = initialEnd;

    final result = await showModalBottomSheet<_TimeOfDayPair>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: SizedBox(
              height: 360,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Set Vacation Time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick a time of the day',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  // Start / End pickers
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CupertinoTimeWheel(
                          initial: start,
                          onChanged: (t) => start = t,
                          label: 'From',
                          width: 120,
                        ),
                        const SizedBox(width: 16),
                        _CupertinoTimeWheel(
                          initial: end,
                          onChanged: (t) => end = t,
                          label: 'To',
                          width: 120,
                        ),
                      ],
                    ),
                  ),

                  // Confirm button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4285F4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop(_TimeOfDayPair(start, end));
                        },
                        child: const Text(
                          'Save Time',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      await _updateVacationTime(vacation, result.item1, result.item2);
    }
  }

  // ======== WIDGET TREE ========
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF8BC34A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          title: const Text(
            'Job Calendar',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    Config.createVacationRouteName,
                    arguments: {"provider_id": ProviderId},
                  ).then((value) {
                    if (value == true || value != null) {
                      _getCalendarDetails();
                    }
                  });
                },
              ),
            ),
          ],
        ),
        body: 
        
   SingleChildScrollView(
  child: Column(
    children: [
      // Calendar
      _calendarCard(),

      // Tabs below the calendar
      Container(
        color: Colors.white,
        child: TabBar(
          indicatorColor: const Color(0xFF4285F4),
          labelColor: Colors.black87,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusDot(color: Colors.green, size: 12),
                  const SizedBox(width: 8),
                  const Text('Orders'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatusDot(color: Colors.red, size: 12),
                  const SizedBox(width: 8),
                  const Text('On vacation'),
                ],
              ),
            ),
          ],
        ),
      ),

      // Tab content
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: TabBarView(
          children: [
            // ===== Orders Tab =====
            getoders.isEmpty
                ? _emptyMessage('No orders for this month')
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    itemCount: getoders.length,
                    itemBuilder: (context, index) => buildJobCard(getoders[index]),
                  ),

            // ===== Vacation Tab =====
            getvacations.isEmpty
                ? _emptyMessage('No vacations for this month')
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 16, bottom: 20),
                    itemCount: getvacations.length,
                    itemBuilder: (context, index) {
                      final v = getvacations[index];
                      return buildVacationCard(v);
                    },
                  ),
          ],
        ),
      ),
    ],
  ),
)

        
      ),
    );
  }

  // ======== Small UI helpers ========
  Widget _calendarCard() {
    return 
    
    Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month - 1,
                    );
                  });
                  _getCalendarDetails();
                },
              ),
              Text(
                '${_getMonthName(selectedMonth.month)}, ${selectedMonth.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    selectedMonth = DateTime(
                      selectedMonth.year,
                      selectedMonth.month + 1,
                    );
                  });
                  _getCalendarDetails();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Week headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                  .map((day) => SizedBox(
                width: 40,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          buildCalendar(),
        ],
      ),
    );
  }

  Widget _legendRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: const [
              _StatusDot(color: Colors.green, size: 12),
              SizedBox(width: 8),
              Text(
                'Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Row(
            children: const [
              _StatusDot(color: Colors.red, size: 12),
              SizedBox(width: 8),
              Text(
                'On vacation',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }

  // ======== Time parsing/formatting helpers ========
  static TimeOfDay? _parseTimeOfDay(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final trimmed = s.trim();
    final parts = trimmed.split(' ');
    if (parts.length == 2) {
      final hm = parts[0].split(':');
      if (hm.length >= 2) {
        int hour = int.tryParse(hm[0]) ?? 0;
        int minute = int.tryParse(hm[1]) ?? 0;
        final ampm = parts[1].toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } else {
      final hm = trimmed.split(':');
      if (hm.length >= 2) {
        int hour = int.tryParse(hm[0]) ?? 0;
        int minute = int.tryParse(hm[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  static String _formatTimeOfDay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final suffix = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$mm $suffix';
  }
}

// ======== Small components ========
class _StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const _StatusDot({required this.color, this.size = 6, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String day;
  final int number;
  final Color accent;
  const _DateChip({
    Key? key,
    required this.day,
    required this.number,
    required this.accent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            number.toString(),
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CupertinoTimeWheel extends StatefulWidget {
  final TimeOfDay initial;
  final ValueChanged<TimeOfDay> onChanged;
  final String label;
  final double width;

  const _CupertinoTimeWheel({
    Key? key,
    required this.initial,
    required this.onChanged,
    required this.label,
    this.width = 100,
  }) : super(key: key);

  @override
  State<_CupertinoTimeWheel> createState() => _CupertinoTimeWheelState();
}

class _CupertinoTimeWheelState extends State<_CupertinoTimeWheel> {
  late int hour; // 1..12
  late int minute; // 0, 5, 10, ...
  late String period; // AM/PM
 

  @override
  void initState() {
    super.initState();
  
    period = widget.initial.period == DayPeriod.am ? 'AM' : 'PM';
    hour = widget.initial.hourOfPeriod == 0 ? 12 : widget.initial.hourOfPeriod;
    minute = 0; // Set minutes to 0 by default
  }

  void _emit() {
    int h24 = hour % 12;
    if (period == 'PM') h24 += 12;
    widget.onChanged(TimeOfDay(hour: h24, minute: minute));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            widget.label,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Hour picker - reduced width
                    SizedBox(
                      width: constraints.maxWidth * 0.5, // Use 50% of available width
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(initialItem: (hour - 1)),
                        onSelectedItemChanged: (i) {
                          setState(() => hour = i + 1);
                          _emit();
                        },
                        children: List.generate(
                          12,
                              (i) => Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 18), // Reduced font size
                            ),
                          ),
                        ),
                      ),
                    ),
                    // AM/PM picker - reduced width
                    SizedBox(
                      width: constraints.maxWidth * 0.4, // Use 40% of available width
                      child: CupertinoPicker(
                        itemExtent: 32,
                        scrollController: FixedExtentScrollController(
                          initialItem: period == 'AM' ? 0 : 1,
                        ),
                        onSelectedItemChanged: (i) {
                          setState(() => period = i == 0 ? 'AM' : 'PM');
                          _emit();
                        },
                        children: const [
                          Center(
                            child: Text(
                              'AM',
                              style: TextStyle(fontSize: 16), // Reduced font size
                            ),
                          ),
                          Center(
                            child: Text(
                              'PM',
                              style: TextStyle(fontSize: 16), // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeOfDayPair {
  final TimeOfDay item1;
  final TimeOfDay item2;
  _TimeOfDayPair(this.item1, this.item2);
}

Widget _emptyMessage(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
