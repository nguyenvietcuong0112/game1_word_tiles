import time
from batch_generate_levels import generate_levels_for_language, DEFAULT_TOTAL_LEVELS


def main():
    languages = ["german", "french", "italian"]
    print("==================================================")
    print("🇪🇺 EXPANSION PACK: GERMAN, FRENCH, ITALIAN")
    print(f"Languages: {', '.join(languages)}")
    print("==================================================")

    overall_start = time.time()
    for lang in languages:
        total_count = DEFAULT_TOTAL_LEVELS[lang]
        print(f"\n>>> Starting {lang.upper()} ({total_count} levels)...")
        generate_levels_for_language(lang, start=1, end=total_count)

    print(f"\n==================================================")
    print(f"🎉 ALL 3 NEW LANGUAGES GENERATED in {time.time() - overall_start:.2f} seconds!")
    print("==================================================")


if __name__ == "__main__":
    main()
