import re
import json

# Read index.js
with open('index.js', 'r', encoding='utf-8') as f:
    content = f.read()

# Find _cartdat array
match = re.search(r'var _cartdat\s*=\s*\[(.*?)\];', content, re.DOTALL)
if not match:
    match = re.search(r'_cartdat\s*=\s*\[(.*?)\];', content, re.DOTALL)

if match:
    cartdat_str = match.group(1)
    cartdat = json.loads("[" + cartdat_str + "]")
    
    # Verify length
    if len(cartdat) == 32768:
        # Convert list of integers to raw bytes
        rom_bytes = bytes(cartdat)
        
        # Save as leagueofpico.p8.rom
        output_filename = 'leagueofpico.p8.rom'
        with open(output_filename, 'wb') as out_f:
            out_f.write(rom_bytes)
            
        print(f"Success! Cartridge extracted and saved to: {output_filename}")
        print(f"File size: {len(rom_bytes)} bytes")
    else:
        print(f"Warning: Expected 32768 bytes, but got {len(cartdat)} bytes.")
else:
    print("Could not find _cartdat array in index.js")
