import argparse
import asyncio
import json
import subprocess
from pathlib import Path

import edge_tts


VOICE = "en-US-EmmaNeural"
RATE = "-12%"
VOLUME = "+0%"
PITCH = "+0Hz"
CONCURRENCY = 4
RETRIES = 4


NODE_EXPORT_SCRIPT = r"""
const fs = require("fs");
const vm = require("vm");

const curriculum = fs.readFileSync("phonics_curriculum.js", "utf8");
const html = fs.readFileSync("phonics.html", "utf8");
const inlineScripts = [...html.matchAll(/<script(?![^>]*src=)[^>]*>([\s\S]*?)<\/script>/gi)]
  .map(match => match[1])
  .join("\n");

const noopElement = () => ({
  addEventListener() {},
  hidden: true,
  style: { setProperty() {} },
  innerHTML: "",
  textContent: "",
  disabled: false
});

const ctx = {
  window: {
    addEventListener() {},
    location: {},
    speechSynthesis: { cancel() {}, speak() {}, getVoices() { return []; } },
    setTimeout() {},
    clearTimeout() {},
    setInterval() {},
    clearInterval() {}
  },
  document: {
    addEventListener() {},
    getElementById() { return noopElement(); },
    querySelector() { return noopElement(); },
    documentElement: { style: { setProperty() {} } }
  },
  console,
  Audio: function() { return { load() {}, readyState: 0 }; },
  HTMLMediaElement: { HAVE_NOTHING: 0 },
  SpeechSynthesisUtterance: function() {},
  setTimeout() {},
  clearTimeout() {},
  setInterval() {},
  clearInterval() {}
};

vm.createContext(ctx);
vm.runInContext(`${curriculum}\n${inlineScripts}`, ctx);

const seen = new Set();
const phrases = [];
for (const [sectionName, section] of Object.entries(ctx.PHONICS_DATA)) {
  section.units.forEach((unit, unitIndex) => {
    ctx.makeCollabPhrases(unit, unit.sightWords || []).forEach(item => {
      const key = ctx.phraseAudioKey(item.phrase);
      if (seen.has(key)) return;
      seen.add(key);
      phrases.push({
        key,
        phrase: item.phrase,
        section: sectionName,
        unitIndex: unitIndex + 1,
        unitName: unit.name
      });
    });
  });
}

process.stdout.write(JSON.stringify(phrases));
"""


def load_collab_phrases(project_dir: Path) -> list[dict[str, str]]:
    result = subprocess.run(
        ["node", "-e", NODE_EXPORT_SCRIPT],
        cwd=project_dir,
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


async def generate_phrase(
    item: dict[str, str],
    output_dir: Path,
    semaphore: asyncio.Semaphore,
    force: bool,
) -> str:
    output_path = output_dir / f"{item['key']}.mp3"
    if not force and output_path.exists() and output_path.stat().st_size > 0:
        return "skipped"

    async with semaphore:
        for attempt in range(1, RETRIES + 1):
            try:
                communicator = edge_tts.Communicate(
                    text=f"{item['phrase']}.",
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


async def generate_all(project_dir: Path, output_dir: Path, force: bool = False) -> None:
    phrases = load_collab_phrases(project_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    semaphore = asyncio.Semaphore(CONCURRENCY)
    completed = 0
    created = 0

    async def run_one(item: dict[str, str]) -> None:
        nonlocal completed, created
        result = await generate_phrase(item, output_dir, semaphore, force)
        completed += 1
        created += result == "created"
        print(
            f"[{completed:03}/{len(phrases)}] {result:7} {item['key']}",
            flush=True,
        )

    await asyncio.gather(*(run_one(item) for item in phrases))

    manifest = {
        "voice": VOICE,
        "rate": RATE,
        "uniqueCollabAudioFiles": len(phrases),
        "phrases": phrases,
    }
    (output_dir.parent / "collab_manifest.json").write_text(
        json.dumps(manifest, indent=2),
        encoding="utf-8",
    )
    print(f"Finished: {created} created, {len(phrases) - created} already existed.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Zoops PoP collab phrase MP3 files.")
    parser.add_argument(
        "--project-dir",
        type=Path,
        default=Path(__file__).resolve().parent,
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent / "audio" / "collab",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate every collab phrase with the configured voice.",
    )
    args = parser.parse_args()
    asyncio.run(generate_all(args.project_dir.resolve(), args.output.resolve(), args.force))


if __name__ == "__main__":
    main()
