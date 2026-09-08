import glob
import json
import os
import sys
from typing import Dict, List, Set, Tuple

DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]


class TrieNode:
    def __init__(self):
        self.children: Dict[str, TrieNode] = {}
        self.is_word: bool = False


class WordTrie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str):
        node = self.root
        for ch in word.upper():
            if ch not in node.children:
                node.children[ch] = TrieNode()
            node = node.children[ch]
        node.is_word = True


def load_dictionary(lang: str, data_dir: str) -> WordTrie:
    trie = WordTrie()
    word_count = 0

    if lang == "english":
        paths = [
            os.path.join(data_dir, "all_clean_en.txt"),
            os.path.join(data_dir, "common_clean_en.txt"),
        ]
        enable_path = os.path.join(data_dir, "enable1.txt")
        if os.path.exists(enable_path):
            paths.append(enable_path)
    else:
        paths = [
            os.path.join(data_dir, f"clean_{lang}.txt"),
            os.path.join(data_dir, f"raw_{lang}.txt"),
        ]

    words_set = set()
    for p in paths:
        if os.path.exists(p):
            with open(p, "r", encoding="utf-8") as f:
                for line in f:
                    w = line.strip().upper()
                    # Filter: length >= 3, valid letters
                    if len(w) >= 3 and w.isalpha():
                        words_set.add(w)

    for w in words_set:
        trie.insert(w)
        word_count += 1

    print(f"Loaded {word_count} words for {lang}")
    return trie


def find_words_on_grid(grid: List[List[str]], trie: WordTrie, max_len: int = 10) -> Set[str]:
    height = len(grid)
    width = len(grid[0]) if height > 0 else 0
    found: Set[str] = set()

    def dfs(r: int, c: int, node: TrieNode, path: Set[Tuple[int, int]], curr_str: str):
        if node.is_word and len(curr_str) >= 3:
            found.add(curr_str)

        if len(curr_str) >= max_len:
            return

        for dr, dc in DIRECTIONS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < height and 0 <= nc < width and (nr, nc) not in path:
                ch = grid[nr][nc]
                if ch in node.children:
                    dfs(nr, nc, node.children[ch], path | {(nr, nc)}, curr_str + ch)

    for r in range(height):
        for c in range(width):
            ch = grid[r][c]
            if ch in trie.root.children:
                dfs(r, c, trie.root.children[ch], {(r, c)}, ch)

    return found


def process_language(lang: str, project_root: str):
    data_dir = os.path.join(project_root, "tools", "data")
    levels_dir = os.path.join(project_root, "assets", "levels", lang)

    if not os.path.exists(levels_dir):
        print(f"Levels directory not found: {levels_dir}")
        return

    trie = load_dictionary(lang, data_dir)
    file_paths = glob.glob(os.path.join(levels_dir, "level*.json"))
    file_paths.sort(key=lambda p: int("".join(filter(str.isdigit, os.path.basename(p))) or 0))

    print(f"Processing {len(file_paths)} levels in {lang}...")
    total_added = 0
    levels_updated = 0

    for fpath in file_paths:
        with open(fpath, "r", encoding="utf-8") as f:
            data = json.load(f)

        lvl_id = data.get("id", 0)

        # Explicit fixes for specific problematic levels in English
        if lang == "english":
            if lvl_id == 13:
                data["target_words"] = [
                    {"word": "STAR", "type": 0},
                    {"word": "ART", "type": 0},
                    {"word": "RAT", "type": 0},
                    {"word": "TAR", "type": 0},
                ]
            elif lvl_id == 14:
                data["target_words"] = [
                    {"word": "POST", "type": 0},
                    {"word": "SPOT", "type": 0},
                    {"word": "STOP", "type": 0},
                    {"word": "TOP", "type": 0},
                ]

        letters_raw = data.get("letters", "")
        grid = [list(row) for row in letters_raw.split(",") if row]
        if not grid:
            continue

        target_set = {tw["word"].upper() for tw in data.get("target_words", [])}
        existing_extras = {ew["word"].upper() for ew in data.get("extra_words", [])}

        found_words = find_words_on_grid(grid, trie)

        # Combine all found words that are not targets + existing valid extras
        combined_extras = (found_words - target_set) | (existing_extras - target_set)

        # Sort: by length ascending, then alphabetical
        sorted_extras = sorted(list(combined_extras), key=lambda w: (len(w), w))

        if len(sorted_extras) != len(existing_extras) or sorted_extras != sorted(list(existing_extras)) or (lang == "english" and lvl_id in (13, 14)):
            total_added += len(sorted_extras) - len(existing_extras)
            levels_updated += 1
            data["extra_words"] = [{"word": w, "type": 0} for w in sorted_extras]

            with open(fpath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)

    print(f"Finished {lang}: updated {levels_updated} levels (net extra words change: {total_added}).")


def main():
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    languages = [
        "english",
        "vietnamese",
        "french",
        "german",
        "italian",
        "portuguese",
        "russian",
        "spanish",
        "turkish",
    ]

    target_lang = sys.argv[1] if len(sys.argv) > 1 else None
    if target_lang:
        languages = [target_lang]

    for lang in languages:
        process_language(lang, project_root)


if __name__ == "__main__":
    main()
