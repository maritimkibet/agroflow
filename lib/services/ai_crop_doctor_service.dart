import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
    try {
      // Use Google Vision API for plant disease detection
      const apiKey = 'AIzaSyC2qxVLaZSVCcGu_khOHMeK0vRxGoOtCl8'; // Replace with your actual API key
      const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
      
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'TEXT_DETECTION', 'maxResults': 5}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _analyzeVisionResponse(data);
      } else {
        throw Exception('Vision API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to mock response if API fails
      return _getMockDiagnosis();
    }
  }

  Map<String, dynamic> _analyzeVisionResponse(Map<String, dynamic> visionData) {
    // Analyze Google Vision API response for plant diseases
    final labels = visionData['responses']?[0]?['labelAnnotations'] ?? [];
    
    // Look for disease-related keywords in labels
    final diseaseKeywords = {
      'leaf': ['Leaf Blight', 'Leaf Spot'],
      'rust': ['Rust', 'Leaf Rust'],
      'mildew': ['Powdery Mildew', 'Downy Mildew'],
      'blight': ['Early Blight', 'Late Blight'],
      'spot': ['Bacterial Spot', 'Black Spot'],
      'wilt': ['Fusarium Wilt', 'Bacterial Wilt'],
    };

    String detectedDisease = 'Unknown Plant Condition';
    double confidence = 0.5;
    String severity = 'mild';

    for (var label in labels) {
      final description = label['description'].toString().toLowerCase();
      final score = label['score'] ?? 0.5;
      
      for (var keyword in diseaseKeywords.keys) {
        if (description.contains(keyword)) {
          detectedDisease = diseaseKeywords[keyword]!.first;
          confidence = score;
          severity = score > 0.8 ? 'severe' : score > 0.6 ? 'moderate' : 'mild';
          break;
        }
      }
    }

    return {
      'disease': detectedDisease,
      'confidence': confidence,
      'severity': severity,
    };
  }

  Map<String, dynamic> _getMockDiagnosis() {
    // Return error when API is unavailable - no mock data
    return {
      'disease': 'Unable to analyze image',
      'confidence': 0.0,
      'severity': 'unknown',
      'error': 'Vision API unavailable - please check your internet connection and API configuration'
    };
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

  // Pest identification - requires real AI implementation
  Future<Map<String, dynamic>> identifyPest(File imageFile) async {
    try {
      // Convert image to base64 for API call
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use Google Vision API for pest identification
      const apiKey = 'AIzaSyC2qxVLaZSVCcGu_khOHMeK0vRxGoOtCl8'; // Replace with your actual API key
      const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
      
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 5}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _analyzePestResponse(data);
      } else {
        throw Exception('Vision API Error: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'error': 'Failed to identify pest: $e',
        'note': 'Please ensure you have a valid Google Vision API key and internet connection'
      };
    }
  }

  Map<String, dynamic> _analyzePestResponse(Map<String, dynamic> visionData) {
    final labels = visionData['responses']?[0]?['labelAnnotations'] ?? [];
    
    // Look for pest-related keywords in labels
    final pestKeywords = {
      'aphid': ['Aphids', 'moderate', 'medium'],
      'mite': ['Spider Mites', 'severe', 'high'],
      'whitefly': ['Whiteflies', 'mild', 'low'],
      'caterpillar': ['Caterpillars', 'severe', 'high'],
      'beetle': ['Beetles', 'moderate', 'medium'],
      'thrips': ['Thrips', 'mild', 'medium'],
    };

    String detectedPest = 'Unknown Pest';
    String damageLevel = 'unknown';
    String urgency = 'low';

    for (var label in labels) {
      final description = label['description'].toString().toLowerCase();
      // final score = label['score'] ?? 0.5; // Score not used in current implementation
      
      for (var keyword in pestKeywords.keys) {
        if (description.contains(keyword)) {
          final pestInfo = pestKeywords[keyword]!;
          detectedPest = pestInfo[0];
          damageLevel = pestInfo[1];
          urgency = pestInfo[2];
          break;
        }
      }
    }

    if (detectedPest == 'Unknown Pest') {
      return {
        'error': 'No pest detected in image',
        'note': 'Please ensure the image clearly shows the pest or pest damage'
      };
    }

    return {
      'pest': detectedPest,
      'damage_level': damageLevel,
      'urgency': urgency,
      'control_methods': _getPestControlMethods(detectedPest),
      'biological_control': _getBiologicalControl(detectedPest),
    };
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

  // Soil health analysis from image - requires real AI implementation
  Future<Map<String, dynamic>> analyzeSoilHealth(File imageFile) async {
    try {
      // Convert image to base64 for API call
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Use Google Vision API for soil analysis
      const apiKey = 'AIzaSyC2qxVLaZSVCcGu_khOHMeK0vRxGoOtCl8'; // Replace with your actual API key
      const url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';
      
      final requestBody = {
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'IMAGE_PROPERTIES'}
            ]
          }
        ]
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _analyzeSoilResponse(data);
      } else {
        throw Exception('Vision API Error: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'error': 'Failed to analyze soil: $e',
        'note': 'Please ensure you have a valid Google Vision API key and internet connection',
        'recommendations': [
          'Take a clear photo of the soil surface',
          'Ensure good lighting conditions',
          'Consider professional soil testing for accurate results',
        ],
      };
    }
  }

  Map<String, dynamic> _analyzeSoilResponse(Map<String, dynamic> visionData) {
    final labels = visionData['responses']?[0]?['labelAnnotations'] ?? [];
    final colors = visionData['responses']?[0]?['imagePropertiesAnnotation']?['dominantColors']?['colors'] ?? [];
    
    // Analyze soil based on visual characteristics
    String soilType = 'Unknown';
    String moistureLevel = 'Unknown';
    String organicMatter = 'Unknown';
    
    // Analyze dominant colors for soil characteristics
    if (colors.isNotEmpty) {
      final dominantColor = colors[0]['color'];
      final red = dominantColor['red'] ?? 0;
      final green = dominantColor['green'] ?? 0;
      final blue = dominantColor['blue'] ?? 0;
      
      // Basic soil type estimation based on color
      if (red > 100 && green < 80 && blue < 60) {
        soilType = 'Clay (reddish)';
      } else if (red > 80 && green > 60 && blue < 50) {
        soilType = 'Loamy';
      } else if (red < 60 && green < 60 && blue < 60) {
        soilType = 'Sandy (dark)';
      } else {
        soilType = 'Mixed composition';
      }
      
      // Estimate moisture based on color darkness
      final brightness = (red + green + blue) / 3;
      if (brightness < 80) {
        moistureLevel = 'High (dark soil)';
      } else if (brightness < 150) {
        moistureLevel = 'Moderate';
      } else {
        moistureLevel = 'Low (light/dry soil)';
      }
    }

    // Look for organic matter indicators in labels
    for (var label in labels) {
      final description = label['description'].toString().toLowerCase();
      if (description.contains('compost') || description.contains('organic')) {
        organicMatter = 'High';
      } else if (description.contains('sand') || description.contains('dry')) {
        organicMatter = 'Low';
      }
    }

    if (organicMatter == 'Unknown') {
      organicMatter = 'Moderate (estimated)';
    }

    return {
      'soil_type': soilType,
      'moisture_level': moistureLevel,
      'organic_matter': organicMatter,
      'ph_estimate': 'Requires lab testing',
      'analysis_method': 'Visual AI analysis',
      'recommendations': [
        'Conduct professional soil testing for accurate pH and nutrient levels',
        'Add organic compost to improve soil structure',
        'Test soil moisture regularly',
        'Consider cover crops for soil protection',
      ],
      'limitations': [
        'Visual analysis provides estimates only',
        'Lab testing recommended for precise measurements',
        'Nutrient levels cannot be determined visually',
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