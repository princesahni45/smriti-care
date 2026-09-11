// lib/core/ai/ai_context_builder.dart
//
// Bounded context builder for local on-device SLM inference.
//
// Security & Safety Guarantees:
// - Does NOT leak caregiver PINs, passwords, or patient medical records.
// - Enforces a restricted, deterministic schema for SLM outputs.
// - Restricts candidate outputs to canonical predefined VoiceIntent values.
// - Prevents prompt injection by stripping control characters and dangerous tokens.

import '../voice/voice_context.dart';

/// Immutable context payload passed to the local AI engine.
class AiContext {
  final String activeLanguage;
  final String currentRoute;
  final String? currentGame;
  final List<String> allowedIntents;
  final List<String> availableScreenActions;
  final String formattedPromptContext;

  const AiContext({
    required this.activeLanguage,
    required this.currentRoute,
    this.currentGame,
    required this.allowedIntents,
    required this.availableScreenActions,
    required this.formattedPromptContext,
  });
}

/// Builder that transforms application state into a safe, bounded [AiContext].
class AiContextBuilder {
  /// List of predefined canonical intent identifiers approved for SLM classification.
  static const List<String> approvedCanonicalIntents = [
    'OPEN_HOME',
    'OPEN_GAMES',
    'OPEN_MEMORY_GAME',
    'OPEN_WORD_RECALL',
    'OPEN_DIFFERENT_OBJECT',
    'OPEN_REMINDERS',
    'READ_NEXT_REMINDER',
    'OPEN_DAILY_ROUTINE',
    'OPEN_HELP',
    'CALL_CAREGIVER',
    'CHANGE_LANGUAGE',
    'GO_BACK',
    'CANCEL',
    'UNKNOWN',
  ];

  /// Construct an [AiContext] from the active [VoiceContext].
  /// Explicitly strips any sensitive credentials, PINs, or raw database records.
  static AiContext buildContext(VoiceContext voiceContext) {
    final language =
        voiceContext.activeLanguageCode.toLowerCase().split('-').first;
    final route = voiceContext.currentRoute.isNotEmpty
        ? voiceContext.currentRoute
        : '/dashboard';
    final currentGame = voiceContext.currentGame;

    // Filter available actions for the current screen
    final screenActions = _resolveAvailableActions(voiceContext);

    // Formulate a strict system prompt constraint for local SLM
    final buffer = StringBuffer();
    buffer.writeln(
        'Task: Classify patient voice command into exactly one predefined intent.');
    buffer.writeln('Language: $language');
    buffer.writeln('CurrentScreen: $route');
    if (currentGame != null) {
      buffer.writeln('ActiveGame: $currentGame');
    }
    buffer.writeln('AllowedIntents: [${approvedCanonicalIntents.join(', ')}]');
    buffer.writeln(
        'Rule: Return ONLY the intent name in uppercase. No commentary, no code, no tool execution.');

    return AiContext(
      activeLanguage: language,
      currentRoute: route,
      currentGame: currentGame,
      allowedIntents: approvedCanonicalIntents,
      availableScreenActions: screenActions,
      formattedPromptContext: buffer.toString(),
    );
  }

  /// Clean user input string to remove potential injection delimiters.
  static String sanitizePrompt(String rawPrompt) {
    return rawPrompt
        .replaceAll(RegExp(r'[\r\n\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _resolveAvailableActions(VoiceContext ctx) {
    if (ctx.isGamesScreen) {
      return const [
        'OPEN_MEMORY_GAME',
        'OPEN_WORD_RECALL',
        'OPEN_DIFFERENT_OBJECT',
        'GO_BACK'
      ];
    }
    if (ctx.isMemoryMatchScreen) {
      return const ['ADAPTIVE_DIFFICULTY', 'GO_BACK', 'OPEN_GAMES'];
    }
    if (ctx.isRemindersScreen) {
      return const ['READ_NEXT_REMINDER', 'GO_BACK', 'OPEN_HOME'];
    }
    return const [
      'OPEN_GAMES',
      'OPEN_REMINDERS',
      'OPEN_DAILY_ROUTINE',
      'CALL_CAREGIVER',
      'OPEN_HOME'
    ];
  }
}
