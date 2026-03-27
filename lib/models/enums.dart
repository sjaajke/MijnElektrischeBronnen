enum BronType { trafo, generator, pv, batterij }

enum BeveiligingType { automatLsig, smeltveiligheid, differentiaal }

enum BedrijfsModus { netbedrijf, eilandbedrijf, eilandGeneratorBatterij, hybride, noodbedrijf }

enum BelastingPrioriteit { kritisch, normaal, nietKritisch }

enum BelastingPeriodePreset {
  altijd,      // 24/7
  werkdag,     // Ma-Vr 08:00-17:00
  kantooruren, // Ma-Vr 09:00-17:00
  dag,         // 07:00-22:00
  nacht,       // 22:00-07:00
  ochtend,     // 06:00-12:00
  middag,      // 12:00-18:00
  avond,       // 18:00-23:00
  weekend,     // Za-Zo
  piekuren,    // 07:00-09:00 en 17:00-19:00
}

enum FoutNiveau { kritisch, waarschuwing, informatief }

enum SelectiviteitStatus { ok, nietSelectief, onbekend }

extension BronTypeLabel on BronType {
  String get label {
    switch (this) {
      case BronType.trafo:
        return 'Net / Trafo';
      case BronType.generator:
        return 'Generator';
      case BronType.pv:
        return 'PV (Zonnepanelen)';
      case BronType.batterij:
        return 'Batterij (BESS)';
    }
  }
}

extension BeveiligingTypeLabel on BeveiligingType {
  String get label {
    switch (this) {
      case BeveiligingType.automatLsig:
        return 'Automaat (LSIG)';
      case BeveiligingType.smeltveiligheid:
        return 'Smeltveiligheid';
      case BeveiligingType.differentiaal:
        return 'Differentiaal';
    }
  }
}

extension BelastingPeriodePresetLabel on BelastingPeriodePreset {
  String get label {
    switch (this) {
      case BelastingPeriodePreset.altijd:      return 'Altijd (24/7)';
      case BelastingPeriodePreset.werkdag:     return 'Werkdag (Ma-Vr 08-17)';
      case BelastingPeriodePreset.kantooruren: return 'Kantooruren (Ma-Vr 09-17)';
      case BelastingPeriodePreset.dag:         return 'Dag (07:00-22:00)';
      case BelastingPeriodePreset.nacht:       return 'Nacht (22:00-07:00)';
      case BelastingPeriodePreset.ochtend:     return 'Ochtend (06:00-12:00)';
      case BelastingPeriodePreset.middag:      return 'Middag (12:00-18:00)';
      case BelastingPeriodePreset.avond:       return 'Avond (18:00-23:00)';
      case BelastingPeriodePreset.weekend:     return 'Weekend (Za-Zo)';
      case BelastingPeriodePreset.piekuren:    return 'Piekuren (07-09 en 17-19)';
    }
  }
}

extension BedrijfsModusLabel on BedrijfsModus {
  String get label {
    switch (this) {
      case BedrijfsModus.netbedrijf:
        return 'Netbedrijf';
      case BedrijfsModus.eilandbedrijf:
        return 'Eilandbedrijf (Generator)';
      case BedrijfsModus.eilandGeneratorBatterij:
        return 'Eilandbedrijf (Generator + Batterij)';
      case BedrijfsModus.hybride:
        return 'Hybride (Net + PV + Batterij)';
      case BedrijfsModus.noodbedrijf:
        return 'Noodbedrijf';
    }
  }
}
