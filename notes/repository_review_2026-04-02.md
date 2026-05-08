# Repository Review Notes (2026-04-02)

## Documentation updates suggested

1. Add a **Gallery Generation** section to `README.md` with the exact command to rebuild pages.
2. Add a **filename convention** section so contributors can follow a predictable pattern.
3. Add a **filename lint/check command** to make maintenance easier when adding new images.

## Python site generator improvements suggested

1. Add an optional `--check-names` mode to validate image naming before rebuilds.
2. Escape generated HTML attributes for image names/titles to avoid malformed pages from odd filenames.
3. Keep gallery generation output unchanged by default so current workflow remains simple (`python3 generate_gallery.py`).

## Suggested filename cleanups

These are high-confidence naming mismatches found during this review:

- `desktop/space/space_solar-eclipse-widescreenpng`
  - Suggested: `desktop/space/space_solar-eclipse-widescreen.png`
- `mobile/gaming/gaming_Lineage-goddess.jpg`
  - Suggested: `mobile/gaming/gaming_lineage-goddess.jpg`
- `mobile/outdoors/outdoors_Leaves.png`
  - Suggested: `mobile/outdoors/outdoors_leaves.png`

Possible typo candidates worth manual confirmation:

- `dual/history/history_jolly-rodger.jpg`
  - Possible intended spelling: `dual/history/history_jolly-roger.jpg`
- `desktop/popculture/popculture_lotm-cards.png`
  - If this refers to *Lord of the Rings*, possible rename: `desktop/popculture/popculture_lotr-cards.png`

## Notes

- This review focused on repo structure, naming consistency, and generator maintainability.
- No automatic image-content classification was used for semantic renaming.
