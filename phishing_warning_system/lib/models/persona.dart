/// Represents a simulated participant in the experiment.
/// Each persona has a unique ID and five demographic/behavioral variables
/// that influence how the AI agent simulates phishing susceptibility.
class Persona {
  /// Unique identifier for this participant
  final String id;

  /// Age of the simulated participant (18-65)
  final int age;

  /// Sex of the simulated participant (male, female, non-binary)
  final String sex;

  /// Level of prior cybersecurity training
  /// Values: none, minimal, moderate, extensive
  final String cybersecurityTraining;

  /// Average daily messaging app usage in hours, rounded to nearest integer
  final int dailyMessagingUsage;

  /// Current stress level at time of experiment session
  /// Values: low, moderate, high
  final String stressLevel;

  const Persona({
    required this.id,
    required this.age,
    required this.sex,
    required this.cybersecurityTraining,
    required this.dailyMessagingUsage,
    required this.stressLevel,
  });

  /// Converts the persona to a map for use in CSV export and API prompts
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age': age,
      'sex': sex,
      'cybersecurity_training': cybersecurityTraining,
      'daily_messaging_usage': dailyMessagingUsage,
      'stress_level': stressLevel,
    };
  }

  /// Returns a human-readable summary of the persona
  /// Used during researcher review before each session
  @override
  String toString() {
    return 'Persona(id: $id, age: $age, sex: $sex, '
        'training: $cybersecurityTraining, '
        'usage: ${dailyMessagingUsage}h/day, '
        'stress: $stressLevel)';
  }
}