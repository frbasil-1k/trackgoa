import 'package:flutter/foundation.dart';

/// Evidence-backed confidence classification conforming to the SMART-GO standard:
/// - A: Direct authoritative evidence (e.g., official GTFS feed, KTCL fleet records)
/// - B: Strong independent evidence (e.g., OpenStreetMap road geometry, published timetables)
/// - C: Reasonable corroborated evidence (multiple independent reports)
/// - D: Weak / uncertain / insufficient evidence (excluded or under review)
/// - E: Inferred / generated / simulated (e.g., road routing from stops, live demo telemetry)
enum ProvenanceConfidence {
  aAuthoritative,
  bStrongIndependent,
  cCorroborated,
  dWeak,
  eSimulatedOrGenerated,
}

extension ProvenanceConfidenceX on ProvenanceConfidence {
  String get code {
    switch (this) {
      case ProvenanceConfidence.aAuthoritative:
        return 'A';
      case ProvenanceConfidence.bStrongIndependent:
        return 'B';
      case ProvenanceConfidence.cCorroborated:
        return 'C';
      case ProvenanceConfidence.dWeak:
        return 'D';
      case ProvenanceConfidence.eSimulatedOrGenerated:
        return 'E';
    }
  }

  String get label {
    switch (this) {
      case ProvenanceConfidence.aAuthoritative:
        return 'Authoritative (Official Record)';
      case ProvenanceConfidence.bStrongIndependent:
        return 'Strong Independent';
      case ProvenanceConfidence.cCorroborated:
        return 'Corroborated Evidence';
      case ProvenanceConfidence.dWeak:
        return 'Unverified / Weak';
      case ProvenanceConfidence.eSimulatedOrGenerated:
        return 'Simulated / Generated';
    }
  }

  bool get isVerifiedReal =>
      this == ProvenanceConfidence.aAuthoritative ||
      this == ProvenanceConfidence.bStrongIndependent ||
      this == ProvenanceConfidence.cCorroborated;
}

/// Nature of data origin.
enum DataOriginType {
  realVerified,
  generatedFromRealStops,
  simulatedTelemetry,
}

extension DataOriginTypeX on DataOriginType {
  String get label {
    switch (this) {
      case DataOriginType.realVerified:
        return 'Verified Real Data';
      case DataOriginType.generatedFromRealStops:
        return 'Generated from Real Stops';
      case DataOriginType.simulatedTelemetry:
        return 'Simulated Demo Realtime';
    }
  }
}

/// Audit record tracking the provenance of any transit entity or field.
@immutable
class ProvenanceRecord {
  const ProvenanceRecord({
    required this.entity,
    required this.field,
    required this.value,
    required this.source,
    required this.confidence,
    required this.originType,
    this.sourceUrlOrFile,
    this.sourceDate,
    this.notes,
  });

  final String entity;
  final String field;
  final String value;
  final String source;
  final ProvenanceConfidence confidence;
  final DataOriginType originType;
  final String? sourceUrlOrFile;
  final String? sourceDate;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'entity': entity,
    'field': field,
    'value': value,
    'source': source,
    'confidence': confidence.code,
    'originType': originType.name,
    if (sourceUrlOrFile != null) 'sourceUrlOrFile': sourceUrlOrFile,
    if (sourceDate != null) 'sourceDate': sourceDate,
    if (notes != null) 'notes': notes,
  };
}
