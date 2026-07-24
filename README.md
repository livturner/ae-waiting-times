# ae-waiting-times
which health boards are failing to meet the 4-hour A&E standard, is it getting better or worse, and which boards need attention now, before it shows up in the next quarterly report.

### notes (draft)
- **Duplicate record found**: one exact duplicate in the source data — board `S08000031`, May 2015, treatment location `G405H`, Type 1 — appeared twice (both `All` and `Unplanned` attendance categories). Removed via a window-function dedup (`ROW_NUMBER()` partitioned by the full row-identity columns, keeping the lowest `id`). Confirmed genuine duplicate, not a repeated-insert artifact, since it was isolated to a single row rather than affecting the whole table.

- **Null pattern in episode-level columns**: all five episode metric columns (`attendances_episode`, `within_4hrs_episode`, `over_8hrs_episode`, `over_12hrs_episode`, `pct_within_4hrs_episode`) are null on exactly the same rows every time — 16,894 of 39,581 total rows (42.7%). Confirms nulls aren't scattered/random — they represent whole rows with no episode-level submission at all, not individual missing fields.

- **Root cause: department type, not board quality**. `Type 3` (minor injury units, doctor/nurse-led) is 69% null (16,594 of 23,974 rows) vs `Type 1` (major 24/7 Emergency Departments) at under 2% null (300 of 15,607 rows). This tracks PHS's own methodology: smaller Type 3 sites often lack the systems to submit detailed patient-level episode data and instead submit aggregate-only monthly totals.

- **Board-level null variation is a downstream effect, not a separate issue**: boards with more null rows (e.g. `S08000022` Highland at 77%, `S08000020` Grampian at 68%) are rural boards with proportionally more Type 3 sites. Boards near 0% null (`S08000031` Greater Glasgow and Clyde, `S08000019` Forth Valley) are urban, Type 1-dominated boards. Not a data quality difference between boards — a structural difference in site mix.

- **Scoping decision**: filtering to `Type 1` + `attendance_category = 'All'` gives near-complete (98%), consistent coverage across every board, and aligns with how the 4-hour standard is primarily reported nationally. Type 3 excluded from the core analysis on this basis, not dropped silently.
- Initial analysis used an unweighted average of monthly percentages, which understated NHS Grampian's underperformance by masking that its worst months were also its highest-volume months (62.8% → 55.0% under a volume-weighted calculation)
- Grampian is the real finding here. It dropped from 62.8% to 55.0% — a 7.8-point swing, the largest of any board. That means Grampian's worse months were also its higher-volume months, and the simple average was masking that by treating a quiet month and a busy month as equally important. Under the weighted calculation, Grampian now sits essentially level with Lanarkshire as one of the two worst performers, not comfortably mid-pack like the first version suggested.
