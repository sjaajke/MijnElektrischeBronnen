enum BronType { trafo, generator, pv, batterij }

enum BeveiligingType { automatLsig, smeltveiligheid, differentiaal }

enum BedrijfsModus { netbedrijf, eilandbedrijf, hybride, noodbedrijf }

enum BelastingPrioriteit { kritisch, normaal, nietKritisch }

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

extension BedrijfsModusLabel on BedrijfsModus {
  String get label {
    switch (this) {
      case BedrijfsModus.netbedrijf:
        return 'Netbedrijf';
      case BedrijfsModus.eilandbedrijf:
        return 'Eilandbedrijf (Generator)';
      case BedrijfsModus.hybride:
        return 'Hybride (Net + PV + Batterij)';
      case BedrijfsModus.noodbedrijf:
        return 'Noodbedrijf';
    }
  }
}
