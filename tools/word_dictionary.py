import os
import urllib.request
from typing import List, Set, Dict, Optional

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

ENABLE1_URL = "https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt"
FREQ20K_URL = "https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt"

ENABLE1_PATH = os.path.join(DATA_DIR, "enable1.txt")
FREQ20K_PATH = os.path.join(DATA_DIR, "freq20k.txt")
COMMON_CLEAN_PATH = os.path.join(DATA_DIR, "common_clean_en.txt")
ALL_CLEAN_PATH = os.path.join(DATA_DIR, "all_clean_en.txt")

# Blocklist for casual mobile games
CASUAL_BLOCKLIST = {
    "SEX", "SEXY", "PORN", "NUDE", "NUDES", "NAKED", "ANUS", "PENIS", "VAGINA",
    "CRAP", "SHIT", "FUCK", "DAMN", "HELL", "BITCH", "SLUT", "WHORE", "COCK",
    "DICK", "TITS", "BOOBS", "ANAL", "ASSHOLE", "BASTARD", "DRUG", "DRUGS",
    "WEED", "HEROIN", "COCAINE", "KILL", "MURDER", "SUICIDE", "DIE", "DIED",
}


def ensure_dictionaries(force_rebuild: bool = False):
    """Ensure dictionary files are downloaded and curated."""
    os.makedirs(DATA_DIR, exist_ok=True)

    if (
        not force_rebuild
        and os.path.exists(COMMON_CLEAN_PATH)
        and os.path.exists(ALL_CLEAN_PATH)
        and os.path.getsize(COMMON_CLEAN_PATH) > 1000
        and os.path.getsize(ALL_CLEAN_PATH) > 1000
    ):
        return

    if not os.path.exists(ENABLE1_PATH):
        print("Downloading Enable1 official word game dictionary...")
        urllib.request.urlretrieve(ENABLE1_URL, ENABLE1_PATH)

    if not os.path.exists(FREQ20K_PATH):
        print("Downloading 20K English frequency wordlist...")
        urllib.request.urlretrieve(FREQ20K_URL, FREQ20K_PATH)

    with open(ENABLE1_PATH, "r", encoding="utf-8", errors="ignore") as f:
        enable1_set = {
            w.strip().upper()
            for w in f
            if w.strip() and 3 <= len(w.strip()) <= 8 and w.strip().isalpha() and any(v in w.strip().upper() for v in "AEIOUY")
        }

    with open(FREQ20K_PATH, "r", encoding="utf-8", errors="ignore") as f:
        freq_raw = [w.strip().upper() for w in f if w.strip()]

    clean_common = []
    seen_common = set()
    for w in freq_raw:
        if (
            w in enable1_set
            and w not in seen_common
            and w not in CASUAL_BLOCKLIST
            and not any(bad in w for bad in ["FUCK", "SHIT", "PORN", "SLUT", "WHORE"])
        ):
            seen_common.add(w)
            clean_common.append(w)

    temp_common = COMMON_CLEAN_PATH + ".tmp"
    with open(temp_common, "w", encoding="utf-8") as f:
        for w in clean_common:
            f.write(w + "\n")
    os.replace(temp_common, COMMON_CLEAN_PATH)

    temp_all = ALL_CLEAN_PATH + ".tmp"
    with open(temp_all, "w", encoding="utf-8") as f:
        for w in sorted(enable1_set - CASUAL_BLOCKLIST):
            f.write(w + "\n")
    os.replace(temp_all, ALL_CLEAN_PATH)

    print(f"Curated clean dictionary: {len(clean_common)} common words, {len(enable1_set)} total dictionary words.")


class TrieNode:
    def __init__(self):
        self.children: Dict[str, TrieNode] = {}
        self.is_word: bool = False


class WordTrie:
    def __init__(self):
        self.root = TrieNode()

    def insert(self, word: str):
        node = self.root
        for char in word:
            if char not in node.children:
                node.children[char] = TrieNode()
            node = node.children[char]
        node.is_word = True


class EnglishDictionary:
    def __init__(self):
        ensure_dictionaries()
        self.common_words: List[str] = self._load_words(COMMON_CLEAN_PATH)
        self.all_words_set: Set[str] = set(self._load_words(ALL_CLEAN_PATH))

        self.words_by_len: Dict[int, List[str]] = {}
        for w in self.common_words:
            self.words_by_len.setdefault(len(w), []).append(w)

        # Build Trie on all clean Enable1 words
        self.trie = WordTrie()
        for w in self.all_words_set:
            self.trie.insert(w)

    def _load_words(self, path: str) -> List[str]:
        with open(path, "r", encoding="utf-8") as f:
            return [line.strip().upper() for line in f if line.strip()]

    def get_words_of_length(self, length: int) -> List[str]:
        return self.words_by_len.get(length, [])


if __name__ == "__main__":
    ensure_dictionaries(force_rebuild=True)
    d = EnglishDictionary()
    print("Clean dictionary verified. Common words:", len(d.common_words), "Total Enable1 words:", len(d.all_words_set))
