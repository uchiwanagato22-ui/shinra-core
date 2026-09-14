import 'package:flutter/material.dart';
import 'video_export.dart';
import 'gif_export.dart';
import '../models/rig.dart';
import 'dart:io';

/// Central export handler that manages MP4, GIF, and PNG exports.
class ExportHandler {
  /// Show export options dialog and handle selection
  static Future<void> showExportDialog(
    BuildContext context,
    GlobalKey viewportKey,
    ProjectState project,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        viewportKey: viewportKey,
        project: project,
      ),
    );
  }
}

class ExportDialog extends StatefulWidget {
  const ExportDialog({
    super.key,
    required this.viewportKey,
    required this.project,
  });

  final GlobalKey viewportKey;
  final ProjectState project;

  @override State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  VideoExporter.ExportFormat format = VideoExporter.ExportFormat.tiktok;
  int fps = 30;
  bool isExporting = false;
  double progress = 0;
  String status = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Animation'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Format:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final fmt in VideoExporter.ExportFormat.values)
                  ChoiceChip(
                    label: Text(fmt.name.toUpperCase()),
                    selected: format == fmt,
                    onSelected: (selected) {
                      if (selected) setState(() => format = fmt);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('FPS:', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: fps.toDouble(),
              min: 12,
              max: 60,
              divisions: 6,
              label: '$fps FPS',
              onChanged: (v) => setState(() => fps = v.toInt()),
            ),
            if (isExporting) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text(status, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isExporting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isExporting ? null : () => _startExport(),
          child: Text(isExporting ? 'Exporting...' : 'Export'),
        ),
      ],
    );
  }

  Future<void> _startExport() async {
    setState(() {
      isExporting = true;
      progress = 0;
      status = 'Initializing...';
    });

    try {
      String resultPath;

      if (format == VideoExporter.ExportFormat.gif) {
        resultPath = await GifExporter.export(
          widget.viewportKey,
          widget.project,
          fps: fps,
          onProgress: (current, total) {
            setState(() {
              progress = current / total;
              status = 'Rendering frame $current / $total';
            });
          },
        );
      } else if (format == VideoExporter.ExportFormat.png) {
        resultPath = await VideoExporter.exportPngSequence(
          widget.viewportKey,
          widget.project,
          fps: fps,
          onProgress: (current, total) {
            setState(() {
              progress = current / total;
              status = 'Rendering frame $current / $total';
            });
          },
        );
      } else {
        // MP4 exports
        final width = format.width;
        final height = format.height;
        resultPath = await VideoExporter.exportMp4(
          widget.viewportKey,
          widget.project,
          width,
          height,
          fps: fps,
          onProgress: (current, total) {
            setState(() {
              progress = current / total;
              status = 'Rendering frame $current / $total';
            });
          },
        );
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(resultPath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isExporting = false;
          status = 'Error: $e';
        });
      }
    }
  }

  void _showSuccessDialog(String filePath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your animation has been exported.'),
            const SizedBox(height: 8),
            SelectableText(
              filePath,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Next: Share on TikTok, YouTube, or edit in your video software.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
