
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyWeekApp());
}

const List<String> weekDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const Color purple = Color(0xFF7562C9);
const Color darkPurple = Color(0xFF292344);
const Color pageBackground = Color(0xFFF7F5FC);

class Course {
  final String id;
  final String name;
  final String day;
  final int startMinutes;
  final int endMinutes;

  const Course({
    required this.id,
    required this.name,
    required this.day,
    required this.startMinutes,
    required this.endMinutes,
  });

  int get durationMinutes => endMinutes - startMinutes;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'day': day,
      'startMinutes': startMinutes,
      'endMinutes': endMinutes,
    };
  }

  factory Course.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data()!;

    return Course(
      id: document.id,
      name: data['name'] as String,
      day: data['day'] as String,
      startMinutes: (data['startMinutes'] as num).toInt(),
      endMinutes: (data['endMinutes'] as num).toInt(),
    );
  }
}

int? parseTime(String value) {
  final match = RegExp(
    r'^([01]\d|2[0-3]):([0-5]\d)$',
  ).firstMatch(value.trim());

  if (match == null) return null;

  final hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);

  return hours * 60 + minutes;
}

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;

  return '${hours.toString().padLeft(2, '0')}:'
      '${remainingMinutes.toString().padLeft(2, '0')}';
}

String formatDuration(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';

  return '${hours}h ${minutes}m';
}

// Firestore location for the currently signed-in user.
CollectionReference<Map<String, dynamic>> userCoursesCollection() {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('You must be signed in.');
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('courses');
}

class MyWeekApp extends StatelessWidget {
  const MyWeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Week',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: pageBackground,
        appBarTheme: const AppBarTheme(
          backgroundColor: pageBackground,
          foregroundColor: darkPurple,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  String _selectedDay = 'Monday';

  Future<void> _saveCourse(Course course) async {
    await userCoursesCollection()
        .doc(course.id)
        .set(course.toMap());
  }

  Future<void> _deleteCourse(Course course) async {
    await userCoursesCollection().doc(course.id).delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} deleted'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddCourse(List<Course> courses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(
          selectedDay: _selectedDay,
          existingCourses: courses,
          onSave: _saveCourse,
        ),
      ),
    );
  }

  void _openEditCourse(Course course, List<Course> courses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(
          selectedDay: course.day,
          existingCourses: courses,
          course: course,
          onSave: _saveCourse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: userCoursesCollection().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Week')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Could not load your courses. Please check your '
                      'internet connection and Firestore settings.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: purple),
            ),
          );
        }

        final courses = snapshot.data!.docs
            .map((document) => Course.fromDocument(document))
            .toList();

        final selectedDayCourses = courses
            .where((course) => course.day == _selectedDay)
            .toList()
          ..sort(
                (a, b) => a.startMinutes.compareTo(b.startMinutes),
          );

        final totalWeeklyMinutes = courses.fold<int>(
          0,
              (total, course) => total + course.durationMinutes,
        );

        final totalDailyMinutes = selectedDayCourses.fold<int>(
          0,
              (total, course) => total + course.durationMinutes,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: purple),
                SizedBox(width: 9),
                Text(
                  'My Week',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                    fontSize: 23,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 22),
                  _buildSummaryCards(
                    courses.length,
                    totalWeeklyMinutes,
                  ),
                  const SizedBox(height: 25),
                  _buildDaySelector(),
                  const SizedBox(height: 18),
                  _buildDailySummary(
                    selectedDayCourses.length,
                    totalDailyMinutes,
                  ),
                  const SizedBox(height: 16),
                  _buildCourseList(
                    selectedDayCourses,
                    courses,
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openAddCourse(courses),
            backgroundColor: purple,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Course',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your week,',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const Text(
          'beautifully organized.',
          style: TextStyle(
            fontSize: 20,
            color: purple,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Plan your classes and make every hour count.',
          style: TextStyle(
            fontSize: 14,
            color: darkPurple.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(int courseCount, int weeklyMinutes) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.menu_book_rounded,
            label: 'Total courses',
            value: '$courseCount',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.schedule_rounded,
            label: 'Weekly hours',
            value: formatDuration(weeklyMinutes),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: purple, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: darkPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: darkPurple.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your timetable',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isSelected = day == _selectedDay;

              return ChoiceChip(
                label: Text(day.substring(0, 3)),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedDay = day;
                  });
                },
                selectedColor: purple,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : darkPurple,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: isSelected ? purple : Colors.transparent,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummary(int count, int dailyMinutes) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: purple.withOpacity(0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, color: purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$_selectedDay • $count courses',
              style: const TextStyle(
                color: darkPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatDuration(dailyMinutes),
            style: const TextStyle(
              color: purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(
      List<Course> dayCourses,
      List<Course> allCourses,
      ) {
    if (dayCourses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: 40,
          horizontal: 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: purple.withOpacity(0.55),
            ),
            const SizedBox(height: 14),
            const Text(
              'Nothing planned yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: darkPurple,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add a course to organize your day.',
              style: TextStyle(
                color: darkPurple.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: dayCourses.map((course) {
        return _courseCard(course, allCourses);
      }).toList(),
    );
  }

  Widget _courseCard(Course course, List<Course> allCourses) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: purple.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 65,
            decoration: BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: purple,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${formatMinutes(course.startMinutes)} - '
                          '${formatMinutes(course.endMinutes)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: darkPurple.withOpacity(0.65),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: darkPurple,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _openEditCourse(course, allCourses);
              } else if (value == 'delete') {
                _deleteCourse(course);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 19),
                    SizedBox(width: 9),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 19),
                    SizedBox(width: 9),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CourseFormScreen extends StatefulWidget {
  final String selectedDay;
  final List<Course> existingCourses;
  final Course? course;
  final Future<void> Function(Course) onSave;

  const CourseFormScreen({
    super.key,
    required this.selectedDay,
    required this.existingCourses,
    required this.onSave,
    this.course,
  });

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  late String _selectedDay;

  bool _isSaving = false;

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();

    _selectedDay = widget.course?.day ?? widget.selectedDay;

    _nameController = TextEditingController(
      text: widget.course?.name ?? '',
    );

    _startController = TextEditingController(
      text: widget.course == null
          ? ''
          : formatMinutes(widget.course!.startMinutes),
    );

    _endController = TextEditingController(
      text: widget.course == null
          ? ''
          : formatMinutes(widget.course!.endMinutes),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) return;

    final start = parseTime(_startController.text);
    final end = parseTime(_endController.text);

    if (start == null || end == null) return;

    if (end <= start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time.'),
        ),
      );
      return;
    }

    final hasOverlap = widget.existingCourses.any((course) {
      if (course.id == widget.course?.id) return false;
      if (course.day != _selectedDay) return false;

      return start < course.endMinutes &&
          end > course.startMinutes;
    });

    if (hasOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This course overlaps another course.'),
        ),
      );
      return;
    }

    final newCourse = Course(
      id: widget.course?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      day: _selectedDay,
      startMinutes: start,
      endMinutes: end,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(newCourse);

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save course: $error'),
        ),
      );

      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Course' : 'Add Course',
          style: const TextStyle(
            color: darkPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course details',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add the details of your class below.',
                  style: TextStyle(
                    color: darkPurple.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 25),

                const Text(
                  'Course name',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Software Engineering',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a course name.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'Day',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: weekDays.map((day) {
                    return DropdownMenuItem(
                      value: day,
                      child: Text(day),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDay = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'Start time',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _startController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: '08:00',
                    helperText: 'Use 24-hour format, e.g. 08:30',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || parseTime(value) == null) {
                      return 'Enter a valid time, e.g. 08:30.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'End time',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkPurple,
                  ),
                ),
                const SizedBox(height: 9),
                TextFormField(
                  controller: _endController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: '10:00',
                    helperText: 'Use 24-hour format, e.g. 10:00',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || parseTime(value) == null) {
                      return 'Enter a valid time, e.g. 10:00.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isSaving ? null : _saveCourse,
                    icon: _isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : (_isEditing ? 'Save Changes' : 'Add Course'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: purple,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
