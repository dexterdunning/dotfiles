---
name: disk-visual
description: Scan home dir and generate an interactive treemap of disk usage
---

Run the disk-usage scanner and open the resulting visual in the preview panel.

Steps:
1. Run `/Users/dexter/projects/docs/disk-usage/scan.sh /tmp/disk_usage_visual.html` (takes ~30s).
2. Show the user a short summary: total/used/free GB, the top 5 space consumers, and the largest reclaim candidates.
3. Confirm the visual is visible in the Launch preview panel at `/tmp/disk_usage_visual.html`.

Do NOT delete anything. If the user asks to clean up a directory, confirm the path and size first, then proceed.

If `$ARGUMENTS` is non-empty, treat it as the output path passed to scan.sh.
