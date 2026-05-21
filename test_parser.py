import re
import json

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
    with open('game.p8', 'r', encoding='utf-8') as f:
        p8_content = f.read()

def extract_section(p8_content, section_name):
    # Match section header and get content until the next header or end of file
    match = re.search(r"^__" + re.escape(section_name) + r"__\r?\n([\s\S]*?)(?=(?:^__\w+__\r?\n)|\Z)", p8_content, re.MULTILINE)
    if match:
        return match.group(1).strip()
    return None

def main():
    with open('game.p8', 'r', encoding='utf-8') as f:
        p8_content = f.read()

    # Extract sections using robust function
    gfx_content = extract_section(p8_content, 'gfx')
    map_content = extract_section(p8_content, 'map')
    gff_content = extract_section(p8_content, 'gff')
    music_content = extract_section(p8_content, 'music')
    sfx_content = extract_section(p8_content, 'sfx')

    rom = bytearray(32768)

    # 1. Parse gfx
    if gfx_content:
        gfx_lines = gfx_content.split('\n')
        print(f"GFX lines found: {len(gfx_lines)}")
        for idx, line in enumerate(gfx_lines[:128]):
            row_bytes = parse_gfx_line(line)
            addr = idx * 64
            rom[addr : addr + 64] = row_bytes

    # 2. Parse map
    if map_content:
        map_lines = map_content.split('\n')
        print(f"Map lines found: {len(map_lines)}")
        for idx, line in enumerate(map_lines):
            row_bytes = parse_map_line(line)
            if idx < 32:
                addr = 0x2000 + idx * 128
                rom[addr : addr + 128] = row_bytes
            elif idx < 64:
                addr = 0x1000 + (idx - 32) * 128
                rom[addr : addr + 128] = row_bytes

    # 3. Parse gff
    if gff_content:
        gff_lines = gff_content.split('\n')
        print(f"GFF lines found: {len(gff_lines)}")
        gff_bytes = parse_gff_section(gff_lines)
        rom[0x3000 : 0x3100] = gff_bytes

    # 4. Parse music
    if music_content:
        music_lines = music_content.split('\n')
        print(f"Music lines found: {len(music_lines)}")
        for idx, line in enumerate(music_lines[:64]):
            pat_bytes = parse_music_line(line)
            addr = 0x3100 + idx * 4
            rom[addr : addr + 4] = pat_bytes

    # 5. Parse sfx
    if sfx_content:
        sfx_lines = sfx_content.split('\n')
        print(f"SFX lines found: {len(sfx_lines)}")
        for idx, line in enumerate(sfx_lines[:64]):
            sfx_bytes = parse_sfx_line(line)
            addr = 0x3200 + idx * 68
            rom[addr : addr + 68] = sfx_bytes

    # 6. Load index.js to compare
    with open('index.js', 'r', encoding='utf-8') as f:
        js_content = f.read()
    cartdat_match = re.search(r"var\s+_cartdat\s*=\s*(\[[\s\S]*?\]);", js_content)
    if not cartdat_match:
        print("Could not find _cartdat in index.js")
        return
    cartdat = json.loads(cartdat_match.group(1))

    diffs = []
    regions = {
        "GFX 1 (0x0000-0x0FFF)": (0, 0x1000),
        "GFX 2 / Map 2 (0x1000-0x1FFF)": (0x1000, 0x2000),
        "Map 1 (0x2000-0x2FFF)": (0x2000, 0x3000),
        "GFF (0x3000-0x30FF)": (0x3000, 0x3100),
        "Music (0x3100-0x31FF)": (0x3100, 0x3200),
        "SFX (0x3200-0x42FF)": (0x3200, 0x4300)
    }
    
    region_diffs = {name: [] for name in regions}
    for i in range(0x4300):
        if rom[i] != cartdat[i]:
            diffs.append((i, cartdat[i], rom[i]))
            for name, (start, end) in regions.items():
                if start <= i < end:
                    region_diffs[name].append((i, cartdat[i], rom[i]))
                    break

    print(f"Total differences in the first 0x4300 bytes: {len(diffs)}")
    for name, r_diffs in region_diffs.items():
        print(f"  {name}: {len(r_diffs)} differences")
        if len(r_diffs) > 0:
            print("    First 5:")
            for addr, c_val, p_val in r_diffs[:5]:
                print(f"      Address {hex(addr)} ({addr}): cartdat={c_val}, parsed={p_val}")

if __name__ == '__main__':
    main()
