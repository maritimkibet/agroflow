import 'package:hive/hive.dart';

part 'crop_data.g.dart';

@HiveType(typeId: 6)
class CropData extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final Map<String, WateringSchedule> wateringScheduleByRegion;

  @HiveField(4)
  final int growthDurationDays;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final List<String>? tips;

  CropData({
    required this.id,
    required this.name,
    required this.description,
    required this.wateringScheduleByRegion,
    required this.growthDurationDays,
    this.imageUrl,
    this.tips,
  });
}

@HiveType(typeId: 7)
class WateringSchedule {
  @HiveField(0)
  final int frequencyDays;

  @HiveField(1)
  final double amountLiters;

  @HiveField(2)
  final String? notes;

  WateringSchedule({
    required this.frequencyDays,
    required this.amountLiters,
    this.notes,
  });
}

// Predefined crop data for common crops
class CropDataRepository {
  static Map<String, CropData> getCropData() {
    return {
      'maize': CropData(
        id: 'maize',
        name: 'Maize',
        description: 'A staple grain crop in many regions.',
        wateringScheduleByRegion: {
          'Eastern': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 5.0,
            notes: 'Reduce frequency during rainy season',
          ),
          'Western': WateringSchedule(
            frequencyDays: 2,
            amountLiters: 6.0,
            notes: 'Increase amount during dry season',
          ),
          'Central': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 5.5,
            notes: 'Standard watering',
          ),
          'default': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 5.0,
            notes: 'Adjust based on local conditions',
          ),
        },
        growthDurationDays: 120,
        tips: [
          'Plant in well-drained soil',
          'Ensure adequate spacing between plants',
          'Apply fertilizer after 4 weeks',
        ],
      ),
      'beans': CropData(
        id: 'beans',
        name: 'Beans',
        description: 'A protein-rich legume crop.',
        wateringScheduleByRegion: {
          'Eastern': WateringSchedule(
            frequencyDays: 4,
            amountLiters: 3.0,
            notes: 'Beans need less water in this region',
          ),
          'Western': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 4.0,
            notes: 'Regular watering needed',
          ),
          'Central': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 3.5,
            notes: 'Standard watering',
          ),
          'default': WateringSchedule(
            frequencyDays: 3,
            amountLiters: 3.5,
            notes: 'Adjust based on soil moisture',
          ),
        },
        growthDurationDays: 90,
        tips: [
          'Good for crop rotation with maize',
          'Harvest when pods are dry',
          'Store in cool, dry place',
        ],
      ),
      'tomatoes': CropData(
        id: 'tomatoes',
        name: 'Tomatoes',
        description: 'A popular vegetable/fruit crop.',
        wateringScheduleByRegion: {
          'Eastern': WateringSchedule(
            frequencyDays: 2,
            amountLiters: 2.0,
            notes: 'Regular watering needed',
          ),
          'Western': WateringSchedule(
            frequencyDays: 1,
            amountLiters: 2.5,
            notes: 'Daily watering recommended',
          ),
          'Central': WateringSchedule(
            frequencyDays: 2,
            amountLiters: 2.0,
            notes: 'Standard watering',
          ),
          'default': WateringSchedule(
            frequencyDays: 2,
            amountLiters: 2.0,
            notes: 'Keep soil consistently moist',
          ),
        },
        growthDurationDays: 70,
        tips: [
          'Stake plants for support',
          'Prune suckers for better yield',
          'Watch for pests and diseases',
        ],
      ),
    };
  }
}