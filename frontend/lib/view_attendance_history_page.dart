import 'package:flutter/material.dart';
import 'utils/constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppColors 
{
  static const Color primaryDark = Color(0xFF170036);
  static const Color primaryPurple = Color(0xFF4C1D95);
  static const Color cardBackground = Color(0xFFEDEBFF);
  static const Color textLight = Color(0xFFF4F4FF);
  static const Color textDark = Color(0xFF131A33);
  static const Color accentGreen = Color(0xFF22C55E);

  static const LinearGradient pageBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryPurple],
  );
}


class AttendanceRecordItem 
{
  final String sessionId;
  final String status;
  final String? timestamp;

  AttendanceRecordItem({
    required this.sessionId,
    required this.status,
    this.timestamp,
  });

  factory AttendanceRecordItem.fromJson(Map<String, dynamic> json) 
  {
    return AttendanceRecordItem(
      sessionId: json['session_id'] ?? '',
      status: json['status'] ?? 'Unknown',
      timestamp: json['timestamp'],
    );
  }
}


class AttendanceHistoryResponse 
{
  final List<AttendanceRecordItem> daily;
  final List<AttendanceRecordItem> weekly;
  final List<AttendanceRecordItem> semester;

  AttendanceHistoryResponse({
    required this.daily,
    required this.weekly,
    required this.semester,
  });

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) 
  {
    return AttendanceHistoryResponse(
      daily: (json['daily'] as List? ?? [])
          .map((i) => AttendanceRecordItem.fromJson(i))
          .toList(),
      weekly: (json['weekly'] as List? ?? [])
          .map((i) => AttendanceRecordItem.fromJson(i))
          .toList(),
      semester: (json['semester'] as List? ?? [])
          .map((i) => AttendanceRecordItem.fromJson(i))
          .toList(),
    );
  }
}


class ViewAttendanceHistoryPage extends StatefulWidget {
  const ViewAttendanceHistoryPage({super.key, this.userId});
  final String? userId; // recive user id

  @override
  State<ViewAttendanceHistoryPage> createState() =>
      _ViewAttendanceHistoryPageState();
}

class _ViewAttendanceHistoryPageState extends State<ViewAttendanceHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final String baseUrl = ApiConstsnts.baseUrl; 
  bool _isLoading = false; 
  String? _error; 
  AttendanceHistoryResponse? _history; 

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory(); 
  }

  @override
  void dispose() 
  {
    _tabController
        .dispose(); 
    super.dispose();
  }

  // دالة لجلب بيانات سجل الحضور من الخادم
  Future<void> _loadHistory() async 
  {
    String? studentId = widget.userId;
    if (studentId == null || studentId.isEmpty) 
    {
      final prefs = await SharedPreferences.getInstance();
      studentId = prefs.getString("user_id");
    }
    if (studentId == null || studentId.isEmpty) return;
    setState(() 
    {
      _isLoading = true;
      _error = null;
    });

    try 
    {
      
      final response = await http.get(
        Uri.parse("$baseUrl/students/$studentId/attendance-history"),
      );

      if (response.statusCode == 200) 
      {
        final data = jsonDecode(response.body);
        print(data);
        setState(() 
        {
          _history = AttendanceHistoryResponse.fromJson(data);
        });
      } 
      else 
      {
        setState(() => _error = "Error: ${response.statusCode}");
      }
    } 
    catch (e) 
    {
      setState(() => _error = e.toString());
    }
    finally 
    {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          ApiConstsnts.attendanceHistoryTitle,
          style: TextStyle(color: AppColors.textLight),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Semester'),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRecordList(_history?.daily ?? const []),
                  _buildRecordList(_history?.weekly ?? const []),
                  _buildRecordList(_history?.semester ?? const []),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بناء قائمة السجلات لكل تبويب
  Widget _buildRecordList(List<AttendanceRecordItem> records) {
    // عرض مؤشر التحميل إذا كانت البيانات قيد الجلب
    if (_isLoading && _history == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // عرض رسالة في حال عدم وجود سجلات
    if (records.isEmpty) {
      return const Center(
        child: Text(
          'No records found.',
          style: TextStyle(color: AppColors.textLight),
        ),
      );
    }

    // عرض السجلات في قائمة مفصلة
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = records[index];
        String timeText = 'N/A';
        // تنسيق التاريخ إذا كان موجوداً
        if (item.timestamp != null) {
          final dateTime = DateTime.parse(item.timestamp!);
          timeText = DateFormat('yyyy-MM-dd').format(dateTime);
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session #${item.sessionId}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Status: ${item.status}',
                style: const TextStyle(color: AppColors.textDark),
              ),
              Text(
                'Date: $timeText',
                style: const TextStyle(color: AppColors.textDark),
              ),
            ],
          ),
        );
      },
    );
  }
}
