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
  String get viewModeBoth => 'Ambos';

  @override
  String get viewModeLyricsOnly => 'Solo letra';

  @override
  String get viewModeChordsOnly => 'Solo acordes';

  @override
  String get instrumentalSection => 'Instrumental (Sin letra)';

  @override
  String get noChordsForSection =>
      'No hay acordes ingresados para esta sección.';

  @override
  String get noAudioAttachedTitle => 'Sin Audio de Referencia Adjunto';

  @override
  String get noAudioAttachedSubtitle =>
      'Adjunta un MP3, WAV o pista guía de ensayo para reproducción y cambio de tono';

  @override
  String get attachAudioAction => 'Adjuntar Audio';

  @override
  String get detachAudioAction => 'Desvincular Audio';

  @override
  String get noMembersInRoster => 'Sin Miembros en la Plantilla';

  @override
  String get noMembersInRosterSubtitle =>
      'Invita personas a tu organización para formar tu equipo.';

  @override
  String get noEventsInCalendar => 'Sin Servicios ni Ensayos Programados';

  @override
  String get noEventsInCalendarSubtitle => 'Toca + para programar un evento.';

  @override
  String get localWorkspace => 'Espacio de Trabajo Local';

  @override
  String get localOfflineTier => 'Desconectado';

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
  String get tapAddSongHint => 'Toca + para añadir canciones y armar tu lista.';

  @override
  String get setlistStatSongs => 'Canciones';

  @override
  String get setlistStatAvgBpm => 'BPM medio';

  @override
  String get setlistOrderHeader => 'Orden';

  @override
  String get setlistDragHint => 'Arrastra para reordenar';

  @override
  String setlistItemNote(String note) {
    return 'Nota: $note';
  }

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

  @override
  String get duplicateSection => 'Duplicar sección';

  @override
  String sectionDuplicatedNotice(String name) {
    return 'Se duplicó $name';
  }

  @override
  String sectionPreloadedNotice(String name) {
    return 'Se precargaron acordes y letra del $name anterior';
  }

  @override
  String preloadFromPrevious(String name) {
    return 'Precargar de $name anterior';
  }

  @override
  String get copyFromExistingSection => 'Copiar de otra sección...';

  @override
  String get copySectionContent => 'Copiar Contenido';

  @override
  String get addSongToRepertoire => 'Agregar Canción al Repertorio';

  @override
  String get importByWebUrl => 'Importar por Enlace Web';

  @override
  String get importByWebUrlSubtitle =>
      'Obtén acordes y letra desde Cifra Club, LaCuerda o enlace web';

  @override
  String get scanWithGemini => 'Escanear con IA Gemini (OMR)';

  @override
  String get scanWithGeminiSubtitle =>
      'Escanea partituras impresas desde la cámara o fotos';

  @override
  String get writeInSongEditor => 'Escribir en el Editor de Canciones';

  @override
  String get writeInSongEditorSubtitle =>
      'Crea una partitura en blanco e introduce secciones a mano';

  @override
  String get pasteTextBackup => 'Pegar Texto / Respaldo';

  @override
  String get pasteTextBackupSubtitle =>
      'Pega texto ChordPro, partituras simples o respaldos JSON';

  @override
  String get importTabUrl => 'Importar por URL';

  @override
  String get importTabScan => 'Escanear con Gemini';

  @override
  String get importTabText => 'Pegar Texto / JSON';

  @override
  String get urlInputLabel => 'Enlace Web / URL de la canción';

  @override
  String get urlInputHint =>
      'https://acordes.lacuerda.net/... o cifraclub.com/...';

  @override
  String get pasteFromClipboard => 'Pegar del Portapapeles';

  @override
  String get fetchSong => 'Obtener Canción';

  @override
  String get fetchingSong => 'Obteniendo Canción...';

  @override
  String get supportedWebsites => 'Sitios Web Compatibles y TXT Directo';

  @override
  String get supportedWebsitesHint =>
      'Compatible con LaCuerda (acordes.lacuerda.net) y Cifra Club (cifraclub.com). Los acordes y secciones se procesan automáticamente.';

  @override
  String urlImportSuccess(String title) {
    return '¡Se importó con éxito \"$title\" al Repertorio!';
  }

  @override
  String get urlImportError =>
      'Por favor introduce o pega un enlace de canción válido';

  @override
  String get addToRepertoire => 'Agregar al Repertorio';

  @override
  String get openInEditor => 'Abrir en Editor';

  @override
  String get chordsAndLyricsPreview => 'Vista Previa de Letra y Acordes';

  @override
  String sectionsCount(int count) {
    return '$count secciones';
  }

  @override
  String chordsUsedCount(int count) {
    return '$count acordes usados';
  }

  @override
  String get textImportHeader => 'Pega Texto de Canción o Respaldo JSON';

  @override
  String get loadSample => 'Cargar Ejemplo';

  @override
  String get clear => 'Limpiar';

  @override
  String get textImportPlaceholder =>
      'Pega el texto de tu canción aquí (ej. // Título: Canción, [G] letra...)';

  @override
  String importSongCount(int count) {
    return 'Importar $count Canción(es)';
  }

  @override
  String get scanCameraAction => 'Capturar con la Cámara';

  @override
  String get scanGalleryAction => 'Elegir de Fotos / Galería';

  @override
  String get scanCameraSubtitle =>
      'Toma una foto de una partitura impresa o cifrado';

  @override
  String get scanGallerySubtitle =>
      'Selecciona una imagen de partitura o página PDF del dispositivo';

  @override
  String get cifraClubBlockedNotice =>
      'No se pudo acceder a Cifra Club por protección anti-bot. Copia los acordes y usa la pestaña Pegar Texto, o importa desde LaCuerda.';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get usernameHintHelper => '3-30 caracteres: letras, números, _ o .';

  @override
  String get usernameInvalidHelper =>
      'Usa 3-30 caracteres: letras, números, _ o .';

  @override
  String get usernameCheckingHelper => 'Comprobando...';

  @override
  String get usernameAvailableHelper => 'El nombre de usuario está disponible';

  @override
  String get usernameTakenHelper => 'El nombre de usuario ya está en uso';

  @override
  String get usernameInvalidError =>
      'El nombre de usuario debe tener 3-30 caracteres: letras, números, _ o .';

  @override
  String get usernameTakenError => 'Ese nombre de usuario ya está en uso.';

  @override
  String get welcomeTitle => 'Bienvenido a Battuta';

  @override
  String get welcomeSubtitle =>
      'Tus partituras, setlists y banda, listos para el escenario.';

  @override
  String get welcomeSignIn => 'Iniciar sesión';

  @override
  String get welcomeCreateAccount => 'Crear cuenta';

  @override
  String get welcomeContinueOffline => 'Continuar sin conexión';

  @override
  String get welcomeOfflineNote =>
      'Todo funciona en este dispositivo. Puedes iniciar sesión después desde Ajustes.';

  @override
  String get accountDeactivatedNotice =>
      'Esta cuenta fue desactivada y se cerró la sesión. Su historial se conserva.';

  @override
  String get signInPageTitle => 'Iniciar sesión';

  @override
  String get createAccountPageTitle => 'Crear cuenta';

  @override
  String get authInvalidEmail => 'Introduce un correo electrónico válido.';

  @override
  String get authPasswordTooShort =>
      'La contraseña debe tener al menos 6 caracteres.';

  @override
  String get authMagicLinkSent =>
      '¡Enlace enviado! Revisa tu correo para iniciar sesión.';

  @override
  String get authAccountCreatedCheckEmail =>
      '¡Cuenta creada! Revisa tu correo para confirmarla.';

  @override
  String get authPasswordResetSent =>
      'Correo para restablecer la contraseña enviado.';

  @override
  String get forgotPasswordAction => '¿Olvidaste la contraseña?';

  @override
  String get backendErrorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get backendErrorOffline =>
      'Sin conexión. Conéctate a internet e inténtalo de nuevo.';

  @override
  String get backendErrorNotAdmin =>
      'Solo los administradores de la organización pueden hacer esto.';

  @override
  String get backendErrorNotMember => 'No eres miembro de esta organización.';

  @override
  String get backendErrorLastAdmin =>
      'Una organización necesita al menos un administrador. Nombra primero a otro administrador.';

  @override
  String get backendErrorInvalidName => 'Introduce un nombre válido.';

  @override
  String get backendErrorOrganizationArchived =>
      'Esta organización está archivada.';

  @override
  String get backendErrorNotSignedIn => 'Inicia sesión para hacer esto.';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get accountSignInTile => 'Iniciar sesión';

  @override
  String get accountDeactivateAction => 'Desactivar cuenta';

  @override
  String get accountDeactivateTitle => '¿Desactivar la cuenta?';

  @override
  String get accountDeactivateExplanation =>
      'Se cerrará tu sesión y ya no podrás usar esta cuenta. Tus canciones en este dispositivo se conservan y lo que aportaste a las organizaciones queda como historial.';

  @override
  String accountDeactivateTypeToConfirm(String word) {
    return 'Escribe $word para confirmar.';
  }

  @override
  String get organizationsTitle => 'Organizaciones';

  @override
  String get noOrganizationsYet => 'Aún no hay organización';

  @override
  String get createOrganizationAction => 'Crear organización';

  @override
  String get organizationNameLabel => 'Nombre de la organización';

  @override
  String get allBandsLabel => 'Todas las bandas';

  @override
  String get memberRoleLabel => 'Miembro';

  @override
  String get bandsLabel => 'Bandas';

  @override
  String get adminsLabel => 'Admins';

  @override
  String get rolesInstrumentsLabel => 'Roles e instrumentos';

  @override
  String get rosterSignInTitle => 'Inicia sesión para ver tu equipo';

  @override
  String get rosterSignInMessage =>
      'Las organizaciones, miembros y bandas viven en tu cuenta. Inicia sesión para crear o unirte a una.';

  @override
  String get noOrganizationInvitesNote =>
      'Crea una organización para tu equipo o únete a una con un enlace de invitación.';

  @override
  String get manageBandsAction => 'Gestionar bandas';

  @override
  String get leaveOrganizationAction => 'Salir de la organización';

  @override
  String get leaveOrganizationConfirm =>
      'Perderás el acceso al equipo y al calendario de esta organización.';

  @override
  String removeMemberConfirm(String name) {
    return '¿Quitar a $name de esta organización?';
  }

  @override
  String removedMemberSuccess(String name) {
    return 'Se quitó a $name';
  }

  @override
  String get youBadge => 'Tú';

  @override
  String get editBandAction => 'Editar banda';

  @override
  String get deleteBandAction => 'Eliminar banda';

  @override
  String deleteBandConfirm(String name) {
    return '¿Eliminar $name? Sus miembros permanecen en la organización.';
  }

  @override
  String get newBandAction => 'Nueva banda';

  @override
  String get bandNameLabel => 'Nombre de la banda';

  @override
  String memberSavePartialRole(String reason) {
    return 'Se guardaron algunos cambios, pero no se pudo cambiar el rol. $reason';
  }

  @override
  String memberSavePartialBands(String reason) {
    return 'Se guardaron algunos cambios, pero no se pudieron actualizar las bandas. $reason';
  }

  @override
  String get calendarSignInTitle =>
      'Inicia sesión para planificar servicios con tu organización';

  @override
  String get calendarSignInMessage =>
      'Los servicios, los equipos y las ausencias se comparten con tu organización. Inicia sesión para verlos.';

  @override
  String get myServicesTitle => 'Mis servicios';

  @override
  String get acceptAssignmentAction => 'Aceptar';

  @override
  String get declineAssignmentAction => 'Rechazar';

  @override
  String get declineAssignmentTitle => '¿Rechazar este servicio?';

  @override
  String get declineReasonLabel => 'Motivo (opcional)';

  @override
  String get assignmentStatusAccepted => 'Aceptado';

  @override
  String get assignmentStatusPending => 'Pendiente de respuesta';

  @override
  String get assignmentStatusDeclined => 'Rechazado';

  @override
  String get assignmentStatusAway => 'Ausente';

  @override
  String declinedReasonLine(String reason) {
    return 'Motivo: $reason';
  }

  @override
  String get myAbsencesTitle => 'Mis ausencias';

  @override
  String get noAbsencesYet =>
      'Sin ausencias. Añade los días en que no puedes tocar.';

  @override
  String get addAbsenceAction => 'Añadir ausencia';

  @override
  String get editAbsenceAction => 'Editar ausencia';

  @override
  String get deleteAbsenceAction => 'Eliminar ausencia';

  @override
  String get absenceFromLabel => 'Desde';

  @override
  String get absenceToLabel => 'Hasta';

  @override
  String get absenceNoteLabel => 'Nota (opcional)';

  @override
  String get absenceEndBeforeStart =>
      'La fecha final no puede ser anterior a la inicial.';

  @override
  String absenceRangeLabel(String start, String end) {
    return '$start al $end';
  }

  @override
  String get repeatsLabel => 'Se repite';

  @override
  String get repeatNever => 'No se repite';

  @override
  String lookaheadOption(int count) {
    return 'Mostrar los próximos $count servicios';
  }

  @override
  String get setlistLabel => 'Lista de canciones';

  @override
  String get noSetlistOption => 'Sin lista de canciones';

  @override
  String get repeatingServiceNote =>
      'Esto cambia solo esta fecha. Edita el horario recurrente para cambiar todas.';

  @override
  String deleteServiceConfirm(String title) {
    return '¿Eliminar $title? Su equipo también se elimina.';
  }

  @override
  String get editScheduleTitle => 'Editar horario recurrente';

  @override
  String get noSchedulesYet => 'Aún no hay horarios recurrentes.';

  @override
  String scheduleSummary(String cadence, String time) {
    return '$cadence a las $time';
  }

  @override
  String get scheduleActiveLabel => 'Activo';

  @override
  String get schedulePausedLabel => 'En pausa';

  @override
  String scheduleEndsLabel(String date) {
    return 'Termina el $date';
  }

  @override
  String get pauseScheduleAction => 'Pausar';

  @override
  String get resumeScheduleAction => 'Reanudar';

  @override
  String get stopScheduleAction => 'Terminar desde una fecha';

  @override
  String get deleteScheduleAction => 'Eliminar horario';

  @override
  String deleteScheduleConfirm(String title) {
    return '¿Eliminar $title? Los servicios ya creados se quedan en el calendario.';
  }

  @override
  String assignPickerTitle(String title) {
    return 'Asignar a $title';
  }

  @override
  String get assignInstrumentLabel => 'Instrumento';

  @override
  String get availableOnlyFilter => 'Disponibles';

  @override
  String playsInstrumentFilter(String instrument) {
    return 'Toca $instrument';
  }

  @override
  String get memberAwayThatDay => 'Ausente ese día';

  @override
  String get memberAlreadyAssigned => 'Ya está en este servicio';

  @override
  String get noMembersMatch => 'Ningún miembro coincide.';

  @override
  String memberAssignedSuccess(String name) {
    return '$name añadido al equipo';
  }

  @override
  String memberReassignedSuccess(String name) {
    return 'Reasignado a $name';
  }

  @override
  String get removeFromLineupAction => 'Quitar del equipo';

  @override
  String alertAwayCoverNeeded(String role) {
    return 'Ausente ese día — falta cobertura para $role';
  }

  @override
  String cantAttendCoverNeededFor(String role) {
    return 'Rechazó — falta cobertura para $role';
  }

  @override
  String get noMembersForService => 'Aún no hay miembros para asignar.';

  @override
  String get lineupMemberUnknown => 'Antiguo miembro';

  @override
  String get inviteAction => 'Invitar';

  @override
  String get inviteSheetTitle => 'Invitar personas';

  @override
  String get inviteTabLink => 'Enlace y QR';

  @override
  String get inviteTabUsername => 'Usuario';

  @override
  String get inviteExpiryLabel => 'Caduca en';

  @override
  String get inviteExpiry1Day => '1 día';

  @override
  String get inviteExpiry7Days => '7 días';

  @override
  String get inviteExpiry30Days => '30 días';

  @override
  String get inviteMaxUsesLabel => 'Usos máximos (opcional)';

  @override
  String get inviteMaxUsesInvalid => 'Introduce un número entero de 1 o más';

  @override
  String get inviteBandLabel => 'Banda (opcional)';

  @override
  String get inviteNoBand => 'Sin banda';

  @override
  String get inviteCreateLink => 'Crear enlace';

  @override
  String get inviteLinkLabel => 'Enlace de invitación';

  @override
  String get inviteCopy => 'Copiar';

  @override
  String get inviteLinkCopied => 'Enlace copiado';

  @override
  String get inviteShare => 'Compartir';

  @override
  String inviteShareMessage(String organization, String link) {
    return 'Únete a $organization en Battuta: $link';
  }

  @override
  String get inviteQrSemantics => 'Código QR del enlace de invitación';

  @override
  String get inviteQrHint =>
      'Escanéalo con la cámara de un teléfono o tableta para abrir Battuta.';

  @override
  String get inviteActiveLinksTitle => 'Enlaces activos';

  @override
  String get inviteNoActiveLinks => 'Aún no hay enlaces activos.';

  @override
  String inviteLinkExpires(String date) {
    return 'Caduca el $date';
  }

  @override
  String inviteLinkUsesUnlimited(int count) {
    return '$count usos';
  }

  @override
  String inviteLinkUsesLimited(int count, int max) {
    return '$count de $max usos';
  }

  @override
  String get inviteShowAction => 'Mostrar';

  @override
  String get inviteRevokeAction => 'Revocar';

  @override
  String get inviteSearchLabel => 'Buscar por usuario o nombre';

  @override
  String get inviteSearchHint => 'Escribe al menos 3 caracteres.';

  @override
  String get inviteNoResults => 'No se encontró a nadie.';

  @override
  String get inviteSendAction => 'Invitar';

  @override
  String get inviteSentLabel => 'Invitado';

  @override
  String get inviteAlreadyMemberLabel => 'Miembro';

  @override
  String get invitePreviouslyDeclined => 'Rechazó antes';

  @override
  String inviteSentSnack(String name) {
    return 'Invitación enviada a $name';
  }

  @override
  String get invitePendingTitle => 'Invitaciones pendientes';

  @override
  String get inviteNoPending => 'No hay invitaciones pendientes.';

  @override
  String get inviteCancelAction => 'Cancelar invitación';

  @override
  String get inviteInvitedUserFallback => 'Usuario invitado';

  @override
  String get backendErrorInviteNotFound =>
      'Este enlace de invitación no es válido.';

  @override
  String get backendErrorInviteExpired =>
      'Este enlace de invitación ha caducado.';

  @override
  String get backendErrorInviteRevoked =>
      'Este enlace de invitación fue revocado.';

  @override
  String get backendErrorInviteUsedUp =>
      'Este enlace de invitación ya no tiene usos disponibles.';

  @override
  String get backendErrorAlreadyMember => 'Esa persona ya es miembro.';

  @override
  String get backendErrorAlreadyInvited =>
      'Esa persona ya tiene una invitación pendiente.';

  @override
  String get backendErrorUserNotFound =>
      'No hay ningún usuario activo con ese nombre de usuario.';

  @override
  String get backendErrorCannotInviteSelf => 'No puedes invitarte a ti mismo.';

  @override
  String get backendErrorInvitationNotPending =>
      'Esta invitación ya fue respondida.';

  @override
  String get backendErrorInvitationNotFound => 'Esta invitación ya no existe.';

  @override
  String get backendErrorBandNotInOrganization =>
      'Esa banda no pertenece a esta organización.';

  @override
  String get backendErrorInvalidExpiry => 'Esa caducidad no está permitida.';

  @override
  String get backendErrorInvalidMaxUses =>
      'Ese número de usos no está permitido.';

  @override
  String get joinTitle => 'Unirse a una organización';

  @override
  String get joinJoining => 'Uniéndote…';

  @override
  String get joinFailedTitle => 'No se pudo unir';

  @override
  String get joinRetry => 'Reintentar';

  @override
  String get joinBackToApp => 'Volver a Battuta';

  @override
  String get joinWithLinkAction => 'Unirse con un enlace';

  @override
  String get joinPasteTitle => 'Unirse con un enlace de invitación';

  @override
  String get joinPasteLabel => 'Enlace o código de invitación';

  @override
  String get joinPasteSubmit => 'Unirse';

  @override
  String get joinPasteInvalid =>
      'Ese no es un enlace o código de invitación válido.';

  @override
  String get joinPendingNote =>
      'Invitación guardada. Inicia sesión o crea una cuenta para unirte.';

  @override
  String get joinPendingDismiss => 'Descartar';

  @override
  String get joinConfirmTitle => '¿Unirte a esta organización?';

  @override
  String joinConfirmMessage(String account) {
    return 'Iniciaste sesión como $account. ¿Unirte con el enlace de invitación que abriste?';
  }

  @override
  String get joinConfirmAction => 'Unirme';

  @override
  String get inviteRevokeConfirmTitle => '¿Revocar este enlace?';

  @override
  String get inviteRevokeConfirmBody =>
      'Nadie podrá unirse con él. Podrás crear un enlace nuevo después.';

  @override
  String get joinSuccessSnack => 'Te uniste a la organización.';

  @override
  String invitationFrom(String organization) {
    return '$organization te invitó a unirse.';
  }

  @override
  String get invitationOrganizationFallback => 'Una organización';

  @override
  String get invitationAccept => 'Aceptar';

  @override
  String get invitationDecline => 'Rechazar';

  @override
  String invitationAcceptedSnack(String organization) {
    return 'Te uniste a $organization.';
  }

  @override
  String get invitationDeclinedSnack => 'Invitación rechazada.';

  @override
  String invitationSeeAll(int count) {
    return 'Ver todas las invitaciones ($count)';
  }

  @override
  String get inboxTitle => 'Bandeja de entrada';

  @override
  String get inboxTooltip => 'Bandeja de entrada';

  @override
  String inboxTooltipUnread(int count) {
    return 'Bandeja de entrada, $count nuevas';
  }

  @override
  String get inboxMarkAllRead => 'Marcar todo como leído';

  @override
  String get inboxEmptyTitle => 'Estás al día';

  @override
  String get inboxEmptyMessage =>
      'Aquí aparecen las invitaciones y novedades de tus organizaciones.';

  @override
  String get inboxSignInMessage =>
      'Inicia sesión para ver tus invitaciones y novedades.';

  @override
  String get inboxInvitationsTitle => 'Invitaciones';

  @override
  String get inboxUpdatesTitle => 'Novedades';

  @override
  String get inboxOrganizationGone => 'Ya no estás en esa organización.';

  @override
  String notifInvitation(String organization) {
    return 'Te invitaron a unirte a $organization';
  }

  @override
  String notifRoleChanged(String organization, String role) {
    return 'Tu rol en $organization ahora es $role';
  }

  @override
  String notifRemoved(String organization) {
    return 'Te quitaron de $organization';
  }

  @override
  String notifMemberProfileEdited(String organization, String fields) {
    return 'Un administrador actualizó tu perfil en $organization: $fields';
  }

  @override
  String notifEventAssigned(String event) {
    return 'Te asignaron a $event';
  }

  @override
  String notifEventUnassigned(String event) {
    return 'Te quitaron de $event';
  }

  @override
  String notifAssignmentDeclined(String event) {
    return 'Un miembro rechazó $event';
  }

  @override
  String notifArchiveRequested(String organization) {
    return 'Se solicitó archivar $organization';
  }

  @override
  String notifArchiveCancelled(String organization) {
    return 'Se canceló el archivado de $organization';
  }

  @override
  String notifArchiveCompleted(String organization) {
    return '$organization fue archivada';
  }

  @override
  String get notifSongVersionForked =>
      'Alguien hizo una copia de uno de tus arreglos';

  @override
  String get notifUnknown => 'Tienes una notificación nueva';

  @override
  String get notifOrganizationFallback => 'tu organización';

  @override
  String get notifEventFallback => 'un servicio';

  @override
  String get notifFieldInstruments => 'instrumentos';

  @override
  String get notifFieldMinPitch => 'nota más grave';

  @override
  String get notifFieldMaxPitch => 'nota más aguda';

  @override
  String get notifFieldNotes => 'notas';

  @override
  String get notifFieldsFallback => 'datos del perfil';

  @override
  String get timeJustNow => 'Ahora mismo';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String get repertoireScopeMyLibrary => 'Mi biblioteca';

  @override
  String repertoireScopeOrganization(String name) {
    return 'Repertorio de $name';
  }

  @override
  String get repertoireScopeLabel => 'Repertorio a mostrar';

  @override
  String get repertoireSearchHint => 'Buscar título, artista o etiqueta';

  @override
  String get orgSettingsTooltip => 'Ajustes de la organización';

  @override
  String get orgRepertoireEmptyTitle =>
      'Este repertorio aún no tiene canciones';

  @override
  String get orgRepertoireEmptyAdminHint =>
      'Añade versiones compartidas con esta organización, o públicas.';

  @override
  String get orgRepertoireEmptyMemberHint =>
      'Los administradores aún no han añadido canciones.';

  @override
  String get addToRepertoireAction => 'Añadir al repertorio';

  @override
  String get removeFromRepertoireAction => 'Quitar del repertorio';

  @override
  String get removeFromRepertoireTitle => '¿Quitar del repertorio?';

  @override
  String removeFromRepertoireConfirm(String title) {
    return '\"$title\" saldrá del repertorio. Las entradas de listas que lo usan conservan el título, pero ya no se podrán abrir.';
  }

  @override
  String removeFromRepertoireDone(String title) {
    return 'Se quitó \"$title\" del repertorio';
  }

  @override
  String addedToRepertoireDone(String title) {
    return 'Se añadió \"$title\" al repertorio';
  }

  @override
  String get repertoirePickerTitle => 'Añadir al repertorio';

  @override
  String get repertoirePickerSearchLabel =>
      'Buscar canciones compartidas y públicas';

  @override
  String get repertoirePickerEmpty =>
      'No hay versiones. Una versión debe estar compartida con esta organización o ser pública.';

  @override
  String get repertoirePickerAdded => 'Añadida';

  @override
  String get repertoirePickerYours => 'Tuya';

  @override
  String repertoirePickerAddTooltip(String title) {
    return 'Añadir $title';
  }

  @override
  String ownedByName(String name) {
    return 'De $name';
  }

  @override
  String ownedByDeactivated(String name) {
    return 'De $name (desactivado)';
  }

  @override
  String get ownerUnknown => 'otro usuario';

  @override
  String get readOnlyVersionHint =>
      'Esta versión es de solo lectura. Puedes verla y transponerla aquí, pero solo su dueño puede editarla.';

  @override
  String get readOnlyVersionEditorNotice =>
      'Solo el dueño puede editar esta versión.';

  @override
  String get orgSetlistsEmptyAdminHint =>
      'Crea una lista para esta organización a partir de su repertorio.';

  @override
  String get orgSetlistsEmptyMemberHint =>
      'Aún no hay listas. Los administradores las publican aquí.';

  @override
  String get setlistReadOnlyNotice =>
      'Solo los administradores pueden editar esta lista. Aún puedes abrir las canciones y transponerlas.';

  @override
  String setlistCreateFailed(String error) {
    return 'No se pudo guardar la lista: $error';
  }

  @override
  String get backendErrorNotOwner =>
      'Solo el dueño puede cambiar esta versión.';

  @override
  String get backendErrorPermissionDenied =>
      'No tienes permiso para eso, o la canción ya no está disponible para esta organización.';

  @override
  String get backendErrorArchiveAlreadyRequested => 'Ya se pidió archivar.';

  @override
  String get backendErrorArchiveNotRequested =>
      'No hay una solicitud de archivado que responder.';

  @override
  String get orgSettingsTitle => 'Ajustes de la organización';

  @override
  String get orgSettingsNotFound => 'Esta organización no está disponible.';

  @override
  String get orgSettingsYourRole => 'Tu rol';

  @override
  String get orgSettingsRenameAction => 'Renombrar';

  @override
  String get orgSettingsRenameTitle => 'Renombrar organización';

  @override
  String get orgSettingsRenamed => 'Organización renombrada';

  @override
  String get orgSettingsQuotaTitle => 'Plan y cuota';

  @override
  String orgSettingsQuotaTier(String tier) {
    return 'Plan: $tier';
  }

  @override
  String orgSettingsQuotaCredits(int count) {
    return '$count créditos de IA al mes';
  }

  @override
  String orgSettingsQuotaStorage(String size) {
    return 'Almacenamiento: $size';
  }

  @override
  String get orgSettingsQuotaUnavailable =>
      'La cuota no está disponible sin conexión.';

  @override
  String get orgSettingsLeaveHint =>
      'Si eres el único administrador, nombra antes a otro miembro administrador.';

  @override
  String get orgSettingsLeaveDone => 'Saliste de la organización';

  @override
  String get orgSettingsArchivedNotice =>
      'Esta organización está archivada y es de solo lectura.';

  @override
  String get orgArchiveSection => 'Archivar organización';

  @override
  String get orgArchiveWarning =>
      'Archivar no se puede deshacer desde la app. La organización pasa a solo lectura y desaparece de tu selector. Todos los administradores deben aprobarlo.';

  @override
  String get orgArchiveRequestAction => 'Pedir archivado';

  @override
  String orgArchiveRequestedBy(String name) {
    return 'Pedido por $name';
  }

  @override
  String get orgArchiveApprovalsTitle => 'Aprobaciones de administradores';

  @override
  String get orgArchiveApproved => 'Aprobó';

  @override
  String get orgArchivePending => 'Pendiente';

  @override
  String get orgArchiveApproveAction => 'Aprobar archivado';

  @override
  String get orgArchiveCancelAction => 'Cancelar solicitud';

  @override
  String orgArchiveConfirmTitle(String name) {
    return '¿Archivar $name?';
  }

  @override
  String get orgArchiveConfirmBody =>
      'Esto no se puede deshacer desde la app. Escribe el nombre de la organización para confirmar.';

  @override
  String orgArchiveTypeToConfirm(String name) {
    return 'Escribe \"$name\"';
  }

  @override
  String get orgArchiveConfirmAction => 'Archivar';

  @override
  String get orgArchiveRequestSent =>
      'Archivado pedido. Los demás administradores deben aprobarlo.';

  @override
  String get orgArchiveApprovedDone => 'Se registró tu aprobación';

  @override
  String get orgArchiveCancelledDone => 'Solicitud de archivado cancelada';

  @override
  String get orgArchiveDone => 'La organización se archivó';

  @override
  String get repertoireEntrySyncing => 'Sincronizando…';

  @override
  String get repertoireEntryAfterSync =>
      'Disponible tras la próxima sincronización';

  @override
  String get sharingButton => 'Compartir';

  @override
  String get sharingSheetTitle => 'Compartir';

  @override
  String get sharingLabelField => 'Nombre de la versión';

  @override
  String get sharingWhoCanSee => 'Quién puede ver esta versión';

  @override
  String get sharingPrivateTitle => 'Solo yo';

  @override
  String get sharingPrivateHint => 'Solo tú la ves.';

  @override
  String get sharingOrganizationsTitle => 'Mis organizaciones';

  @override
  String get sharingOrganizationsHint =>
      'Los miembros de las organizaciones que elijas pueden abrirla y hacer su propia copia.';

  @override
  String get sharingPublicTitle => 'Pública';

  @override
  String get sharingPublicHint =>
      'Cualquiera con sesión iniciada puede encontrarla, abrirla y hacer su propia copia.';

  @override
  String get sharingPickOrganizations => 'Compartir con';

  @override
  String get sharingNoOrganizations =>
      'Únete a una organización para compartir con ella.';

  @override
  String get sharingPickOne => 'Elige al menos una organización.';

  @override
  String get sharingSyncNote =>
      'Se guarda en este dispositivo. Los demás verán el cambio cuando tengas conexión.';

  @override
  String get sharingSave => 'Guardar';

  @override
  String get sharingSaved => 'Se actualizó cómo se comparte';

  @override
  String get visibilityPrivate => 'Privada';

  @override
  String get visibilityOrganizations => 'Organizaciones';

  @override
  String get visibilityPublic => 'Pública';

  @override
  String get versionsOtherTitle => 'Otras versiones';

  @override
  String get versionsAllTitle => 'Versiones';

  @override
  String get versionsLoading => 'Buscando más versiones…';

  @override
  String get versionsEmpty => 'Aún no hay otras versiones.';

  @override
  String get versionsOfflineNote =>
      'Sin conexión: se muestran las versiones guardadas en este dispositivo.';

  @override
  String get versionYours => 'Tuya';

  @override
  String get versionFork => 'Bifurcación';

  @override
  String versionForkOf(String label) {
    return 'Bifurcación de $label';
  }

  @override
  String get versionOnDevice => 'En este dispositivo';

  @override
  String get versionNeedsInternet => 'Conéctate para abrir esta versión.';

  @override
  String versionOpenTooltip(String label) {
    return 'Abrir $label';
  }

  @override
  String get forkButton => 'Bifurcar a mi biblioteca';

  @override
  String forkTooltip(String label) {
    return 'Bifurcar $label a mi biblioteca';
  }

  @override
  String get forkDialogTitle => 'Bifurcar esta versión';

  @override
  String get forkDialogBody =>
      'Obtienes tu propia copia para editar. El original no cambia.';

  @override
  String get forkLabelField => 'Nombre de tu copia';

  @override
  String forkDefaultLabel(String label) {
    return '$label (copia)';
  }

  @override
  String get forkConfirm => 'Bifurcar';

  @override
  String get forkDone => 'Se bifurcó a tu biblioteca';

  @override
  String get forkDoneOffline =>
      'Bifurcada en este dispositivo. Se sincroniza cuando tengas conexión.';

  @override
  String get songTitleLockedHint =>
      'El título y el artista pertenecen a la canción. Solo quien la creó puede cambiarlos.';

  @override
  String get songPageTitle => 'Canción';

  @override
  String get songPageNeedsInternet =>
      'Conéctate para ver todas las versiones de esta canción.';

  @override
  String get discoverTitle => 'Descubrir';

  @override
  String get discoverTooltip => 'Descubrir canciones públicas';

  @override
  String get discoverHint =>
      'Versiones públicas compartidas por otros músicos. Ábrelas para leerlas o bifúrcalas a tu biblioteca.';

  @override
  String get discoverSearchLabel => 'Buscar canciones públicas';

  @override
  String get discoverEmpty => 'No hay canciones públicas que coincidan.';

  @override
  String get discoverNeedsInternet => 'Descubrir requiere conexión a internet.';

  @override
  String get discoverSignIn =>
      'Inicia sesión para descubrir canciones públicas.';

  @override
  String get backendErrorVersionNotFound =>
      'Esa versión ya no está disponible.';

  @override
  String get backendErrorSongNotFound => 'Esa canción ya no está disponible.';

  @override
  String get discoverLoadMore => 'Cargar más';

  @override
  String get songLinkSuggestionsTitle => '¿Es una de estas canciones?';

  @override
  String get songLinkSuggestionsHint =>
      'Elige una canción para añadir tu versión. Si no, se crea una canción nueva.';

  @override
  String songLinkVersionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versiones',
      one: '1 versión',
    );
    return '$_temp0';
  }

  @override
  String get songLinkNewSong => 'Canción nueva';

  @override
  String songLinkNewSongSubtitle(String title) {
    return 'Crear “$title”';
  }

  @override
  String songLinkLinkedTo(String title) {
    return 'Versión de “$title”';
  }

  @override
  String get songLinkChange => 'Cambiar';

  @override
  String get songLinkOfflineNote =>
      'Se muestran las canciones guardadas en este dispositivo.';

  @override
  String get songLinkSheetTitle => '¿Qué canción es?';

  @override
  String songLinkSheetBody(String title) {
    return '“$title” se parece a una canción que ya existe. Añade tu versión a ella o crea una canción nueva.';
  }

  @override
  String get moveToSongButton => 'Mover a otra canción';

  @override
  String get moveToSongTitle => 'Mover a otra canción';

  @override
  String moveToSongIntro(String title) {
    return 'Elige la canción a la que pertenece “$title”. Tu versión se mueve allí y muestra el título y el artista de esa canción.';
  }

  @override
  String get moveToSongSearchLabel => 'Buscar canciones';

  @override
  String get moveToSongNoResults => 'No hay canciones que coincidan.';

  @override
  String get moveToSongAction => 'Mover aquí';

  @override
  String get moveToSongConfirmTitle => '¿Mover esta versión?';

  @override
  String moveToSongConfirmBody(String song) {
    return 'Esta versión se moverá a “$song”. Las listas y los repertorios la siguen usando.';
  }

  @override
  String moveToSongDone(String song) {
    return 'Versión movida a “$song”';
  }

  @override
  String get versionUnavailableTitle => 'Esta versión ya no está disponible';

  @override
  String get versionUnavailableBody =>
      'Se eliminó, se hizo privada o ya no se comparte contigo.';

  @override
  String get backendErrorNotVersionOwner =>
      'Solo el dueño de una versión puede moverla.';

  @override
  String get backendErrorSongExists =>
      'Ya existe una canción con ese título y artista. Mueve tu versión a ella.';

  @override
  String get supabasePresetRemote => 'Remoto';

  @override
  String get supabasePresetLocal => 'Local';

  @override
  String get supabaseUrlInvalid => 'La URL debe empezar con https:// o http://';

  @override
  String get supabaseKeyEmpty => 'Introduce la clave pública del proyecto';

  @override
  String supabaseUnreachable(String host) {
    return 'No se pudo conectar con $host. Revisa la URL, la clave y tu red.';
  }

  @override
  String supabaseConnectedTo(String host) {
    return 'Conectado a $host';
  }

  @override
  String supabaseSavedRestart(String host) {
    return 'Guardado. Cierra y vuelve a abrir Battuta para conectarte a $host.';
  }

  @override
  String get authAccountCreatedConfirmThenSignIn =>
      '¡Cuenta creada! Confírmala desde el correo que te enviamos y luego inicia sesión aquí.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileAvatarTooltip => 'Perfil';

  @override
  String get profileEditAction => 'Editar perfil';

  @override
  String get profileDisplayNameLabel => 'Nombre';

  @override
  String get profileDisplayNameInvalid =>
      'Escribe un nombre de hasta 80 caracteres.';

  @override
  String get profileSaved => 'Perfil actualizado';

  @override
  String get profileLoadingEditHint =>
      'Tu perfil aún no se ha cargado. Conéctate a internet para editarlo.';

  @override
  String get profileMyOrganizations => 'Mis organizaciones';

  @override
  String get profileNoInstruments => 'Aún sin instrumentos';

  @override
  String get profileOrganizationOptionsTooltip => 'Opciones de la organización';

  @override
  String get profileEditInstruments => 'Editar mis instrumentos';

  @override
  String profileInstrumentsIn(String organization) {
    return 'Mis instrumentos en $organization';
  }

  @override
  String get profileInstrumentsSaved => 'Instrumentos actualizados';

  @override
  String get profileActiveOrganizationBadge => 'Activa';

  @override
  String get profileLeaveAdminHint =>
      'Los administradores deben ceder el rol de administrador en los ajustes de la organización antes de salir.';

  @override
  String get profileOrganizationOpenSettings => 'Ajustes de la organización';

  @override
  String get profileMoreTooltip => 'Más opciones';

  @override
  String get photoSheetPersonTitle => 'Foto de perfil';

  @override
  String get photoSheetPersonSubtitle =>
      'La ven tus compañeros y aparece en tus canciones';

  @override
  String get photoSheetLogoTitle => 'Logo de la organización';

  @override
  String get photoSheetLogoSubtitle =>
      'Lo ven todos los miembros de la organización';

  @override
  String get photoSheetHintCircle =>
      'Elige una foto y pellizca y arrastra para ajustarla al círculo';

  @override
  String get photoSheetHintSquare =>
      'Elige una foto y pellizca y arrastra para ajustarla al cuadrado';

  @override
  String get photoTakeAction => 'Tomar foto';

  @override
  String get photoChooseAction => 'Elegir foto';

  @override
  String get photoSaveAction => 'Guardar foto';

  @override
  String get photoRemoveAction => 'Quitar foto';

  @override
  String get photoUpdated => 'Foto actualizada';

  @override
  String get photoRemoved => 'Foto eliminada';

  @override
  String get photoPickFailed =>
      'No se pudo abrir la cámara ni la fototeca. Revisa los permisos de la app en Ajustes.';

  @override
  String get photoChangeTooltip => 'Cambiar foto';

  @override
  String get organizationLogoChangeTooltip => 'Cambiar logo de la organización';

  @override
  String get backendErrorImageTooLarge =>
      'Esa foto es demasiado grande. Elige una más pequeña.';

  @override
  String get profileStatOrganizations => 'Organizaciones';

  @override
  String get profileStatVersions => 'Versiones';

  @override
  String get profileStatUpcoming => 'Próximos';

  @override
  String get profileAppSettings => 'Ajustes de la app';

  @override
  String get profileDeactivateHint => 'Desactivar la cuenta está en el menú ⋯';

  @override
  String get profileSwitchToOrganization => 'Cambiar a esta organización';

  @override
  String get profileViewOrganization => 'Ver organización';

  @override
  String get organizationProfileTitle => 'Organización';

  @override
  String get organizationYouAreAdmin => 'ERES ADMINISTRADOR';

  @override
  String get organizationAddDescription => 'Añade una descripción';

  @override
  String get organizationStatMembers => 'Miembros';

  @override
  String get organizationStatSongs => 'Canciones';

  @override
  String get organizationManageAction => 'Gestionar';

  @override
  String get organizationMembersHeading => 'Miembros';

  @override
  String organizationSeeAll(int count) {
    return 'Ver los $count';
  }

  @override
  String get organizationNoBands => 'Aún no hay bandas';

  @override
  String get organizationNextUp => 'Próximo';

  @override
  String get organizationNoUpcoming => 'No hay servicios próximos';

  @override
  String get organizationMemberDeactivated => 'Cuenta desactivada';

  @override
  String get organizationEditTitle => 'Editar perfil de la organización';

  @override
  String get organizationDescriptionLabel => 'Descripción';

  @override
  String get organizationProfileSaved => 'Organización actualizada';

  @override
  String get organizationNotFound => 'Esta organización ya no está disponible.';

  @override
  String get photoCropTitle => 'Ajustar foto';

  @override
  String get songScreenTitle => 'Canción';

  @override
  String songOriginalKey(String key) {
    return 'Original: $key';
  }

  @override
  String get songStatBpm => 'BPM';

  @override
  String get songStatTime => 'Compás';

  @override
  String get transposeLabel => 'Transponer';

  @override
  String get transposeAndSave => 'Transponer y guardar';

  @override
  String get addToSetlist => 'Añadir a lista';

  @override
  String get addToSetlistEmpty =>
      'Aún no hay listas donde añadir esta canción. Crea una en la pestaña Listas.';

  @override
  String addedToSetlist(String setlist) {
    return 'Añadida a $setlist';
  }

  @override
  String get alreadyInSetlist => 'Ya añadida';

  @override
  String get moreOptions => 'Más opciones';

  @override
  String get generalSection => 'General';

  @override
  String get themeStage => 'Escenario';

  @override
  String get themeRehearsal => 'Ensayo';

  @override
  String get languageSystemDefault => 'Sistema';

  @override
  String get accountSyncSection => 'Cuenta y sincronización';

  @override
  String get serverLabel => 'Servidor';

  @override
  String get syncOfflineTitle => 'Sin conexión';

  @override
  String get syncSavedOnDevice => 'Todo se guarda también en este dispositivo';

  @override
  String syncLastSyncedAt(String time) {
    return 'Última sincronización: $time';
  }
}
