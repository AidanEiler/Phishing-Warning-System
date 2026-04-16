/// Represents one of the nine experimental conditions in the 2x2x2 factorial design.
/// Eight conditions correspond to all combinations of the three binary independent
/// variables, plus one control condition with no warning displayed.
/// Each participant is assigned to exactly one condition for all three sessions.
class Condition {
  /// Condition number (1-9)
  /// Conditions 1-8 are the factorial combinations
  /// Condition 9 is the control (no warning)
  final int conditionNumber;

  /// Delivery mode for this condition
  /// Values: interruptive, passive, none (control)
  final String deliveryMode;

  /// Language specificity for this condition
  /// Values: generic, contextual, none (control)
  final String languageSpecificity;

  /// Visual presentation for this condition
  /// Values: static, polymorphic, none (control)
  final String visualPresentation;

  /// Whether this is the control condition (no warning displayed)
  final bool isControl;

  const Condition({
    required this.conditionNumber,
    required this.deliveryMode,
    required this.languageSpecificity,
    required this.visualPresentation,
    required this.isControl,
  });

  /// Returns a human-readable label for this condition
  /// Used in the experiment setup screen and CSV export
  String get label {
    if (isControl) return 'Condition 9 (Control - No Warning)';
    return 'Condition $conditionNumber '
        '($deliveryMode / $languageSpecificity / $visualPresentation)';
  }

  /// All nine experimental conditions as a static list.
  /// Conditions 1-8 are the fully crossed factorial combinations.
  /// Condition 9 is the control with no warning.
  static final List<Condition> allConditions = [
    const Condition(
      conditionNumber: 1,
      deliveryMode: 'interruptive',
      languageSpecificity: 'generic',
      visualPresentation: 'static',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 2,
      deliveryMode: 'interruptive',
      languageSpecificity: 'generic',
      visualPresentation: 'polymorphic',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 3,
      deliveryMode: 'interruptive',
      languageSpecificity: 'contextual',
      visualPresentation: 'static',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 4,
      deliveryMode: 'interruptive',
      languageSpecificity: 'contextual',
      visualPresentation: 'polymorphic',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 5,
      deliveryMode: 'passive',
      languageSpecificity: 'generic',
      visualPresentation: 'static',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 6,
      deliveryMode: 'passive',
      languageSpecificity: 'generic',
      visualPresentation: 'polymorphic',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 7,
      deliveryMode: 'passive',
      languageSpecificity: 'contextual',
      visualPresentation: 'static',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 8,
      deliveryMode: 'passive',
      languageSpecificity: 'contextual',
      visualPresentation: 'polymorphic',
      isControl: false,
    ),
    const Condition(
      conditionNumber: 9,
      deliveryMode: 'none',
      languageSpecificity: 'none',
      visualPresentation: 'none',
      isControl: true,
    ),
  ];

  @override
  String toString() => label;
}