import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/activity_session.dart';
import '../services/social_share_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/social_share_card.dart';
import 'route_replay_screen.dart';

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

  ShareCardStyle _currentStyle = ShareCardStyle.clean;
  String? _selectedPhotoPath;
  bool _mapDarkTheme = true;
  bool _isSharing = false;
  ShareDestination? _activeDestination;
  String _athleteName = UserProfileService.currentAthleteName;

  @override
  void initState() {
    super.initState();
    _selectedPhotoPath = widget.session.photoPath;
    if (_selectedPhotoPath != null) {
      _currentStyle = ShareCardStyle.photo;
    } else {
      _currentStyle = ShareCardStyle.clean;
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

  Future<void> _saveToGallery() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final fileName = 'velora_${widget.session.id}';
      final success = await SocialShareService.saveImageToGallery(
        repaintKey: _repaintKey,
        title: fileName,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.neonGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _currentStyle == ShareCardStyle.transparent
                          ? 'Stiker transparan berhasil disimpan ke Galeri (Pictures/Velora)!'
                          : 'Kartu aktivitas berhasil disimpan ke Galeri (Pictures/Velora)!',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.cardSurfaceElevated,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan gambar ke galeri.'),
              backgroundColor: AppColors.neonRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.neonRed,
            behavior: SnackBarBehavior.floating,
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
          Tooltip(
            message: 'Simpan ke Galeri Ponsel (Pictures/Velora)',
            child: IconButton(
              icon: const Icon(Icons.download_rounded, color: AppColors.textPrimary),
              onPressed: _saveToGallery,
            ),
          ),
          Tooltip(
            message: 'Buat Video Flyover 3D (MP4)',
            child: TextButton.icon(
              icon: const Icon(Icons.movie_filter_rounded, color: AppColors.neonCyan, size: 20),
              label: const Text(
                'Video Flyover',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (widget.session.coordinates.length < 2) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Aktivitas ini belum merekam rute bergerak (butuh min. 2 titik GPS) untuk video flyover.',
                      ),
                      backgroundColor: AppColors.cardSurfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RouteReplayScreen(
                      session: widget.session,
                      autoStartVideoExport: true,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pratinjau Kanvas Kartu 9:16
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _currentStyle == ShareCardStyle.transparent
                          ? const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if (_currentStyle == ShareCardStyle.transparent)
                          const Positioned.fill(
                            child: CustomPaint(
                              painter: TransparencyGridPainter(),
                            ),
                          ),
                        SocialShareCard(
                          session: widget.session,
                          backgroundPhotoPath: _selectedPhotoPath,
                          style: _currentStyle,
                          mapDarkTheme: _mapDarkTheme,
                          repaintKey: _repaintKey,
                          athleteName: _athleteName,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bar Aksi Bawah: Pilihan Tema Gaya & Tombol Bagikan
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  // 1. Selector Tab Gaya Tampilan (Clean / Transparan / Foto / Peta / Klasik)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildStyleChip(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Clean',
                          style: ShareCardStyle.clean,
                        ),
                        const SizedBox(width: 8),
                        _buildStyleChip(
                          icon: Icons.opacity_rounded,
                          label: 'Transparan',
                          style: ShareCardStyle.transparent,
                        ),
                        const SizedBox(width: 8),
                        _buildStyleChip(
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
                        const SizedBox(width: 8),
                        _buildStyleChip(
                          icon: Icons.map_rounded,
                          label: 'Peta',
                          style: ShareCardStyle.map,
                        ),
                        const SizedBox(width: 8),
                        _buildStyleChip(
                          icon: Icons.dashboard_rounded,
                          label: 'Klasik',
                          style: ShareCardStyle.minimal,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 2. Kontrol Kontekstual Berdasarkan Gaya yang Dipilih
                  if (_currentStyle == ShareCardStyle.clean) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 14, color: AppColors.primaryOrange),
                              SizedBox(width: 6),
                              Text(
                                'Format Clean Minimalis (Strava Style)',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentStyle == ShareCardStyle.transparent) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrange.withAlpha(25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primaryOrange.withAlpha(70)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.opacity_rounded, size: 14, color: AppColors.primaryOrange),
                              SizedBox(width: 6),
                              Text(
                                'Stiker PNG Transparan (Bisa Ditempel di IG)',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentStyle == ShareCardStyle.map) ...[
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
                                _currentStyle = ShareCardStyle.clean;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                  ] else if (_currentStyle == ShareCardStyle.minimal) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.dashboard_rounded, size: 14, color: AppColors.neonCyan),
                              SizedBox(width: 6),
                              Text(
                                'Format Kartu Lengkap Klasik',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
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
                  else ...[
                    if (_currentStyle == ShareCardStyle.transparent) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveToGallery,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text(
                            'SIMPAN STIKER PNG KE GALERI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
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
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primaryOrange : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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

/// Painter pola checkerboard papan catur untuk menandakan transparansi kanvas di pratinjau
class TransparencyGridPainter extends CustomPainter {
  final double squareSize;
  final Color color1;
  final Color color2;

  const TransparencyGridPainter({
    this.squareSize = 12.0,
    this.color1 = const Color(0xFF1E2430),
    this.color2 = const Color(0xFF13171F),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()..color = color1;
    final paint2 = Paint()..color = color2;
    canvas.drawRect(Offset.zero & size, paint2);

    final cols = (size.width / squareSize).ceil();
    final rows = (size.height / squareSize).ceil();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if ((r + c) % 2 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(c * squareSize, r * squareSize, squareSize, squareSize),
            paint1,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant TransparencyGridPainter oldDelegate) => false;
}
