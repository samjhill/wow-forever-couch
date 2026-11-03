#!/usr/bin/env python3
"""Mirror CouchDictateRoute channel policy for offline unit tests.

Policy:
  raid                         → raid
  party size >= 3 (not raid)   → party
  solo or party size 1–2       → say
  override say|party|raid      → that channel
"""
from __future__ import annotations

import argparse
import sys


def resolve(
    *,
    in_raid: bool = False,
    group_size: int = 0,
    override: str | None = None,
) -> tuple[str, str]:
    if override:
        o = override.strip().lower()
        if o in {"say", "s"}:
            return "say", "override"
        if o in {"party", "p"}:
            return "party", "override"
        if o in {"raid", "r"}:
            return "raid", "override"
        raise ValueError(f"bad override: {override}")
    if in_raid:
        return "raid", "raid"
    if group_size >= 3:
        return "party", "party3+"
    if group_size >= 1:
        return "say", "party2"
    return "say", "solo"


def slash_prefix(channel: str) -> str:
    return {"say": "/say ", "party": "/p ", "raid": "/raid "}[channel]


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--raid", action="store_true")
    p.add_argument("--size", type=int, default=0)
    p.add_argument("--override", default=None)
    p.add_argument("--slash", action="store_true", help="print slash prefix only")
    args = p.parse_args()
    channel, reason = resolve(in_raid=args.raid, group_size=args.size, override=args.override)
    if args.slash:
        print(slash_prefix(channel), end="")
    else:
        print(f"{channel}\t{reason}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
