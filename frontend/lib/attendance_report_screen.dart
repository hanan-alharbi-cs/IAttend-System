import 'package:flutter/material.dart';


class AttendanceReportScreen extends StatelessWidget
 {
  const AttendanceReportScreen({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B46), 
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "ATTENDANCE REPORT",
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Expanded(
                  child: _buildExportButton(
                    title: "Excel (Editable)",
                    subtitle: "For manual editing",
                    icon: Icons.table_chart,
                    color: const Color(0xFF2ecc71), 
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildExportButton(
                    title: "PDF (Official)",
                    subtitle: "Ready to print",
                    icon: Icons.picture_as_pdf,
                    color: const Color(0xFFe74c3c), 
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Choose your preferred format to save or share the report.",
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Expanded(
            child: Center(
              child: Text(
                "No records found",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildExportButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) 
  {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              subtitle,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}