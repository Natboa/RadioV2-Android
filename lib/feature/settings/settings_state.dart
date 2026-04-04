sealed class SettingsUiState {
  const SettingsUiState();
}

class SettingsIdle extends SettingsUiState {
  const SettingsIdle();
}

// ── Import ────────────────────────────────────────────────────────────────────

class SettingsImporting extends SettingsUiState {
  const SettingsImporting();
}

class SettingsImportDone extends SettingsUiState {
  final int added;
  final int total;
  const SettingsImportDone({required this.added, required this.total});
}

class SettingsImportError extends SettingsUiState {
  final String message;
  const SettingsImportError(this.message);
}

// ── Export ────────────────────────────────────────────────────────────────────

class SettingsExporting extends SettingsUiState {
  const SettingsExporting();
}

class SettingsExportDone extends SettingsUiState {
  const SettingsExportDone();
}

class SettingsExportError extends SettingsUiState {
  final String message;
  const SettingsExportError(this.message);
}
