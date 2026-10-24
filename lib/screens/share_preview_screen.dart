import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../services/social_share_service.dart';
import '../services/user_profile_service.dart';
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

  ShareCardStyle _currentStyle = ShareCardStyle.map;
  String? _selectedPhotoPath;
  bool _mapDarkTheme = true;
  bool _isSharing = false;
  ShareDestination? _activeDestination;
  String _athleteName = UserProfileService.currentAthleteName;

  @override
  void initState() {
    super.initState();
    _selectedPhotoPath = widget.session.photoPath;
    if (widget.session.coordinates.length < 2) {
      _currentStyle = _selectedPhotoPath != null
          ? ShareCardStyle.photo
          : ShareCardStyle.minimal;
    } else {
      _currentStyle = ShareCardStyle.map;
    }
    _loadAthleteName();
  }

  Future<void> _loadAthleteName() async {
    final name = await UserProfileService.getAthleteName();
    if (mounted) {
      setState(() {
        _athleteName = name;
      });
    }
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
          _currentStyle = ShareCardStyle.photo;
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

  Future<void> _shareImage([ShareDestination destination = ShareDestination.system]) async {
    if (_isSharing) return;
    setState(() {
      _isSharing = true;
      _activeDestination = destination;
    });

    try {
      final distStr = '${widget.session.distanceKm.toStringAsFixed(2)} km';
      final title =
          'Velora ${widget.session.sportsType.shortName} • $distStr dalam ${widget.session.formattedDuration}!';

      final box = context.findRenderObject() as RenderBox?;
      final origin =
          box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      final success = await SocialShareService.shareActivityImage(
        repaintKey: _repaintKey,
        activityTitle: title,
        destination: destination,
        subject: 'Velora Activity',
        sharePositionOrigin: origin,
      );

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memproses gambar kartu untuk dibagikan.'),
            backgroundColor: AppColors.neonRed,
          ),
        );
      }
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
        setState(() {
          _isSharing = false;
          _activeDestination = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Bagikan ke Media Sosial'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pratinjau Kanvas Kartu 9:16
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: SocialShareCard(
                    session: widget.session,
                    backgroundPhotoPath: _selectedPhotoPath,
                    style: _currentStyle,
                    mapDarkTheme: _mapDarkTheme,
                    repaintKey: _repaintKey,
                    athleteName: _athleteName,
                  ),
                ),
              ),
            ),

            // Bar Aksi Bawah: Pilihan Tema Gaya & Tombol Bagikan
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
                  // 1. Selector Tab Gaya Tampilan (Peta / Foto / Minimalis)
                  Row(
                    children: [
                      Expanded(
                        child: _buildStyleChip(
                          icon: Icons.map_rounded,
                          label: 'Peta Rute',
                          style: ShareCardStyle.map,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStyleChip(
                          icon: Icons.photo_camera_rounded,
                          label: 'Foto Saya',
                          style: ShareCardStyle.photo,
                          onTap: () {
                            if (_selectedPhotoPath == null) {
                              _showPhotoSourceBottomSheet();
                            } else {
                              setState(() => _currentStyle = ShareCardStyle.photo);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStyleChip(
                          icon: Icons.palette_rounded,
                          label: 'Minimalis',
                          style: ShareCardStyle.minimal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // 2. Kontrol Kontekstual Berdasarkan Gaya yang Dipilih
                  if (_currentStyle == ShareCardStyle.map) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _mapDarkTheme = !_mapDarkTheme);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.neonCyan,
                            side: const BorderSide(color: AppColors.borderSubtle),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(
                            _mapDarkTheme
                                ? Icons.wb_sunny_rounded
                                : Icons.nightlight_round,
                            size: 16,
                          ),
                          label: Text(
                            _mapDarkTheme
                                ? 'Ubah ke Peta Terang'
                                : 'Ubah ke Peta Gelap',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentStyle == ShareCardStyle.photo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_rounded, size: 18),
                            label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        if (_selectedPhotoPath != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppColors.neonRed,
                            tooltip: 'Hapus Foto',
                            onPressed: () {
                              setState(() {
                                _selectedPhotoPath = null;
                                _currentStyle = ShareCardStyle.map;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. Tombol Bagikan dengan Pilihan WhatsApp Story / IG Story / Lainnya
                  if (_isSharing)
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.cardSurfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryOrange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _activeDestination == ShareDestination.whatsApp
                                ? 'MEMPROSES KE WHATSAPP...'
                                : _activeDestination == ShareDestination.instagramStory
                                    ? 'MEMPROSES KE IG STORY...'
                                    : 'MEMPROSES GAMBAR KARTU...',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        // Tombol WhatsApp (Status & Chat)
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _shareImage(ShareDestination.whatsApp),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tombol Instagram Story
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: () => _shareImage(ShareDestination.instagramStory),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE1306C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: const Text(
                              'IG Story',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Tombol Lainnya (System Share Sheet)
                        Expanded(
                          flex: 2,
                          child: OutlinedButton.icon(
                            onPressed: () => _shareImage(ShareDestination.system),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text(
                              'Lainnya',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleChip({
    required IconData icon,
    required String label,
    required ShareCardStyle style,
    VoidCallback? onTap,
  }) {
    final isSelected = _currentStyle == style;

    return InkWell(
      onTap: onTap ?? () => setState(() => _currentStyle = style),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryOrange.withAlpha(40)
              : AppColors.cardSurfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPhotoSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryOrange),
                  title: const Text('Ambil Foto dari Kamera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: AppColors.neonCyan),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
