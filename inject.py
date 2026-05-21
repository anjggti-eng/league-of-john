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

def extract_section(p8_content, section_name):
    match = re.search(r"^__" + re.escape(section_name) + r"__\r?\n([\s\S]*?)(?=(?:^__\w+__\r?\n)|\Z)", p8_content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None

def parse_gfx_line(line):
    line = line.strip().ljust(128, '0')
    row_bytes = bytearray()
    for i in range(0, 128, 2):
        low = int(line[i], 16)
        high = int(line[i+1], 16)
        row_bytes.append((high << 4) | low)
    return row_bytes

def parse_map_line(line):
    line = line.strip().ljust(256, '0')
    row_bytes = bytearray()
    for i in range(0, 256, 2):
        val = int(line[i:i+2], 16)
        row_bytes.append(val)
    return row_bytes

def parse_gff_section(lines):
    full_str = "".join(lines).strip().replace("\n", "").replace("\r", "")
    full_str = full_str.ljust(512, '0')
    gff_bytes = bytearray()
    for i in range(0, 512, 2):
        val = int(full_str[i:i+2], 16)
        gff_bytes.append(val)
    return gff_bytes

def parse_sfx_line(line):
    line = line.strip().ljust(168, '0')
    nibbles = [int(c, 16) for c in line]
    
    byte_0 = (nibbles[0] << 4) | nibbles[1]
    byte_1 = (nibbles[2] << 4) | nibbles[3]
    byte_2 = (nibbles[4] << 4) | nibbles[5]
    byte_3 = (nibbles[6] << 4) | nibbles[7]
    
    sfx_bytes = bytearray(68)
    for i in range(32):
        offset = 8 + i * 5
        n0 = nibbles[offset]
        n1 = nibbles[offset + 1]
        n2 = nibbles[offset + 2]
        n3 = nibbles[offset + 3]
        n4 = nibbles[offset + 4]
        
        pitch = (n0 << 4) | n1
        waveform = n2
        volume = n3
        effect = n4
        
        note_val = pitch & 0x3F
        note_val |= (waveform & 0x07) << 6
        note_val |= (volume & 0x07) << 9
        note_val |= (effect & 0x07) << 12
        if waveform >= 8:
            note_val |= 0x8000
        
        sfx_bytes[i * 2] = note_val & 0xFF
        sfx_bytes[i * 2 + 1] = (note_val >> 8) & 0xFF
        
    sfx_bytes[64] = byte_0
    sfx_bytes[65] = byte_1
    sfx_bytes[66] = byte_2
    sfx_bytes[67] = byte_3
    return sfx_bytes

def parse_music_line(line):
    parts = line.strip().split()
    if len(parts) < 5:
        parts += ['00'] * (5 - len(parts))
        
    flags = int(parts[0], 16)
    sfx0 = int(parts[1], 16)
    sfx1 = int(parts[2], 16)
    sfx2 = int(parts[3], 16)
    sfx3 = int(parts[4], 16)
    
    ch0 = sfx0 & 0x7F
    if flags & 0x01:
        ch0 |= 0x80
    ch1 = sfx1 & 0x7F
    if flags & 0x02:
        ch1 |= 0x80
    ch2 = sfx2 & 0x7F
    if flags & 0x04:
        ch2 |= 0x80
    ch3 = sfx3 & 0x7F
    return [ch0, ch1, ch2, ch3]

def main():
    # 1. Read game.p8
    with open('game.p8', 'r', encoding='utf-8') as f:
        p8_content = f.read()

    # Extract __lua__ section
    lua_code = extract_section(p8_content, 'lua')
    if not lua_code:
        print("Could not find __lua__ section in game.p8")
        return
        
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

    # Extract ROM sections from game.p8
    gfx_content = extract_section(p8_content, 'gfx')
    map_content = extract_section(p8_content, 'map')
    gff_content = extract_section(p8_content, 'gff')
    music_content = extract_section(p8_content, 'music')
    sfx_content = extract_section(p8_content, 'sfx')

    # 3. Parse and Inject gfx
    if gfx_content:
        gfx_lines = gfx_content.split('\n')
        print(f"Injecting GFX ({len(gfx_lines)} rows)...")
        for idx, line in enumerate(gfx_lines[:128]):
            row_bytes = parse_gfx_line(line)
            addr = idx * 64
            new_cartdat[addr : addr + 64] = row_bytes

    # 4. Parse and Inject map
    if map_content:
        map_lines = map_content.split('\n')
        print(f"Injecting MAP ({len(map_lines)} rows)...")
        for idx, line in enumerate(map_lines):
            row_bytes = parse_map_line(line)
            if idx < 32:
                addr = 0x2000 + idx * 128
                new_cartdat[addr : addr + 128] = row_bytes
            elif idx < 64:
                addr = 0x1000 + (idx - 32) * 128
                new_cartdat[addr : addr + 128] = row_bytes

    # 5. Parse and Inject gff
    if gff_content:
        gff_lines = gff_content.split('\n')
        print(f"Injecting Sprite Flags...")
        gff_bytes = parse_gff_section(gff_lines)
        new_cartdat[0x3000 : 0x3100] = gff_bytes

    # 6. Parse and Inject music
    if music_content:
        music_lines = music_content.split('\n')
        print(f"Injecting Music ({len(music_lines)} patterns)...")
        for idx, line in enumerate(music_lines[:64]):
            pat_bytes = parse_music_line(line)
            addr = 0x3100 + idx * 4
            new_cartdat[addr : addr + 4] = pat_bytes
    else:
        print("Music section not found in game.p8, preserving original music bytes.")

    # 7. Parse and Inject sfx
    if sfx_content:
        sfx_lines = sfx_content.split('\n')
        print(f"Injecting SFX ({len(sfx_lines)} slots)...")
        for idx, line in enumerate(sfx_lines[:64]):
            sfx_bytes = parse_sfx_line(line)
            addr = 0x3200 + idx * 68
            new_cartdat[addr : addr + 68] = sfx_bytes
    else:
        print("SFX section not found in game.p8, preserving original SFX bytes.")

    # 8. Overwrite code section starting at 0x4300 with compressed code
    for i, b in enumerate(compressed):
        new_cartdat[0x4300 + i] = b
        
    # Zero out the rest of the code section, leaving the very last byte (version byte) intact
    for i in range(0x4300 + len(compressed), len(new_cartdat) - 1):
        new_cartdat[i] = 0
        
    # Set the version byte at the end of the cartridge to 8 (PICO-8 format version)
    new_cartdat[32767] = 8
        
    print(f"New _cartdat length: {len(new_cartdat)}")
    
    # Format new _cartdat string
    # To keep size reasonable, write 32 integers per line
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
