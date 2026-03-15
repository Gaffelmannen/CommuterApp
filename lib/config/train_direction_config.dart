class TrainLineDirectionRule {
  const TrainLineDirectionRule({
    required this.northboundDestinations,
    required this.southboundDestinations,
  });

  final List<String> northboundDestinations;
  final List<String> southboundDestinations;
}

class TrainDirectionConfig {
  // Global fallback keywords used when a line-specific rule does not match.
  static const List<String> northboundDestinations = [
    'stockholm',
    'stockholm city',
    'city',
    'odenplan',
    'solna',
    'sundbyberg',
    'ulriksdal',
    'helenelund',
    'upplands vasby',
    'arlanda',
    'marsta',
    'uppsala',
    'balsta',
    'kallhall',
    'jakobsberg',
    'spanga',
  ];

  static const List<String> southboundDestinations = [
    'sodertalje',
    'sodertalje centrum',
    'sodertalje hamn',
    'tumba',
    'ronsninge',
    'tullinge',
    'flemingsberg',
    'huddinge',
    'stuvsta',
    'nynashamn',
    'vasterhaninge',
    'segersang',
    'jorna',
    'gnesta',
  ];

  // Line-based rules. Add more here as needed.
  static const Map<String, TrainLineDirectionRule> lineRules = {
    '40': TrainLineDirectionRule(
      northboundDestinations: [
        'stockholm',
        'stockholm city',
        'city',
        'odenplan',
        'solna',
        'upplands vasby',
        'arlanda',
        'uppsala',
      ],
      southboundDestinations: [
        'sodertalje',
        'sodertalje centrum',
        'sodertalje hamn',
      ],
    ),
    '41': TrainLineDirectionRule(
      northboundDestinations: [
        'stockholm',
        'stockholm city',
        'city',
        'odenplan',
        'solna',
        'marsta',
      ],
      southboundDestinations: [
        'sodertalje',
        'sodertalje centrum',
        'sodertalje hamn',
      ],
    ),
    '43': TrainLineDirectionRule(
      northboundDestinations: [
        'stockholm',
        'stockholm city',
        'city',
        'balsta',
      ],
      southboundDestinations: [
        'nynashamn',
      ],
    ),
    '44': TrainLineDirectionRule(
      northboundDestinations: [
        'stockholm',
        'stockholm city',
        'city',
        'balsta',
      ],
      southboundDestinations: [
        'sodertalje',
        'sodertalje centrum',
        'sodertalje hamn',
      ],
    ),
    '48': TrainLineDirectionRule(
      northboundDestinations: [
        'stockholm',
        'stockholm city',
        'city',
        'gnesta',
      ],
      southboundDestinations: [
        'marsta',
      ],
    ),
  };
}