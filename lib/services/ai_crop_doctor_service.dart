import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'hive_service.dart';
import 'localization_service.dart';

class AICropDoctorService {
  static final AICropDoctorService _instance = AICropDoctorService._internal();
  factory AICropDoctorService() => _instance;
  AICropDoctorService._internal();

  final HiveService _hiveService = HiveService();
  final LocalizationService _localizationService = LocalizationService();
  final ImagePicker _imagePicker = ImagePicker();

  // AI-powered crop disease detection
  Future<Map<String, dynamic>> diagnoseCropDisease(File imageFile) async {
    try {
      // Convert image to base64 for API call
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call AI vision API (using Google Vision or custom model)
      final diagnosis = await _callVisionAPI(base64Image);
      
      // Get localized treatment recommendations
      final treatment = await _getTreatmentRecommendations(diagnosis);
      
      // Save diagnosis history
      await _saveDiagnosisHistory(diagnosis, treatment);
      
      return {
        'disease': diagnosis['disease'],
        'confidence': diagnosis['confidence'],
        'severity': diagnosis['severity'],
        'treatment': treatment,
        'prevention': _getPreventionTips(diagnosis['disease']),
        'local_remedies': _getLocalRemedies(diagnosis['disease']),
      };
    } catch (e) {
      return _getOfflineDiagnosis();
    }
  }

  Future<Map<String, dynamic>> _callVisionAPI(String base64Image) async {
    // Mock AI response - in production, integrate with actual AI service
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call
    
    final diseases = [
      {'disease': 'Leaf Blight', 'confidence': 0.85, 'severity': 'moderate'},
      {'disease': 'Powdery Mildew', 'confidence': 0.78, 'severity': 'mild'},
      {'disease': 'Rust', 'confidence': 0.92, 'severity': 'severe'},
      {'disease': 'Bacterial Spot', 'confidence': 0.73, 'severity': 'moderate'},
    ];
    
    return diseases[DateTime.now().millisecond % diseases.length];
  }

  Future<Map<String, dynamic>> _getTreatmentRecommendations(Map<String, dynamic> diagnosis) async {
    final disease = diagnosis['disease'];
    // final severity = diagnosis['severity']; // Reserved for future severity-based treatments
    
    final treatments = {
      'Leaf Blight': {
        'immediate': ['Remove affected leaves', 'Improve air circulation', 'Reduce watering frequency'],
        'chemical': ['Apply copper-based fungicide', 'Use systemic fungicide if severe'],
        'organic': ['Neem oil spray', 'Baking soda solution', 'Compost tea application'],
        'timeline': '7-14 days for improvement',
      },
      'Powdery Mildew': {
        'immediate': ['Increase air circulation', 'Avoid overhead watering', 'Remove infected parts'],
        'chemical': ['Sulfur-based fungicide', 'Potassium bicarbonate spray'],
        'organic': ['Milk spray (1:10 ratio)', 'Garlic and soap solution', 'Essential oil spray'],
        'timeline': '5-10 days for improvement',
      },
      'Rust': {
        'immediate': ['Remove infected leaves immediately', 'Avoid wetting leaves', 'Improve drainage'],
        'chemical': ['Copper fungicide', 'Triazole fungicides for severe cases'],
        'organic': ['Horsetail tea', 'Chamomile infusion', 'Beneficial bacteria spray'],
        'timeline': '10-21 days for recovery',
      },
    };
    
    return treatments[disease] ?? _getGenericTreatment();
  }

  Map<String, dynamic> _getGenericTreatment() {
    return {
      'immediate': ['Isolate affected plants', 'Improve growing conditions', 'Monitor closely'],
      'chemical': ['Consult local agricultural extension', 'Use broad-spectrum fungicide'],
      'organic': ['Neem oil application', 'Improve soil health', 'Beneficial microorganisms'],
      'timeline': '7-14 days to assess progress',
    };
  }

  List<String> _getPreventionTips(String disease) {
    return [
      'Practice crop rotation',
      'Ensure proper plant spacing',
      'Water at soil level, not on leaves',
      'Remove plant debris regularly',
      'Use disease-resistant varieties',
      'Maintain soil health with organic matter',
      'Monitor plants regularly for early detection',
    ];
  }

  List<String> _getLocalRemedies(String disease) {
    final language = _localizationService.currentLanguage;
    
    switch (language) {
      case 'sw': // East African remedies
        return [
          'Mchafu wa nazi (coconut water) spray',
          'Mchanganyiko wa kitunguu saumu na sabuni',
          'Chai ya majani ya mti wa neem',
          'Maji ya maziwa ya ng\'ombe (diluted milk)',
        ];
      case 'hi': // Indian Ayurvedic remedies
        return [
          'नीम का तेल छिड़काव',
          'हल्दी और पानी का घोल',
          'गोमूत्र का प्रयोग',
          'तुलसी और लहसुन का काढ़ा',
        ];
      case 'es': // Latin American remedies
        return [
          'Extracto de ajo y cebolla',
          'Té de cola de caballo',
          'Solución de bicarbonato de sodio',
          'Extracto de ortiga',
        ];
      default:
        return [
          'Garlic and onion extract spray',
          'Chamomile tea application',
          'Baking soda solution',
          'Nettle extract treatment',
        ];
    }
  }

  Future<void> _saveDiagnosisHistory(Map<String, dynamic> diagnosis, Map<String, dynamic> treatment) async {
    final history = await _hiveService.getData('diagnosis_history') ?? [];
    history.add({
      'timestamp': DateTime.now().toIso8601String(),
      'diagnosis': diagnosis,
      'treatment': treatment,
    });
    await _hiveService.saveData('diagnosis_history', history);
  }

  Map<String, dynamic> _getOfflineDiagnosis() {
    return {
      'disease': 'Unable to diagnose offline',
      'confidence': 0.0,
      'severity': 'unknown',
      'treatment': _getGenericTreatment(),
      'prevention': _getPreventionTips('general'),
      'local_remedies': _getLocalRemedies('general'),
      'note': 'Connect to internet for AI-powered diagnosis',
    };
  }

  // Pest identification
  Future<Map<String, dynamic>> identifyPest(File imageFile) async {
    try {
      // final bytes = await imageFile.readAsBytes(); // Reserved for future AI integration
      // final base64Image = base64Encode(bytes); // Reserved for future AI integration
      
      // Mock pest identification
      final pests = [
        {'pest': 'Aphids', 'damage_level': 'moderate', 'urgency': 'medium'},
        {'pest': 'Spider Mites', 'damage_level': 'severe', 'urgency': 'high'},
        {'pest': 'Whiteflies', 'damage_level': 'mild', 'urgency': 'low'},
        {'pest': 'Caterpillars', 'damage_level': 'severe', 'urgency': 'high'},
      ];
      
      final pest = pests[DateTime.now().millisecond % pests.length];
      
      return {
        'pest': pest['pest'],
        'damage_level': pest['damage_level'],
        'urgency': pest['urgency'],
        'control_methods': _getPestControlMethods(pest['pest'] as String),
        'biological_control': _getBiologicalControl(pest['pest'] as String),
      };
    } catch (e) {
      return {'error': 'Failed to identify pest'};
    }
  }

  Map<String, List<String>> _getPestControlMethods(String pest) {
    final methods = {
      'Aphids': {
        'immediate': ['Spray with water', 'Remove by hand', 'Use sticky traps'],
        'organic': ['Ladybug release', 'Neem oil spray', 'Soap solution'],
        'chemical': ['Systemic insecticide', 'Contact insecticide'],
      },
      'Spider Mites': {
        'immediate': ['Increase humidity', 'Spray with water', 'Remove affected leaves'],
        'organic': ['Predatory mites', 'Essential oil spray', 'Diatomaceous earth'],
        'chemical': ['Miticide application', 'Systemic acaricide'],
      },
    };
    
    return methods[pest]?.cast<String, List<String>>() ?? {
      'immediate': ['Monitor closely', 'Isolate affected plants'],
      'organic': ['Beneficial insects', 'Natural sprays'],
      'chemical': ['Consult agricultural extension'],
    };
  }

  List<String> _getBiologicalControl(String pest) {
    final bioControl = {
      'Aphids': ['Ladybugs', 'Lacewings', 'Parasitic wasps', 'Hoverflies'],
      'Spider Mites': ['Predatory mites', 'Minute pirate bugs', 'Thrips'],
      'Whiteflies': ['Encarsia wasps', 'Delphastus beetles', 'Sticky traps'],
      'Caterpillars': ['Bacillus thuringiensis', 'Trichogramma wasps', 'Birds'],
    };
    
    return bioControl[pest] ?? ['Beneficial insects', 'Natural predators'];
  }

  // Soil health analysis from image
  Future<Map<String, dynamic>> analyzeSoilHealth(File imageFile) async {
    // Mock soil analysis - in production, use AI to analyze soil color, texture, etc.
    return {
      'soil_type': 'Loamy',
      'moisture_level': 'Adequate',
      'organic_matter': 'Medium',
      'ph_estimate': '6.5-7.0',
      'recommendations': [
        'Add compost to improve organic matter',
        'Test pH for accurate measurement',
        'Consider cover crops for soil protection',
        'Maintain proper drainage',
      ],
      'deficiency_signs': [
        'Slight nitrogen deficiency visible',
        'Good phosphorus levels',
        'Adequate potassium content',
      ],
    };
  }

  // Get diagnosis history
  Future<List<Map<String, dynamic>>> getDiagnosisHistory() async {
    final history = await _hiveService.getData('diagnosis_history') ?? [];
    return List<Map<String, dynamic>>.from(history);
  }

  // Take photo for diagnosis
  Future<File?> takePhotoForDiagnosis() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    return image != null ? File(image.path) : null;
  }

  // Select photo from gallery
  Future<File?> selectPhotoForDiagnosis() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    
    return image != null ? File(image.path) : null;
  }
}