// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suite Universelle de Conversion de ROMs';

  @override
  String get convertButton => 'Convertir';

  @override
  String convertButtonWithCount(int count) {
    return 'Convertir ($count Fichiers)';
  }

  @override
  String get dropZoneHint => 'Glissez & déposez des fichiers ROM ici';

  @override
  String get dropZoneSubHint => 'ou Cliquez pour parcourir';

  @override
  String get settingsTitle => 'Paramètres de Conversion';

  @override
  String get outputFormat => 'Format de Sortie';

  @override
  String get compressionLevel => 'Niveau de Compression';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Élevé';

  @override
  String get compressionMax => 'Maximum';

  @override
  String get postProcessing => 'Post-Traitement';

  @override
  String get verifyAfterConversion => 'Vérifier après la conversion';

  @override
  String get outputDestination => 'Destination de Sortie';

  @override
  String get browse => 'Parcourir';

  @override
  String get statusWaiting => 'En attente...';

  @override
  String get statusConverting => 'Conversion en cours...';

  @override
  String get statusDone => 'Terminé';

  @override
  String get statusFailed => 'Échec';

  @override
  String get aboutTitle => 'À propos d\'OpenROM';

  @override
  String get settingsScreen => 'Paramètres';

  @override
  String get aboutScreen => 'À propos';

  @override
  String get themeScreen => 'Thèmes';

  @override
  String get errorCoreNotFound =>
      'openrom-core introuvable. Veuillez télécharger à nouveau le ZIP complet.';

  @override
  String get errorUnsupportedFormat =>
      'Ce format de fichier n\'est pas pris en charge.';

  @override
  String get errorDiskSpace =>
      'Espace disque insuffisant pour cette conversion.';

  @override
  String get errorConversionFailed =>
      'La conversion a échoué. Le fichier ROM est peut-être corrompu.';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get closeButton => 'Fermer';

  @override
  String get reportBugButton => 'Signaler un bug';

  @override
  String get clearQueue => 'Vider la file d\'attente';

  @override
  String get removeFile => 'Supprimer';

  @override
  String get openOutputFolder => 'Ouvrir le dossier de sortie';
}
