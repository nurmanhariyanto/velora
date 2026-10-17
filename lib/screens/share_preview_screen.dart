import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../services/social_share_service.dart';
import '../widgets/social_share_card.dart';

/// Layar Pratinjau Ekspor Gambar Media Sosial (WhatsApp / Instagram Story)
class SharePreviewScreen extends StatefulWidget {
  final ActivitySession session;

  const SharePreviewScreen({
    super.key,
    required this.session,
  });

  @override
  State<SharePreviewScreen> createState() => _SharePreviewScreenState();
}

class _SharePreviewScreenState extends State<SharePreviewScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();
  String? _selectedPhotoPath;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _selectedPhotoPath = widget.session.photoPath;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedPhotoPath = image.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    }
  }

  Future<void> _shareImage() async {
    setState(() => _isSharing = true);

    try {
      final distStr = '${widget.session.distanceKm.toStringAsFixed(2)} km';
      final title =
          'Velora ${widget.session.sportsType.shortName} • $distStr dalam ${widget.session.formattedDuration}!';

      await SocialShareService.shareActivityImage(
        repaintKey: _repaintKey,
        activityTitle: title,
        subject: 'Velora: Run & Ride Activity',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membagikan gambar: $e'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Bagikan ke Media Sosial'),
        actions: [
          if (_selectedPhotoPath != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Latar Belakang',
              onPressed: () {
                setState(() => _selectedPhotoPath = null);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pratinjau Kanvas Kartu 9:16
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: SocialShareCard(
                    session: widget.session,
                    backgroundPhotoPath: _selectedPhotoPath,
                    repaintKey: _repaintKey,
                  ),
                ),
              ),
            ),

            // Bar Aksi Bawah: Pilihan Foto & Tombol Bagikan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.borderSubtle),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Pemilih Foto
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.camera),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.camera_alt_rounded, size: 20),
                          label: const Text('Ambil Foto'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickPhoto(ImageSource.gallery),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.photo_library_rounded, size: 20),
                          label: const Text('Dari Galeri'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tombol Bagikan Utama
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSharing ? null : _shareImage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: _isSharing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.share_rounded, size: 22),
                      label: Text(
                        _isSharing ? 'MEMPROSES GAMBAR...' : 'BAGIKAN (IG / WA)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
