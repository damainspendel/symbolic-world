#!/usr/bin/env python3
"""Export human validations (minus nothing sensitive — no paragraph text is stored)
to the public atlas as web/public/validations.json. Tolerant of absence."""
import json, pathlib
ROOT = pathlib.Path(__file__).resolve().parent.parent
src = ROOT / 'pipeline' / 'human_validations.json'
recs = json.load(open(src)) if src.exists() else []
out = {"updated": max((r.get('date','') for r in recs), default=None),
       "validations": [{"key": f"{r['subject']}|{r['relation']}|{r['object']}",
                        "volume": r['volume'], "paragraph": r['paragraph'],
                        "support": r['support'], "voice": r['voice'],
                        "date": r.get('date'), "by": r.get('validated_by','author')} for r in recs]}
json.dump(out, open(ROOT / 'web' / 'public' / 'validations.json', 'w'), indent=1, ensure_ascii=False)
print(f"exported {len(recs)} validations")
