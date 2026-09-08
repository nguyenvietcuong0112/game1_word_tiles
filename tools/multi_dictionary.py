import os
import urllib.request
from typing import List, Set, Dict, Optional

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

URLS = {
    "english_enable1": "https://raw.githubusercontent.com/dolph/dictionary/master/enable1.txt",
    "english_freq": "https://raw.githubusercontent.com/first20hours/google-10000-english/master/20k.txt",
    "spanish": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/es/es_50k.txt",
    "portuguese": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/pt_br/pt_br_50k.txt",
    "russian": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/ru/ru_50k.txt",
    "turkish": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/tr/tr_50k.txt",
    "german": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/de/de_50k.txt",
    "french": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/fr/fr_50k.txt",
    "italian": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/it/it_50k.txt",
    "vietnamese": "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/vi/vi_50k.txt",
}

VOWELS_BY_LANG = {
    "english": "AEIOUY",
    "spanish": "AEIOUYÁÉÍÓÚÜ",
    "portuguese": "AEIOUYÁÉÍÓÚÂÊÔÃÕ",
    "russian": "АЕИОУЫЭЮЯ",
    "turkish": "AEIİOÖUÜ",
    "german": "AEIOUYÄÖÜ",
    "french": "AEIOUYÀÂÄÉÈÊËÎÏÔÙÛÜŸÇ",
    "italian": "AEIOUYÀÈÉÌÍÒÓÙÚ",
    "vietnamese": "AĂÂEÊIOÔƠUƯYÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴ",
}

COMMON_FILLERS_BY_LANG = {
    "english": ("AEIOU", "RSTLANDMPCB"),
    "spanish": ("AEIOU", "RSLNDTMCPBG"),
    "portuguese": ("AEIOU", "RSLNDTMCPBG"),
    "russian": ("АЕИОУ", "БВГДЖЗКЛМНПРСТ"),
    "turkish": ("AEIİO", "RSLNDTMCPBK"),
    "german": ("AEIOU", "RSTNLDMGKBCF"),
    "french": ("AEIOU", "RSTNLMDPCGFV"),
    "italian": ("AEIOU", "RSTNLMDPCGFV"),
    "vietnamese": ("AĂÂEÊIOÔƠUƯ", "BCHKLMNPQRSTVĐX"),
}

CASUAL_BLOCKLIST = {
    "SEX", "SEXY", "PORN", "NUDE", "NUDES", "NAKED", "ANUS", "PENIS", "VAGINA",
    "CRAP", "SHIT", "FUCK", "DAMN", "HELL", "BITCH", "SLUT", "WHORE", "COCK",
    "DICK", "TITS", "BOOBS", "ANAL", "ASSHOLE", "BASTARD", "DRUG", "DRUGS",
    "WEED", "HEROIN", "COCAINE", "KILL", "MURDER", "SUICIDE", "DIE", "DIED",
}


def turkish_upper(s: str) -> str:
    m = {"i": "İ", "ı": "I", "ç": "Ç", "ğ": "Ğ", "ö": "Ö", "ş": "Ş", "ü": "Ü"}
    return "".join(m.get(c, c.upper()) for c in s)


def normalize_word(word: str, language: str) -> str:
    word = word.strip()
    if language == "turkish":
        return turkish_upper(word)
    elif language == "russian":
        return word.upper().replace("Ё", "Е")
    elif language == "german":
        return word.upper().replace("ß", "SS").replace("ẞ", "SS")
    else:
        return word.upper()


def ensure_language_dictionary(language: str):
    os.makedirs(DATA_DIR, exist_ok=True)
    clean_path = os.path.join(DATA_DIR, f"clean_{language}.txt")

    if os.path.exists(clean_path) and os.path.getsize(clean_path) > 1000:
        return

    print(f"Preparing dictionary for {language}...")
    vowels = VOWELS_BY_LANG.get(language, "AEIOU")

    if language == "english":
        enable1_path = os.path.join(DATA_DIR, "enable1.txt")
        freq_path = os.path.join(DATA_DIR, "freq20k.txt")
        if not os.path.exists(enable1_path):
            urllib.request.urlretrieve(URLS["english_enable1"], enable1_path)
        if not os.path.exists(freq_path):
            urllib.request.urlretrieve(URLS["english_freq"], freq_path)

        with open(enable1_path, "r", encoding="utf-8", errors="ignore") as f:
            enable1_set = {
                w.strip().upper()
                for w in f
                if w.strip() and 3 <= len(w.strip()) <= 8 and w.strip().isalpha() and any(v in w.strip().upper() for v in vowels)
            }

        with open(freq_path, "r", encoding="utf-8", errors="ignore") as f:
            freq_raw = [w.strip().upper() for w in f if w.strip()]

        clean_words = []
        seen = set()
        for w in freq_raw:
            if w in enable1_set and w not in seen and w not in CASUAL_BLOCKLIST:
                seen.add(w)
                clean_words.append(w)
        for w in sorted(enable1_set):
            if w not in seen and w not in CASUAL_BLOCKLIST:
                seen.add(w)
                clean_words.append(w)

    else:
        raw_path = os.path.join(DATA_DIR, f"raw_{language}.txt")
        if not os.path.exists(raw_path):
            urllib.request.urlretrieve(URLS[language], raw_path)

        with open(raw_path, "r", encoding="utf-8", errors="ignore") as f:
            raw_lines = [line.strip().split()[0] for line in f if line.strip()]

        clean_words = []
        seen = set()
        for w_raw in raw_lines:
            w = normalize_word(w_raw, language)
            if 3 <= len(w) <= 8 and w.isalpha() and any(v in w for v in vowels) and w not in CASUAL_BLOCKLIST:
                if w not in seen:
                    seen.add(w)
                    clean_words.append(w)

    temp_path = clean_path + ".tmp"
    with open(temp_path, "w", encoding="utf-8") as f:
        for w in clean_words:
            f.write(w + "\n")
    os.replace(temp_path, clean_path)

    print(f"Curated {language} dictionary: {len(clean_words)} valid words.")


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


class MultiLanguageDictionary:
    def __init__(self, language: str):
        self.language = language
        ensure_language_dictionary(language)
        self.clean_path = os.path.join(DATA_DIR, f"clean_{language}.txt")
        self.words: List[str] = self._load_words()
        self.words_set: Set[str] = set(self.words)

        self.words_by_len: Dict[int, List[str]] = {}
        for w in self.words:
            self.words_by_len.setdefault(len(w), []).append(w)

        self.trie = WordTrie()
        for w in self.words:
            self.trie.insert(w)

        self.vowels, self.consonants = COMMON_FILLERS_BY_LANG.get(
            language, ("AEIOU", "RSTLNMDPC")
        )
        self.vowel_set = set(VOWELS_BY_LANG.get(language, "AEIOU"))

        print(f"Loaded {language} dictionary: {len(self.words)} words indexed.")

    def _load_words(self) -> List[str]:
        with open(self.clean_path, "r", encoding="utf-8") as f:
            return [line.strip() for line in f if line.strip()]

    def get_common_pool(self, max_count: int) -> List[str]:
        return self.words[:max_count]
