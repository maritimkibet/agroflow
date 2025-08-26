import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'hive_service.dart';

class BlockchainTraceabilityService {
  static final BlockchainTraceabilityService _instance = BlockchainTraceabilityService._internal();
  factory BlockchainTraceabilityService() => _instance;
  BlockchainTraceabilityService._internal();

  final HiveService _hiveService = HiveService();
  List<TraceabilityBlock> _blockchain = [];

  Future<void> initialize() async {
    await _loadBlockchain();
  }

  Future<void> _loadBlockchain() async {
    final data = await _hiveService.getData('blockchain');
    if (data != null) {
      _blockchain = (data as List).map((e) => TraceabilityBlock.fromJson(e)).toList();
    }
  }

  Future<void> _saveBlockchain() async {
    await _hiveService.saveData('blockchain', _blockchain.map((e) => e.toJson()).toList());
  }

  // Create a new block for farm-to-table traceability
  Future<String> createTraceabilityRecord({
    required String productId,
    required String farmerId,
    required String action,
    required Map<String, dynamic> data,
    String? location,
    List<String>? certifications,
  }) async {
    final previousHash = _blockchain.isNotEmpty ? _blockchain.last.hash : '0';
    
    final block = TraceabilityBlock(
      index: _blockchain.length,
      timestamp: DateTime.now(),
      productId: productId,
      farmerId: farmerId,
      action: action,
      data: data,
      location: location,
      certifications: certifications ?? [],
      previousHash: previousHash,
    );

    block.hash = _calculateHash(block);
    _blockchain.add(block);
    await _saveBlockchain();

    return block.hash;
  }

  String _calculateHash(TraceabilityBlock block) {
    final input = '${block.index}${block.timestamp.millisecondsSinceEpoch}'
        '${block.productId}${block.farmerId}${block.action}'
        '${jsonEncode(block.data)}${block.previousHash}';
    
    return sha256.convert(utf8.encode(input)).toString();
  }

  // Get complete traceability history for a product
  List<TraceabilityBlock> getProductHistory(String productId) {
    return _blockchain.where((block) => block.productId == productId).toList();
  }

  // Generate QR code data for product traceability
  Map<String, dynamic> generateQRCodeData(String productId) {
    final history = getProductHistory(productId);
    if (history.isEmpty) return {};

    final latestBlock = history.last;
    return {
      'product_id': productId,
      'farmer_id': latestBlock.farmerId,
      'harvest_date': history.firstWhere((b) => b.action == 'harvest', orElse: () => latestBlock).timestamp.toIso8601String(),
      'certifications': latestBlock.certifications,
      'location': latestBlock.location,
      'verification_url': 'https://agroflow.app/verify/$productId',
      'blockchain_hash': latestBlock.hash,
    };
  }

  // Verify blockchain integrity
  bool verifyBlockchain() {
    for (int i = 1; i < _blockchain.length; i++) {
      final currentBlock = _blockchain[i];
      final previousBlock = _blockchain[i - 1];

      // Check if current block's hash is valid
      if (currentBlock.hash != _calculateHash(currentBlock)) {
        return false;
      }

      // Check if current block points to previous block
      if (currentBlock.previousHash != previousBlock.hash) {
        return false;
      }
    }
    return true;
  }

  // Get sustainability metrics from blockchain
  Map<String, dynamic> getSustainabilityMetrics(String farmerId) {
    final farmerBlocks = _blockchain.where((block) => block.farmerId == farmerId).toList();
    
    int organicProducts = 0;
    int certifiedProducts = 0;
    double totalCarbonFootprint = 0;
    Set<String> uniqueProducts = {};

    for (final block in farmerBlocks) {
      uniqueProducts.add(block.productId);
      
      if (block.certifications.contains('organic')) {
        organicProducts++;
      }
      if (block.certifications.isNotEmpty) {
        certifiedProducts++;
      }
      
      final carbonData = block.data['carbon_footprint'];
      if (carbonData != null) {
        totalCarbonFootprint += carbonData as double;
      }
    }

    return {
      'total_products': uniqueProducts.length,
      'organic_percentage': uniqueProducts.isEmpty ? 0 : (organicProducts / uniqueProducts.length * 100),
      'certification_rate': uniqueProducts.isEmpty ? 0 : (certifiedProducts / uniqueProducts.length * 100),
      'average_carbon_footprint': uniqueProducts.isEmpty ? 0 : (totalCarbonFootprint / uniqueProducts.length),
      'sustainability_score': _calculateSustainabilityScore(organicProducts, certifiedProducts, uniqueProducts.length),
    };
  }

  double _calculateSustainabilityScore(int organic, int certified, int total) {
    if (total == 0) return 0;
    
    final organicScore = (organic / total) * 40;
    final certificationScore = (certified / total) * 30;
    final diversityScore = total > 5 ? 30 : (total / 5) * 30;
    
    return organicScore + certificationScore + diversityScore;
  }

  // Common traceability actions
  Future<void> recordPlanting(String productId, String farmerId, Map<String, dynamic> plantingData) async {
    await createTraceabilityRecord(
      productId: productId,
      farmerId: farmerId,
      action: 'planting',
      data: plantingData,
    );
  }

  Future<void> recordHarvest(String productId, String farmerId, Map<String, dynamic> harvestData) async {
    await createTraceabilityRecord(
      productId: productId,
      farmerId: farmerId,
      action: 'harvest',
      data: harvestData,
    );
  }

  Future<void> recordProcessing(String productId, String processorId, Map<String, dynamic> processingData) async {
    await createTraceabilityRecord(
      productId: productId,
      farmerId: processorId,
      action: 'processing',
      data: processingData,
    );
  }

  Future<void> recordTransport(String productId, String transporterId, Map<String, dynamic> transportData) async {
    await createTraceabilityRecord(
      productId: productId,
      farmerId: transporterId,
      action: 'transport',
      data: transportData,
    );
  }
}

class TraceabilityBlock {
  final int index;
  final DateTime timestamp;
  final String productId;
  final String farmerId;
  final String action;
  final Map<String, dynamic> data;
  final String? location;
  final List<String> certifications;
  final String previousHash;
  String hash = '';

  TraceabilityBlock({
    required this.index,
    required this.timestamp,
    required this.productId,
    required this.farmerId,
    required this.action,
    required this.data,
    this.location,
    required this.certifications,
    required this.previousHash,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'timestamp': timestamp.toIso8601String(),
    'productId': productId,
    'farmerId': farmerId,
    'action': action,
    'data': data,
    'location': location,
    'certifications': certifications,
    'previousHash': previousHash,
    'hash': hash,
  };

  factory TraceabilityBlock.fromJson(Map<String, dynamic> json) {
    final block = TraceabilityBlock(
      index: json['index'],
      timestamp: DateTime.parse(json['timestamp']),
      productId: json['productId'],
      farmerId: json['farmerId'],
      action: json['action'],
      data: Map<String, dynamic>.from(json['data']),
      location: json['location'],
      certifications: List<String>.from(json['certifications']),
      previousHash: json['previousHash'],
    );
    block.hash = json['hash'];
    return block;
  }
}