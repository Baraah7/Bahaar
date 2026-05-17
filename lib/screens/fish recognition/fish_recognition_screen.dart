import 'dart:io';
import 'package:bahaar/core/constants/app_colors.dart';
import 'package:bahaar/l10n/fish_recognition/fish_recognition_localizations.dart';
import 'package:bahaar/models/fishing/fish_probability_model.dart';
import 'package:bahaar/providers/fish%20recognition/fish_classification_provider.dart';
import 'package:bahaar/providers/language/language_provider.dart';
import 'package:bahaar/widgets/common/app_empty_state.dart';
import 'package:bahaar/widgets/common/app_loading_view.dart';
import 'package:bahaar/widgets/common/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class FishRecognitionScreen extends ConsumerStatefulWidget {
  const FishRecognitionScreen({super.key});

  @override
  ConsumerState<FishRecognitionScreen> createState() =>
      _FishRecognitionScreenState();
}

class _FishRecognitionScreenState extends ConsumerState<FishRecognitionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fishClassificationProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
        });
        await _classifyImage(File(photo.path));
      }
    } catch (e) {
      _showError('Failed to open camera: $e');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _classifyImage(File(image.path));
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    ref.read(fishClassificationProvider.notifier).classifyImage(imageFile);
  }

  void _showError(String message) {
    showAppSnackBar(context, message, isError: true);
  }

  void _resetClassification() {
    setState(() {
      _selectedImage = null;
    });
    ref.read(fishClassificationProvider.notifier).clearResult();
  }

  @override
  Widget build(BuildContext context) {
    final classificationState = ref.watch(fishClassificationProvider);
    final isInitialized = classificationState.isInitialized;
    final hasError = classificationState.error != null && !isInitialized;
    final l10n = FishRecognitionLocalizations.of(context);

    if (classificationState.result != null) {
      _animationController.forward();
    } else {
      _animationController.reset();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.accent,
              AppColors.primary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (Navigator.canPop(context))
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              Expanded(
                child: hasError
                    ? AppEmptyState(
                        icon: Icons.error_outline_rounded,
                        title: FishRecognitionLocalizations.of(context)
                            .failedToLoadModel,
                        message: classificationState.error,
                        buttonText:
                            FishRecognitionLocalizations.of(context).tryAgain,
                        onButtonPressed: () => ref
                            .read(fishClassificationProvider.notifier)
                            .initialize(),
                        iconColor: Colors.white,
                      )
                    : !isInitialized
                        ? AppLoadingView(
                            message: l10n.loadingRecognitionModel,
                            color: Colors.white)
                        : _buildMainContent(context, classificationState, l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    dynamic classificationState,
    FishRecognitionLocalizations l10n,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            if (_selectedImage == null) ...[
              _buildUploadArea(classificationState, l10n),
              const SizedBox(height: 24),
              _buildSupportedSpecies(l10n),
            ] else ...[
              _buildImagePreview(classificationState, l10n),
              const SizedBox(height: 20),
              if (classificationState.result != null) ...[
                if (classificationState.result!.isUnknown)
                  _buildUnknownCard(classificationState.result!, l10n)
                else ...[
                  _buildResultCard(context, classificationState.result!, l10n),
                  const SizedBox(height: 16),
                  _buildFishInfoCard(classificationState.result!, l10n),
                ],
              ],
              if (classificationState.error != null)
                _buildErrorCard(classificationState.error!),
              const SizedBox(height: 16),
              _buildActionButtons(classificationState, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea(
      dynamic classificationState, FishRecognitionLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phishing_rounded,
              size: 56,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.takePhotoOfFish,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.systemWillIdentify,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.camera_alt_rounded,
                  label: l10n.camera,
                  onPressed: classificationState.isLoading
                      ? null
                      : _pickImageFromCamera,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.photo_library_rounded,
                  label: l10n.gallery,
                  onPressed: classificationState.isLoading
                      ? null
                      : _pickImageFromGallery,
                  isPrimary: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
  }) {
    return Material(
      color: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isPrimary ? AppColors.accent : Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? AppColors.accent : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(
      dynamic classificationState, FishRecognitionLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Image.file(
              _selectedImage!,
              height: 280,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            if (classificationState.isLoading)
              Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.analyzing,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(
      BuildContext context, dynamic result, FishRecognitionLocalizations l10n) {
    final isConfident = result.isConfident;
    final confidence = result.confidence as double;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _buildConfidenceIndicator(confidence, isConfident),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ref.watch(languageProvider).languageCode == 'ar'
                            ? result.arabicName
                            : result.className,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isConfident
                                ? Icons.verified_rounded
                                : Icons.info_outline_rounded,
                            size: 18,
                            color: isConfident
                                ? const Color.fromARGB(255, 28, 244, 172)
                                : const Color.fromARGB(255, 242, 159, 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isConfident
                                ? l10n.highConfidence
                                : l10n.lowConfidence,
                            style: TextStyle(
                              fontSize: 14,
                              color: isConfident
                                  ? const Color.fromARGB(255, 28, 244, 172)
                                  : const Color.fromARGB(255, 242, 159, 16),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isConfident) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tryTakingClearerPhoto,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFishInfoCard(dynamic result, FishRecognitionLocalizations l10n) {
    final info = l10n.fishInfoFor(result.className as String);
    if (info == null) return const SizedBox.shrink();
    final scientificName =
        FishRecognitionLocalizations.scientificNameFor(result.className as String) ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                l10n.fishInfo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  scientificName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoGrid(items: [
            _InfoItem(
                Icons.place_outlined, l10n.labelHabitat, info['habitat']!),
            _InfoItem(Icons.straighten_rounded, l10n.labelSize, info['size']!),
            _InfoItem(
                Icons.wb_sunny_outlined, l10n.labelSeason, info['season']!),
            _InfoItem(Icons.restaurant_outlined, l10n.labelDiet, info['diet']!),
            _InfoItem(
                Icons.star_outline_rounded, l10n.labelFlavor, info['flavor']!),
          ]),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
          const SizedBox(height: 14),
          _InfoRow(
              icon: Icons.public_rounded,
              label: l10n.labelPopularIn,
              value: info['popular_in']!),
          const SizedBox(height: 10),
          _InfoRow(
              icon: Icons.favorite_outline_rounded,
              label: l10n.labelNutrition,
              value: info['nutrition']!),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFFFD54F), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    info['fact']!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownCard(dynamic result, FishRecognitionLocalizations l10n) {
    final isNoFish = result.isNoFish == true;
    final confidence =
        isNoFish ? result.detectorScore as double : result.confidence as double;
    final percentage = (confidence * 100).toInt();
    final title = isNoFish ? l10n.noFishDetected : l10n.unsupportedSpecies;
    final hint =
        isNoFish ? l10n.noFishDetectedHint : l10n.unsupportedSpeciesHint;
    final statusLabel = isNoFish ? l10n.noFishDetected : l10n.lowConfidence;
    final icon = isNoFish
        ? Icons.image_not_supported_outlined
        : Icons.help_outline_rounded;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Question mark circle
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: confidence,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFB0BEC5)),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Center(
                        child: Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB0BEC5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(icon, size: 18, color: const Color(0xFFB0BEC5)),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB0BEC5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.camera_enhance_outlined,
                      color: Color(0xFFFFD54F), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
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

  Widget _buildConfidenceIndicator(double confidence, bool isConfident) {
    final percentage = (confidence * 100).toInt();
    final color = isConfident
        ? const Color.fromARGB(255, 28, 244, 172)
        : const Color.fromARGB(255, 242, 159, 16);

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              value: confidence,
              strokeWidth: 6,
              backgroundColor: color.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Center(
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      dynamic classificationState, FishRecognitionLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _resetClassification,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.newImage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _speciesImages = {
    'Gilt-Head Bream': 'assets/images/Gilt-Head Bream.jpg',
    'Horse Mackerel': 'assets/images/Horse mackerel.jpg',
    'Red Mullet': 'assets/images/Red Mullet.jpg',
    'Sea Bass': 'assets/images/Seabass.jpg',
    'Shrimp': 'assets/images/Shrimp.jpeg',
  };

  Widget _buildSupportedSpecies(FishRecognitionLocalizations l10n) {
    final isArabic = ref.watch(languageProvider).languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 10),
              Text(
                l10n.supportedSpecies,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.3,
            children: FishSpecies.values.map((s) {
              final englishName = s.englishName;
              final displayName = isArabic ? s.arabicName : englishName;
              final imagePath = _speciesImages[englishName];
              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imagePath != null)
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Icon(Icons.set_meal_rounded,
                              color: Colors.white54, size: 40),
                        ),
                      )
                    else
                      Container(
                        color: Colors.white.withValues(alpha: 0.1),
                        child: const Icon(Icons.set_meal_rounded,
                            color: Colors.white54, size: 40),
                      ),
                    // Dark gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    // Label at bottom
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: Colors.white60),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, size: 15, color: Colors.white60),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 90,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
