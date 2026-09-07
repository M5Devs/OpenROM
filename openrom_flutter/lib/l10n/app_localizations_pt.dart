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
      'A ferramenta de conversão (chdman/maxcso) fechou inesperadamente.';

  @override
  String get errorConversionFailed =>
      'A conversão falhou. O arquivo ROM pode estar corrompido.';

  @override
  String get errorFileNotFound =>
      'O arquivo de entrada foi movido ou removido.';

  @override
  String get errorOutputDirNotFound =>
      'A pasta de saída selecionada não existe mais.';

  @override
  String get errorPermissionDenied =>
      'O OpenROM não tem permissão para escrever na pasta de saída.';

  @override
  String get errorCorruptedFile =>
      'O arquivo parece estar corrompido ou tem 0 bytes.';

  @override
  String get errorUnknown => 'Ocorreu um erro inesperado.';

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

  @override
  String get patcherTitle => 'Aplicador de Patches';

  @override
  String get patcherRomFile => 'Arquivo ROM';

  @override
  String get patcherPatchFile => 'Arquivo de Patch';

  @override
  String get patcherOutputFile => 'Arquivo de Saída';

  @override
  String get patcherSameFolder => 'Mesma pasta do ROM';

  @override
  String get patcherIgnoreChecksum => 'Ignorar erros de checksum';

  @override
  String get patcherApplyButton => 'Aplicar Patch';

  @override
  String get patcherSuccess => 'Patch aplicado com sucesso!';

  @override
  String get patcherFormat => 'Formato';

  @override
  String get patcherChecksumPassed => 'passou';

  @override
  String get patcherChecksumSkipped => 'ignorado';

  @override
  String get patcherDropHint => 'Arraste e solte os arquivos ROM e Patch aqui';

  @override
  String get toolsTitle => 'Ferramentas';

  @override
  String get compressorTitle => 'Compressor de ROM';

  @override
  String get compressorAddFiles => 'Adicionar arquivos';

  @override
  String get compressorAddFolder => 'Adicionar pasta';

  @override
  String get compressorOutputFormat => 'Formato de saída';

  @override
  String get compressorLevel => 'Nível de compressão';

  @override
  String get compressorLevelFast => 'Rápido';

  @override
  String get compressorLevelNormal => 'Normal';

  @override
  String get compressorLevelUltra => 'Ultra';

  @override
  String get compressorDeleteSource => 'Excluir origem ao concluir';

  @override
  String get compressorSameFolder => 'Mesma pasta de origem';

  @override
  String compressorButton(int count) {
    return 'Comprimir ($count arquivos)';
  }

  @override
  String get compressorSkipped => 'Ignorado (já comprimido)';

  @override
  String get m3uTitle => 'Gerador M3U';

  @override
  String get m3uDropHint => 'Solte os arquivos de disco aqui';

  @override
  String get m3uOutputLabel => 'Pasta de saída';

  @override
  String get m3uButton => 'Gerar M3U';

  @override
  String m3uSuccess(String filename) {
    return 'Criado: $filename';
  }
}
