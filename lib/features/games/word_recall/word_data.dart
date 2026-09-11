// lib/features/games/word_recall/word_data.dart
//
// Word banks, level configurations, and distraction questions
// ported directly from WordRecall.jsx.

class WordItem {
  final String word;
  final String emoji;

  const WordItem({required this.word, required this.emoji});
}

const List<WordItem> kWordBankL1 = [
  WordItem(word: 'Mango', emoji: '🥭'),
  WordItem(word: 'Bus', emoji: '🚌'),
  WordItem(word: 'Dog', emoji: '🐕'),
  WordItem(word: 'Flower', emoji: '🌸'),
  WordItem(word: 'Chair', emoji: '🪑'),
  WordItem(word: 'Book', emoji: '📚'),
  WordItem(word: 'Umbrella', emoji: '☂️'),
];

const List<String> kDistractorBankL1 = [
  'Cat',
  'Apple',
  'Train',
  'Table',
  'Shoe',
  'Bird',
  'Clock',
  'Ball'
];

class WordRecallLevelConfig {
  final int id;
  final String difficulty;
  final String label;
  final String tagline;
  final int learningSeconds;
  final String mode; // 'random' or 'fixed'
  final int count;
  final int distractorCount;
  final List<WordItem>? fixedWords;
  final List<String>? fixedDistractors;

  const WordRecallLevelConfig({
    required this.id,
    required this.difficulty,
    required this.label,
    required this.tagline,
    required this.learningSeconds,
    required this.mode,
    this.count = 5,
    this.distractorCount = 3,
    this.fixedWords,
    this.fixedDistractors,
  });
}

const Map<int, WordRecallLevelConfig> kWordRecallLevels = {
  1: WordRecallLevelConfig(
    id: 1,
    difficulty: 'Easy',
    label: 'Level 1 — Easy',
    tagline: '5 simple words, plenty of time to look.',
    learningSeconds: 25,
    mode: 'random',
    count: 5,
    distractorCount: 3,
  ),
  2: WordRecallLevelConfig(
    id: 2,
    difficulty: 'Medium',
    label: 'Level 2 — Medium',
    tagline: '5 words, a little less time, more choices.',
    learningSeconds: 20,
    mode: 'fixed',
    fixedWords: [
      WordItem(word: 'Apple', emoji: '🍎'),
      WordItem(word: 'Train', emoji: '🚂'),
      WordItem(word: 'Key', emoji: '🔑'),
      WordItem(word: 'Flower', emoji: '🌸'),
      WordItem(word: 'Cup', emoji: '☕'),
    ],
    fixedDistractors: ['Bus', 'Dog', 'Chair', 'Mango', 'Book'],
  ),
  3: WordRecallLevelConfig(
    id: 3,
    difficulty: 'Hard',
    label: 'Level 3 — Hard',
    tagline: '7 words, shorter viewing time, more choices.',
    learningSeconds: 15,
    mode: 'fixed',
    fixedWords: [
      WordItem(word: 'Bottle', emoji: '🧴'),
      WordItem(word: 'Garden', emoji: '🌳'),
      WordItem(word: 'Clock', emoji: '🕐'),
      WordItem(word: 'Banana', emoji: '🍌'),
      WordItem(word: 'Doctor', emoji: '🩺'),
      WordItem(word: 'Window', emoji: '🪟'),
      WordItem(word: 'Bicycle', emoji: '🚲'),
    ],
    fixedDistractors: [
      'Table',
      'Mirror',
      'Basket',
      'Ladder',
      'Bench',
      'Cupboard'
    ],
  ),
};

class DistractionQuestion {
  final String prompt;
  final List<String> options;

  const DistractionQuestion({required this.prompt, required this.options});
}

const List<DistractionQuestion> kDistractionQuestions = [
  DistractionQuestion(
    prompt: 'What color is the sky on a sunny day?',
    options: ['Blue', 'Green', 'Purple'],
  ),
  DistractionQuestion(
    prompt: 'What number comes after 2?',
    options: ['1', '3', '5'],
  ),
  DistractionQuestion(
    prompt: 'Which one of these is a sweet fruit?',
    options: ['Banana', 'Chair', 'Bus'],
  ),
  DistractionQuestion(
    prompt: 'What is 1 + 1?',
    options: ['1', '2', '3'],
  ),
];
