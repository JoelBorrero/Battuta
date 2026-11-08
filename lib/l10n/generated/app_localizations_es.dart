// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Battuta';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get close => 'Cerrar';

  @override
  String get done => 'Listo';

  @override
  String get dismiss => 'Descartar';

  @override
  String get search => 'Buscar';

  @override
  String get all => 'Todos';

  @override
  String get navRepertoire => 'Repertorio';

  @override
  String get navScan => 'Escanear';

  @override
  String get navSetlists => 'Listas';

  @override
  String get navTeam => 'Equipo';

  @override
  String get navLive => 'En Vivo';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeSubtitle => 'Elige modo claro, oscuro o del sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get languageSection => 'Idioma / Language';

  @override
  String get languageLabel => 'Idioma de la aplicación';

  @override
  String get languageSubtitle =>
      'Selecciona el idioma preferido para la aplicación';

  @override
  String get languageAuto => 'Automático';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get cloudSyncSection => 'Sincronización en la Nube (Supabase)';

  @override
  String get cloudAccountLabel => 'Cuenta en la Nube';

  @override
  String get supabaseConnectionLabel => 'Conexión con Supabase';

  @override
  String get syncStatusLabel => 'Estado de Sincronización';

  @override
  String get syncNow => 'Sincronizar';

  @override
  String get signOut => 'Cerrar Sesión';

  @override
  String get aboutSection => 'Acerca de';

  @override
  String get versionLabel => 'Versión';

  @override
  String get teamRosterTab => 'Plantilla del Equipo';

  @override
  String get bandCalendarTab => 'Calendario del Grupo';

  @override
  String get addMusician => 'Añadir Miembro';

  @override
  String get addService => 'Nuevo Servicio';

  @override
  String get recurringSchedules => 'Horarios Recurrentes';

  @override
  String get periodicServicesTitle => 'Servicios Periódicos y Próximos';

  @override
  String get nextService => 'PRÓXIMO SERVICIO';

  @override
  String get findCover => 'Buscar Reemplazo';

  @override
  String get workspaceResourcesSection => 'Recursos y Cuota del Espacio';

  @override
  String get activeWorkspacePool => 'RECURSOS DEL ESPACIO ACTIVO';

  @override
  String get geminiAiCredits => 'Créditos Gemini AI';

  @override
  String get cloudStorage => 'Almacenamiento en la Nube';

  @override
  String get developerOptions => 'Opciones de Desarrollador';

  @override
  String get developerOptionsSubtitle =>
      'Configurar URL personalizada de Supabase y claves de IA';

  @override
  String get repertoireTitle => 'Repertorio';

  @override
  String get chordChart => 'Gráfico de Acordes';

  @override
  String get musicalStaff => 'Pentagrama Musical';

  @override
  String get newSong => 'Nueva Canción';

  @override
  String get editSong => 'Editar Canción';

  @override
  String get addSong => 'Añadir Canción';

  @override
  String get deleteSong => 'Eliminar Canción';

  @override
  String get deleteSongTitle => '¿Eliminar Canción?';

  @override
  String deleteSongConfirm(String title) {
    return '¿Estás seguro de que deseas eliminar \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String deletedSongSuccess(String title) {
    return 'Se eliminó \"$title\"';
  }

  @override
  String get newSetlist => 'Nueva Lista';

  @override
  String get createSetlist => 'Crear Lista';

  @override
  String get createNewSetlist => 'Crear Nueva Lista';

  @override
  String get editSetlist => 'Editar Lista';

  @override
  String get deleteSetlistTitle => '¿Eliminar Lista?';

  @override
  String deleteSetlistConfirm(String title) {
    return '¿Estás seguro de que deseas eliminar \"$title\"? Esta acción no se puede deshacer.';
  }

  @override
  String deletedSetlistSuccess(String title) {
    return 'Se eliminó la lista \"$title\"';
  }

  @override
  String createdSetlistSuccess(String title) {
    return 'Se creó la lista \"$title\"';
  }

  @override
  String songsTab(int count) {
    return 'Canciones ($count)';
  }

  @override
  String setlistsTab(int count) {
    return 'Listas ($count)';
  }

  @override
  String get scanSheetMusicTooltip => 'Escanear partitura';

  @override
  String get searchSongsTooltip => 'Buscar canciones';

  @override
  String get typeToSearchSongs => 'Escribe para buscar canciones…';

  @override
  String get noSongsFound => 'No se encontraron canciones';

  @override
  String get failedToLoadRepertoire => 'Error al cargar el repertorio';

  @override
  String get retry => 'Reintentar';

  @override
  String get repertoireEmpty => 'Tu repertorio está vacío';

  @override
  String get repertoireEmptyAdminHint =>
      'Toca el botón + para añadir tu primera canción';

  @override
  String get repertoireEmptyMemberHint =>
      'No hay canciones disponibles aún. Contacta a un administrador para añadir canciones.';

  @override
  String get loadSampleSongs => 'Cargar Canciones de Muestra';

  @override
  String get scanScore => 'Escanear Partitura';

  @override
  String get noSetlistsYet => 'Aún no hay listas';

  @override
  String get setlistsEmptyAdminHint =>
      'Crea una lista organizada para servicios dominicales o ensayos.';

  @override
  String get setlistsEmptyMemberHint =>
      'No hay listas creadas aún. Las listas aparecerán aquí cuando sean publicadas por el director.';

  @override
  String get loadSampleSetlist => 'Cargar Lista de Muestra';

  @override
  String setlistSongsCount(int count) {
    return '$count canciones';
  }

  @override
  String get upcomingService => 'Próximo servicio';

  @override
  String get setlistTitleField => 'Título de la Lista *';

  @override
  String get setlistTitleHint => 'ej. Domingo Mañana - Pascua';

  @override
  String get notesServiceThemeField => 'Notas / Tema del Servicio';

  @override
  String get notesServiceThemeHint => 'ej. Formato acústico, santa cena en Re';

  @override
  String get deleteSetlistTooltip => 'Eliminar lista';

  @override
  String get songDetail => 'Detalle de Canción';

  @override
  String get transposeSong => 'Transportar Tonalidad';

  @override
  String get reset => 'Restablecer';

  @override
  String get originalKey => 'Tonalidad Original';

  @override
  String semitonesCount(String prefix, int count) {
    return '$prefix$count semitonos';
  }

  @override
  String get downOneSemitone => 'Bajar 1 semitono';

  @override
  String get upOneSemitone => 'Subir 1 semitono';

  @override
  String saveTransposedKey(String key) {
    return 'Guardar Tonalidad Transportada ($key) en la Canción';
  }

  @override
  String get transposeKeyTooltip => 'Transportar Tonalidad';

  @override
  String get notationEditorTooltip => 'Editor de Notación';

  @override
  String get exportPdfTooltip => 'Exportar Partitura PDF';

  @override
  String get exportMidiTooltip => 'Exportar Archivo MIDI';

  @override
  String get interactiveNotationView => 'Vista de Notación Interactiva';

  @override
  String get editInNotationEditor => 'Editar en Editor de Notación';

  @override
  String get noSectionsYet => 'Esta canción aún no tiene secciones.';

  @override
  String repeatTimes(int count) {
    return 'Repetir $count×';
  }

  @override
  String beatsCount(int count) {
    return '$count tiempos';
  }

  @override
  String get backToRepertoire => 'Volver al Repertorio';

  @override
  String get songNotFound => 'Canción no encontrada en el repertorio';

  @override
  String songKeyBadge(String key) {
    return 'Tonalidad: $key';
  }

  @override
  String failedToExportPdf(String error) {
    return 'Error al exportar PDF: $error';
  }

  @override
  String failedToExportMidi(String error) {
    return 'Error al exportar MIDI: $error';
  }

  @override
  String get viewOnly => 'Solo Lectura';

  @override
  String get readOnlyAdminWarning =>
      'Vista de solo lectura: Se requieren permisos de administrador para crear o modificar canciones del repertorio.';

  @override
  String get songTitleLabel => 'Título de la Canción *';

  @override
  String get songTitleHint => 'ej. Gracia Admirable';

  @override
  String get songTitleValidation => 'Por favor ingresa un título de canción';

  @override
  String get artistComposerLabel => 'Artista / Compositor *';

  @override
  String get artistComposerHint => 'ej. John Newton';

  @override
  String get artistValidation => 'Por favor ingresa un artista o compositor';

  @override
  String get musicalSetup => 'Configuración Musical';

  @override
  String get keyLabel => 'Tonalidad';

  @override
  String get meterLabel => 'Compás';

  @override
  String get decreaseBpm => 'Disminuir BPM';

  @override
  String get increaseBpm => 'Aumentar BPM';

  @override
  String get tapTempo => 'Pulsar Tempo';

  @override
  String get addTag => 'Añadir Etiqueta';

  @override
  String get tagHint => 'ej. adoración, alabanza, balada';

  @override
  String get notesInstructionsLabel =>
      'Notas / Instrucciones de Interpretación';

  @override
  String get notesInstructionsHint =>
      'ej. Capo traste 3, intro acústica lenta...';

  @override
  String songSectionsCount(int count) {
    return 'Secciones de la Canción ($count)';
  }

  @override
  String get addSection => 'Añadir Sección';

  @override
  String get quickAdd => 'Añadir rápido: ';

  @override
  String get noSectionsAddedHint =>
      'No hay secciones añadidas. Toca \"+ Añadir Sección\" para construir tu canción.';

  @override
  String get sectionName => 'Nombre de la Sección';

  @override
  String get decreaseRepeats => 'Disminuir repeticiones';

  @override
  String get increaseRepeats => 'Aumentar repeticiones';

  @override
  String get moveUp => 'Subir';

  @override
  String get moveDown => 'Bajar';

  @override
  String get deleteSection => 'Eliminar Sección';

  @override
  String get chordsFieldLabel => 'Acordes (ej. C | G/B | Am | F)';

  @override
  String get chordsFieldHint =>
      'Escribe símbolos de acordes separados por espacios o barras';

  @override
  String get applyChordsTooltip => 'Aplicar texto de acordes';

  @override
  String get addChordBuilderTooltip => 'Abrir creador de acordes';

  @override
  String get sectionLyricsLabel => 'Letra de la Sección';

  @override
  String get sectionLyricsHint => 'Ingresa la letra línea por línea...';

  @override
  String get rehearsalNotesLabel => 'Notas de Ensayo (opcional)';

  @override
  String get rehearsalNotesHint => 'ej. El solo de guitarra empieza aquí...';

  @override
  String get addChord => 'Añadir Acorde';

  @override
  String get rootNote => 'Nota Fundamental';

  @override
  String get quality => 'Tipo de Acorde';

  @override
  String get bassNote => 'Bajo (Acorde Invertido)';

  @override
  String get noneOption => 'Ninguno';

  @override
  String get beatsLabel => 'Tiempos: ';

  @override
  String get add => 'Añadir';

  @override
  String songUpdatedSuccess(String title) {
    return 'Canción \"$title\" actualizada exitosamente';
  }

  @override
  String songCreatedSuccess(String title) {
    return 'Canción \"$title\" creada exitosamente';
  }

  @override
  String failedToSaveSong(String error) {
    return 'Error al guardar canción: $error';
  }

  @override
  String get songDeletedSuccess => 'Canción eliminada';

  @override
  String get adminRequiredWarning =>
      'Se requieren permisos de administrador para crear o modificar canciones.';

  @override
  String get setlistTitle => 'Lista';

  @override
  String get descriptionNotesField => 'Descripción / Notas';

  @override
  String get addSongToSetlist => 'Añadir Canción a la Lista';

  @override
  String get noSongsInRepertoireYet =>
      'Aún no hay canciones en el repertorio. Crea o carga canciones de muestra.';

  @override
  String get allSongsAlreadyInSetlist =>
      'Todas las canciones ya están en esta lista.';

  @override
  String get setlistEmpty => 'Esta lista aún no tiene canciones.';

  @override
  String get tapAddSongHint =>
      'Toca \"Añadir Canción a la Lista\" abajo para armar tu lista.';

  @override
  String get removeFromSetlistTooltip => 'Quitar de la lista';

  @override
  String songOriginalMeta(String artist, String key, int tempo) {
    return '$artist • Original: $key ($tempo BPM)';
  }

  @override
  String get unknownArtist => 'Artista desconocido';

  @override
  String get editSetlistInfoTooltip => 'Editar información de la lista';

  @override
  String get scanLeadSheet => 'Escanear Partitura';

  @override
  String get omrScannerTitle => 'Escáner OMR';

  @override
  String get omrScannerSubtitle =>
      'Apunta la cámara a una partitura o elige una imagen para extraer\nacordes, melodía y estructura con Gemini AI.';

  @override
  String get openCamera => 'Abrir Cámara';

  @override
  String get chooseFromLibrary => 'Elegir de la Galería';

  @override
  String addedToRepertoireSuccess(String title) {
    return '¡Se añadió \"$title\" al Repertorio!';
  }

  @override
  String extractedMeasuresSuccess(int measures, String section) {
    return 'Se extrajeron $measures compases para \"$section\".';
  }

  @override
  String get scanSheetMusic => 'Escanear Partitura';

  @override
  String get omrDebugLogs => 'Registros de Diagnóstico OMR';

  @override
  String get fullSheetSchemaA => 'Partitura Completa (Esquema A)';

  @override
  String get staffSnippetSchemaB => 'Fragmento de Pentagrama (Esquema B)';

  @override
  String get camera => 'Cámara';

  @override
  String get photos => 'Fotos';

  @override
  String get fullSheetDesc =>
      'Captura el arreglo completo con metadatos, pentagramas, acordes y letras.';

  @override
  String get staffSnippetDesc =>
      'Recorta un solo sistema o melodía para ingreso rápido de ritmo paso a paso.';

  @override
  String get cropSystem => 'Recortar Sistema';

  @override
  String get changeImage => 'Cambiar Imagen';

  @override
  String get analyzeWithGemini => 'Analizar con Gemini AI';

  @override
  String get recognitionError => 'Error de Reconocimiento';

  @override
  String get viewDebugLogs => 'Ver Registros de Diagnóstico';

  @override
  String get recognitionComplete => '¡Reconocimiento Completo!';

  @override
  String get openInRepertoire => 'Abrir en Repertorio';

  @override
  String get openInRhythmEditor => 'Abrir en Editor de Ritmo';

  @override
  String get analyzingSheet => 'Analizando partitura con Gemini AI...';

  @override
  String get processingImage => 'Procesando imagen...';

  @override
  String get transcribingSheet => 'Transcribiendo notas, acordes y pentagramas';

  @override
  String get omrDiagnosticLogs => 'Registros de Diagnóstico OMR';

  @override
  String get persistentFileSystemLogs => 'Registros en Sistema de Archivos';

  @override
  String get refreshLogs => 'Actualizar Registros';

  @override
  String get clearLogs => 'Limpiar Registros';

  @override
  String get clearOmrLogsTitle => '¿Limpiar Registros OMR?';

  @override
  String get clearOmrLogsConfirm =>
      'Esto vaciará el archivo omr_debug.log en el dispositivo.';

  @override
  String get clearAction => 'Limpiar';

  @override
  String get omrLogsCleared =>
      'Registros OMR eliminados del sistema de archivos.';

  @override
  String get locatingLogFile => 'Ubicando archivo de registro...';

  @override
  String get loadingDiagnosticLogs => 'Cargando registros de diagnóstico...';

  @override
  String get noLogsRecordedYet =>
      'Aún no hay registros.\nEjecuta un escaneo OMR para capturar diagnósticos.';

  @override
  String get copyAllLogs => 'Copiar Todos los Registros';

  @override
  String get omrLogsCopied => 'Registros OMR copiados al portapapeles.';

  @override
  String get scoreEditor => 'Editor de Notación';

  @override
  String get notationSavedSuccess =>
      '¡Cambios de notación guardados en la Canción!';

  @override
  String failedToSaveScore(String error) {
    return 'Error al guardar partitura: $error';
  }

  @override
  String get playbackTempo => 'Tempo de Reproducción';

  @override
  String get setTempo => 'Establecer Tempo';

  @override
  String get scoreAudioPreview => 'Vista Previa de Audio';

  @override
  String get pauseMelody => 'Pausar Melodía';

  @override
  String get playMelody => 'Reproducir Melodía';

  @override
  String get stopRewind => 'Detener y Rebobinar';

  @override
  String get unmuteSound => 'Activar Sonido de Notas';

  @override
  String get muteSound => 'Silenciar Sonido de Notas';

  @override
  String get apiConfigurationSection => 'Configuración de API';

  @override
  String get geminiApiKeyLabel => 'Clave de API Gemini';

  @override
  String get geminiKeyNotConfigured =>
      'No configurada — toca para ingresar clave';

  @override
  String get customLabel => 'Personalizada';

  @override
  String get devEnvLabel => '.env Desarrollo';

  @override
  String get loadingStatus => 'Cargando estado...';

  @override
  String get errorLoadingKey => 'Error al cargar la clave';

  @override
  String get omrDiagnosticLogsSubtitle =>
      'Inspeccionar solicitudes, latencias y respuestas de Gemini';

  @override
  String get appTagline =>
      'Un compañero de ensayo y partituras\npara bandas y equipos de alabanza.';

  @override
  String get licensesLabel => 'Licencias';

  @override
  String get footerAttribution => 'Hecho con ♪ para equipos de alabanza';

  @override
  String get supabaseConfigSubtitle => 'Configurar URL del Proyecto y Anon Key';

  @override
  String get notSignedInOffline => 'Sesión no iniciada — SQLite local activo';

  @override
  String get synchronizingDatabase =>
      'Sincronizando base de datos local con la nube…';

  @override
  String get offlineCached => 'Sin conexión: Cambios locales guardados';

  @override
  String get readyToSync => 'Listo para sincronizar';

  @override
  String billingPeriodScans(int count) {
    return '$count escaneos de partituras completas en este período';
  }

  @override
  String storageTracksCount(int count) {
    return '$count partituras y pistas de audio almacenadas';
  }

  @override
  String get workspaceMetricsUnavailable =>
      'Métricas del espacio de trabajo no disponibles';

  @override
  String get worshipTeamTitle => 'Equipo de Alabanza y Banda';

  @override
  String get liveStageSync => 'Sincronización en Vivo';

  @override
  String get directorHost => 'Director (Anfitrión)';

  @override
  String get musicianFollower => 'Músico (Seguidor)';

  @override
  String get hostingStatus => 'TRANSMITIENDO';

  @override
  String get syncedStatus => 'SINCRONIZADO';

  @override
  String get standaloneStatus => 'AUTÓNOMO';

  @override
  String get syncingChangesTooltip => 'Sincronizando cambios con Supabase…';

  @override
  String get cloudSyncedTooltip => 'Sincronizado con la nube';

  @override
  String cloudSyncedWithTimeTooltip(String time) {
    return 'Sincronizado con la nube ($time)';
  }

  @override
  String get offlineSQLiteTooltip =>
      'Sin conexión — trabajando con base de datos local SQLite';

  @override
  String get syncErrorTooltip => 'Error de sincronización';

  @override
  String get cloudReadyTooltip => 'Nube lista (tocar para sincronizar)';

  @override
  String get syncingStatus => 'Sincronizando…';

  @override
  String get syncedStatusLabel => 'Sincronizado';

  @override
  String get offlineStatusLabel => 'Sin conexión';

  @override
  String get switchActiveProfileTooltip => 'Cambiar perfil de usuario activo';

  @override
  String activeProfileTooltip(String name, String role) {
    return 'Perfil activo: $name ($role)';
  }

  @override
  String get coverageAlertsTooltip => 'Alertas de Cobertura de Músicos';

  @override
  String coverageAlertsCountTooltip(int count) {
    return '$count alerta(s) de cobertura';
  }

  @override
  String get addTeamMemberTooltip => 'Añadir miembro del equipo';

  @override
  String get addServiceEventTooltip => 'Añadir evento de servicio';

  @override
  String get noUpcomingServices => 'No hay servicios programados próximamente.';

  @override
  String get scheduleFirstService => 'Programar Primer Servicio';

  @override
  String get editMember => 'Editar Miembro';

  @override
  String get scheduleForService => 'Programar para Servicio';

  @override
  String get editService => 'Editar Servicio';

  @override
  String get assignGroup => 'Asignar Grupo';

  @override
  String get assignMusician => 'Asignar Músico';

  @override
  String get triggerTestCue => 'Lanzar Señal de Prueba';

  @override
  String get approveJump => 'Aprobar Salto';

  @override
  String get geminiApiKeySaved =>
      'Clave de API Gemini guardada de forma segura.';

  @override
  String get removeApiKeyTitle => '¿Eliminar clave de API?';

  @override
  String get customApiKeyRemoved => 'Clave de API personalizada eliminada.';

  @override
  String get removeKey => 'Eliminar Clave';

  @override
  String get saveKey => 'Guardar Clave';

  @override
  String get supabaseProjectSetup => 'Configuración de Proyecto Supabase';

  @override
  String get restoreDefault => 'Restaurar Predeterminado';

  @override
  String get saveAndConnect => 'Guardar y Conectar';

  @override
  String get selectActiveProfileTitle => 'Seleccionar Perfil de Usuario Activo';

  @override
  String get switchActiveProfileDesc =>
      'Cambia de usuario activo para probar permisos de músico o funciones de administrador.';

  @override
  String get adminRole => 'Admin';

  @override
  String get administrator => 'Administrador';

  @override
  String get musician => 'Músico';

  @override
  String activeUserChanged(String name, String role) {
    return 'Usuario activo: $name ($role)';
  }

  @override
  String get totalRoster => 'Plantilla Total';

  @override
  String get scheduledLabel => 'Programado';

  @override
  String get availableLabel => 'Disponible';

  @override
  String get availableStatus => 'Disponible';

  @override
  String get nextServicePrefix => 'Próximo:';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterScheduled => 'Programados';

  @override
  String get filterVocals => 'Voces';

  @override
  String get filterBand => 'Banda';

  @override
  String get noMembersMatchFilter => 'Ningún miembro coincide con este filtro.';

  @override
  String get nextServiceBadge => 'PRÓXIMO SERVICIO';

  @override
  String get bandLineupTitle => 'Alineación de la Banda';

  @override
  String get cantAttendBadge => 'No puede asistir';

  @override
  String get notScheduledForServices =>
      'No está programado actualmente para próximos servicios';

  @override
  String cloudSyncSuccess(int pushed, int pulled) {
    return 'Sincronizado con éxito ($pushed enviados, $pulled recibidos)';
  }

  @override
  String get cloudSyncStatusTitle => 'Sincronización en la Nube';

  @override
  String get cloudSignInRequired =>
      'Inicia sesión en Supabase para sincronizar con la nube.';

  @override
  String get cloudOfflineMode =>
      'Modo sin conexión activo. Todos los cambios se guardan localmente en SQLite.';

  @override
  String get signInAction => 'Iniciar Sesión';

  @override
  String get configureAction => 'Configurar';

  @override
  String get retryAction => 'Reintentar';

  @override
  String get noMusiciansAssignedYet =>
      'Aún no hay músicos asignados. Toca \"Asignar Músico\" para programar miembros de la banda.';

  @override
  String get deleteService => 'Eliminar Servicio';

  @override
  String get supabaseNotConfigured =>
      'El cliente de Supabase no está configurado. Los cambios se guardan localmente en SQLite.';

  @override
  String get onStageNow => 'EN ESCENARIO AHORA';

  @override
  String get introPreRoll => 'INTRODUCCIÓN / PRE-ROLL';

  @override
  String get queuedNext => 'Siguiente en cola:';

  @override
  String get waitingForCue => 'Ninguna (Esperando señal)';

  @override
  String get localLanDirectorServer => 'SERVIDOR DIRECTOR LAN LOCAL';

  @override
  String get connectToDirectorDevice => 'CONECTAR A DISPOSITIVO DIRECTOR';

  @override
  String get startZeroConfigServer =>
      'Inicia un servidor WebSocket local sin configuración para que todos los músicos sigan tus señales en vivo.';

  @override
  String serverRunningOnPort(int port) {
    return 'Servidor activo en el puerto efímero $port. Las tablets de los miembros pueden conectarse en esta red Wi-Fi local.';
  }

  @override
  String get stopHostServer => 'Detener Servidor';

  @override
  String get startLanHost => 'Iniciar Servidor LAN';

  @override
  String get directorHostIp => 'IP del Director';

  @override
  String get portLabel => 'Puerto';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connectAsFollower => 'Conectar como Seguidor';

  @override
  String connectionFailed(String error) {
    return 'Fallo al conectar: $error';
  }

  @override
  String get leaderLockRequestsTitle =>
      'LeaderLock: Solicitudes de Transición de Músicos';

  @override
  String get followerRequestedChange =>
      'El músico solicitó un cambio de sección';

  @override
  String requestPrefix(String section) {
    return 'Solicitud: $section';
  }

  @override
  String get jumpAction => 'SALTAR';

  @override
  String get clearQueueAction => 'LIMPIAR COLA';

  @override
  String get supabaseConfigExplanation =>
      'Ingresa el endpoint de tu proyecto Supabase y la clave pública anónima para habilitar la sincronización en la nube.';

  @override
  String get projectUrlLabel => 'URL del Proyecto';

  @override
  String get anonPublicKeyLabel => 'Clave Pública Anónima (Anon Key)';

  @override
  String get magicLinkSignInTitle => 'Iniciar Sesión con Magic Link';

  @override
  String get createAccountTitle => 'Crear Cuenta de Supabase';

  @override
  String get signInTitle => 'Iniciar Sesión en Supabase';

  @override
  String get fullNameLabel => 'Nombre Completo';

  @override
  String get emailAddressLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get usePasswordAction => 'Usar Contraseña';

  @override
  String get sendMagicLinkAction => 'Enviar Magic Link';

  @override
  String get haveAccountSignInAction => '¿Ya tienes cuenta? Iniciar Sesión';

  @override
  String get newRegisterAction => '¿Nuevo? Regístrate';

  @override
  String get sendLinkAction => 'Enviar Enlace';

  @override
  String get registerAction => 'Registrarse';

  @override
  String schedulingAttentionNeeded(int count) {
    return 'Atención de Programación Requerida ($count)';
  }

  @override
  String get dismissAction => 'Descartar';

  @override
  String coverageAlertsCount(int count) {
    return 'Alertas de Cobertura ($count)';
  }

  @override
  String get noPendingGaps =>
      'No hay ausencias pendientes. ¡Todos los servicios están cubiertos!';

  @override
  String get assignMusicianReplacement => 'Asignar Músico de Reemplazo';

  @override
  String cannotAttendPrefix(String name) {
    return 'No puede asistir: $name';
  }

  @override
  String roleDatePrefix(String role, String date) {
    return 'Rol: $role • $date';
  }

  @override
  String get selectSubstituteMusician => 'Seleccionar Músico Suplente:';

  @override
  String get substituteMusicianLabel => 'Músico Suplente';

  @override
  String playsRoleTag(String role) {
    return '★ Toca $role';
  }

  @override
  String get inLineupTag => '(En Alineación)';

  @override
  String get assignedRoleLabel => 'Rol Asignado';

  @override
  String get attendanceStatusLabel => 'Estado de Asistencia';

  @override
  String get confirmReplacement => 'Confirmar Reemplazo';

  @override
  String replacedMusicianSuccess(
    String oldMember,
    String newMember,
    String date,
  ) {
    return '¡Se reemplazó a $oldMember por $newMember para $date!';
  }

  @override
  String get noOtherMembersToSubstitute =>
      'No hay otros miembros del equipo disponibles para sustituir.';

  @override
  String get confirmAttendance => 'Confirmar Asistencia';

  @override
  String get markUnavailableCannotAttend =>
      'Marcar No Disponible / No Asistirá';

  @override
  String get flagsDateReplacement =>
      'Marca la fecha para que el admin asigne un suplente';

  @override
  String get findReplacementSubstitute => 'Buscar Reemplazo / Suplente';

  @override
  String get assignAnotherMember =>
      'Asigna a otro miembro para tomar este lugar';

  @override
  String get removeFromLineup => 'Eliminar de la Alineación';

  @override
  String assignMusicianToDate(String date) {
    return 'Asignar Músico a $date';
  }

  @override
  String get bandMemberLabel => 'Miembro de la Banda';

  @override
  String get assignedRoleForService => 'Rol Asignado para el Servicio';

  @override
  String get assignToLineupAction => 'Asignar a Alineación';

  @override
  String get noArrangementGroupsYet =>
      'Aún no se han creado grupos de arreglos.';

  @override
  String get assignGroupToService => 'Asignar Grupo a Servicio';

  @override
  String get addRepetitiveScheduleRule => 'Agregar Regla de Horario Repetitivo';

  @override
  String aheadCount(int count) {
    return '$count por delante';
  }

  @override
  String get fullNameRequired => 'Nombre Completo *';

  @override
  String get rolesInstrumentsRequired => 'Roles e Instrumentos *';

  @override
  String rolesSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get selectAtLeastOneRole =>
      'Selecciona al menos un rol (los músicos pueden tener múltiples roles)';

  @override
  String get vocalTessituraRange => 'Tesitura Vocal (Rango)';

  @override
  String get generalAvailabilityLabel => 'Disponibilidad General';

  @override
  String get notesAssignmentLabel => 'Notas / Asignación';

  @override
  String get serviceTitleRequired => 'Título del Servicio *';

  @override
  String get serviceTypeLabel => 'Tipo de Servicio';

  @override
  String get recurrenceScheduleLabel => 'Horario de Repetición';

  @override
  String get occurrencesToGenerate => 'Ocurrencias a Generar';

  @override
  String get locationVenueLabel => 'Ubicación / Lugar';

  @override
  String get callTimeInstructionsLabel =>
      'Hora de Convocatoria e Instrucciones';

  @override
  String get singleDateOnly => '1 servicio (Solo una fecha)';

  @override
  String seriesCountServices(int count, int weeks) {
    return '$count servicios ($weeks semanas por delante)';
  }

  @override
  String cantAttendCoverNeeded(String role) {
    return 'No puede asistir — falta suplente para $role';
  }

  @override
  String get statusUnavailableNeedsSub =>
      'Estado general es No Disponible — puede necesitar suplente';

  @override
  String get networkErrorNoInternet =>
      'Error de red: No se pudo conectar con Gemini AI. Revisa tu conexión a internet o inténtalo de nuevo.';

  @override
  String get omrTimeoutError =>
      'El análisis de IA tardó demasiado. Comprueba tu conexión a internet o inténtalo de nuevo.';

  @override
  String get geminiApiKeyNotConfigured =>
      'La clave de API de Gemini no está configurada. Por favor configúrala en Ajustes.';

  @override
  String get omrParseError =>
      'No se pudo transcribir la partitura. Asegúrate de que la imagen sea nítida e inténtalo de nuevo.';

  @override
  String scanTitlePrefix(String title) {
    return 'Título: $title';
  }

  @override
  String scanSectionsCount(int count) {
    return 'Secciones: $count';
  }

  @override
  String scanSectionName(String name) {
    return 'Sección: $name';
  }

  @override
  String scanMeasuresCount(int count) {
    return 'Compases: $count';
  }

  @override
  String get removeMember => 'Eliminar Integrante';

  @override
  String get memberOptionsTooltip => 'Opciones del integrante';

  @override
  String get musicianViewLabel => 'Vista de Músico';

  @override
  String replaceMemberAction(String name) {
    return 'Reemplazar a $name';
  }

  @override
  String get showLabel => 'Mostrar: ';

  @override
  String get recurringServiceSchedules => 'Horarios de Servicios Recurrentes';

  @override
  String get recurringSchedulesSubtitle =>
      'Cada evento repetitivo es una instancia recurrente única. Ajusta la proyección continua (X eventos por delante) o establece una fecha límite para dejar de generar eventos.';

  @override
  String get noRecurringSchedulesYet =>
      'Aún no hay horarios recurrentes configurados.';

  @override
  String get schedulePausedNotice =>
      'Horario en Pausa — no se generan ocurrencias';

  @override
  String get disableSinceDate => 'Desactivar desde fecha...';

  @override
  String disabledFromDate(String date) {
    return 'Desactivado desde $date';
  }

  @override
  String updatedMemberSuccess(String name) {
    return '¡$name actualizado!';
  }

  @override
  String addedMemberSuccess(String name) {
    return '¡$name añadido al equipo!';
  }

  @override
  String updatedServiceSuccess(String title) {
    return '¡$title actualizado!';
  }

  @override
  String scheduledServiceSuccess(String title) {
    return '¡$title programado!';
  }

  @override
  String recurringScheduleSuccess(String title, int count) {
    return '¡Horario recurrente configurado para $title (mostrando próximos $count eventos)!';
  }

  @override
  String assignedMusicianSuccess(String name, String title) {
    return '¡$name asignado a $title!';
  }

  @override
  String assignedGroupSuccess(String group, int count, String date) {
    return '¡$group ($count integrantes) asignado a $date!';
  }

  @override
  String get editTeamMember => 'Editar Integrante del Equipo';

  @override
  String get addTeamMember => 'Añadir Integrante del Equipo';

  @override
  String get tapToToggleRoles =>
      'Toca para alternar roles (ej. Pianista + Voz + Guitarrista):';

  @override
  String get vocalTessituraDiscardedTitle =>
      'Tesitura Vocal: Omitida (Instrumental)';

  @override
  String get vocalTessituraDiscardedSubtitle =>
      'Omitida automáticamente porque solo se seleccionaron instrumentos o roles de producción.';

  @override
  String get arrangementGroupsSubteams => 'Grupos de Arreglos / Subequipos';

  @override
  String groupsAssignedCount(int count) {
    return '$count asignados';
  }

  @override
  String get memberRotatingTeamsSubtitle =>
      'El integrante puede pertenecer a varios equipos rotativos:';

  @override
  String get administratorRole => 'Rol de Administrador';

  @override
  String get administratorRoleSubtitle =>
      'Otorga autoridad para crear canciones, programar servicios y asignar suplentes.';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get addMemberAction => 'Añadir Integrante';

  @override
  String get editServiceEvent => 'Editar Evento de Servicio';

  @override
  String get addServiceRehearsal => 'Añadir Servicio / Ensayo';

  @override
  String groupMembersCount(int count) {
    return '$count integrantes';
  }

  @override
  String unavailableCountSubtitle(int count) {
    return '$count no disponibles';
  }

  @override
  String get attachReferenceAudio => 'Adjuntar Audio de Referencia';

  @override
  String get attachAudioInstructions =>
      'Selecciona un archivo de audio o pega un enlace de ensayo (MP3, WAV, M4A):';

  @override
  String get audioTrackSource => 'Fuente de la Pista de Audio';

  @override
  String get attachTrackAction => 'Adjuntar Pista';

  @override
  String get practiceReference => 'Referencia de Ensayo';

  @override
  String metronomeClickTooltip(int tempo) {
    return 'Clic de Metrónomo ($tempo BPM)';
  }

  @override
  String get attachAudioTrackTooltip => 'Adjuntar Pista de Audio';

  @override
  String loopingPrefix(String section) {
    return 'Bucle: $section';
  }

  @override
  String get playbackSpeedTooltip => 'Velocidad de Reproducción';

  @override
  String speedLabel(double speed) {
    return '$speed× Velocidad';
  }

  @override
  String rewindSecondsTooltip(int seconds) {
    return 'Retroceder $seconds segundos';
  }

  @override
  String forwardSecondsTooltip(int seconds) {
    return 'Adelantar $seconds segundos';
  }

  @override
  String get pauseAction => 'Pausa';

  @override
  String get playAction => 'Reproducir';

  @override
  String get loopSectionTooltip => 'Repetir Sección en Bucle';

  @override
  String get noLoopFullSong => 'Sin Bucle (Canción Completa)';

  @override
  String loopSectionItem(String section) {
    return 'Bucle: $section';
  }

  @override
  String get createService => 'Crear Servicio';

  @override
  String createSeriesCount(int count) {
    return 'Crear Serie ($count)';
  }

  @override
  String get lyricsAndChords => 'Letra y Acordes';

  @override
  String get alignChordsAction => 'Alinear Acordes';

  @override
  String get karaokeAlignTitle => 'Alineación de Acordes Karaoke';

  @override
  String get karaokeAlignSubtitle =>
      'Toca un acorde y luego la palabra donde entra.';

  @override
  String get visualTapMode => 'Toque Visual / Karaoke';

  @override
  String get chordProTextMode => 'Texto ChordPro';

  @override
  String get chordPalette => 'Paleta de Acordes';

  @override
  String get addChordLabel => 'Agregar Acorde';

  @override
  String get eraserMode => 'Borrador';

  @override
  String get autoAlignAction => 'Distribuir Auto';

  @override
  String get clearChordsAction => 'Quitar Acordes';

  @override
  String get liveCueMode => 'Cue en Vivo';

  @override
  String get stopCueMode => 'Detener Cue';

  @override
  String get chordProEditorInstructions =>
      'Edita notación ChordPro directamente. Escribe los acordes entre corchetes antes de las palabras: [G]Sublime [C]gracia';

  @override
  String get noLyricsForSection =>
      'Esta sección aún no tiene letra ni acordes alineados.';
}
