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
  String get errorToolFailed =>
      'L\'outil de conversion (chdman/maxcso) a quitté de manière inattendue.';

  @override
  String get errorConversionFailed =>
      'La conversion a échoué. Le fichier ROM est peut-être corrompu.';

  @override
  String get errorFileNotFound =>
      'Le fichier d\'entrée a été déplacé ou supprimé.';

  @override
  String get errorOutputDirNotFound =>
      'Le dossier de sortie sélectionné n\'existe plus.';

  @override
  String get errorPermissionDenied =>
      'OpenROM ne peut pas écrire dans le dossier de sortie.';

  @override
  String get errorCorruptedFile =>
      'Le fichier semble être corrompu ou fait 0 octet.';

  @override
  String get errorUnknown => 'Une erreur inattendue est survenue.';

  @override
  String get errorDetailsLabel => 'Détails';

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

  @override
  String get patcherTitle => 'Patcheur de ROM';

  @override
  String get patcherRomFile => 'Fichier ROM';

  @override
  String get patcherPatchFile => 'Fichier de Patch';

  @override
  String get patcherOutputFile => 'Fichier de Sortie';

  @override
  String get patcherSameFolder => 'Même dossier que le ROM';

  @override
  String get patcherIgnoreChecksum =>
      'Ignorer les erreurs de somme de contrôle';

  @override
  String get patcherApplyButton => 'Appliquer le Patch';

  @override
  String get patcherSuccess => 'Patché avec succès !';

  @override
  String get patcherFormat => 'Format';

  @override
  String get patcherChecksumPassed => 'réussi';

  @override
  String get patcherChecksumSkipped => 'ignoré';

  @override
  String get patcherDropHint => 'Déposez les fichiers ROM et Patch ici';

  @override
  String get toolsTitle => 'Outils';

  @override
  String get compressorTitle => 'Compresseur de ROM';

  @override
  String get compressorAddFiles => 'Ajouter des fichiers';

  @override
  String get compressorAddFolder => 'Ajouter un dossier';

  @override
  String get compressorOutputFormat => 'Format de sortie';

  @override
  String get compressorLevel => 'Niveau de compression';

  @override
  String get compressorLevelFast => 'Rapide';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Supprimer la source après fin';

  @override
  String get compressorSameFolder => 'Même dossier que la source';

  @override
  String compressorButton(int count) {
    return 'Compresser ($count fichiers)';
  }

  @override
  String get compressorSkipped => 'Ignoré (déjà compressé)';

  @override
  String get m3uTitle => 'Générateur M3U';

  @override
  String get m3uDropHint => 'Déposez les fichiers de disque ici';

  @override
  String get m3uOutputLabel => 'Dossier de sortie';

  @override
  String get m3uButton => 'Générer M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Créé : $filename';
  }
}
