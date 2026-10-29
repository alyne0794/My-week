
import 'package:flutter/material.dart';

void main() {
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
          elevation: 1,
          shadowColor: purple.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF9F8FD),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE6E1F2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: purple,
              width: 1.5,
            ),
          ),
        ),
      ),
      home: const TimetableScreen(),
    );
  }
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<Course> _courses = [
    const Course(
      id: '1',
      name: 'Mobile Programming',
      day: 'Monday',
      startMinutes: 9 * 60,
      endMinutes: 10 * 60,
    ),
    const Course(
      id: '2',
      name: 'Database Systems',
      day: 'Monday',
      startMinutes: 9 * 60 + 30,
      endMinutes: 10 * 60 + 30,
    ),
    const Course(
      id: '3',
      name: 'Software Engineering',
      day: 'Tuesday',
      startMinutes: 8 * 60,
      endMinutes: 10 * 60,
    ),
    const Course(
      id: '4',
      name: 'Web Development',
      day: 'Wednesday',
      startMinutes: 10 * 60,
      endMinutes: 12 * 60,
    ),
    const Course(
      id: '5',
      name: 'Computer Networks',
      day: 'Friday',
      startMinutes: 13 * 60,
      endMinutes: 15 * 60,
    ),
  ];

  List<Course> _coursesForDay(String day) {
    final result = _courses
        .where((course) => course.day == day)
        .toList();

    result.sort(
          (a, b) => a.startMinutes.compareTo(b.startMinutes),
    );

    return result;
  }

  bool _overlaps(Course first, Course second) {
    return first.startMinutes < second.endMinutes &&
        second.startMinutes < first.endMinutes;
  }

  List<Course> _clashingCourses(Course course) {
    return _courses.where((other) {
      return other.id != course.id &&
          other.day == course.day &&
          _overlaps(course, other);
    }).toList();
  }

  int _dailyMinutes(String day) {
    return _coursesForDay(day).fold(
      0,
          (total, course) => total + course.durationMinutes,
    );
  }

  int get _weeklyMinutes {
    return _courses.fold(
      0,
          (total, course) => total + course.durationMinutes,
    );
  }

  Future<void> _addCourse() async {
    final newCourse = await Navigator.push<Course>(
      context,
      MaterialPageRoute(
        builder: (_) => const CourseFormScreen(),
      ),
    );

    if (!mounted || newCourse == null) return;

    setState(() {
      _courses.add(newCourse);
    });
  }

  Future<void> _editCourse(Course course) async {
    final updatedCourse = await Navigator.push<Course>(
      context,
      MaterialPageRoute(
        builder: (_) => CourseFormScreen(course: course),
      ),
    );

    if (!mounted || updatedCourse == null) return;

    setState(() {
      final index = _courses.indexWhere(
            (item) => item.id == updatedCourse.id,
      );

      if (index != -1) {
        _courses[index] = updatedCourse;
      }
    });
  }

  Future<void> _deleteCourse(Course course) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          'Are you sure you want to delete "${course.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || shouldDelete != true) return;

    setState(() {
      _courses.removeWhere((item) => item.id == course.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${course.name} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              if (!_courses.any(
                    (item) => item.id == course.id,
              )) {
                _courses.add(course);
              }
            });
          },
        ),
      ),
    );
  }

  Color _dayColor(String day) {
    switch (day) {
      case 'Monday':
        return const Color(0xFF7562C9);
      case 'Tuesday':
        return const Color(0xFF3987B8);
      case 'Wednesday':
        return const Color(0xFF399B83);
      case 'Thursday':
        return const Color(0xFFD58B42);
      case 'Friday':
        return const Color(0xFFCE668B);
      default:
        return const Color(0xFF64748B);
    }
  }

  Widget _buildCourseCard(Course course) {
    final clashes = _clashingCourses(course);
    final hasClash = clashes.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: hasClash
          ? const Color(0xFFFFF8F4)
          : const Color(0xFFFCFBFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: hasClash
              ? const Color(0xFFFFD4BF)
              : const Color(0xFFECE8F5),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _editCourse(course),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: hasClash ? 82 : 62,
                decoration: BoxDecoration(
                  color: hasClash ? Colors.deepOrange : purple,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                        Flexible(
                          child: Text(
                            '${formatMinutes(course.startMinutes)}'
                                ' – '
                                '${formatMinutes(course.endMinutes)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF554F6C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDuration(course.durationMinutes),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (hasClash) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE9DD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.deepOrange,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Clashes with: '
                                    '${clashes.map((c) => c.name).join(', ')}',
                                style: const TextStyle(
                                  color: Color(0xFF9A3D10),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Course actions',
                onSelected: (value) {
                  if (value == 'edit') {
                    _editCourse(course);
                  } else if (value == 'delete') {
                    _deleteCourse(course);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySection(String day) {
    final dayCourses = _coursesForDay(day);
    final color = _dayColor(day);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFECE8F5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF33245C).withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day,
                      style: const TextStyle(
                        color: darkPurple,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dayCourses.isEmpty
                          ? 'Free day'
                          : '${dayCourses.length} '
                          '${dayCourses.length == 1 ? 'class' : 'classes'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatDuration(_dailyMinutes(day)),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (dayCourses.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F7FC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: Colors.grey.shade500,
                    size: 21,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No classes on $day',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...dayCourses.map(_buildCourseCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCourse,
        backgroundColor: purple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add course',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF7562C9),
                      Color(0xFF9B88E5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: purple.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'YOUR WEEK AT A GLANCE',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      formatDuration(_weeklyMinutes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Total scheduled class hours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _summaryItem(
                          Icons.menu_book_rounded,
                          '${_courses.length}',
                          'Courses',
                        ),
                        const SizedBox(width: 22),
                        _summaryItem(
                          Icons.calendar_view_week_rounded,
                          '${_courses.map((c) => c.day).toSet().length}',
                          'Active days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Weekly timetable',
                      style: TextStyle(
                        color: darkPurple,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'MON – SUN',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: weekDays.map(_buildDaySection).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(
      IconData icon,
      String value,
      String label,
      ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 19),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class CourseFormScreen extends StatefulWidget {
  final Course? course;

  const CourseFormScreen({super.key, this.course});

  @override
  State<CourseFormScreen> createState() => _CourseFormScreenState();
}

class _CourseFormScreenState extends State<CourseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  String _selectedDay = 'Monday';

  bool get _isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();

    final course = widget.course;

    _nameController = TextEditingController(
      text: course?.name ?? '',
    );
    _startController = TextEditingController(
      text: course == null
          ? ''
          : formatMinutes(course.startMinutes),
    );
    _endController = TextEditingController(
      text: course == null
          ? ''
          : formatMinutes(course.endMinutes),
    );

    if (course != null) {
      _selectedDay = course.day;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  String? _validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a time';
    }

    if (parseTime(value) == null) {
      return 'Use 24-hour HH:MM format, e.g. 09:30';
    }

    return null;
  }

  void _saveCourse() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final start = parseTime(_startController.text)!;
    final end = parseTime(_endController.text)!;

    if (end <= start) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid time: End time must be later than start time.',
          ),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final course = Course(
      id: widget.course?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      day: _selectedDay,
      startMinutes: start,
      endMinutes: end,
    );

    Navigator.pop(context, course);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Course' : 'Add Course',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: darkPurple,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7562C9),
                      Color(0xFF9B88E5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 35,
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Course details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Organize your study week',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Course name',
                style: TextStyle(
                  color: darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Mobile Programming',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a course name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Day of the week',
                style: TextStyle(
                  color: darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDay,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today_outlined),
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
                  color: darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _startController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  hintText: '09:00',
                  helperText: 'Use 24-hour format, e.g. 09:00',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
                validator: _validateTime,
              ),
              const SizedBox(height: 20),
              const Text(
                'End time',
                style: TextStyle(
                  color: darkPurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _endController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  hintText: '11:00',
                  helperText: 'Must be later than the start time',
                  prefixIcon: Icon(Icons.schedule_outlined),
                ),
                validator: _validateTime,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _saveCourse,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Add Course',
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
