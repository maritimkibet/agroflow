class ValidationService {
  // Email validation
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name is required';
    }
    
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    return null;
  }

  // Product name validation
  static String? validateProductName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Product name is required';
    }
    
    if (name.trim().length < 2) {
      return 'Product name must be at least 2 characters long';
    }
    
    if (name.length > 50) {
      return 'Product name must be less than 50 characters';
    }
    
    return null;
  }

  // Price validation
  static String? validatePrice(String? price) {
    if (price == null || price.isEmpty) {
      return 'Price is required';
    }
    
    final priceValue = double.tryParse(price);
    if (priceValue == null) {
      return 'Please enter a valid price';
    }
    
    if (priceValue <= 0) {
      return 'Price must be greater than 0';
    }
    
    if (priceValue > 1000000) {
      return 'Price seems too high';
    }
    
    return null;
  }

  // Quantity validation
  static String? validateQuantity(String? quantity) {
    if (quantity == null || quantity.isEmpty) {
      return 'Quantity is required';
    }
    
    final quantityValue = double.tryParse(quantity);
    if (quantityValue == null) {
      return 'Please enter a valid quantity';
    }
    
    if (quantityValue <= 0) {
      return 'Quantity must be greater than 0';
    }
    
    return null;
  }

  // Description validation
  static String? validateDescription(String? description) {
    if (description == null || description.isEmpty) {
      return 'Description is required';
    }
    
    if (description.trim().length < 10) {
      return 'Description must be at least 10 characters long';
    }
    
    if (description.length > 500) {
      return 'Description must be less than 500 characters';
    }
    
    return null;
  }

  // Location validation
  static String? validateLocation(String? location) {
    if (location == null || location.isEmpty) {
      return 'Location is required';
    }
    
    if (location.trim().length < 2) {
      return 'Location must be at least 2 characters long';
    }
    
    return null;
  }

  // Task title validation
  static String? validateTaskTitle(String? title) {
    if (title == null || title.isEmpty) {
      return 'Task title is required';
    }
    
    if (title.trim().length < 3) {
      return 'Task title must be at least 3 characters long';
    }
    
    if (title.length > 100) {
      return 'Task title must be less than 100 characters';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Date is required';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(date.year, date.month, date.day);
    
    if (selectedDate.isBefore(today)) {
      return 'Date cannot be in the past';
    }
    
    // Don't allow dates more than 1 year in the future
    final oneYearFromNow = today.add(const Duration(days: 365));
    if (selectedDate.isAfter(oneYearFromNow)) {
      return 'Date cannot be more than 1 year in the future';
    }
    
    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // URL validation
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // URL is optional
    }
    
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Please enter a valid URL';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Crop type validation
  static String? validateCropType(String? cropType) {
    if (cropType == null || cropType.isEmpty) {
      return 'Crop type is required';
    }
    
    final validCrops = [
      'Tomatoes', 'Potatoes', 'Onions', 'Carrots', 'Lettuce', 'Spinach',
      'Cabbage', 'Broccoli', 'Cauliflower', 'Peppers', 'Cucumbers',
      'Beans', 'Peas', 'Corn', 'Wheat', 'Rice', 'Barley', 'Oats',
      'Soybeans', 'Sunflowers', 'Other'
    ];
    
    if (!validCrops.contains(cropType)) {
      return 'Please select a valid crop type';
    }
    
    return null;
  }

  // Batch validation for forms
  static Map<String, String> validateForm(Map<String, dynamic> formData, Map<String, String? Function(String?)> validators) {
    final errors = <String, String>{};
    
    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = formData[fieldName]?.toString();
      
      final error = validator(value);
      if (error != null) {
        errors[fieldName] = error;
      }
    }
    
    return errors;
  }

  // Check if form is valid
  static bool isFormValid(Map<String, String> errors) {
    return errors.isEmpty;
  }
}