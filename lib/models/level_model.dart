class TargetWord {
  final String word;
  final int type; // 0 = normal, 2 = highlighted/bonus

  const TargetWord({
    required this.word,
    required this.type,
  });

  factory TargetWord.fromJson(Map<String, dynamic> json) {
    return TargetWord(
      word: (json['word'] as String).toUpperCase().trim(),
      type: json['type'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'type': type,
      };
}

class ObstacleCell {
  final int x;
  final int y;

  const ObstacleCell({required this.x, required this.y});

  factory ObstacleCell.fromJson(Map<String, dynamic> json) {
    return ObstacleCell(
      x: json['x'] as int,
      y: json['y'] as int,
    );
  }

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

class ObstacleModel {
  final int id;
  final int requiredWords;
  final int type;
  final List<ObstacleCell> cells;

  const ObstacleModel({
    required this.id,
    required this.requiredWords,
    required this.type,
    required this.cells,
  });

  factory ObstacleModel.fromJson(Map<String, dynamic> json) {
    return ObstacleModel(
      id: json['id'] as int? ?? 0,
      requiredWords: json['required_words'] as int? ?? 0,
      type: json['type'] as int? ?? 0,
      cells: (json['cells'] as List? ?? [])
          .map((c) => ObstacleCell.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LetterTile {
  final int row;
  final int col;
  final String letter;
  int count; // remaining times this letter must be used
  final int initialCount;
  bool isObstacleLocked;
  int? obstacleRequiredWords;
  bool isCleared;

  LetterTile({
    required this.row,
    required this.col,
    required this.letter,
    required this.count,
    required this.initialCount,
    this.isObstacleLocked = false,
    this.obstacleRequiredWords,
    this.isCleared = false,
  });

  LetterTile copyWith({
    int? count,
    bool? isObstacleLocked,
    bool? isCleared,
  }) {
    return LetterTile(
      row: row,
      col: col,
      letter: letter,
      count: count ?? this.count,
      initialCount: initialCount,
      isObstacleLocked: isObstacleLocked ?? this.isObstacleLocked,
      obstacleRequiredWords: obstacleRequiredWords,
      isCleared: isCleared ?? this.isCleared,
    );
  }
}

class LevelModel {
  final int id;
  final int width;
  final int height;
  final List<TargetWord> targetWords;
  final List<TargetWord> extraWords;
  final List<List<String>> letterGrid;
  final List<ObstacleModel> obstacles;

  const LevelModel({
    required this.id,
    required this.width,
    required this.height,
    required this.targetWords,
    required this.extraWords,
    required this.letterGrid,
    required this.obstacles,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    final lettersRaw = (json['letters'] as String? ?? '').toUpperCase();
    final rows = lettersRaw.split(',');
    final grid = rows.map((r) => r.split('')).toList();

    return LevelModel(
      id: json['id'] as int,
      width: json['width'] as int,
      height: json['height'] as int,
      targetWords: (json['target_words'] as List? ?? [])
          .map((w) => TargetWord.fromJson(w as Map<String, dynamic>))
          .toList(),
      extraWords: (json['extra_words'] as List? ?? [])
          .map((w) => TargetWord.fromJson(w as Map<String, dynamic>))
          .toList(),
      letterGrid: grid,
      obstacles: (json['obstacles'] as List? ?? [])
          .map((o) => ObstacleModel.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
