import argparse
import asyncio
import json
import re
from pathlib import Path

import edge_tts


VOICE = "en-US-EmmaNeural"
RATE = "-14%"
VOLUME = "+0%"
PITCH = "+0Hz"
CONCURRENCY = 4
RETRIES = 4


def find_word_arrays(source_path: Path) -> list[str]:
    source = source_path.read_text(encoding="utf-8")
    word_arrays = re.findall(r"words(?:\s*:|,\s*)\s*(\[[^\]]+\])", source)
    if word_arrays:
        return word_arrays

    curriculum_path = source_path.with_name("phonics_curriculum.js")
    if curriculum_path.exists():
        curriculum = curriculum_path.read_text(encoding="utf-8")
        word_arrays = []
        for call in re.findall(r"phonicsUnit\([^\n]+\)", curriculum):
            arrays = re.findall(r"\[[^\]]*\]", call)
            if len(arrays) >= 3:
                word_arrays.append(arrays[2])
        return word_arrays
    return []


def load_words(source_path: Path) -> list[str]:
    word_arrays = find_word_arrays(source_path)
    words = []
    for raw_array in word_arrays:
        words.extend(json.loads(raw_array))
    return list(dict.fromkeys(word.lower().strip() for word in words if word.strip()))


async def generate_word(
    word: str,
    output_path: Path,
    semaphore: asyncio.Semaphore,
    force: bool,
) -> str:
    if not force and output_path.exists() and output_path.stat().st_size > 0:
        return "skipped"

    async with semaphore:
        for attempt in range(1, RETRIES + 1):
            try:
                communicator = edge_tts.Communicate(
                    text=f"{word}.",
                    voice=VOICE,
                    rate=RATE,
                    volume=VOLUME,
                    pitch=PITCH,
                )
                await communicator.save(str(output_path))
                return "created"
            except Exception:
                output_path.unlink(missing_ok=True)
                if attempt == RETRIES:
                    raise
                await asyncio.sleep(attempt * 1.5)
    return "failed"


async def generate_all(html_path: Path, output_dir: Path, force: bool = False) -> None:
    word_arrays = find_word_arrays(html_path)
    words = load_words(html_path)
    output_dir.mkdir(parents=True, exist_ok=True)
    semaphore = asyncio.Semaphore(CONCURRENCY)
    completed = 0
    created = 0

    async def run_one(word: str) -> None:
        nonlocal completed, created
        result = await generate_word(
            word,
            output_dir / f"{word}.mp3",
            semaphore,
            force,
        )
        completed += 1
        created += result == "created"
        print(f"[{completed:03}/{len(words)}] {result:7} {word}", flush=True)

    await asyncio.gather(*(run_one(word) for word in words))

    manifest = {
        "voice": VOICE,
        "rate": RATE,
        "totalWordsInLessons": sum(len(json.loads(raw)) for raw in word_arrays),
        "uniqueAudioFiles": len(words),
        "words": words,
    }
    (output_dir.parent / "manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )
    print(f"Finished: {created} created, {len(words) - created} already existed.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Zoops PoP phonics MP3 files.")
    parser.add_argument(
        "--html",
        type=Path,
        default=Path(__file__).with_name("phonics.html"),
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).with_name("audio") / "words",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate every current curriculum word with the configured voice.",
    )
    args = parser.parse_args()
    asyncio.run(generate_all(args.html.resolve(), args.output.resolve(), args.force))


if __name__ == "__main__":
    main()
