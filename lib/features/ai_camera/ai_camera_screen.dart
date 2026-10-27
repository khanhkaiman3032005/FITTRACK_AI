import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/food_data.dart';
import '../../models/meal_entry.dart';
import '../../services/nutrition_service.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/fittrack_motion.dart';

class AiCameraScreen extends StatefulWidget {
  const AiCameraScreen({super.key});

  @override
  State<AiCameraScreen> createState() => _AiCameraScreenState();
}

class _AiCameraScreenState extends State<AiCameraScreen> {
  final ImagePicker _picker = ImagePicker();
  static Uint8List? _cachedImageBytes;
  static String? _cachedImageName;
  static Map<String, dynamic>? _cachedFoodResult;
  static bool _savedCurrentImage = false;
  static String _cachedFoodName = '';
  static String _cachedPortion = '';

  static double _cachedOriginalPortionGrams = 0;
  static double _cachedOriginalCalories = 0;
  static double _cachedOriginalProtein = 0;
  static double _cachedOriginalCarbs = 0;
  static double _cachedOriginalFat = 0;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _isLoading = false;
  Map<String, dynamic>? _foodResult;
  bool _isSaving = false;

  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();

  final TextEditingController _gramsPerUnitController = TextEditingController();

  String _portionUnit = 'g';

  static String _cachedPortionUnit = 'g';
  static String _cachedGramsPerUnit = '';

  static const Map<String, String> _portionUnits = {
    'g': 'Gram (g)',
    'ml': 'Mililit (ml)',
    'miếng': 'Miếng',
    'phần': 'Phần',
    'chén': 'Chén',
    'bát': 'Bát',
  };

  double _originalPortionGrams = 0;
  double _originalCalories = 0;
  double _originalProtein = 0;
  double _originalCarbs = 0;
  double _originalFat = 0;

  @override
  void initState() {
    super.initState();

    _imageBytes = _cachedImageBytes;
    _imageName = _cachedImageName;

    if (_cachedFoodResult != null) {
      _foodResult = Map<String, dynamic>.from(_cachedFoodResult!);
    }

    _foodNameController.text = _cachedFoodName;
    _portionController.text = _cachedPortion;
    _portionUnit = _cachedPortionUnit;
    _gramsPerUnitController.text = _cachedGramsPerUnit;

    _originalPortionGrams = _cachedOriginalPortionGrams;
    _originalCalories = _cachedOriginalCalories;
    _originalProtein = _cachedOriginalProtein;
    _originalCarbs = _cachedOriginalCarbs;
    _originalFat = _cachedOriginalFat;
  }

  void _saveCache() {
    _cachedImageBytes = _imageBytes;
    _cachedImageName = _imageName;

    _cachedFoodResult = _foodResult == null
        ? null
        : Map<String, dynamic>.from(_foodResult!);

    _cachedFoodName = _foodNameController.text;
    _cachedPortion = _portionController.text;
    _cachedPortionUnit = _portionUnit;
    _cachedGramsPerUnit = _gramsPerUnitController.text;

    _cachedOriginalPortionGrams = _originalPortionGrams;
    _cachedOriginalCalories = _originalCalories;
    _cachedOriginalProtein = _originalProtein;
    _cachedOriginalCarbs = _originalCarbs;
    _cachedOriginalFat = _originalFat;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _imageName = image.name;
        _foodResult = null;
        _savedCurrentImage = false;

        _foodNameController.clear();
        _portionController.clear();
        _portionUnit = 'g';
        _gramsPerUnitController.clear();
      });

      _saveCache();
    } catch (e, stackTrace) {
      debugPrint('AI CAMERA PICK ERROR: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null || _isLoading) return;

    setState(() {
      _isLoading = true;
      _foodResult = null;
    });

    final backendUrl = kIsWeb
        ? 'http://127.0.0.1:8000/api/analyze-food'
        : 'http://10.0.2.2:8000/api/analyze-food';

    try {
      final extension = (_imageName ?? '').toLowerCase();

      String mimeType = 'image/jpeg';

      if (extension.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (extension.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'image_base64': base64Encode(_imageBytes!),
              'mime_type': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 210));

      if (!mounted) return;

      if (response.statusCode != 200) {
        debugPrint('AI CAMERA HTTP ${response.statusCode}: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể phân tích ảnh. Vui lòng thử lại sau.'),
          ),
        );

        return;
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true || data['food'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI chưa nhận diện được món ăn.')),
        );

        return;
      }

      final food = Map<String, dynamic>.from(data['food']);

      final portionText = food['portion']?.toString() ?? '';

      final gramMatches = RegExp(
        r'(\d+(?:[.,]\d+)?)\s*(kg|gram|grams|g)\b',
        caseSensitive: false,
      ).allMatches(portionText).toList();

      double portionGrams = 0;

      if (gramMatches.isNotEmpty) {
        final match = gramMatches.last;

        final value =
            double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;

        final unit = match.group(2)!.toLowerCase();

        portionGrams = unit == 'kg' ? value * 1000 : value;
      }

      if (portionGrams <= 0) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI chưa xác định được khối lượng theo gram. '
              'Vui lòng phân tích lại ảnh.',
            ),
          ),
        );

        return;
      }

      _foodNameController.text = food['food_name']?.toString() ?? 'Món ăn AI';

      _portionController.text = portionGrams.toStringAsFixed(
        portionGrams % 1 == 0 ? 0 : 1,
      );

      _portionUnit = 'g';
      _gramsPerUnitController.clear();

      _originalPortionGrams = portionGrams;
      _originalCalories = (food['calories'] as num?)?.toDouble() ?? 0;
      _originalProtein = (food['protein'] as num?)?.toDouble() ?? 0;
      _originalCarbs = (food['carbs'] as num?)?.toDouble() ?? 0;
      _originalFat = (food['fat'] as num?)?.toDouble() ?? 0;

      setState(() {
        _foodResult = food;
      });

      _saveCache();
    } on TimeoutException {
      debugPrint('AI CAMERA TIMEOUT');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI phản hồi quá lâu. Vui lòng thử lại sau ít phút.'),
        ),
      );
    } catch (e) {
      debugPrint('AI CAMERA ANALYZE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể kết nối FITTRACK AI.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeImage() {
    if (_isLoading) return;

    setState(() {
      _imageBytes = null;
      _imageName = null;
      _foodResult = null;
      _savedCurrentImage = false;

      _foodNameController.clear();
      _portionController.clear();
      _portionUnit = 'g';
      _gramsPerUnitController.clear();

      _originalPortionGrams = 0;
      _originalCalories = 0;
      _originalProtein = 0;
      _originalCarbs = 0;
      _originalFat = 0;
    });

    _cachedImageBytes = null;
    _cachedImageName = null;
    _cachedFoodResult = null;
    _cachedFoodName = '';
    _cachedPortion = '';
    _cachedPortionUnit = 'g';
    _cachedGramsPerUnit = '';

    _cachedOriginalPortionGrams = 0;
    _cachedOriginalCalories = 0;
    _cachedOriginalProtein = 0;
    _cachedOriginalCarbs = 0;
    _cachedOriginalFat = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1729),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Camera',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            Text(
              'FITTRACK AI • Smart Food Scanner',
              style: TextStyle(color: Color(0xFF9AB5CC), fontSize: 10),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 18),
            child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF081F31),
                    Color(0xFF091020),
                    Color(0xFF201332),
                    Color(0xFF080D19),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -130,
            right: -120,
            child: IgnorePointer(
              child: Container(
                width: 390,
                height: 390,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -130,
            child: IgnorePointer(
              child: Container(
                width: 410,
                height: 410,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 550;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 16 : 30,
                    22,
                    compact ? 16 : 30,
                    45,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FitEntrance(
                            child: Container(
                              padding: EdgeInsets.all(compact ? 21 : 29),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF105064),
                                    Color(0xFF173049),
                                    Color(0xFF2C2049),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI VISION TECHNOLOGY',
                                          style: TextStyle(
                                            color: Color(0xFF81E9FF),
                                            letterSpacing: 1.4,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Khám phá dinh dưỡng\nqua hình ảnh.',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 23,
                                            height: 1.2,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Chụp hoặc chọn ảnh món ăn. '
                                          'AI sẽ nhận diện và ước tính '
                                          'thành phần dinh dưỡng.',
                                          style: TextStyle(
                                            color: Color(0xFFC2D5E5),
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: compact ? 55 : 82,
                                    height: compact ? 55 : 82,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.09,
                                      ),
                                      borderRadius: BorderRadius.circular(21),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.document_scanner_rounded,
                                      color: const Color(0xFF83E9FF),
                                      size: compact ? 29 : 42,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          const FitSectionTitle(
                            icon: Icons.center_focus_strong_rounded,
                            title: 'Quét món ăn',
                            subtitle: 'Chọn ảnh rõ nét để AI nhận diện tốt hơn',
                            accent: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          FitEntrance(child: _buildImageArea()),
                          const SizedBox(height: 17),
                          _buildImageButtons(),
                          if (_imageBytes != null) ...[
                            const SizedBox(height: 17),
                            SizedBox(
                              height: 55,
                              child: FilledButton.icon(
                                onPressed: _isLoading ? null : _analyzeImage,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  _isLoading
                                      ? 'Đang nhận diện món ăn...'
                                      : 'Phân tích bằng FITTRACK AI',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: const Color(0xFF071522),
                                  disabledBackgroundColor: const Color(
                                    0xFF1C4B60,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (_isLoading) ...[
                            const SizedBox(height: 15),
                            const FitGlassPanel(
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'AI đang xử lý hình ảnh...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                        Text(
                                          'Nếu model chính quá tải, '
                                          'hệ thống sẽ tự động thử model '
                                          'dự phòng. Vui lòng chờ.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_foodResult != null) ...[
                            const SizedBox(height: 28),
                            FitEntrance(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: true,
                                    fillColor: const Color(0xFF0D1B30),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                child: _buildFoodResult(),
                              ),
                            ),
                          ],
                          const SizedBox(height: 22),
                          _buildInfoCard(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          height: compact ? 300 : 370,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF142D42), Color(0xFF111B30), Color(0xFF261A3C)],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _imageBytes == null
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.65),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(
                  alpha: _isLoading ? 0.20 : 0.08,
                ),
                blurRadius: _isLoading ? 30 : 20,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.13,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.30,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_rounded,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 19),
                            const Text(
                              'Sẵn sàng nhận diện',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            const Text(
                              'Chụp ảnh hoặc chọn từ thư viện',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
                if (_imageBytes != null && _isLoading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                if (_imageBytes != null && _isLoading)
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 2100),
                      curve: Curves.easeInOutCubic,
                      builder: (context, progress, child) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 21),
                          child: Align(
                            alignment: Alignment(0, -1 + 2 * progress),
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: const Color(0xFF59F1FF),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0xFF00D5FF),
                                    blurRadius: 22,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _AiCameraCornersPainter()),
                  ),
                ),
                if (_imageBytes != null && _imageName != null)
                  Positioned(
                    bottom: 13,
                    left: 13,
                    right: 66,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD071726),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text(
                        _imageName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (_imageBytes != null)
                  Positioned(
                    top: 13,
                    right: 13,
                    child: IconButton.filled(
                      tooltip: 'Xóa ảnh',
                      onPressed: _isLoading ? null : _removeImage,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xCC18253B),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                if (_isLoading)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF59F1FF)),
                        SizedBox(height: 15),
                        Text(
                          'AI ĐANG QUÉT HÌNH ẢNH',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageButtons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;

        final buttonStyle = OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          backgroundColor: const Color(0xFF14233A),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );

        final cameraButton = OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text(
            'Chụp ảnh',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: buttonStyle,
        );

        final galleryButton = OutlinedButton.icon(
          onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded),
          label: const Text(
            'Chọn từ thư viện',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: buttonStyle,
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 52, child: cameraButton),
              const SizedBox(height: 11),
              SizedBox(height: 52, child: galleryButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: SizedBox(height: 53, child: cameraButton)),
            const SizedBox(width: 12),
            Expanded(child: SizedBox(height: 53, child: galleryButton)),
          ],
        );
      },
    );
  }

  double? _getPortionGrams() {
    final quantity = double.tryParse(
      _portionController.text.trim().replaceAll(',', '.'),
    );

    if (quantity == null || quantity <= 0) return null;

    if (_portionUnit == 'g') return quantity;

    final gramsPerUnit = double.tryParse(
      _gramsPerUnitController.text.trim().replaceAll(',', '.'),
    );

    if (gramsPerUnit == null || gramsPerUnit <= 0) return null;

    return quantity * gramsPerUnit;
  }

  void _updateNutritionByPortion(String value) {
    if (_foodResult == null) return;

    final portionGrams = _getPortionGrams();

    final valid =
        portionGrams != null &&
        _originalPortionGrams > 0 &&
        (portionGrams / _originalPortionGrams).isFinite &&
        portionGrams / _originalPortionGrams >= 0.1 &&
        portionGrams / _originalPortionGrams <= 10;

    setState(() {
      _foodResult!['food_name'] = _foodNameController.text.trim();

      if (!valid) {
        _foodResult!['calories'] = 0;
        _foodResult!['protein'] = 0.0;
        _foodResult!['carbs'] = 0.0;
        _foodResult!['fat'] = 0.0;
      } else {
        final ratio = portionGrams / _originalPortionGrams;

        _foodResult!['portion'] =
            '${_portionController.text.trim()} $_portionUnit';

        _foodResult!['calories'] = (_originalCalories * ratio).round();
        _foodResult!['protein'] = double.parse(
          (_originalProtein * ratio).toStringAsFixed(1),
        );
        _foodResult!['carbs'] = double.parse(
          (_originalCarbs * ratio).toStringAsFixed(1),
        );
        _foodResult!['fat'] = double.parse(
          (_originalFat * ratio).toStringAsFixed(1),
        );
      }
    });

    _saveCache();
  }

  Future<void> _addToNutrition() async {
    final result = _foodResult;

    if (result == null || _isSaving || _savedCurrentImage) return;

    final mealType = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101827),
          title: const Text('Chọn bữa ăn'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Bữa sáng'),
                onTap: () => Navigator.pop(context, 'Bữa sáng'),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_outlined),
                title: const Text('Bữa trưa'),
                onTap: () => Navigator.pop(context, 'Bữa trưa'),
              ),
              ListTile(
                leading: const Icon(Icons.nights_stay_outlined),
                title: const Text('Bữa tối'),
                onTap: () => Navigator.pop(context, 'Bữa tối'),
              ),
              ListTile(
                leading: const Icon(Icons.restaurant_outlined),
                title: const Text('Bữa phụ'),
                onTap: () => Navigator.pop(context, 'Bữa phụ'),
              ),
            ],
          ),
        );
      },
    );

    if (mealType == null || !mounted || _isSaving || _savedCurrentImage) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final portion = _getPortionGrams();

      if (portion == null) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập khẩu phần và khối lượng hợp lệ.'),
          ),
        );

        return;
      }

      if (_originalPortionGrams <= 0) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Khối lượng gốc từ AI không hợp lệ.')),
        );

        return;
      }

      final ratio = portion / _originalPortionGrams;

      if (ratio > 10 || ratio < 0.1) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Khẩu phần chênh lệch quá lớn so với kết quả AI. '
              'Vui lòng kiểm tra lại trước khi lưu.',
            ),
          ),
        );

        return;
      }

      final calories = (_originalCalories * ratio).round();

      final protein = double.parse(
        (_originalProtein * ratio).toStringAsFixed(1),
      );

      final carbs = double.parse((_originalCarbs * ratio).toStringAsFixed(1));

      final fat = double.parse((_originalFat * ratio).toStringAsFixed(1));

      final food = FoodData(
        name: _foodNameController.text.trim().isEmpty
            ? 'Món ăn AI'
            : _foodNameController.text.trim(),
        category: 'AI Camera',
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        unit: '${_portionController.text.trim()} $_portionUnit',
      );

      final entry = MealEntry(
        food: food,
        mealType: mealType,
        quantity: 1,
        createdAt: DateTime.now(),
      );

      await NutritionService.addMeal(entry);

      if (!mounted) return;

      setState(() {
        _savedCurrentImage = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã thêm ${food.name} vào $mealType.')),
      );
    } catch (e) {
      debugPrint('AI CAMERA SAVE MEAL ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể thêm món ăn. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildFoodResult() {
    final food = _foodResult!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF152940), Color(0xFF111D32), Color(0xFF231B3B)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Kết quả FITTRACK AI',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${food['confidence'] ?? 0}% tin cậy',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Tên món',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 6),

          TextField(
            controller: _foodNameController,
            decoration: const InputDecoration(
              hintText: 'Tên món ăn',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (_foodResult != null) {
                _foodResult!['food_name'] = value.trim();
                _saveCache();
              }
            },
          ),

          const SizedBox(height: 16),

          const Text(
            'Khẩu phần',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portionController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Số lượng',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _updateNutritionByPortion,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _portionUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Đơn vị',
                    border: OutlineInputBorder(),
                  ),
                  items: _portionUnits.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null || value == _portionUnit) return;

                    final currentGrams =
                        _getPortionGrams() ?? _originalPortionGrams;

                    setState(() {
                      _portionUnit = value;

                      if (value == 'g') {
                        _portionController.text = currentGrams.toStringAsFixed(
                          currentGrams % 1 == 0 ? 0 : 1,
                        );

                        _gramsPerUnitController.clear();
                      } else {
                        _portionController.text = '1';

                        _gramsPerUnitController.text = currentGrams > 0
                            ? currentGrams.toStringAsFixed(
                                currentGrams % 1 == 0 ? 0 : 1,
                              )
                            : '';
                      }
                    });

                    _updateNutritionByPortion(_portionController.text);
                  },
                ),
              ),
            ],
          ),
          if (_portionUnit != 'g') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _gramsPerUnitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Khối lượng tương đương',
                hintText: 'Nhập số gram cho 1 $_portionUnit',
                suffixText: 'g / $_portionUnit',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                _saveCache();
                _updateNutritionByPortion(_portionController.text);
              },
            ),
          ],

          const SizedBox(height: 8),

          const Text(
            'Dinh dưỡng sẽ tự cập nhật theo khẩu phần.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),

          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _nutritionChip('Kcal', '${food['calories'] ?? 0}'),
              _nutritionChip('Protein', '${food['protein'] ?? 0} g'),
              _nutritionChip('Carb', '${food['carbs'] ?? 0} g'),
              _nutritionChip('Fat', '${food['fat'] ?? 0} g'),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed:
                  _isSaving ||
                      _savedCurrentImage ||
                      _getPortionGrams() == null ||
                      _originalPortionGrams <= 0 ||
                      (_getPortionGrams()! / _originalPortionGrams) < 0.1 ||
                      (_getPortionGrams()! / _originalPortionGrams) > 10
                  ? null
                  : _addToNutrition,

              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(
                _savedCurrentImage
                    ? 'Đã thêm vào dinh dưỡng'
                    : _isSaving
                    ? 'Đang thêm...'
                    : 'Xác nhận & thêm vào dinh dưỡng',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionChip(String label, String value) {
    Color accent;

    switch (label) {
      case 'Kcal':
        accent = const Color(0xFFFFB15C);
        break;
      case 'Protein':
        accent = const Color(0xFF2DD4BF);
        break;
      case 'Carb':
        accent = const Color(0xFFA78BFA);
        break;
      case 'Fat':
        accent = const Color(0xFFFF7185);
        break;
      default:
        accent = AppColors.primary;
    }

    return Container(
      constraints: const BoxConstraints(minWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.17), const Color(0xFF101C2E)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accent.withValues(alpha: 0.23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey('$label-$value'),
              style: TextStyle(
                color: accent,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return const FitGlassPanel(
      padding: EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kết quả ước tính bởi AI',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 7),
                Text(
                  'FITTRACK AI giúp nhận diện món ăn '
                  'và ước tính dinh dưỡng từ hình ảnh. '
                  'Bạn có thể kiểm tra tên món, khẩu phần '
                  'và số liệu trước khi lưu vào nhật ký.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiCameraCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF67E8FF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const margin = 19.0;
    const length = 27.0;

    final path = Path()
      ..moveTo(margin, margin + length)
      ..lineTo(margin, margin)
      ..lineTo(margin + length, margin)
      ..moveTo(size.width - margin - length, margin)
      ..lineTo(size.width - margin, margin)
      ..lineTo(size.width - margin, margin + length)
      ..moveTo(margin, size.height - margin - length)
      ..lineTo(margin, size.height - margin)
      ..lineTo(margin + length, size.height - margin)
      ..moveTo(size.width - margin - length, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin)
      ..lineTo(size.width - margin, size.height - margin - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AiCameraCornersPainter oldDelegate) {
    return false;
  }
}
