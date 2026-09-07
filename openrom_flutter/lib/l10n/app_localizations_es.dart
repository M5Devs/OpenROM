// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suite Universal de Conversión de ROMs';

  @override
  String get convertButton => 'Convertir';

  @override
  String convertButtonWithCount(int count) {
    return 'Convertir ($count Archivos)';
  }

  @override
  String get dropZoneHint => 'Arrastra y suelta archivos ROM aquí';

  @override
  String get dropZoneSubHint => 'o haz clic para explorar';

  @override
  String get settingsTitle => 'Configuración de Conversión';

  @override
  String get outputFormat => 'Formato de Salida';

  @override
  String get compressionLevel => 'Nivel de Compresión';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Alta';

  @override
  String get compressionMax => 'Máxima';

  @override
  String get postProcessing => 'Post-Procesamiento';

  @override
  String get verifyAfterConversion => 'Verificar después de convertir';

  @override
  String get outputDestination => 'Destino de Salida';

  @override
  String get browse => 'Examinar';

  @override
  String get statusWaiting => 'Esperando...';

  @override
  String get statusConverting => 'Convirtiendo...';

  @override
  String get statusDone => 'Hecho';

  @override
  String get statusFailed => 'Fallido';

  @override
  String get aboutTitle => 'Acerca de OpenROM';

  @override
  String get settingsScreen => 'Ajustes';

  @override
  String get aboutScreen => 'Acerca de';

  @override
  String get themeScreen => 'Temas';

  @override
  String get errorCoreNotFound =>
      'No se encontró openrom-core. Por favor, vuelve a descargar el ZIP completo.';

  @override
  String get errorUnsupportedFormat =>
      'Este formato de archivo no es compatible.';

  @override
  String get errorDiskSpace =>
      'No hay suficiente espacio en disco para esta conversión.';

  @override
  String get errorToolFailed =>
      'La herramienta de conversión falló inesperadamente.';

  @override
  String get errorConversionFailed =>
      'La conversión falló. El archivo ROM podría estar dañado.';

  @override
  String get errorFileNotFound => 'El archivo de entrada se movió o eliminó.';

  @override
  String get errorOutputDirNotFound =>
      'La carpeta de salida seleccionada ya no existe.';

  @override
  String get errorPermissionDenied =>
      'OpenROM no puede escribir en la carpeta de salida.';

  @override
  String get errorCorruptedFile =>
      'El archivo parece estar dañado o tiene 0 bytes.';

  @override
  String get errorUnknown => 'Algo salió mal. Esto podría ser un error.';

  @override
  String get errorDetailsLabel => 'Detalles';

  @override
  String get retryButton => 'Reintentar';

  @override
  String get closeButton => 'Cerrar';

  @override
  String get reportBugButton => 'Reportar Error';

  @override
  String get clearQueue => 'Limpiar Cola';

  @override
  String get removeFile => 'Eliminar';

  @override
  String get openOutputFolder => 'Abrir Carpeta de Salida';
}
