import os
import json
from collections import defaultdict

DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]

DICT_PATH = os.path.join(os.path.dirname(__file__), 'data', 'clean_english.txt')
with open(DICT_PATH, 'r', encoding='utf-8') as f:
    all_dict_words = [line.strip().upper() for line in f if line.strip()]

common_vocab_set = set(all_dict_words[:12000])

trie = {}
for w in all_dict_words:
    if 3 <= len(w) <= 8 and w in common_vocab_set:
        node = trie
        for ch in w:
            node = node.setdefault(ch, {})
        node['$'] = True

def find_all_paths(grid, word):
    H = len(grid)
    W = len(grid[0])
    paths = []
    def dfs(r, c, idx, visited, path):
        if idx == len(word):
            paths.append(list(path))
            return
        for dr, dc in DIRECTIONS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < H and 0 <= nc < W and (nr, nc) not in visited and grid[nr][nc] == word[idx]:
                visited.add((nr, nc))
                path.append((nr, nc))
                dfs(nr, nc, idx + 1, visited, path)
                path.pop()
                visited.remove((nr, nc))
    for r in range(H):
        for c in range(W):
            if grid[r][c] == word[0]:
                dfs(r, c, 1, {(r, c)}, [(r, c)])
    return paths

def solve_words(words, W, H, max_count=2):
    grid = [['' for _ in range(W)] for _ in range(H)]
    cell_usage = defaultdict(int)

    def get_paths_for_word(r, c, word, idx, visited, path):
        if idx == len(word):
            yield path
            return
        for dr, dc in DIRECTIONS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < H and 0 <= nc < W and (nr, nc) not in visited:
                if (grid[nr][nc] == '' or grid[nr][nc] == word[idx]) and cell_usage[(nr, nc)] < max_count:
                    visited.add((nr, nc))
                    yield from get_paths_for_word(nr, nc, word, idx + 1, visited, path + [(nr, nc)])
                    visited.remove((nr, nc))

    def place_word(w_idx):
        if w_idx == len(words):
            if any(grid[r][c] == '' for r in range(H) for c in range(W)):
                return False
            for w in words:
                if len(find_all_paths(grid, w)) != 1:
                    return False
            return True

        word = words[w_idx]
        for sr in range(H):
            for sc in range(W):
                if (grid[sr][sc] == '' or grid[sr][sc] == word[0]) and cell_usage[(sr, sc)] < max_count:
                    for p in get_paths_for_word(sr, sc, word, 1, {(sr, sc)}, [(sr, sc)]):
                        orig = []
                        for (r, c), ch in zip(p, word):
                            orig.append((r, c, grid[r][c]))
                            grid[r][c] = ch
                            cell_usage[(r, c)] += 1
                        if place_word(w_idx + 1):
                            return True
                        for r, c, old_ch in orig:
                            grid[r][c] = old_ch
                            cell_usage[(r, c)] -= 1
        return False

    if place_word(0):
        return grid, cell_usage
    return None

def find_extra_words(grid, target_words):
    H = len(grid)
    W = len(grid[0])
    target_set = set(target_words)
    found = set()

    def dfs(r, c, node, visited, s):
        if '$' in node and len(s) >= 3 and s not in target_set:
            found.add(s)
        for dr, dc in DIRECTIONS:
            nr, nc = r + dr, c + dc
            if 0 <= nr < H and 0 <= nc < W and (nr, nc) not in visited:
                ch = grid[nr][nc]
                if ch in node:
                    visited.add((nr, nc))
                    dfs(nr, nc, node[ch], visited, s + ch)
                    visited.remove((nr, nc))

    for r in range(H):
        for c in range(W):
            ch = grid[r][c]
            if ch in trie:
                dfs(r, c, trie[ch], {(r, c)}, ch)

    return sorted(list(found), key=lambda x: (len(x), x))

# Dedicated handcrafted configs for Levels 1 to 10 (matching tutorial specs)
HANDCRAFTED_LEVELS = [
    {
        "id": 1,
        "words": ["CAT", "DOG", "PEN"],
        "grid": [
            ["C", "A", "T"],
            ["D", "P", "E"],
            ["O", "G", "N"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 2,
        "words": ["PIG", "COW", "GOAT"],
        "grid": [
            ["P", "T", "C"],
            ["I", "A", "O"],
            ["G", "O", "W"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 3,
        "words": ["TEA", "EGG", "CUP"],
        "grid": [
            ["T", "E", "G"],
            ["E", "C", "G"],
            ["A", "U", "P"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 4,
        "words": ["CAR", "BUS", "VAN"],
        "grid": [
            ["R", "A", "C"],
            ["B", "V", "A"],
            ["U", "S", "N"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 5,
        "words": ["BEE", "ANT", "BUG"],
        "grid": [
            ["B", "A", "B"],
            ["E", "N", "U"],
            ["E", "T", "G"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 6,
        "words": ["FIRE", "HOT", "TENT"],
        "grid": [
            ["F", "H", "O"],
            ["I", "T", "T"],
            ["R", "E", "N"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 7,
        "words": ["STAR", "SKY", "DARK"],
        "grid": [
            ["S", "K", "R"],
            ["T", "Y", "A"],
            ["A", "R", "D"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 8,
        "words": ["FOX", "OWL", "DEER"],
        "grid": [
            ["F", "L", "D"],
            ["O", "W", "E"],
            ["X", "R", "E"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 9,
        "words": ["MILK", "CAKE", "PIE"],
        "grid": [
            ["M", "C", "P"],
            ["I", "A", "I"],
            ["L", "K", "E"]
        ],
        "width": 3,
        "height": 3
    },
    {
        "id": 10,
        "words": ["FROG", "DUCK", "FISH"],
        "grid": [
            ["F", "D", "K", "F"],
            ["R", "U", "C", "I"],
            ["O", "G", "H", "S"]
        ],
        "width": 4,
        "height": 3
    }
]

DYNAMIC_SPECS_11_TO_20 = [
    (11, ['HOME', 'DOOR', 'ROOM'], 4, 3, 2),
    (12, ['BALL', 'PLAY', 'GAME'], 4, 3, 2),
    (13, ['BOOK', 'READ', 'DESK'], 4, 3, 2),
    (14, ['HAND', 'FOOT', 'FACE'], 4, 3, 2),
    (15, ['RAIN', 'SNOW', 'WIND', 'COLD'], 4, 3, 2),
    (16, ['BOAT', 'SHIP', 'SAND'], 4, 3, 2),
    (17, ['ROSE', 'PARK', 'LEAF', 'SEED'], 4, 3, 2),
    (18, ['SONG', 'SING', 'BELL', 'RING'], 4, 3, 2),
    (19, ['BABY', 'GIRL', 'BOY', 'LOVE'], 4, 3, 2),
    (20, ['KING', 'QUEEN', 'GOLD', 'STAR'], 4, 4, 2),
]

def save_level_file(level_id, W, H, words, grid, cell_usage):
    extras = find_extra_words(grid, words)
    letters_str = ",".join("".join(row) for row in grid)

    counts_rows = []
    for r in range(H):
        counts_rows.append("".join(str(cell_usage[(r, c)]) for c in range(W)))
    counts_str = ",".join(counts_rows)

    data = {
        "id": level_id,
        "width": W,
        "height": H,
        "target_words": [{"word": w, "type": 0} for w in words],
        "extra_words": [{"word": w, "type": 0} for w in extras],
        "letters": letters_str,
        "counts": counts_str,
        "obstacles": []
    }

    out_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'levels', 'english', f'level{level_id}.json')
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2)
    print(f"Generated Level {level_id}: {words} ({W}x{H}) -> letters: {letters_str}, counts: {counts_str}, max_count: {max(cell_usage.values())}")

def main():
    # 1. Levels 1 to 10
    for cfg in HANDCRAFTED_LEVELS:
        level_id = cfg["id"]
        words = cfg["words"]
        grid = cfg["grid"]
        W = cfg["width"]
        H = cfg["height"]

        cell_usage = defaultdict(int)
        for w in words:
            paths = find_all_paths(grid, w)
            if len(paths) != 1:
                raise ValueError(f"Level {level_id}: Word {w} has {len(paths)} paths!")
            for pt in paths[0]:
                cell_usage[pt] += 1
        save_level_file(level_id, W, H, words, grid, cell_usage)

    # 2. Levels 11 to 20
    for level_id, words, W, H, max_count in DYNAMIC_SPECS_11_TO_20:
        res = solve_words(words, W, H, max_count)
        if not res:
            raise ValueError(f"Failed to solve Level {level_id}: {words}")
        grid, cell_usage = res
        save_level_file(level_id, W, H, words, grid, cell_usage)

    print("\nALL 20 LEVELS (1 to 20) SUCCESSFULLY GENERATED!")

if __name__ == '__main__':
    main()
