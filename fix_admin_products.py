#!/usr/bin/env python3
import re

def fix_admin_product_constructors(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Simple approach: add missing parameters after sellerId
    # Pattern to find Product constructors missing required params
    pattern = r'(Product\(\s*\n\s*id:\s*\'[^\']*\',\s*\n\s*name:[^,]*,)'
    
    def add_required_params(match):
        constructor_start = match.group(1)
        # Add the required parameters
        return constructor_start + '\n        type: ProductType.crop,\n        listingType: ListingType.sell,'
    
    # Replace all Product constructors
    content = re.sub(pattern, add_required_params, content)
    
    # Also need to add tags parameter after sellerId
    pattern2 = r'(sellerId:\s*\'[^\']*\',)'
    def add_tags(match):
        return match.group(1) + '\n        tags: [],'
    
    content = re.sub(pattern2, add_tags, content)
    
    with open(file_path, 'w') as f:
        f.write(content)

# Fix admin service
fix_admin_product_constructors('lib/services/admin_service.dart')
print("Fixed admin_service.dart")