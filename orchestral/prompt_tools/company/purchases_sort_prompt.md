# Prompt: Purchases Table Sorter

Input: markdown representation of the Purchases & Gear table (Item / Notes / Status).

You must:

1. Parse the rows.
2. Move rows with a ✅ or "Purchased" status to the bottom, preserving relative order otherwise.
3. Reorder columns to `[Item, Notes, Status]` (status last).
4. Return JSON with `summary` plus `html` (HTML table). Do not wrap in extra schema metadata.

Do not invent new rows—reuse exactly what is provided.
