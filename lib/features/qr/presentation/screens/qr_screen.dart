import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../providers/qr_provider.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QrProvider>().generateQrData();
    });
  }

  /// Capture the QR widget as PNG bytes.
  Future<Uint8List?> _captureQrImage() async {
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture error: $e');
      return null;
    }
  }

  /// Share the QR code as an image.
  Future<void> _shareQr() async {
    final bytes = await _captureQrImage();
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR code')),
        );
      }
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(bytes, mimeType: 'image/png', name: 'medical_qr.png'),
        ],
        text: 'My Smart Medical ID QR Code',
      ),
    );
  }

  /// Print the QR code.
  Future<void> _printQr(String data) async {
    final doc = pw.Document();

    // Generate QR image bytes for the PDF
    final qrPainter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
    );
    final picData = await qrPainter.toImageData(600);
    if (picData == null) return;
    final qrBytes = picData.buffer.asUint8List();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context ctx) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Smart Medical ID',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Scan this QR code for patient medical information',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 32),
                pw.Image(pw.MemoryImage(qrBytes), width: 250, height: 250),
                pw.SizedBox(height: 32),
                pw.Text(
                  'Present this to medical staff in case of emergency.',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Medical_QR_Code',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qrProvider = context.watch<QrProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medical QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh QR',
            onPressed: qrProvider.isLoading ? null : () => qrProvider.refresh(),
          ),
          if (qrProvider.hasData) ...[
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share QR',
              onPressed: _shareQr,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print QR',
              onPressed: () => _printQr(qrProvider.qrData!),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Full Screen',
            onPressed:
                qrProvider.hasData
                    ? () => _showFullScreen(context, qrProvider.qrData!)
                    : null,
          ),
        ],
      ),
      body: Center(
        child:
            qrProvider.isLoading
                ? const CircularProgressIndicator()
                : qrProvider.hasData
                ? _buildQrCard(context, qrProvider.qrData!)
                : _buildEmptyState(theme),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context, String data) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Scan this code',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Present this QR to medical staff for instant access to your medical ID.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 220,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF0D6EFD),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Action buttons ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.share,
                    label: 'Share',
                    onTap: _shareQr,
                  ),
                  _ActionButton(
                    icon: Icons.print,
                    label: 'Print',
                    onTap: () => _printQr(data),
                  ),
                  _ActionButton(
                    icon: Icons.fullscreen,
                    label: 'Full Screen',
                    onTap: () => _showFullScreen(context, data),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.qr_code_2,
          size: 80,
          color: theme.colorScheme.outlineVariant,
        ),
        const SizedBox(height: 16),
        Text(
          'No QR data available',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => context.read<QrProvider>().refresh(),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  void _showFullScreen(BuildContext context, String data) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _FullScreenQr(data: data)));
  }
}

// ── Action Button widget ──────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full‑screen QR overlay ──────────────────────────────────────────────────

class _FullScreenQr extends StatelessWidget {
  final String data;

  const _FullScreenQr({required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text('Medical QR Code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.width * 0.8,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF0D6EFD),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ),
      ),
    );
  }
}
