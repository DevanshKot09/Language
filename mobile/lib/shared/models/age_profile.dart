import 'package:flutter/material.dart';
import '../design_tokens/tokens.dart';

/// Enum representing the 3 primary age bands for LINGUA AI.
/// The application adapts its presentation and behavior via configuration,
/// never via separate duplicated codebases.
enum AgeBand {
  child,
  teen,
  adult,
}

/// Age-adaptive profile configuration model
class AgeProfileConfig {
  final AgeBand ageBand;
  final String displayName;
  final String ageRangeLabel;
  final double baseFontSize;
  final double lineSpacingMultiplier;
  final double wordSpacingMultiplier;
  final double minTouchTarget;
  final EdgeInsets cardPadding;
  final bool autoPlayAudioInstructions;
  final double defaultSpeechRate;
  final bool showStreaks;
  final bool gentleRewardsOnly;
  final bool enableWordHighlighting;

  const AgeProfileConfig({
    required this.ageBand,
    required this.displayName,
    required this.ageRangeLabel,
    required this.baseFontSize,
    required this.lineSpacingMultiplier,
    required this.wordSpacingMultiplier,
    required this.minTouchTarget,
    required this.cardPadding,
    required this.autoPlayAudioInstructions,
    required this.defaultSpeechRate,
    required this.showStreaks,
    required this.gentleRewardsOnly,
    required this.enableWordHighlighting,
  });

  /// Factory configuration for Child mode (Ages 5–11)
  /// - Warm, highly visual, large touch controls (56px)
  /// - Short instructions with audio narration enabled by default
  /// - Gentle star/exploration rewards, no negative streak pressure
  factory AgeProfileConfig.child() {
    return const AgeProfileConfig(
      ageBand: AgeBand.child,
      displayName: 'Child Learner',
      ageRangeLabel: 'Ages 5–11',
      baseFontSize: 18.0,
      lineSpacingMultiplier: 1.6,
      wordSpacingMultiplier: 1.25,
      minTouchTarget: LinguaTokens.childTouchTarget,
      cardPadding: EdgeInsets.all(24.0),
      autoPlayAudioInstructions: true,
      defaultSpeechRate: 0.85,
      showStreaks: false,
      gentleRewardsOnly: true,
      enableWordHighlighting: true,
    );
  }

  /// Factory configuration for Teen mode (Ages 12–17)
  /// - Modern, motivating, non-childish design
  /// - Practical academic vocabulary, skill milestones
  /// - Forgiving streaks, optional challenge modes
  factory AgeProfileConfig.teen() {
    return const AgeProfileConfig(
      ageBand: AgeBand.teen,
      displayName: 'Teen Learner',
      ageRangeLabel: 'Ages 12–17',
      baseFontSize: 16.0,
      lineSpacingMultiplier: 1.5,
      wordSpacingMultiplier: 1.15,
      minTouchTarget: 48.0,
      cardPadding: EdgeInsets.all(20.0),
      autoPlayAudioInstructions: false,
      defaultSpeechRate: 1.0,
      showStreaks: true,
      gentleRewardsOnly: false,
      enableWordHighlighting: true,
    );
  }

  /// Factory configuration for Adult mode (Ages 18+)
  /// - Professional, clean, low clutter, workplace/practical tasks
  /// - Reduced visual clutter, competence markers, self-directed goals
  factory AgeProfileConfig.adult() {
    return const AgeProfileConfig(
      ageBand: AgeBand.adult,
      displayName: 'Adult Learner',
      ageRangeLabel: 'Ages 18+',
      baseFontSize: 16.0,
      lineSpacingMultiplier: 1.5,
      wordSpacingMultiplier: 1.1,
      minTouchTarget: LinguaTokens.minTouchTarget,
      cardPadding: EdgeInsets.all(16.0),
      autoPlayAudioInstructions: false,
      defaultSpeechRate: 1.0,
      showStreaks: false,
      gentleRewardsOnly: false,
      enableWordHighlighting: false,
    );
  }

  static AgeProfileConfig forBand(AgeBand band) {
    switch (band) {
      case AgeBand.child:
        return AgeProfileConfig.child();
      case AgeBand.teen:
        return AgeProfileConfig.teen();
      case AgeBand.adult:
        return AgeProfileConfig.adult();
    }
  }
}
