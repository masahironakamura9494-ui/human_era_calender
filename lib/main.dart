import 'package:flutter/material.dart';

void main() {
  runApp(const HumanEraCalendarApp());
}

class HumanEraCalendarApp extends StatelessWidget {
  const HumanEraCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Human Era Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: const CalendarGridViewScreen(),
    );
  }
}

// Model to hold journal entry data
class JournalEntry {
  String text;
  String mood; // 'good', 'neutral', 'bad'

  JournalEntry({required this.text, required this.mood});
}

class CalendarGridViewScreen extends StatefulWidget {
  const CalendarGridViewScreen({super.key});

  @override
  State<CalendarGridViewScreen> createState() => _CalendarGridViewScreenState();
}

class _CalendarGridViewScreenState extends State<CalendarGridViewScreen> {
  // 1. DATA PREP: Spring-Aligned Custom Month Names
  final List<String> humanMonthNames = [
    "Primavera", "Floralia", "Verdant", "Solstia", "Aestival", "Messis", 
    "Equinox", "Bruma", "Frigor", "Hibernal", "Gelu", "Thaw", "Interim"
  ];

  late int _currentHEMonth;

  // JOURNAL DATA STORAGE: Maps "YYYY-MM-DD" -> JournalEntry
  final Map<String, JournalEntry> _journalEntries = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    DateTime springEquinox = DateTime(now.year, 3, 20);
    
    // Adjust if current date is before Spring Equinox
    if (now.isBefore(springEquinox)) {
      springEquinox = DateTime(now.year - 1, 3, 20);
    }
    
    int daysPassed = now.difference(springEquinox).inDays + 1;
    
    if (daysPassed <= 336) {
      _currentHEMonth = ((daysPassed - 1) / 28).floor() + 1;
    } else {
      _currentHEMonth = 13;
    }
  }

  // HELPER 1: Convert HE Day relative to March 20 anchor into Gregorian Date
  DateTime getGregorianDate(int heDayOfYear, int currentYear) {
    DateTime anchor = DateTime(currentYear, 3, 20);
    return anchor.add(Duration(days: heDayOfYear - 1));
  }

  // HELPER 2: Dynamic Days (28 for Months 1-12; 29 or 30 for Month 13)
  int getDaysInMonth(int month, int year) {
    if (month < 13) return 28;
    bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
    return isLeapYear ? 30 : 29;
  }

  // HELPER 3: Calculate Lunar Phase (0.0 = New, 0.5 = Full, 1.0 = New)
  double getMoonPhase(DateTime date) {
    DateTime knownNewMoon = DateTime(2024, 1, 11, 11, 57);
    double daysSinceNew = date.difference(knownNewMoon).inHours / 24.0;
    double synodicMonth = 29.53058867;
    
    double phase = (daysSinceNew % synodicMonth) / synodicMonth;
    return phase < 0 ? phase + 1.0 : phase;
  }

  // HELPER 4: Generate key for map storage (e.g., "2026-7-23")
  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  // POPUP DIALOG: Opens when tapping a date block
  void _openJournalDialog(DateTime date, String heDateLabel) {
    String key = _getDateKey(date);
    JournalEntry? existingEntry = _journalEntries[key];

    TextEditingController controller = TextEditingController(
      text: existingEntry?.text ?? '',
    );
    String selectedMood = existingEntry?.mood ?? 'good';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Journal Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '$heDateLabel (${date.day}/${date.month}/${date.year})', 
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mood selector buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMoodIconButton('good', '😊', selectedMood, (newMood) {
                          setDialogState(() => selectedMood = newMood);
                        }),
                        _buildMoodIconButton('neutral', '😐', selectedMood, (newMood) {
                          setDialogState(() => selectedMood = newMood);
                        }),
                        _buildMoodIconButton('bad', '☹️', selectedMood, (newMood) {
                          setDialogState(() => selectedMood = newMood);
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Text Input Field
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Write your thoughts for today...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (controller.text.trim().isEmpty) {
                        _journalEntries.remove(key); // Clear entry if text is empty
                      } else {
                        _journalEntries[key] = JournalEntry(
                          text: controller.text,
                          mood: selectedMood,
                        );
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMoodIconButton(String moodKey, String emoji, String currentMood, Function(String) onTap) {
    bool isSelected = moodKey == currentMood;
    return GestureDetector(
      onTap: () => onTap(moodKey),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.shade50 : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Human Era Calendar Grid'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Month Navigation Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back), 
                  onPressed: () {
                    if (_currentHEMonth > 1) setState(() => _currentHEMonth--);
                  },
                ),
                Text(
                  humanMonthNames[_currentHEMonth - 1].toUpperCase(),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward), 
                  onPressed: () {
                    if (_currentHEMonth < 13) setState(() => _currentHEMonth++);
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Weekday Headers (Transparent background, 3-letter labels)
            Row(
              children: weekdays.map((day) => Expanded(
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    day, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                  ),
                )
              )).toList(),
            ),

            // 28-30 Day Interactive Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.0,
                ),
                itemCount: getDaysInMonth(_currentHEMonth, now.year),
                itemBuilder: (context, index) {
                  int dayOfMonth = index + 1;
                  int totalDayOfYear = ((_currentHEMonth - 1) * 28) + dayOfMonth;

                  final gregDateForThisDay = getGregorianDate(totalDayOfYear, now.year);
                  bool isToday = gregDateForThisDay.day == now.day && gregDateForThisDay.month == now.month;

                  bool isEquinoxDay = _currentHEMonth == 13 && dayOfMonth > 28;
                  bool isEvenGregMonth = gregDateForThisDay.month % 2 == 0;

                  double moonPhase = getMoonPhase(gregDateForThisDay);

                  // Check if a journal entry exists for this day
                  String dateKey = _getDateKey(gregDateForThisDay);
                  JournalEntry? entry = _journalEntries[dateKey];

                  Color tileBackgroundColor;
                  Color textColor;
                  Color subTextColor;

                  if (isEquinoxDay) {
                    tileBackgroundColor = Colors.red.shade700;
                    textColor = Colors.white;
                    subTextColor = Colors.white;
                  } else {
                    tileBackgroundColor = isEvenGregMonth ? Colors.black : Colors.white;
                    textColor = isEvenGregMonth ? Colors.white : Colors.black;
                    subTextColor = isEvenGregMonth ? Colors.white70 : Colors.black54;
                  }

                  String currentMonthName = humanMonthNames[_currentHEMonth - 1];
                  String heDateLabel = "$currentMonthName, Day $dayOfMonth";

                  return GestureDetector(
                    onTap: () => _openJournalDialog(gregDateForThisDay, heDateLabel),
                    child: Container(
                      margin: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                        color: tileBackgroundColor,
                        borderRadius: BorderRadius.circular(12.0),
                        border: isToday
                            ? Border.all(color: Colors.deepPurpleAccent, width: 3.0)
                            : Border.all(
                                color: isEquinoxDay 
                                    ? Colors.transparent 
                                    : (isEvenGregMonth ? Colors.transparent : Colors.black12),
                                width: 1.0,
                              ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Top row: Moon Phase & Mood Icon overlay
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(10, 10),
                                painter: MoonPhasePainter(
                                  phase: moonPhase,
                                  outlineColor: subTextColor,
                                ),
                              ),
                              if (entry != null) ...[
                                const SizedBox(width: 4),
                                Text(
                                  entry.mood == 'good'
                                      ? '😊'
                                      : (entry.mood == 'neutral' ? '😐' : '☹️'),
                                  style: const TextStyle(fontSize: 9),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),

                          // Equinox Day Header Label
                          if (isEquinoxDay) ...[
                            Text(
                              'EQUINOX',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: subTextColor,
                              ),
                            ),
                            const SizedBox(height: 1),
                          ],

                          // HE Day Number
                          Text(
                            '$dayOfMonth',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),

                          // Gregorian Date Label
                          if (!isEquinoxDay) ...[
                            const SizedBox(height: 1),
                            Text(
                              '${gregDateForThisDay.day}/${gregDateForThisDay.month}',
                              style: TextStyle(
                                fontSize: 9,
                                color: subTextColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// CUSTOM PAINTER: Draws vector Moon Phase graphics programmatically
class MoonPhasePainter extends CustomPainter {
  final double phase;
  final Color outlineColor;

  MoonPhasePainter({required this.phase, required this.outlineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final Paint outlinePaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final Paint fillPaint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, outlinePaint);

    if (phase < 0.03 || phase > 0.97) {
      return;
    }

    if (phase >= 0.47 && phase <= 0.53) {
      canvas.drawCircle(center, radius - 0.5, fillPaint);
      return;
    }

    final Path illuminatedPath = Path();

    if (phase < 0.5) {
      illuminatedPath.addArc(Rect.fromCircle(center: center, radius: radius), -1.5708, 3.14159);

      double curveFactor = (phase < 0.25)
          ? 1.0 - (phase / 0.25)
          : -((phase - 0.25) / 0.25);

      Rect innerOval = Rect.fromCenter(
        center: center,
        width: radius * 2 * curveFactor.abs(),
        height: radius * 2,
      );

      if (phase < 0.25) {
        Path innerPath = Path()..addArc(innerOval, -1.5708, 3.14159);
        Path finalPath = Path.combine(PathOperation.difference, illuminatedPath, innerPath);
        canvas.drawPath(finalPath, fillPaint);
      } else {
        Path innerPath = Path()..addArc(innerOval, 1.5708, 3.14159);
        Path finalPath = Path.combine(PathOperation.union, illuminatedPath, innerPath);
        canvas.drawPath(finalPath, fillPaint);
      }
    } else {
      illuminatedPath.addArc(Rect.fromCircle(center: center, radius: radius), 1.5708, 3.14159);

      double normPhase = phase - 0.5;
      double curveFactor = (normPhase < 0.25)
          ? (normPhase / 0.25)
          : -(1.0 - ((normPhase - 0.25) / 0.25));

      Rect innerOval = Rect.fromCenter(
        center: center,
        width: radius * 2 * curveFactor.abs(),
        height: radius * 2,
      );

      if (normPhase < 0.25) {
        Path innerPath = Path()..addArc(innerOval, -1.5708, 3.14159);
        Path finalPath = Path.combine(PathOperation.union, illuminatedPath, innerPath);
        canvas.drawPath(finalPath, fillPaint);
      } else {
        Path innerPath = Path()..addArc(innerOval, 1.5708, 3.14159);
        Path finalPath = Path.combine(PathOperation.difference, illuminatedPath, innerPath);
        canvas.drawPath(finalPath, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MoonPhasePainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.outlineColor != outlineColor;
  }
}