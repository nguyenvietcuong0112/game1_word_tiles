import json
import os
import random
import sys
from typing import List, Tuple, Dict, Set, Optional
from multi_dictionary import MultiLanguageDictionary, TrieNode

DIRECTIONS = [(-1, 0), (1, 0), (0, -1), (0, 1)]  # Up, Down, Left, Right


class MultiLevelGenerator:
    def __init__(self, dictionary: MultiLanguageDictionary):
        self.dict = dictionary
        self.language = dictionary.language

    def find_all_words_on_grid(self, grid: List[List[str]]) -> Dict[str, List[List[Tuple[int, int]]]]:
        """Find all dictionary words on grid via Trie DFS. Returns word -> list of valid paths."""
        height = len(grid)
        width = len(grid[0]) if height > 0 else 0
        found_words: Dict[str, List[List[Tuple[int, int]]]] = {}

        def dfs(r: int, c: int, node: TrieNode, path: List[Tuple[int, int]], current_str: str):
            if node.is_word and len(current_str) >= 3:
                found_words.setdefault(current_str, []).append(list(path))

            for dr, dc in DIRECTIONS:
                nr, nc = r + dr, c + dc
                if 0 <= nr < height and 0 <= nc < width and (nr, nc) not in path:
                    char = grid[nr][nc]
                    if char in node.children:
                        path.append((nr, nc))
                        dfs(nr, nc, node.children[char], path, current_str + char)
                        path.pop()

        for r in range(height):
            for c in range(width):
                char = grid[r][c]
                if char in self.dict.trie.root.children:
                    dfs(r, c, self.dict.trie.root.children[char], [(r, c)], char)

        return found_words

    def generate_single_level(
        self,
        level_id: int,
        width: int,
        height: int,
        min_target_words: int,
        max_target_words: int,
        min_word_len: int = 3,
        max_word_len: int = 6,
        allow_obstacles: bool = False,
        max_attempts: int = 250,
    ) -> Optional[dict]:
        """Generate a validated, solvable level with REAL, MEANINGFUL words in the specified language."""
        rng = random.Random(level_id * 104729 + 17)

        # Scale vocabulary pool based on progression
        if level_id <= 30:
            allowed_pool_size = 1000
        elif level_id <= 100:
            allowed_pool_size = 2500
        elif level_id <= 300:
            allowed_pool_size = 5000
        elif level_id <= 1000:
            allowed_pool_size = 10000
        else:
            allowed_pool_size = len(self.dict.words)

        allowed_target_words_set = set(self.dict.words[:allowed_pool_size])

        for attempt in range(max_attempts):
            # 1. Generate grid using meaningful words
            grid = self._generate_filled_grid(
                width, height, min_word_len, max_word_len, allowed_target_words_set, rng
            )
            if not grid:
                continue

            # 2. Find all valid words on the grid
            all_found = self.find_all_words_on_grid(grid)
            if not all_found:
                continue

            # 3. Select Target Words: strictly meaningful everyday words
            target_words = self._select_target_words(
                grid, all_found, min_target_words, max_target_words, min_word_len, max_word_len, allowed_target_words_set, rng
            )
            if not target_words:
                continue

            # 4. Extra Words: other valid words from dictionary
            target_set = set(target_words)
            extra_words = []
            for w in all_found.keys():
                if w not in target_set and len(w) >= 3:
                    extra_words.append(w)

            # Sort target words: ascending by length, then alphabetical
            target_words.sort(key=lambda x: (len(x), x))
            extra_words.sort(key=lambda x: (len(x), x))

            # 5. Letters string
            letters_str = ",".join("".join(row) for row in grid)

            # 6. Obstacles (if allowed and applicable)
            obstacles = []
            if allow_obstacles and width >= 4 and height >= 3 and len(target_words) >= 6:
                obstacle_data = self._generate_obstacle(grid, all_found, target_words, width, height, rng)
                if obstacle_data:
                    obstacles.append(obstacle_data)

            # 7. Validate level is 100% solvable
            if self._validate_solvable(grid, target_words, obstacles):
                return {
                    "id": level_id,
                    "width": width,
                    "height": height,
                    "target_words": [{"word": w, "type": 0} for w in target_words],
                    "extra_words": [{"word": w, "type": 0} for w in extra_words],
                    "letters": letters_str,
                    "obstacles": obstacles,
                }

        return None

    def _generate_filled_grid(
        self, width: int, height: int, min_len: int, max_len: int, allowed_set: Set[str], rng: random.Random
    ) -> Optional[List[List[str]]]:
        """Fill grid with connected real words."""
        total_cells = width * height
        grid = [["" for _ in range(width)] for _ in range(height)]

        word_pool = [w for w in self.dict.words if w in allowed_set]

        # 1st anchor word
        anchor_len = min(max_len, total_cells)
        anchor_candidates = [
            w for w in word_pool if min_len <= len(w) <= anchor_len and any(v in self.dict.vowel_set for v in w)
        ]
        if not anchor_candidates:
            anchor_candidates = [w for w in word_pool if len(w) >= 3]

        anchor = rng.choice(anchor_candidates)
        path = self._find_random_path(width, height, len(anchor), rng)
        if not path:
            return None

        for (r, c), char in zip(path, anchor):
            grid[r][c] = char

        # Fill subsequent cells with real words
        for _ in range(30):
            empty_cells = [(r, c) for r in range(height) for c in range(width) if grid[r][c] == ""]
            if not empty_cells:
                break

            start_r, start_c = rng.choice(empty_cells)
            target_len = rng.randint(min_len, min(max_len, total_cells))
            cand_words = [
                w for w in word_pool if len(w) == target_len and any(v in self.dict.vowel_set for v in w)
            ]
            if not cand_words:
                continue

            word = rng.choice(cand_words)
            word_path = self._find_path_starting_at(grid, start_r, start_c, len(word), rng)
            if word_path:
                for (r, c), char in zip(word_path, word):
                    if grid[r][c] == "":
                        grid[r][c] = char

        # Fill any stubborn isolated empty cells with typical vowels/consonants
        vowels = list(self.dict.vowels)
        consonants = list(self.dict.consonants)
        for r in range(height):
            for c in range(width):
                if grid[r][c] == "":
                    grid[r][c] = rng.choice(vowels if rng.random() < 0.45 else consonants)

        return grid

    def _find_random_path(
        self, width: int, height: int, length: int, rng: random.Random
    ) -> Optional[List[Tuple[int, int]]]:
        starts = [(r, c) for r in range(height) for c in range(width)]
        rng.shuffle(starts)
        for sr, sc in starts:
            path = self._dfs_path([(sr, sc)], width, height, length, rng)
            if path:
                return path
        return None

    def _dfs_path(
        self, current_path: List[Tuple[int, int]], width: int, height: int, length: int, rng: random.Random
    ) -> Optional[List[Tuple[int, int]]]:
        if len(current_path) == length:
            return current_path

        r, c = current_path[-1]
        dirs = list(DIRECTIONS)
        rng.shuffle(dirs)
        for dr, dc in dirs:
            nr, nc = r + dr, c + dc
            if 0 <= nr < height and 0 <= nc < width and (nr, nc) not in current_path:
                res = self._dfs_path(current_path + [(nr, nc)], width, height, length, rng)
                if res:
                    return res
        return None

    def _find_path_starting_at(
        self, grid: List[List[str]], sr: int, sc: int, length: int, rng: random.Random
    ) -> Optional[List[Tuple[int, int]]]:
        height = len(grid)
        width = len(grid[0])
        return self._dfs_path([(sr, sc)], width, height, length, rng)

    def _select_target_words(
        self,
        grid: List[List[str]],
        all_found: Dict[str, List[List[Tuple[int, int]]]],
        min_targets: int,
        max_targets: int,
        min_word_len: int,
        max_word_len: int,
        allowed_set: Set[str],
        rng: random.Random,
    ) -> Optional[List[str]]:
        """Select strictly high-frequency Common Target Words covering 100% of cells."""
        height = len(grid)
        width = len(grid[0])
        all_cells = {(r, c) for r in range(height) for c in range(width)}

        candidates = [
            w for w in all_found.keys()
            if w in allowed_set and min_word_len <= len(w) <= max_word_len and any(v in self.dict.vowel_set for v in w)
        ]

        if len(candidates) < min_targets:
            return None

        # Sort candidate words by frequency rank in language dictionary
        candidates.sort(key=lambda w: self.dict.words.index(w) if w in self.dict.words_set else 999999)

        selected_words = []
        covered_cells = set()

        for w in candidates:
            paths = all_found[w]
            word_cells = set(paths[0])
            new_cells = word_cells - covered_cells
            if new_cells or len(selected_words) < min_targets:
                if len(selected_words) < max_targets:
                    selected_words.append(w)
                    covered_cells.update(word_cells)

        # Complete coverage
        if covered_cells != all_cells:
            missing = all_cells - covered_cells
            for w in candidates:
                if w not in selected_words and len(selected_words) < max_targets:
                    for p in all_found[w]:
                        if any(cell in missing for cell in p):
                            selected_words.append(w)
                            covered_cells.update(p)
                            missing = all_cells - covered_cells
                            break

        if covered_cells != all_cells or len(selected_words) < min_targets:
            return None

        return selected_words

    def _generate_obstacle(
        self,
        grid: List[List[str]],
        all_found: Dict[str, List[List[Tuple[int, int]]]],
        target_words: List[str],
        width: int,
        height: int,
        rng: random.Random,
    ) -> Optional[dict]:
        """Generate a valid obstacle with solvable unlock requirements."""
        obstacle_cells = [(0, 0)]
        if width >= 4 and rng.random() < 0.5:
            obstacle_cells.append((0, 1))

        obs_set = set(obstacle_cells)

        unblocked_words = 0
        for w in target_words:
            has_free_path = any(not any(c in obs_set for c in path) for path in all_found[w])
            if has_free_path:
                unblocked_words += 1

        if unblocked_words >= 3:
            required = min(unblocked_words - 1, rng.randint(2, min(5, unblocked_words)))
            return {
                "required_words": required,
                "id": 1,
                "type": 0,
                "cells": [{"x": c, "y": r} for (r, c) in obstacle_cells],
            }
        return None

    def _validate_solvable(self, grid: List[List[str]], target_words: List[str], obstacles: List[dict]) -> bool:
        """Simulate solving the level to ensure 100% deadlock-free solvability."""
        height = len(grid)
        width = len(grid[0])

        word_paths: Dict[str, List[List[Tuple[int, int]]]] = {}
        for w in target_words:
            paths = self._find_all_paths_for_word(grid, w)
            if not paths:
                return False
            word_paths[w] = paths

        # Calculate cell usage
        from collections import defaultdict
        cell_counts = defaultdict(int)
        for w in target_words:
            for pt in word_paths[w][0]:
                cell_counts[pt] += 1

        for r in range(height):
            for c in range(width):
                if grid[r][c] and cell_counts[(r, c)] == 0:
                    cell_counts[(r, c)] = 1

        def can_solve_from_state(rem_words: Tuple[str, ...], counts: Dict[Tuple[int, int], int]) -> bool:
            if not rem_words:
                return True
            for w in rem_words:
                valid_paths = [p for p in word_paths[w] if all(counts.get(pt, 0) > 0 for pt in p)]
                for p in valid_paths:
                    new_counts = dict(counts)
                    for pt in p:
                        new_counts[pt] -= 1
                    new_rem = tuple(x for x in rem_words if x != w)
                    if can_solve_from_state(new_rem, new_counts):
                        return True
            return False

        return can_solve_from_state(tuple(target_words), dict(cell_counts))

    def _find_all_paths_for_word(self, grid: List[List[str]], word: str) -> List[List[Tuple[int, int]]]:
        height = len(grid)
        width = len(grid[0])
        results = []

        def dfs(r, c, idx, visited, path):
            if idx == len(word):
                results.append(list(path))
                return
            for dr, dc in DIRECTIONS:
                nr, nc = r + dr, c + dc
                if 0 <= nr < height and 0 <= nc < width and (nr, nc) not in visited and grid[nr][nc] == word[idx]:
                    visited.add((nr, nc))
                    path.append((nr, nc))
                    dfs(nr, nc, idx + 1, visited, path)
                    path.pop()
                    visited.remove((nr, nc))

        for r in range(height):
            for c in range(width):
                if grid[r][c] == word[0]:
                    dfs(r, c, 1, {(r, c)}, [(r, c)])
        return results


def get_level_config(level_num: int) -> dict:
    """Return parameters tuned for smooth casual progression."""
    if level_num <= 10:
        return {"width": 3, "height": 2, "min_targets": 3, "max_targets": 4, "min_len": 3, "max_len": 4, "obstacle": False}
    elif level_num <= 30:
        return {"width": 3, "height": 3, "min_targets": 4, "max_targets": 5, "min_len": 3, "max_len": 4, "obstacle": False}
    elif level_num <= 100:
        return {"width": 3, "height": 3, "min_targets": 4, "max_targets": 6, "min_len": 3, "max_len": 5, "obstacle": False}
    elif level_num <= 300:
        return {"width": 4, "height": 3, "min_targets": 5, "max_targets": 7, "min_len": 3, "max_len": 5, "obstacle": False}
    elif level_num <= 600:
        return {"width": 4, "height": 3, "min_targets": 6, "max_targets": 8, "min_len": 3, "max_len": 6, "obstacle": False}
    elif level_num <= 1000:
        return {"width": 4, "height": 4, "min_targets": 7, "max_targets": 9, "min_len": 3, "max_len": 6, "obstacle": level_num % 10 == 0}
    elif level_num <= 1800:
        return {"width": 4, "height": 4, "min_targets": 8, "max_targets": 11, "min_len": 3, "max_len": 7, "obstacle": level_num % 5 == 0}
    else:
        return {"width": 5, "height": 4, "min_targets": 9, "max_targets": 13, "min_len": 3, "max_len": 7, "obstacle": level_num % 4 == 0}
