# data/

Extracted CSVs. All produced by the notebooks in `notebooks/`, all
from the public BigQuery export `firebase-public-project.analytics_153293282`.

| File | Rows | Grain | Produced by |
|---|---|---|---|
| `day_0.csv` | 4,319 | one row per in-window installer | `01_retention_extraction.ipynb` |
| `user_journal.csv` | 59,037 | one row per (user, active day) | `01_retention_extraction.ipynb` |
| `monetization_events.csv` | 1,939 | one row per monetization event | `03_event_pulls.ipynb` |
| `post_score_distribution.csv` | 312 | one row per (mode, level, score) | `03_event_pulls.ipynb` |
| `spike_forensics.csv` | 853 | one row per (date-or-block, window group, event) | `03_event_pulls.ipynb` |

Two loading notes, both learned the hard way:

- CSV carries no types. Date columns come back as strings and are re-parsed
  at load, never mid-pipeline.
- `spike_forensics.csv`'s `period` column holds both `YYYYMMDD` date strings
  and the literal `stable_block`. It loads with `dtype={'period': str}` —
  `parse_dates` would fail on the mixed content and return all-object.
