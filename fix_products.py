#!/usr/bin/env python3
import re

def fix_product_constructors(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Pattern to match Product constructors
    pattern = r'Product\(\s*\n\s*id:'
    
    # Find all Product constructor locations
    matches = list(re.finditer(pattern, content))
    
    # Process from end to beginning to avoid offset issues
    for match in reversed(matches):
        start = match.start()
        # Find the opening parenthesis
        paren_start = content.find('(', start)
        
        # Find the matching closing parenthesis
        paren_count = 1
        pos = paren_start + 1
        while pos < len(content) and paren_count > 0:
            if content[pos] == '(':
                paren_count += 1
            elif content[pos] == ')':
                paren_count -= 1
            pos += 1
        
        if paren_count == 0:
            # Extract the constructor content
            constructor_content = content[paren_start+1:pos-1]
            
            # Check if required parameters are missing
            if 'type:' not in constructor_content:
                # Find where to insert type parameter (after id)
                id_match = re.search(r"id:\s*'[^']*',", constructor_content)
                if id_match:
                    insert_pos = paren_start + 1 + id_match.end()
                    content = content[:insert_pos] + '\n        type: ProductType.crop,' + content[insert_pos:]
            
            # Re-find the constructor after modification
            constructor_content = content[paren_start+1:content.find(')', paren_start)]
            
            if 'listingType:' not in constructor_content:
                type_match = re.search(r"type:\s*ProductType\.[^,]*,", constructor_content)
                if type_match:
                    insert_pos = paren_start + 1 + type_match.end()
                    content = content[:insert_pos] + '\n        listingType: ListingType.sell,' + content[insert_pos:]
            
            # Re-find the constructor after modification
            constructor_content = content[paren_start+1:content.find(')', paren_start)]
            
            if 'tags:' not in constructor_content:
                # Find sellerId to insert tags after it
                seller_match = re.search(r"sellerId:\s*'[^']*',", constructor_content)
                if seller_match:
                    insert_pos = paren_start + 1 + seller_match.end()
                    content = content[:insert_pos] + '\n        tags: [],' + content[insert_pos:]
    
    with open(file_path, 'w') as f:
        f.write(content)

# Fix marketplace service
fix_product_constructors('lib/services/marketplace_service.dart')
print("Fixed marketplace_service.dart")