// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'OpenROM';

  @override
  String get appSubtitle => 'Suíte Universal de Conversão de ROMs';

  @override
  String get convertButton => 'Converter';

  @override
  String convertButtonWithCount(int count) {
    return 'Converter ($count Arquivos)';
  }

  @override
  String get dropZoneHint => 'Arraste e solte arquivos ROM aqui';

  @override
  String get dropZoneSubHint => 'ou Clique para navegar';

  @override
  String get settingsTitle => 'Configurações de Conversão';

  @override
  String get outputFormat => 'Formato de Saída';

  @override
  String get compressionLevel => 'Nível de Compressão';

  @override
  String get compressionNormal => 'Normal';

  @override
  String get compressionHigh => 'Alta';

  @override
  String get compressionMax => 'Máxima';

  @override
  String get postProcessing => 'Pós-Processamento';

  @override
  String get verifyAfterConversion => 'Verificar após a conversão';

  @override
  String get outputDestination => 'Destino de Saída';

  @override
  String get browse => 'Navegar';

  @override
  String get statusWaiting => 'Aguardando...';

  @override
  String get statusConverting => 'Convertendo...';

  @override
  String get statusDone => 'Concluído';

  @override
  String get statusFailed => 'Falhou';

  @override
  String get aboutTitle => 'Sobre o OpenROM';

  @override
  String get settingsScreen => 'Configurações';

  @override
  String get aboutScreen => 'Sobre';

  @override
  String get themeScreen => 'Temas';

  @override
  String get errorCoreNotFound =>
      'openrom-core não encontrado. Por favor, baixe o ZIP completo novamente.';

  @override
  String get errorUnsupportedFormat =>
      'Este formato de arquivo não é suportado.';

  @override
  String get errorDiskSpace =>
      'Espaço em disco insuficiente para esta conversão.';

  @override
  String get errorToolFailed =>
      'A ferramenta de conversão falhou inesperadamente.';

  @override
  String get errorConversionFailed =>
      'A conversão falhou. O arquivo ROM pode estar corrompido.';

  @override
  String get errorFileNotFound =>
      'O arquivo de entrada foi movido ou excluído.';

  @override
  String get errorOutputDirNotFound =>
      'A pasta de saída selecionada não existe mais.';

  @override
  String get errorPermissionDenied =>
      'OpenROM não pode gravar na pasta de saída.';

  @override
  String get errorCorruptedFile =>
      'O arquivo parece estar corrompido ou tem 0 bytes.';

  @override
  String get errorUnknown => 'Algo deu errado. Isso pode ser um erro.';

  @override
  String get errorDetailsLabel => 'Detalhes';

  @override
  String get retryButton => 'Tentar novamente';

  @override
  String get closeButton => 'Fechar';

  @override
  String get reportBugButton => 'Reportar Erro';

  @override
  String get clearQueue => 'Limpar Fila';

  @override
  String get removeFile => 'Remover';

  @override
  String get openOutputFolder => 'Abrir Pasta de Saída';
}
