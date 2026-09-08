import argparse
import concurrent.futures
import json
import os
import time
from typing import Optional

from multi_dictionary import MultiLanguageDictionary, ensure_language_dictionary
from multi_level_generator import MultiLevelGenerator, get_level_config

DEFAULT_TOTAL_LEVELS = {
    "english": 2461,
    "turkish": 2448,
    "russian": 1927,
    "spanish": 1361,
    "portuguese": 1353,
    "german": 1500,
    "french": 1500,
    "italian": 1500,
    "vietnamese": 1500,
}

_global_dict: Optional[MultiLanguageDictionary] = None
_global_gen: Optional[MultiLevelGenerator] = None


def init_worker(language: str):
    """Initialize dictionary and generator once per worker process for the given language."""
    global _global_dict, _global_gen
    _global_dict = MultiLanguageDictionary(language)
    _global_gen = MultiLevelGenerator(_global_dict)


def generate_level_task(args_tuple):
    """Worker task to generate a single level."""
    global _global_gen
    level_id, language, output_dir = args_tuple

    cfg = get_level_config(level_id)
    level_data = _global_gen.generate_single_level(
        level_id=level_id,
        width=cfg["width"],
        height=cfg["height"],
        min_target_words=cfg["min_targets"],
        max_target_words=cfg["max_targets"],
        min_word_len=cfg["min_len"],
        max_word_len=cfg["max_len"],
        allow_obstacles=cfg["obstacle"],
    )

    if level_data:
        file_path = os.path.join(output_dir, f"level{level_id}.json")
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(level_data, f, indent=2, ensure_ascii=False)
        return True, level_id, len(level_data["target_words"]), len(level_data["extra_words"])
    else:
        return False, level_id, 0, 0


def generate_levels_for_language(
    language: str,
    start: int = 1,
    end: Optional[int] = None,
    workers: Optional[int] = None,
) -> bool:
    if end is None:
        end = DEFAULT_TOTAL_LEVELS.get(language, 1000)
    if workers is None:
        workers = os.cpu_count() or 4

    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    output_dir = os.path.join(project_root, "assets", "levels", language)
    os.makedirs(output_dir, exist_ok=True)

    # Pre-build / download dictionary in main process
    ensure_language_dictionary(language)

    print(f"==================================================")
    print(f"🚀 Batch Level Generator - [{language.upper()}]")
    print(f"Language:    {language}")
    print(f"Range:       Level {start} to {end} ({end - start + 1} levels)")
    print(f"Output:      {output_dir}")
    print(f"CPU Workers: {workers}")
    print(f"==================================================")

    tasks = [(lvl, language, output_dir) for lvl in range(start, end + 1)]

    start_time = time.time()
    success_count = 0
    fail_count = 0
    total_targets = 0
    total_extras = 0

    with concurrent.futures.ProcessPoolExecutor(
        max_workers=workers, initializer=init_worker, initargs=(language,)
    ) as executor:
        for i, result in enumerate(executor.map(generate_level_task, tasks), start=1):
            success, lvl_id, n_targets, n_extras = result
            if success:
                success_count += 1
                total_targets += n_targets
                total_extras += n_extras
            else:
                fail_count += 1
                print(f"⚠️ Failed to generate level {lvl_id}")

            if i % 100 == 0 or i == len(tasks):
                elapsed = time.time() - start_time
                speed = i / elapsed if elapsed > 0 else 0
                print(f"[{i}/{len(tasks)}] Done: {success_count} levels | Speed: {speed:.1f} levels/sec")

    elapsed_total = time.time() - start_time
    print(f"\n==================================================")
    print(f"🎉 [{language.upper()}] COMPLETED in {elapsed_total:.2f} seconds!")
    print(f"✅ Successful Levels: {success_count} / {len(tasks)}")
    if fail_count > 0:
        print(f"❌ Failed Levels:     {fail_count}")
    print(f"📊 Total Target Words: {total_targets} (Avg: {total_targets / max(1, success_count):.1f} words/level)")
    print(f"🎁 Total Extra Words:  {total_extras} (Avg: {total_extras / max(1, success_count):.1f} words/level)")
    print(f"==================================================")

    return fail_count == 0


def main():
    parser = argparse.ArgumentParser(description="Batch generate game levels for any language.")
    parser.add_argument("--language", type=str, default="english", help="Language name")
    parser.add_argument("--start", type=int, default=1, help="Start level ID")
    parser.add_argument("--end", type=int, default=None, help="End level ID")
    parser.add_argument("--workers", type=int, default=os.cpu_count() or 4, help="Number of worker processes")
    args = parser.parse_args()

    generate_levels_for_language(args.language, args.start, args.end, args.workers)


if __name__ == "__main__":
    main()
