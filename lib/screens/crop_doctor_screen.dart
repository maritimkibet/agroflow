import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ai_crop_doctor_service.dart';

class CropDoctorScreen extends StatefulWidget {
  const CropDoctorScreen({super.key});

  @override
  State<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends State<CropDoctorScreen> with SingleTickerProviderStateMixin {
  final AICropDoctorService _cropDoctorService = AICropDoctorService();
  late TabController _tabController;
  
  File? _selectedImage;
  Map<String, dynamic>? _diagnosisResult;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🩺 AI Crop Doctor'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Diagnose'),
            Tab(icon: Icon(Icons.bug_report), text: 'Pests'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiagnosisTab(),
          _buildPestTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildImageSelector(),
          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            _buildImagePreview(),
            const SizedBox(height: 20),
            _buildAnalyzeButton(),
          ],
          if (_diagnosisResult != null) ...[
            const SizedBox(height: 20),
            _buildDiagnosisResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.add_a_photo, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'Take or Select Plant Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get instant AI-powered diagnosis for plant diseases and health issues',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectPhoto,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _diagnosisResult = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Retake'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzePlant,
        icon: _isAnalyzing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.psychology),
        label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze with AI'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDiagnosisResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Diagnosis: ${_diagnosisResult!['disease']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _diagnosisResult!['confidence'],
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _diagnosisResult!['confidence'] > 0.8 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text('Confidence: ${(_diagnosisResult!['confidence'] * 100).toInt()}%'),
            const SizedBox(height: 16),
            _buildTreatmentSection(),
            const SizedBox(height: 16),
            _buildPreventionSection(),
            const SizedBox(height: 16),
            _buildLocalRemediesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTreatmentSection() {
    final treatment = _diagnosisResult!['treatment'];
    return ExpansionTile(
      leading: const Icon(Icons.healing, color: Colors.blue),
      title: const Text('Treatment Options'),
      children: [
        _buildTreatmentCategory('Immediate Actions', treatment['immediate']),
        _buildTreatmentCategory('Organic Solutions', treatment['organic']),
        _buildTreatmentCategory('Chemical Treatment', treatment['chemical']),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Expected Timeline: ${treatment['timeline']}',
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildTreatmentCategory(String title, List<dynamic> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(child: Text(item.toString())),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPreventionSection() {
    return ExpansionTile(
      leading: const Icon(Icons.shield, color: Colors.green),
      title: const Text('Prevention Tips'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _diagnosisResult!['prevention'].map<Widget>((tip) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(tip.toString())),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocalRemediesSection() {
    return ExpansionTile(
      leading: const Icon(Icons.eco, color: Colors.brown),
      title: const Text('Local Remedies'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: _diagnosisResult!['local_remedies'].map<Widget>((remedy) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_florist, size: 16, color: Colors.brown),
                    const SizedBox(width: 8),
                    Expanded(child: Text(remedy.toString())),
                  ],
                ),
              ),
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPestCard(
            'Aphids',
            'Small, soft-bodied insects that feed on plant sap',
            'Use ladybugs, neem oil, or insecticidal soap',
            Icons.bug_report,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildPestCard(
            'Spider Mites',
            'Tiny pests that cause yellowing and webbing on leaves',
            'Increase humidity, use predatory mites, or miticide',
            Icons.pest_control,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildPestCard(
            'Whiteflies',
            'Small white flying insects that damage leaves',
            'Use yellow sticky traps, beneficial insects, or neem oil',
            Icons.flutter_dash,
            Colors.yellow,
          ),
          const SizedBox(height: 16),
          _buildPestCard(
            'Caterpillars',
            'Larvae that eat leaves and can cause significant damage',
            'Hand picking, Bt spray, or beneficial wasps',
            Icons.bug_report,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPestCard(String name, String description, String treatment, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Treatment:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              treatment,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _getMockHistory().length,
      itemBuilder: (context, index) {
        final diagnosis = _getMockHistory()[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              Icons.history, 
              color: _getConfidenceColor(diagnosis['confidence']),
            ),
            title: Text(diagnosis['disease']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(diagnosis['date']),
                const SizedBox(height: 4),
                Text(
                  diagnosis['treatment'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getConfidenceColor(diagnosis['confidence']).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(diagnosis['confidence'] * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(diagnosis['confidence']),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockHistory() {
    return [
      {
        'disease': 'Early Blight',
        'confidence': 0.89,
        'date': '2 days ago',
        'treatment': 'Applied copper fungicide, removed affected leaves',
      },
      {
        'disease': 'Powdery Mildew',
        'confidence': 0.76,
        'date': '1 week ago',
        'treatment': 'Used neem oil spray, improved air circulation',
      },
      {
        'disease': 'Leaf Spot',
        'confidence': 0.82,
        'date': '2 weeks ago',
        'treatment': 'Organic treatment with baking soda solution',
      },
      {
        'disease': 'Bacterial Wilt',
        'confidence': 0.71,
        'date': '3 weeks ago',
        'treatment': 'Removed infected plants, improved drainage',
      },
    ];
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _takePhoto() async {
    final image = await _cropDoctorService.takePhotoForDiagnosis();
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _diagnosisResult = null;
      });
    }
  }

  Future<void> _selectPhoto() async {
    final image = await _cropDoctorService.selectPhotoForDiagnosis();
    if (image != null) {
      setState(() {
        _selectedImage = image;
        _diagnosisResult = null;
      });
    }
  }

  Future<void> _analyzePlant() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final result = await _cropDoctorService.diagnoseCropDisease(_selectedImage!);
      setState(() {
        _diagnosisResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }
}