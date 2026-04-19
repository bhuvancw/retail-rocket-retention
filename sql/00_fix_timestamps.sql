-- ============================================================
-- 00_fix_timestamps.sql
-- Run this ONCE before any other SQL file.
-- PURPOSE: SQLite's strftime() requires event_time in format
-- 'YYYY-MM-DD HH:MM:SS' (exactly 19 chars).
-- pandas wrote it as 'YYYY-MM-DD HH:MM:SS.ffffff' (26 chars).
-- The microseconds break strftime silently — it returns NULL.
-- This update trims everything past the 19th character.
-- ============================================================

-- Step 1: Confirm the problem before fixing
SELECT
    event_time,
    length(event_time)            AS char_length,
    strftime('%Y-%m', event_time) AS strftime_result
FROM events
LIMIT 5;

-- Step 2: Fix it — trim microseconds from event_time
UPDATE events
SET event_time = substr(event_time, 1, 19)
WHERE length(event_time) > 19;

-- Step 3: Confirm the fix worked
SELECT
    event_time,
    length(event_time)            AS char_length,
    strftime('%Y-%m', event_time) AS strftime_result
FROM events
LIMIT 5;