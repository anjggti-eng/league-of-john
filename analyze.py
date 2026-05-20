import re
import json

# Read index.js
with open('index.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Find _cartdat array
match = re.search(r'var _cartdat\s*=\s*\[(.*?)\];', content, re.DOTALL)
if not match:
    # Try finding without var
    match = re.search(r'_cartdat\s*=\s*\[(.*?)\];', content, re.DOTALL)

if match:
    cartdat_str = match.group(1)
    # Parse the array
    # Since it's a comma-separated list of numbers, we can wrap it in brackets and load as JSON
    cartdat = json.loads("[" + cartdat_str + "]")
    print(f"Successfully extracted _cartdat!")
    print(f"Length of _cartdat: {len(cartdat)} bytes")
    cartdat_bytes = bytes(cartdat)
    
    # Print the 16 bytes starting at 0x4300
    meta_bytes = cartdat_bytes[0x4300:0x4310]
    print(f"Bytes at 0x4300: {list(meta_bytes)}")
    
    signature = cartdat_bytes[0x4300:0x4304]
    print(f"Signature raw: {signature}")
    
    # Try big and little endian for sizes
    dec_len_big = int.from_bytes(cartdat_bytes[0x4304:0x4306], byteorder='big')
    dec_len_lit = int.from_bytes(cartdat_bytes[0x4304:0x4306], byteorder='little')
    comp_len_big = int.from_bytes(cartdat_bytes[0x4306:0x4308], byteorder='big')
    comp_len_lit = int.from_bytes(cartdat_bytes[0x4306:0x4308], byteorder='little')
    
    print(f"Decompressed len (Big Endian): {dec_len_big}")
    print(f"Decompressed len (Little Endian): {dec_len_lit}")
    print(f"Compressed len+8 (Big Endian): {comp_len_big}")
    print(f"Compressed len+8 (Little Endian): {comp_len_lit}")

else:
    print("Could not find _cartdat array in index.js")
