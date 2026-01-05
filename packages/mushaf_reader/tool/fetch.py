#!/usr/bin/env python3
"""
Script to fetch correct glyph line numbers from QuranCDN API
and compare with current glyph values in quran.json.

Run with: python3 tool/fetch.py
"""

import json
import time
import urllib.request

API_BASE = "https://api.qurancdn.com/api/qdc/verses/by_page"
QURAN_JSON_PATH = "assets/jsons/quran.json"

def fetch_page(page_num: int) -> dict:
    url = f"{API_BASE}/{page_num}?words=true&per_page=50&word_fields=code_v1,v1_page"
    with urllib.request.urlopen(url, timeout=30) as response:
        return json.loads(response.read().decode('utf-8'))

def build_glyph_for_verse(words: list, prev_line: int = None) -> tuple:
    if not words:
        return "", prev_line
    
    parts = []
    current_line = None
    
    for word in words:
        line_num = word.get('line_number')
        code_v1 = word.get('code_v1', '')
        
        if not code_v1:
            continue
        
        if current_line is not None and line_num != current_line:
            parts.append('\n')
        elif current_line is None and prev_line is not None and line_num != prev_line:
            parts.append('\n')
        
        parts.append(code_v1)
        current_line = line_num
    
    return ''.join(parts), current_line

def visualize_newlines(text: str) -> str:
    """Replace newlines with visible marker for comparison."""
    return text.replace('\n', '⏎\n')

def compare_glyphs(current: str, fetched: str) -> dict:
    """Compare two glyph strings and return difference details."""
    current_lines = current.split('\n')
    fetched_lines = fetched.split('\n')
    
    # Count newlines
    current_newlines = current.count('\n')
    fetched_newlines = fetched.count('\n')
    
    # Check if glyphs (without newlines) match
    current_chars = current.replace('\n', '')
    fetched_chars = fetched.replace('\n', '')
    chars_match = current_chars == fetched_chars
    
    return {
        'match': current == fetched,
        'chars_match': chars_match,
        'current_newlines': current_newlines,
        'fetched_newlines': fetched_newlines,
        'current_line_count': len(current_lines),
        'fetched_line_count': len(fetched_lines),
        'current_char_count': len(current_chars),
        'fetched_char_count': len(fetched_chars),
    }

def main():
    with open(QURAN_JSON_PATH, 'r', encoding='utf-8') as f:
        quran = json.load(f)
    
    ayah_lookup = {}
    for surah in quran['data']['surahs']:
        for ayah in surah['ayahs']:
            ayah_lookup[(surah['number'], ayah['numberInSurah'])] = ayah
    
    # Stats
    total_ayahs = 0
    matching_ayahs = 0
    mismatched_ayahs = []
    chars_only_mismatch = []  # Newlines differ but chars match
    
    for page_num in range(1, 605):
        print(f"\rProcessing page {page_num}/604...", end='', flush=True)
        
        try:
            data = fetch_page(page_num)
        except Exception as e:
            print(f"\nError fetching page {page_num}: {e}")
            continue
            
        prev_line = None
        
        for verse in data.get('verses', []):
            verse_key = verse.get('verse_key', '')
            if ':' not in verse_key:
                continue
            
            sura_num, ayah_num = map(int, verse_key.split(':'))
            fetched_glyph, prev_line = build_glyph_for_verse(verse.get('words', []), prev_line)
            
            if (sura_num, ayah_num) in ayah_lookup:
                total_ayahs += 1
                ayah = ayah_lookup[(sura_num, ayah_num)]
                current_glyph = ayah.get('glyph', ayah.get('code_v4', ''))
                
                comparison = compare_glyphs(current_glyph, fetched_glyph)
                
                if comparison['match']:
                    matching_ayahs += 1
                else:
                    mismatch_info = {
                        'verse': verse_key,
                        'page': page_num,
                        'comparison': comparison,
                        'current': current_glyph,
                        'fetched': fetched_glyph,
                    }
                    
                    if comparison['chars_match']:
                        chars_only_mismatch.append(mismatch_info)
                    else:
                        mismatched_ayahs.append(mismatch_info)
        
        if page_num % 50 == 0:
            time.sleep(0.3)
    
    # Print summary
    print("\n\n" + "="*80)
    print("COMPARISON SUMMARY")
    print("="*80)
    print(f"Total ayahs compared: {total_ayahs}")
    print(f"Matching exactly: {matching_ayahs}")
    print(f"Newline differences only: {len(chars_only_mismatch)}")
    print(f"Character differences: {len(mismatched_ayahs)}")
    
    # Print newline-only mismatches (likely the line break issues)
    if chars_only_mismatch:
        print("\n" + "-"*80)
        print("NEWLINE DIFFERENCES (characters match, line breaks differ):")
        print("-"*80)
        
        # Group by page for easier analysis
        pages_affected = set(m['page'] for m in chars_only_mismatch)
        print(f"Pages affected: {sorted(pages_affected)[:20]}{'...' if len(pages_affected) > 20 else ''}")
        print(f"Total pages affected: {len(pages_affected)}")
        
        # Show first 10 examples
        print("\nFirst 10 examples:")
        for i, m in enumerate(chars_only_mismatch[:10]):
            c = m['comparison']
            print(f"\n  {i+1}. {m['verse']} (page {m['page']}):")
            print(f"     Current:  {c['current_newlines']} newlines, {c['current_line_count']} lines")
            print(f"     Fetched:  {c['fetched_newlines']} newlines, {c['fetched_line_count']} lines")
            print(f"     Current glyph: {visualize_newlines(m['current'][:100])}{'...' if len(m['current']) > 100 else ''}")
            print(f"     Fetched glyph: {visualize_newlines(m['fetched'][:100])}{'...' if len(m['fetched']) > 100 else ''}")
    
    # Print character mismatches (more serious issues)
    if mismatched_ayahs:
        print("\n" + "-"*80)
        print("CHARACTER DIFFERENCES (actual glyph content differs):")
        print("-"*80)
        print(f"Total: {len(mismatched_ayahs)}")
        
        # Show first 5 examples
        print("\nFirst 5 examples:")
        for i, m in enumerate(mismatched_ayahs[:5]):
            c = m['comparison']
            print(f"\n  {i+1}. {m['verse']} (page {m['page']}):")
            print(f"     Current chars: {c['current_char_count']}, Fetched chars: {c['fetched_char_count']}")
            print(f"     Current (no newlines): {m['current'].replace(chr(10), '')[:50]}...")
            print(f"     Fetched (no newlines): {m['fetched'].replace(chr(10), '')[:50]}...")
    
    print("\n" + "="*80)
    
    # Ask user if they want to update
    if chars_only_mismatch or mismatched_ayahs:
        response = input("\nWould you like to update quran.json with fetched glyphs? (y/n): ")
        if response.lower() == 'y':
            print("\nUpdating quran.json...")
            
            # Re-fetch and update (or use cached data)
            for page_num in range(1, 605):
                print(f"\rUpdating page {page_num}/604...", end='', flush=True)
                
                try:
                    data = fetch_page(page_num)
                except Exception as e:
                    continue
                    
                prev_line = None
                
                for verse in data.get('verses', []):
                    verse_key = verse.get('verse_key', '')
                    if ':' not in verse_key:
                        continue
                    
                    sura_num, ayah_num = map(int, verse_key.split(':'))
                    fetched_glyph, prev_line = build_glyph_for_verse(verse.get('words', []), prev_line)
                    
                    if (sura_num, ayah_num) in ayah_lookup:
                        ayah_lookup[(sura_num, ayah_num)]['glyph'] = fetched_glyph
                
                if page_num % 50 == 0:
                    time.sleep(0.3)
            
            with open(QURAN_JSON_PATH, 'w', encoding='utf-8') as f:
                json.dump(quran, f, ensure_ascii=False, indent=2)
            
            print("\nComplete! quran.json has been updated.")
        else:
            print("No changes made.")
    else:
        print("\nAll glyphs match! No updates needed.")

if __name__ == '__main__':
    main()
