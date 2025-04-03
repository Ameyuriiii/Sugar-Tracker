// ActivityManagerPage: This page allows users to manage their activities.
// It displays a list of activities, enables adding, editing, and deleting activities,
// and provides sorting and searching functionalities.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Activity model class to represent an activity
class Activity {
  String id;
  String name;
  String description;
  DateTime time;
  bool isDone;
  String userId;

  Activity({
    required this.id,
    required this.name,
    required this.description,
    required this.time,
    required this.userId,
    this.isDone = false,
  });

  factory Activity.fromDocument(DocumentSnapshot doc) => Activity(
    id: doc.id,
    name: doc['name'] ?? 'Unnamed',
    description: doc['description'] ?? '',
    time: (doc['time'] as Timestamp).toDate(),
    userId: doc['userId'] ?? '',
    isDone: doc['isDone'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'time': time,
    'userId': userId,
    'isDone': isDone,
  };
}

class ActivityManagerPage extends StatefulWidget {
  const ActivityManagerPage({super.key});

  @override
  State<ActivityManagerPage> createState() => _ActivityManagerPageState();
}

class _ActivityManagerPageState extends State<ActivityManagerPage> {
  String _sortBy = 'time';
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to delete an activity and show a snackbar with undo option
  Future<void> _deleteActivity(String id, String name) async {
    final activitiesRef = FirebaseFirestore.instance.collection('activities');
    try {
      await activitiesRef.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Undo not implemented yet')),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        // Show login message if user is not authenticated
        body: Center(child: Text("Please log in first.", style: TextStyle(fontSize: 18))),
      );
    }

    final activitiesRef = FirebaseFirestore.instance.collection('activities');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          'Activity Manager',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) {
              setState(() {
                if (_sortBy == value) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortBy = value;
                  _sortAscending = false;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'time', child: Text('Sort by Time')),
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'isDone', child: Text('Sort by Status')),
            ],
            tooltip: 'Sort Options',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search activities...',
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            // List of alllll activities
            child: StreamBuilder<QuerySnapshot>(
              stream: activitiesRef
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy, size: 60, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No activities added yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _openActivityDialog(context, activitiesRef),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add Your First Activity', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                final activities = docs.map((e) => Activity.fromDocument(e)).toList();

                activities.sort((a, b) {
                  int comparison;
                  switch (_sortBy) {
                    case 'name':
                      comparison = a.name.compareTo(b.name);
                      break;
                    case 'isDone':
                      comparison = (a.isDone ? 1 : 0).compareTo(b.isDone ? 1 : 0);
                      break;
                    case 'time':
                    default:
                      comparison = a.time.compareTo(b.time);
                      break;
                  }
                  return _sortAscending ? comparison : -comparison;
                });

                // Filter activities based on search query
                final filteredActivities = activities
                    .where((activity) =>
                activity.name.toLowerCase().contains(_searchQuery) ||
                    activity.description.toLowerCase().contains(_searchQuery))
                    .toList();

                debugPrint('Docs fetched: ${docs.length}, Filtered: ${filteredActivities.length}');
                // Build list of activity cards
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    return Dismissible(
                      key: Key(activity.id),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: Text('Are you sure you want to delete "${activity.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _deleteActivity(activity.id, activity.name);
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Checkbox(
                                value: activity.isDone,
                                onChanged: (newValue) async {
                                  if (newValue != null) {
                                    await activitiesRef.doc(activity.id).update({'isDone': newValue});
                                  }
                                },
                                activeColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple,
                                        decoration: activity.isDone ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    if (activity.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        activity.description,
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d, yyyy – HH:mm').format(activity.time),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _openActivityDialog(context, activitiesRef, activity: activity),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      final confirm = await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirm Delete'),
                                          content: Text('Are you sure you want to delete "${activity.name}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        _deleteActivity(activity.id, activity.name);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Floating action button to add new activity
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openActivityDialog(context, activitiesRef),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        tooltip: 'Add Activity',
      ),
    );
  }

// Function to open dialog for adding or editing an activity
  void _openActivityDialog(BuildContext context, CollectionReference ref, {Activity? activity}) {
    final user = FirebaseAuth.instance.currentUser!;
    final nameController = TextEditingController(text: activity?.name);
    final descController = TextEditingController(text: activity?.description);
    DateTime selectedDate = activity?.time ?? DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            activity == null ? 'Add Activity' : 'Edit Activity',
            style: const TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.deepPurple[50],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.description, color: Colors.deepPurple),
                    filled: true,
                    fillColor: Colors.deepPurple[50],
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.deepPurple),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        DateFormat('yyyy-MM-dd – HH:mm').format(selectedDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                            setDialogState(() {});
                          }
                        }
                      },
                      child: const Text('Change', style: TextStyle(color: Colors.deepPurple)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                setDialogState(() => isSaving = true);
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Title cannot be empty')),
                  );
                  setDialogState(() => isSaving = false);
                  return;
                }
                final newActivity = {
                  'name': name,
                  'description': descController.text.trim(),
                  'time': selectedDate,
                  'userId': user.uid,
                  'isDone': activity?.isDone ?? false,
                };
                if (activity == null) {
                  await ref.add(newActivity);
                  debugPrint('Added activity: $newActivity');
                } else {
                  await ref.doc(activity.id).update(newActivity);
                  debugPrint('Updated activity: $newActivity');
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSaving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}