import argparse
import glob
import json
import os
import sys

DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]


def validate_level_file(file_path: str) -> tuple:
    """Validate a single level JSON file."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        return False, f"JSON decode error: {e}"

    # Required fields
    required = ["id", "width", "height", "letters", "target_words", "extra_words", "obstacles"]
    for field in required:
        if field not in data:
            return False, f"Missing field '{field}'"

    width = data["width"]
    height = data["height"]
    letters_raw = data["letters"].split(",")

    if len(letters_raw) != height:
        return False, f"Row count mismatch: expected {height}, got {len(letters_raw)}"

    for r_idx, row in enumerate(letters_raw):
        if len(row) != width:
            return False, f"Col count mismatch in row {r_idx}: expected {width}, got {len(row)}"

    grid = [list(row) for row in letters_raw]

    # Target words path validation
    target_words = [tw["word"] for tw in data["target_words"]]
    if not target_words:
        return False, "No target words"

    for word in target_words:
        if not can_trace_word(grid, word, width, height):
            return False, f"Target word '{word}' cannot be traced on grid {letters_raw}"

    # Obstacle validation
    for obs in data["obstacles"]:
        if "required_words" not in obs or "cells" not in obs:
            return False, "Malformed obstacle data"
        if obs["required_words"] >= len(target_words):
            return False, f"Obstacle required words ({obs['required_words']}) >= total target words ({len(target_words)})"

    return True, "OK"


def can_trace_word(grid: list, word: str, width: int, height: int) -> bool:
    """Check if word can be formed on grid using 4 directions without cell reuse."""
    if not word:
        return False

    for r in range(height):
        for c in range(width):
            if grid[r][c] == word[0]:
                if dfs(grid, word, 1, r, c, width, height, {(r, c)}):
                    return True
    return False


def dfs(grid: list, word: str, idx: int, r: int, c: int, width: int, height: int, visited: set) -> bool:
    if idx >= len(word):
        return True

    char = word[idx]
    for dr, dc in DIRECTIONS:
        nr, nc = r + dr, c + dc
        if 0 <= nr < height and 0 <= nc < width and (nr, nc) not in visited and grid[nr][nc] == char:
            visited.add((nr, nc))
            if dfs(grid, word, idx + 1, nr, nc, width, height, visited):
                return True
            visited.remove((nr, nc))
    return False


def main():
    parser = argparse.ArgumentParser(description="Validate generated game levels.")
    parser.add_argument("--language", type=str, default="english", help="Language name")
    args = parser.parse_args()

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    levels_dir = os.path.join(project_root, "assets", "levels", args.language)

    file_paths = glob.glob(os.path.join(levels_dir, "level*.json"))
    file_paths.sort(key=lambda p: int("".join(filter(str.isdigit, os.path.basename(p))) or 0))

    if not file_paths:
        print(f"No level files found in {levels_dir}")
        sys.exit(1)

    print(f"Validating {len(file_paths)} levels in {args.language}...")
    errors = []

    for path in file_paths:
        ok, msg = validate_level_file(path)
        if not ok:
            errors.append((os.path.basename(path), msg))

    if errors:
        print(f"❌ Found {len(errors)} invalid levels:")
        for fname, err in errors[:20]:
            print(f"  - {fname}: {err}")
        sys.exit(1)
    else:
        print(f"✅ ALL {len(file_paths)} LEVELS VALIDATED 100% SUCCESSFULLY! No errors found.")


if __name__ == "__main__":
    main()
