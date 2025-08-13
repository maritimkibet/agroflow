import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/hybrid_storage_service.dart';
import '../models/crop_task.dart';
import 'home_screen.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final HybridStorageService _storageService = HybridStorageService();
  
  int _currentPage = 0;
  final List<String> _selectedCrops = [];
  final List<String> _selectedTasks = [];
  
  // Common crops and farming types worldwide
  final List<Map<String, dynamic>> _commonCrops = [
    {'name': 'Maize/Corn', 'icon': '🌽', 'description': 'Staple grain crop', 'type': 'crop'},
    {'name': 'Rice', 'icon': '🌾', 'description': 'Primary food crop', 'type': 'crop'},
    {'name': 'Wheat', 'icon': '🌾', 'description': 'Cereal grain', 'type': 'crop'},
    {'name': 'Tomatoes', 'icon': '🍅', 'description': 'Vegetable crop', 'type': 'crop'},
    {'name': 'Potatoes', 'icon': '🥔', 'description': 'Root vegetable', 'type': 'crop'},
    {'name': 'Beans', 'icon': '🫘', 'description': 'Legume crop', 'type': 'crop'},
    {'name': 'Onions', 'icon': '🧅', 'description': 'Bulb vegetable', 'type': 'crop'},
    {'name': 'Carrots', 'icon': '🥕', 'description': 'Root vegetable', 'type': 'crop'},
    {'name': 'Dairy Cattle', 'icon': '🐄', 'description': 'Milk production', 'type': 'livestock'},
    {'name': 'Goats', 'icon': '🐐', 'description': 'Milk & meat', 'type': 'livestock'},
    {'name': 'Poultry', 'icon': '🐔', 'description': 'Eggs & meat', 'type': 'livestock'},
    {'name': 'Sheep', 'icon': '🐑', 'description': 'Wool & meat', 'type': 'livestock'},
  ];
  
  // Common farming tasks (crops and livestock)
  final List<Map<String, dynamic>> _commonTasks = [
    // Crop farming tasks
    {'name': 'Land Preparation', 'icon': '🚜', 'description': 'Prepare soil for planting', 'type': 'crop'},
    {'name': 'Planting/Sowing', 'icon': '🌱', 'description': 'Plant seeds or seedlings', 'type': 'crop'},
    {'name': 'Watering/Irrigation', 'icon': '💧', 'description': 'Irrigate crops', 'type': 'crop'},
    {'name': 'Weeding', 'icon': '🌿', 'description': 'Remove unwanted plants', 'type': 'crop'},
    {'name': 'Fertilizing', 'icon': '🧪', 'description': 'Apply nutrients', 'type': 'crop'},
    {'name': 'Pest Control', 'icon': '🐛', 'description': 'Manage pests and diseases', 'type': 'crop'},
    {'name': 'Harvesting', 'icon': '🧺', 'description': 'Collect mature crops', 'type': 'crop'},
    
    // Livestock/Dairy tasks
    {'name': 'Milking', 'icon': '🥛', 'description': 'Milk dairy animals', 'type': 'livestock'},
    {'name': 'Feeding', 'icon': '🌾', 'description': 'Feed livestock', 'type': 'livestock'},
    {'name': 'Health Monitoring', 'icon': '🩺', 'description': 'Check animal health', 'type': 'livestock'},
    {'name': 'Breeding', 'icon': '💕', 'description': 'Manage breeding programs', 'type': 'livestock'},
    {'name': 'Pasture Management', 'icon': '🌱', 'description': 'Manage grazing areas', 'type': 'livestock'},
    
    // General tasks
    {'name': 'Market Research', 'icon': '📊', 'description': 'Research market prices', 'type': 'general'},
    {'name': 'Record Keeping', 'icon': '📝', 'description': 'Maintain farm records', 'type': 'general'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentPage ? Colors.green.shade600 : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildWelcomePage(),
                  _buildCropsPage(),
                  _buildTasksPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _currentPage == 2 ? _completeOnboarding : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
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

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.agriculture,
            size: 120,
            color: Colors.green.shade600,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to AgroFlow!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your smart farming assistant for managing crops, tasks, and marketplace activities worldwide.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureItem(Icons.task_alt, 'Manage Tasks', 'Track your farming activities'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.shopping_cart, 'Marketplace', 'Buy and sell products'),
                const SizedBox(height: 16),
                _buildFeatureItem(Icons.smart_toy, 'AI Assistant', 'Get farming advice'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade600, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCropsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you farm?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the crops you grow or livestock you raise. This helps us provide better advice.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _commonCrops.length,
              itemBuilder: (context, index) {
                final crop = _commonCrops[index];
                final isSelected = _selectedCrops.contains(crop['name']);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCrops.remove(crop['name']);
                      } else {
                        _selectedCrops.add(crop['name']);
                      }
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade100 : Colors.white,
                      border: Border.all(
                        color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          crop['icon'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          crop['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.green.shade800 : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          crop['description'],
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedCrops.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Selected: ${_selectedCrops.join(', ')}',
                style: TextStyle(color: Colors.green.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasksPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What farming tasks do you do?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the farming activities you regularly perform. We\'ll help you track and schedule them.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _commonTasks.length,
              itemBuilder: (context, index) {
                final task = _commonTasks[index];
                final isSelected = _selectedTasks.contains(task['name']);
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTasks.remove(task['name']);
                        } else {
                          _selectedTasks.add(task['name']);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.green.shade100 : Colors.white,
                        border: Border.all(
                          color: isSelected ? Colors.green.shade600 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Text(
                            task['icon'],
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.green.shade800 : Colors.black87,
                                  ),
                                ),
                                Text(
                                  task['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                            ),
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

  Future<void> _completeOnboarding() async {
    try {
      // Create sample tasks based on selected crops and tasks
      if (_selectedCrops.isNotEmpty && _selectedTasks.isNotEmpty) {
        final now = DateTime.now();
        
        for (int i = 0; i < _selectedCrops.length && i < 3; i++) {
          final crop = _selectedCrops[i];
          final taskName = _selectedTasks.isNotEmpty ? _selectedTasks[i % _selectedTasks.length] : 'General Care';
          
          final task = CropTask(
            cropName: crop,
            taskDescription: '$taskName for $crop',
            date: now.add(Duration(days: i + 1)),
            priority: i == 0 ? 'High' : 'Medium',
            taskType: taskName.toLowerCase().replaceAll(' ', '_'),
          );
          
          await _storageService.addOrUpdateTask(task);
        }
      }
      
      // Mark onboarding as complete
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}