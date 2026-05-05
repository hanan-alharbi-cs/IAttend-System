import 'dart:async';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iattend_frontend/utils/constants.dart';

class LiveAttendancePage extends StatefulWidget 
{
  final String sessionId;
  final String courseName;
  final String sessionName;

  const LiveAttendancePage({
    super.key,
    required this.sessionId,
    required this.courseName,
    required this.sessionName,
  });

  @override
  State<LiveAttendancePage> createState() => _LiveAttendancePageState();
}

class _LiveAttendancePageState extends State<LiveAttendancePage> 
{
  bool _isLoading = true;
  String _error = "";
  List<dynamic> _students = [];
  Map<String, dynamic>? _summary;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    // تحميل أولي عند فتح الصفحة
    _fetchLiveAttendance();
    // تحديث مباشر كل 5 ثواني لمتابعة الحضور بشكل لحظي
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) 
    {
      _fetchLiveAttendance(showLoader: false);
    });
  }

  @override
  void dispose() 
  {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLiveAttendance({bool showLoader = true}) async 
  {
    if (showLoader && mounted) 
    {
      setState(() {
        _isLoading = true;
        _error = "";
      });
    }

    try 
    {
      
      final url =
          "${ApiConstsnts.baseUrl}${ApiConstsnts.liveAttendance}${widget.sessionId}";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) 
      {
        if (!mounted) return;
        setState(() 
        {
          _error = "Failed to fetch attendance (${response.statusCode})";
          _isLoading = false;
        });
        return;
      }

      final body = jsonDecode(response.body);
      if (body["status"] != "success") 
      {
        if (!mounted) return;
        setState(() 
        {
          _error = body["message"]?.toString() ?? "Unknown server error";
          _isLoading = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() 
      {
        // تخزين بيانات الطلاب والملخص لعرضها في الواجهة
        _students = body["students"] ?? [];
        _summary = body["summary"];
        _isLoading = false;
        _error = "";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Network error: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(int studentId, String newStatus) async
   {
  try 
  {
    final response = await http.patch(
  
  Uri.parse('${ApiConstsnts.baseUrl}${ApiConstsnts.updateAttendance}'), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'student_id': studentId,
        'session_id': widget.sessionId,
        'status': newStatus,
      }),
    );

    if (response.statusCode == 200) 
    {
      
      _fetchLiveAttendance(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Updated to $newStatus")),
      );
    }
  } catch (e) 
  {
    print("Update error: $e");
  }
}


  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    
    final headers = ['Academic ID', 'Name', 'Status', 'Check-in Time'];
    final data = _students.map((student) 
    {
      return [
        student["academic_id"]?.toString() ?? "-",
        student["name"]?.toString() ?? "Unknown",
        student["status"]?.toString() ?? "Absent",
        student["check_in_time"]?.toString() ?? "-",
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) 
        {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Attendance Report", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateTime.now().toString().split('.')[0]), 
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Course: ${widget.courseName}"),
            pw.Text("Session: ${widget.sessionName}"),
            pw.SizedBox(height: 10),
            pw.Text("Total Students: ${_summary?["total_students"] ?? 0}"),
            pw.Text("Present: ${_summary?["present_students"] ?? 0} | Absent: ${_summary?["absent_students"] ?? 0}"),
            pw.SizedBox(height: 20),
            
            
            pw.Table(
            border: pw.TableBorder.all(),
            children: [
            
           pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColors.grey300),
            children: headers.map((h) => pw.Padding(
           padding: const pw.EdgeInsets.all(5),
           child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
           )).toList(),
           ),
           
            ...data.map((row) => pw.TableRow(
           children: row.map((cell) => pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: pw.Text(cell.toString()),
           )).toList(),
          )),
          ],
          )
          ];
        },
      ),
    );

    // عرض معاينة الملف للطباعة أو الحفظ
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${widget.sessionName}_Attendance_Report.pdf',
    );
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        // عنوان الجلسة الحالية
        title: Text("Live: ${widget.sessionName}"),
        backgroundColor: Colors.deepPurple[800],
        foregroundColor: Colors.white,
        // أضيفي هذا الجزء هنا 👇
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _students.isEmpty ? null : _generatePdf, 
            tooltip: "Generate PDF Report",
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF4A148C), Color(0xFF311B92)],
          ),
        ),
        // عرض الحالة المناسبة: تحميل / خطأ / البيانات
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _error.isNotEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    // سحب لتحديث البيانات يدويًا
                    onRefresh: _fetchLiveAttendance,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildSummaryCard(),
                        const SizedBox(height: 12),
                        ..._students.map((student) => _buildStudentCard(student)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() 
  {
    // إحصائيات سريعة لعرض إجمالي العدد والحضور والغياب
    final total = _summary?["total_students"] ?? 0;
    final present = _summary?["present_students"] ?? 0;
    final absent = _summary?["absent_students"] ?? 0;

    return Card(
      color: Colors.white.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Total: $total   Present: $present   Absent: $absent",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
Widget _buildStudentCard(Map<String, dynamic> student) {
  // تحديد لون الحالة للعرض فقط
  Color statusColor = Colors.redAccent;
  if (student['status'] == 'Present') statusColor = Colors.green;
  if (student['status'] == 'Partially') statusColor = Colors.orange;

  return Card(
    color: Colors.white.withOpacity(0.1),
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor,
        child: Icon(
          student['status'] == 'Present' ? Icons.check : Icons.close,
          color: Colors.white, size: 18,
        ),
      ),
      title: Text(student['name'], style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text("ID: ${student['academic_id']}", style: const TextStyle(color: Colors.white70, fontSize: 12)),
      
      // الزر المطلوب 👇
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            student['status'],
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
            onSelected: (String newValue) => _changeStatus(student['student_id'], newValue),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Present', child: Text('Present (حاضر)')),
              const PopupMenuItem(value: 'Partially', child: Text('Partially (جزئي)')),
              const PopupMenuItem(value: 'Absent', child: Text('Absent (غائب)')),
            ],
          ),
        ],
      ),
    ),
  );
}
}
