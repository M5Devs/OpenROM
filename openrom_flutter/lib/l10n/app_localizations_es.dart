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
      'La herramienta de conversión (chdman/maxcso) falló inesperadamente.';

  @override
  String get errorConversionFailed =>
      'La conversión falló. El archivo ROM podría estar dañado.';

  @override
  String get errorFileNotFound =>
      'El archivo de entrada fue movido o eliminado.';

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
  String get errorUnknown => 'Ocurrió un error inesperado.';

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

  @override
  String get patcherTitle => 'Parcheador de ROM';

  @override
  String get patcherRomFile => 'Archivo ROM';

  @override
  String get patcherPatchFile => 'Archivo de Parche';

  @override
  String get patcherOutputFile => 'Archivo de Salida';

  @override
  String get patcherSameFolder => 'Misma carpeta que el ROM';

  @override
  String get patcherIgnoreChecksum => 'Ignorar errores de suma de comprobación';

  @override
  String get patcherApplyButton => 'Aplicar Parche';

  @override
  String get patcherSuccess => '¡Parcheado con éxito!';

  @override
  String get patcherFormat => 'Formato';

  @override
  String get patcherChecksumPassed => 'aprobado';

  @override
  String get patcherChecksumSkipped => 'omitido';

  @override
  String get patcherDropHint =>
      'Arrastra y suelta los archivos ROM y parche aquí';

  @override
  String get toolsTitle => 'Herramientas';

  @override
  String get compressorTitle => 'Compresor de ROM';

  @override
  String get compressorAddFiles => 'Añadir archivos';

  @override
  String get compressorAddFolder => 'Añadir carpeta';

  @override
  String get compressorOutputFormat => 'Formato de salida';

  @override
  String get compressorLevel => 'Nivel de compresión';

  @override
  String get compressorLevelFast => 'Rápido';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Eliminar origen al finalizar';

  @override
  String get compressorSameFolder => 'Misma carpeta que el origen';

  @override
  String compressorButton(int count) {
    return 'Comprimir ($count archivos)';
  }

  @override
  String get compressorSkipped => 'Omitido (ya comprimido)';

  @override
  String get m3uTitle => 'Generador de M3U';

  @override
  String get m3uDropHint => 'Arrastre archivos de disco aquí';

  @override
  String get m3uOutputLabel => 'Carpeta de salida';

  @override
  String get m3uButton => 'Generar M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Creado: $filename';
  }

  @override
  String get cueGeneratorTitle => 'Generador de CUE';

  @override
  String get cueGeneratorBinFile => 'Archivo BIN';

  @override
  String get cueGeneratorDetectedMode => 'Modo detectado';

  @override
  String get cueGeneratorButton => 'Generar CUE';

  @override
  String cueGeneratorSuccess(String filename) {
    return 'Creado: $filename';
  }

  @override
  String get binMergerTitle => 'Unificador de BIN';

  @override
  String get binMergerCueFile => 'Archivo CUE (multipista)';

  @override
  String binMergerDetected(int count) {
    return 'Detectados: $count archivos BIN';
  }

  @override
  String get binMergerButton => 'Unir BINs';

  @override
  String binMergerSuccess(String filename) {
    return 'Unido: $filename';
  }

  @override
  String get headerRemoverTitle => 'Eliminador de Cabecera';

  @override
  String get headerRemoverSystem => 'Sistema';

  @override
  String get headerRemoverFound => 'Cabecera encontrada';

  @override
  String get headerRemoverNotFound => 'Sin cabecera';

  @override
  String get headerRemoverConfidence => 'Confianza';

  @override
  String get headerRemoverBackup => 'Guardar copia de seguridad (.bak)';

  @override
  String get headerRemoverButton => 'Eliminar Cabecera';

  @override
  String headerRemoverSuccess(String filename) {
    return 'ROM limpio: $filename';
  }

  @override
  String get headerRemoverNoHeader => 'No se detectó cabecera de copiador.';
}
