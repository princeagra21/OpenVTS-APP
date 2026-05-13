import 'dart:async';

import 'package:open_vts/core/observability/observability_service.dart';

class MapPerformanceDiagnostics {
  MapPerformanceDiagnostics({ObservabilityService? observability})
      : _observability = observability;

  final ObservabilityService? _observability;

  int activeMarkerCount = 0;
  int lastBatchSize = 0;
  int frameWarningCount = 0;
  Duration? lastHistoryProcessingDuration;

  void recordMarkerBatch({required int markerCount, required int batchSize}) {
    activeMarkerCount = markerCount;
    lastBatchSize = batchSize;
    unawaited(
      _observability?.recordMetric(
            'map.marker_batch_size',
            batchSize,
            tags: <String, Object?>{'activeMarkers': markerCount},
          ) ??
          Future<void>.value(),
    );
  }

  void recordFrameWarning() {
    frameWarningCount += 1;
    unawaited(
      _observability?.recordMetric('map.frame_warning_count', frameWarningCount) ?? Future<void>.value(),
    );
  }

  void recordHistoryProcessing(Duration duration) {
    lastHistoryProcessingDuration = duration;
    unawaited(
      _observability?.recordMetric(
            'map.history_processing_ms',
            duration.inMilliseconds,
          ) ??
          Future<void>.value(),
    );
  }
}
