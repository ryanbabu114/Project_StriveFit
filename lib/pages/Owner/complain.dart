import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintsList extends StatefulWidget {
  @override
  _ComplaintsListState createState() => _ComplaintsListState();
}

class _ComplaintsListState extends State<ComplaintsList> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> complaints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await supabase.from('complaints').select('*');

      setState(() {
        complaints = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching complaints: $error");
      setState(() => isLoading = false);
      _showErrorSnackbar("Failed to load complaints. Please try again.");
    }
  }

  Future<void> _deleteComplaint(int id) async {
    try {
      await supabase.from('complaints').delete().eq('id', id);
      _showSuccessSnackbar("Complaint deleted.");
      _fetchComplaints();
    } catch (e) {
      _showErrorSnackbar("Failed to delete complaint.");
    }
  }

  Future<void> _resolveComplaint(int id) async {
    try {
      await supabase.from('complaints').update({'status': 'resolved'}).eq('id', id);
      _showSuccessSnackbar("Complaint marked as resolved.");
      _fetchComplaints();
    } catch (e) {
      _showErrorSnackbar("Failed to resolve complaint.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complaints List')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : complaints.isEmpty
          ? Center(child: Text('No complaints found.'))
          : ListView.builder(
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final complaint = complaints[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                complaint['name'] ?? 'No name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email: ${complaint['from_email'] ?? 'N/A'}'),
                  SizedBox(height: 5),
                  Text('Complaint: ${complaint['Complain'] ?? 'N/A'}'),
                  SizedBox(height: 5),
                  Text('Status: ${complaint['status'] ?? 'pending'}'),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteComplaint(complaint['id']);
                  } else if (value == 'resolve') {
                    _resolveComplaint(complaint['id']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'resolve',
                    child: Text('Mark as Resolved'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
