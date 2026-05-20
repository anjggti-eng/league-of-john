import re
import json

LITERALS = 60
LITERAL_STRING = "^\n 0123456789abcdefghijklmnopqrstuvwxyz!#%(){}[]<>+=/*:;.,~_"
literal_index = {ord(c): idx for idx, c in enumerate(LITERAL_STRING)}

def find_repeatable_block(dat, pos, length):
    max_block_len = 17
    max_hist_len = (255 - 60) * 16 # 3120
    
    max_len = min(max_block_len, length - pos)
    max_hist_len = min(max_hist_len, pos)
    
    best_len = 0
    best_i = -100000
    
    for i in range(pos - max_hist_len, pos):
        j = i
        while (j - i) < max_len and j < pos and dat[j] == dat[pos + j - i]:
            j += 1
        
        curr_len = j - i
        if curr_len > best_len:
            best_len = curr_len
            best_i = i
            
    block_offset = pos - best_i
    return best_len, block_offset

def compress_legacy(in_bytes):
    modified_code = bytearray(in_bytes)
    if b"_update60" in modified_code:
        if len(modified_code) > 0 and modified_code[-1] not in (ord(' '), ord('\n'), ord('\r')):
            modified_code.append(ord('\n'))
        modified_code.extend(b"if(_update60)_update=function()_update60()_update_buttons()_update60()end")
        
    out = bytearray()
    # 1. Header tag ":c:"
    out.extend(b":c:\x00")
    # 2. Write uncompressed size (2 bytes, big-endian)
    uncomp_len = len(modified_code)
    out.append((uncomp_len >> 8) & 0xFF)
    out.append(uncomp_len & 0xFF)
    # 3. Compressed size (2 bytes, set to 0)
    out.extend(b"\x00\x00")
    
    pos = 0
    while pos < len(modified_code):
        block_len, block_offset = find_repeatable_block(modified_code, pos, len(modified_code))
        
        if block_len >= 3:
            out.append((block_offset // 16) + LITERALS)
            out.append((block_offset % 16) + (block_len - 2) * 16)
            pos += block_len
        else:
            char_val = modified_code[pos]
            idx = literal_index.get(char_val, 0)
            out.append(idx)
            if idx == 0:
                out.append(char_val)
            pos += 1
            
    return bytes(out)

def main():
    # 1. Read game.p8
    with open('game.p8', 'r', encoding='utf-8') as f:
        p8_content = f.read()

    # Extract __lua__ section
    lua_match = re.search(r"__lua__\n([\s\S]*?)\n__(?:gfx|map|gff|sfx|music|label)__", p8_content)
    if not lua_match:
        print("Could not find __lua__ section in game.p8")
        return
        
    lua_code = lua_match.group(1)
    
    # Normalize line endings to Unix style (\n) to prevent PICO-8 syntax errors
    lua_code = lua_code.replace('\r\n', '\n').replace('\r', '\n')
    
    # Map emojis back to PICO-8 special characters
    lua_code = (lua_code
                .replace('⬆️', '\x94')
                .replace('⬇️', '\x83')
                .replace('⬅️', '\x8b')
                .replace('➡️', '\x91')
                .replace('🅾️', '\x8e')
                .replace('❎', '\x97'))
                
    # Convert code to bytes
    # PICO-8 code is encoded as single bytes. encode using backslashreplace or raw ascii
    lua_bytes = lua_code.encode('latin1', errors='replace')
    
    # Compress Lua bytes
    compressed = compress_legacy(lua_bytes)
    print(f"Original Lua code length: {len(lua_bytes)}")
    print(f"Compressed length: {len(compressed)}")
    
    # 2. Read index.js
    with open('index.js', 'r', encoding='utf-8') as f:
        js_content = f.read()
        
    # Find _cartdat array definition
    cartdat_match = re.search(r"var\s+_cartdat\s*=\s*(\[[\s\S]*?\]);", js_content)
    if not cartdat_match:
        print("Could not find _cartdat in index.js")
        return
        
    cartdat_list = json.loads(cartdat_match.group(1))
    print(f"Original _cartdat length: {len(cartdat_list)}")
    
    # Create a new cartdat array of the original size (usually 32768)
    new_cartdat = list(cartdat_list)
    if len(new_cartdat) < 32768:
        new_cartdat += [0] * (32768 - len(new_cartdat))
    
    # Overwrite code section starting at 0x4300 with compressed code
    for i, b in enumerate(compressed):
        new_cartdat[0x4300 + i] = b
        
    # Zero out the rest of the code section, leaving the very last byte (version byte) intact
    for i in range(0x4300 + len(compressed), len(new_cartdat) - 1):
        new_cartdat[i] = 0
        
    # Set the version byte at the end of the cartridge to 8 (PICO-8 format version)
    new_cartdat[32767] = 8
        
    print(f"New _cartdat length: {len(new_cartdat)}")
    
    # Format new _cartdat string
    # To keep size reasonable, let's write 32 integers per line
    formatted_list_items = [str(x) for x in new_cartdat]
    lines = []
    for i in range(0, len(formatted_list_items), 32):
        lines.append(",".join(formatted_list_items[i:i+32]))
    new_array_str = "[\n" + ",\n".join(lines) + "\n]"
    
    # Replace in js_content
    js_content_new = js_content.replace(cartdat_match.group(1), new_array_str)
    
    # Write back to index.js
    with open('index.js', 'w', encoding='utf-8') as f:
        f.write(js_content_new)
        
    print("Successfully injected new cart data into index.js!")

if __name__ == '__main__':
    main()
