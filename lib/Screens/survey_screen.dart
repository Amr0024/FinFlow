import 'package:flutter/material.dart';
import 'main_screen.dart'; // Import the main screen
import 'dart:math'; // Import for Random and pi

class SurveyScreen extends StatefulWidget {
  @override
  _SurveyScreenState createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  int _currentQuestionIndex = 0;
  Map<String, dynamic> _surveyResults = {};
  Set<String> _selectedGoals = {}; // Store selected financial goals

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'How often do you track your expenses?',
      'options': ['Daily', 'Weekly', 'Monthly', 'Rarely'],
    },
    {
      'question': 'On average, how much do you spend daily?',
      'options': ['Less than \$20', '\$20-\$50', '\$50-\$100', 'More than \$100'],
    },
    {
      'question': 'On average, how much do you spend monthly?',
      'options': ['Less than \$500', '\$500-\$1000', '\$1000-\$2000', 'More than \$2000'],
    },
    {
      'question': 'What is your age?',
      'options': ['Under 18', '18-24', '25-34', '35-44', '45-54', '55+'],
    },
    {
      'question': 'What is your gender? (Optional)',
      'options': ['Male', 'Female', 'Prefer not to say'],
    },
    {
      'question': 'Do you have any debt?',
      'options': ['Yes', 'No'],
      'skipCondition': (answer) => answer == 'No', // Skip next question if "No"
    },
    {
      'question': 'What type of debt do you have?',
      'options': ['Credit Card', 'Student Loan', 'Mortgage', 'Personal Loan', 'Other'],
      'conditional': true, // Only show if the user answered "Yes" to the previous question
    },
    {
      'question': 'Do you use your own car or public transportation?',
      'options': ['Own Car', 'Public Transportation', 'Both', 'Neither'],
    },
    {
      'question': 'How often do you want to track your expenses?',
      'options': ['Daily', 'Weekly', 'Monthly'],
    },
    {
      'question': 'What are your financial goals? (Select two that apply)',
      'options': [
        'Save for a big purchase',
        'Build an emergency fund',
        'Pay off debt',
        'Invest for the future',
        'Travel',
        'Other',
      ],
      'multiple': true, // Allow multiple selections
    },
  ];

  void _answerQuestion(String answer) {
    setState(() {
      if (_questions[_currentQuestionIndex]['multiple'] == true) {
        // Handle multiple selection for financial goals
        if (_selectedGoals.contains(answer)) {
          _selectedGoals.remove(answer); // Deselect if already selected
        } else {
          if (_selectedGoals.length < 2) {
            _selectedGoals.add(answer); // Select if less than 2 goals are selected
          }
        }

        // Automatically move to the next screen if two goals are selected
        if (_selectedGoals.length == 2) {
          _submitSurvey(); // Submit the survey and navigate to the next page
        }
      } else {
        // Save the answer for non-multiple choice questions
        _surveyResults[_questions[_currentQuestionIndex]['question']] = answer;

        // Check if the current question has a skip condition
        if (_questions[_currentQuestionIndex]['skipCondition'] != null) {
          bool shouldSkip = _questions[_currentQuestionIndex]['skipCondition'](answer);
          if (shouldSkip) {
            // Skip the next question if the condition is met
            _currentQuestionIndex++;
          }
        }

        // Move to the next question if not a multiple-choice question
        _currentQuestionIndex++;

        // If all questions are answered, submit the survey
        if (_currentQuestionIndex >= _questions.length) {
          _submitSurvey();
        }
      }
    });
  }

  void _submitSurvey() {
    // Save the selected financial goals to the survey results
    _surveyResults['Financial Goals'] = _selectedGoals.toList();

    // Handle survey submission
    print(_surveyResults); // For debugging

    // Navigate to the main screen and pass the selected goals and survey results
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreen(
          selectedGoals: _selectedGoals.toList(),
          surveyResults: _surveyResults, // Pass surveyResults here
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with gradient and hollow circles
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.purple[800]!], // Dark blue to purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.2, 0.8], // Smooth transition
                tileMode: TileMode.clamp, // Prevents weird lines
              ),
            ),
            child: CustomPaint(
              size: Size.infinite,
              painter: HollowCirclePainter(),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image at the top
                      Image.asset(
                        'assets/images/finflow_logo.png', // Replace with your image path
                        height: 150,
                      ),
                      SizedBox(height: 20),
                      // Progress Indicator
                      LinearProgressIndicator(
                        value: (_currentQuestionIndex + 1) / _questions.length,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                      SizedBox(height: 20),
                      // Question
                      Text(
                        _questions[_currentQuestionIndex]['question'],
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40),
                      // Buttons for options
                      if (_questions[_currentQuestionIndex]['multiple'] == true)
                        ..._questions[_currentQuestionIndex]['options'].map<Widget>((option) {
                          return Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton(
                              onPressed: () => _answerQuestion(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _selectedGoals.contains(option)
                                    ? Colors.purple.withOpacity(0.5)
                                    : Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList()
                      else
                        ..._questions[_currentQuestionIndex]['options'].map<Widget>((option) {
                          return Container(
                            width: double.infinity,
                            margin: EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton(
                              onPressed: () => _answerQuestion(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for hollow circles
class HollowCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white.withOpacity(0.1) // Light white color for circles
      ..style = PaintingStyle.stroke // Hollow circles
      ..strokeWidth = 2; // Circle border width

    final Random random = Random();

    // Draw multiple circles
    for (int i = 0; i < 50; i++) {
      final double radius = 20 + i * 10; // Vary the radius
      final double x = size.width * (i % 10) / 10; // Spread horizontally
      final double y = size.height * (i % 5) / 5; // Spread vertically

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No need to repaint
  }
}