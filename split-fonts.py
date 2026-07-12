#!/usr/bin/env python3
"""Font Splitter for Flutter — splits large CJK fonts into small TTF chunks."""

import json
import os
import subprocess
import sys
from pathlib import Path

FONTS = [
    ("mobile/assets/fonts/NotoSansSC-Regular.ttf", "regular"),
    ("mobile/assets/fonts/NotoSansSC-Bold.ttf", "bold"),
]
OUT_DIR = Path("mobile/assets/fonts/chunks")
CHARS_PER_CHUNK = 350
PYFTSUBSET = "/Users/skat/Library/Python/3.14/bin/pyftsubset"


def get_font_chars(font_path: str) -> list[int]:
    """Extract all codepoints from a font's cmap table."""
    from fontTools.ttLib import TTFont

    font = TTFont(font_path)
    cmap = font.getBestCmap()
    font.close()
    return sorted(cmap.keys())


def split_chars(chars: list[int], size: int) -> list[list[int]]:
    """Split character list into groups of `size`."""
    chunks = []
    for i in range(0, len(chars), size):
        chunks.append(chars[i : i + size])
    return chunks


def chars_to_unicode_range(chars: list[int]) -> str:
    """Convert a list of codepoints to CSS unicode-range syntax."""
    ranges = []
    start = None
    prev = None

    def flush():
        nonlocal start, prev
        if start is not None:
            if start == prev:
                ranges.append(f"U+{start:04X}")
            else:
                ranges.append(f"U+{start:04X}-{prev:04X}")
            start = None
            prev = None

    for cp in chars:
        if start is None:
            start = cp
            prev = cp
        elif cp == prev + 1:
            prev = cp
        else:
            flush()
            start = cp
            prev = cp
    flush()

    return ", ".join(ranges)


def subset_font(font_path: str, chars: list[int], out_path: str) -> bool:
    """Create a subset TTF containing only the given chars."""
    unicodes = ",".join(f"U+{cp:04X}" for cp in chars)
    result = subprocess.run(
        [
            PYFTSUBSET,
            font_path,
            f"--unicodes={unicodes}",
            "--no-subset-tables+=*",
            f"--output-file={out_path}",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"  WARN: pyftsubset failed: {result.stderr[:200]}")
    return result.returncode == 0


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    all_chunks = {}

    for font_path_str, name in FONTS:
        font_path = Path(font_path_str)
        if not font_path.exists():
            print(f"SKIP: {font_path} not found")
            continue

        sub_dir = OUT_DIR / name
        sub_dir.mkdir(parents=True, exist_ok=True)

        print(f"Splitting {name} ({font_path})...")
        chars = get_font_chars(str(font_path))
        print(f"  Total chars: {len(chars)}")
        groups = split_chars(chars, CHARS_PER_CHUNK)
        print(f"  Chunks: {len(groups)} (~{CHARS_PER_CHUNK} chars each)")

        key = f"NotoSansSC-{name.capitalize()}"
        all_chunks[key] = []

        for idx, group in enumerate(groups):
            chunk_name = f"chunk-{idx:03d}.ttf"
            out_path = sub_dir / chunk_name

            ok = subset_font(str(font_path), group, str(out_path))
            size = out_path.stat().st_size if out_path.exists() else 0

            all_chunks[key].append(
                {
                    "file": f"{name}/{chunk_name}",
                    "size": size,
                    "unicode": chars_to_unicode_range(group),
                    "family": "NotoSansSC",
                }
            )

            if (idx + 1) % 20 == 0:
                print(f"  Progress: {idx + 1}/{len(groups)}")

        # Remove the original .ttf from chunks dir (we only need the subsets)
        ttf_count = len(list(sub_dir.glob("*.ttf")))
        print(f"  -> {ttf_count} TTF chunks")

    # Write chunk map
    map_path = OUT_DIR / "chunk_map.json"
    map_path.write_text(json.dumps(all_chunks, ensure_ascii=False, indent=2))
    print(f"\nChunk map -> {map_path}")

    for key, chunks in all_chunks.items():
        total = sum(c["size"] for c in chunks)
        print(f"  {key}: {len(chunks)} chunks, {total / 1024:.0f}KB total")


if __name__ == "__main__":
    main()
