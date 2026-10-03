import 'package:flutter/material.dart';
import '../design_tokens/tokens.dart';

/// The two primary clinical/educational support tracks in LINGUA AI.
/// DLD and Dyslexia must remain separate skill/support tracks.
enum SupportTrack {
  dldSpokenLanguage,
  dyslexiaLiteracy,
  multimodalBoth,
}

extension SupportTrackExtension on SupportTrack {
  String get title {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return 'Spoken Language Support (DLD Focus)';
      case SupportTrack.dyslexiaLiteracy:
        return 'Literacy & Reading Support (Dyslexia Focus)';
      case SupportTrack.multimodalBoth:
        return 'Dual-Track Practice (Oral + Written Language)';
    }
  }

  String get shortLabel {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return 'DLD Spoken Track';
      case SupportTrack.dyslexiaLiteracy:
        return 'Dyslexia Reading Track';
      case SupportTrack.multimodalBoth:
        return 'Connected Track';
    }
  }

  String get subtitle {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return 'Focuses on vocabulary breadth & depth, grammar, morphosyntax, listening comprehension, and narrative formulation.';
      case SupportTrack.dyslexiaLiteracy:
        return 'Focuses on phonological awareness, systematic phonics, decoding automaticity, spelling, and reading fluency.';
      case SupportTrack.multimodalBoth:
        return 'Addresses both oral language structure and reading/decoding automaticity with balanced practice sessions.';
    }
  }

  Color get primaryColor {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return LinguaTokens.dldTrack;
      case SupportTrack.dyslexiaLiteracy:
        return LinguaTokens.dyslexiaTrack;
      case SupportTrack.multimodalBoth:
        return LinguaTokens.accent500;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return LinguaTokens.dldTrackBg;
      case SupportTrack.dyslexiaLiteracy:
        return LinguaTokens.dyslexiaTrackBg;
      case SupportTrack.multimodalBoth:
        return LinguaTokens.accent100;
    }
  }

  String get apiId {
    switch (this) {
      case SupportTrack.dldSpokenLanguage:
        return 'dld_track';
      case SupportTrack.dyslexiaLiteracy:
        return 'dyslexia_track';
      case SupportTrack.multimodalBoth:
        return 'both_track';
    }
  }

  static SupportTrack fromApiId(String id) {
    switch (id) {
      case 'dld_track':
        return SupportTrack.dldSpokenLanguage;
      case 'dyslexia_track':
        return SupportTrack.dyslexiaLiteracy;
      case 'both_track':
        return SupportTrack.multimodalBoth;
      default:
        return SupportTrack.dldSpokenLanguage;
    }
  }
}
