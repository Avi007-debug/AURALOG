-- ============================================
-- AuraLog Database Testing Script
-- ============================================
-- Run these queries in Supabase SQL Editor to test each table
-- Make sure to run the initial schema first (001_initial_schema.sql)

-- ============================================
-- TEST 1: USERS TABLE
-- ============================================
-- Test user creation
INSERT INTO users (id, email, name, preferences) VALUES
('test-user-1', 'alice@example.com', 'Alice Smith', '{"theme": "dark", "notifications": true}'),
('test-user-2', 'bob@example.com', 'Bob Johnson', '{"theme": "light", "notifications": false}')
ON CONFLICT (id) DO NOTHING;

-- Verify users were created
SELECT * FROM users;

-- Test user update
UPDATE users 
SET name = 'Alice M. Smith', avatar_url = 'https://example.com/avatar.jpg'
WHERE id = 'test-user-1';

-- Verify update
SELECT * FROM users WHERE id = 'test-user-1';

-- ============================================
-- TEST 2: SESSIONS TABLE
-- ============================================
-- Test session creation (active session)
INSERT INTO sessions (id, user_id, status) VALUES
('test-session-1', 'test-user-1', 'active'),
('test-session-2', 'test-user-1', 'completed');

-- Verify sessions were created
SELECT * FROM sessions WHERE user_id = 'test-user-1';

-- Test updating session to completed
UPDATE sessions 
SET 
  status = 'completed',
  end_time = NOW(),
  journal_entry = 'Felt relaxed during meditation session'
WHERE id = 'test-session-1';

-- Verify update
SELECT * FROM sessions WHERE id = 'test-session-1';

-- ============================================
-- TEST 3: EMOTION_RECORDS TABLE
-- ============================================
-- Test adding emotion records to a session
INSERT INTO emotion_records (session_id, emotion, confidence, stress_level, emotion_scores) VALUES
('test-session-1', 'happy', 85.5, 20.0, '{"happy": 85.5, "sad": 5.2, "neutral": 9.3}'),
('test-session-1', 'happy', 88.0, 18.5, '{"happy": 88.0, "sad": 4.0, "neutral": 8.0}'),
('test-session-1', 'neutral', 75.0, 25.0, '{"happy": 60.0, "sad": 10.0, "neutral": 75.0}'),
('test-session-1', 'happy', 90.0, 15.0, '{"happy": 90.0, "sad": 3.0, "neutral": 7.0}');

-- Verify emotion records were created
SELECT * FROM emotion_records WHERE session_id = 'test-session-1' ORDER BY timestamp;

-- Test emotion distribution for a session
SELECT 
  emotion, 
  COUNT(*) as count, 
  AVG(confidence) as avg_confidence,
  AVG(stress_level) as avg_stress
FROM emotion_records 
WHERE session_id = 'test-session-1'
GROUP BY emotion
ORDER BY count DESC;

-- ============================================
-- TEST 4: Calculate Session Statistics
-- ============================================
-- Update session end time first
UPDATE sessions 
SET end_time = NOW() + INTERVAL '5 minutes'
WHERE id = 'test-session-1';

-- Run the calculation function
SELECT calculate_session_stats('test-session-1');

-- Verify calculated statistics
SELECT 
  id, 
  dominant_emotion, 
  average_confidence, 
  average_stress, 
  duration,
  status
FROM sessions 
WHERE id = 'test-session-1';

-- ============================================
-- TEST 5: VIDEO_SESSIONS TABLE
-- ============================================
-- Test video session creation
INSERT INTO video_sessions (user_id, session_id, duration, dominant_emotion, emotion_data, average_confidence, average_stress) VALUES
('test-user-1', 'test-session-1', 300, 'happy', 
 '{"happy": 75.5, "sad": 8.2, "angry": 3.1, "neutral": 13.2}', 
 82.5, 22.0);

-- Verify video session
SELECT * FROM video_sessions WHERE user_id = 'test-user-1';

-- ============================================
-- TEST 6: VOICE_JOURNALS TABLE
-- ============================================
-- Test voice journal creation
INSERT INTO voice_journals (user_id, session_id, title, content, emotion, confidence, duration) VALUES
('test-user-1', 'test-session-1', 'Morning Reflection', 
 'Today I feel energized and ready to tackle my goals. The meditation really helped.', 
 'happy', 85.0, 120);

INSERT INTO voice_journals (user_id, title, content, emotion, confidence, duration) VALUES
('test-user-1', 'Evening Thoughts', 
 'Reflecting on a productive day. Feeling grateful for the progress made.', 
 'happy', 90.0, 180);

-- Verify voice journals
SELECT * FROM voice_journals WHERE user_id = 'test-user-1';

-- ============================================
-- TEST 7: Complex Queries (Analytics)
-- ============================================

-- Get user's emotion distribution over all sessions
SELECT 
  e.emotion,
  COUNT(*) as total_records,
  ROUND(AVG(e.confidence)::numeric, 2) as avg_confidence,
  ROUND(AVG(e.stress_level)::numeric, 2) as avg_stress
FROM emotion_records e
JOIN sessions s ON e.session_id = s.id
WHERE s.user_id = 'test-user-1'
GROUP BY e.emotion
ORDER BY total_records DESC;

-- Get session summary with record counts
SELECT 
  s.id,
  s.start_time,
  s.end_time,
  s.duration,
  s.dominant_emotion,
  s.average_confidence,
  s.average_stress,
  COUNT(e.id) as emotion_record_count
FROM sessions s
LEFT JOIN emotion_records e ON s.id = e.session_id
WHERE s.user_id = 'test-user-1'
GROUP BY s.id, s.start_time, s.end_time, s.duration, s.dominant_emotion, s.average_confidence, s.average_stress
ORDER BY s.start_time DESC;

-- Get user's recent activity summary
SELECT 
  'sessions' as type,
  COUNT(*)::text as count,
  MAX(created_at) as latest
FROM sessions
WHERE user_id = 'test-user-1'
UNION ALL
SELECT 
  'voice_journals' as type,
  COUNT(*)::text as count,
  MAX(created_at) as latest
FROM voice_journals
WHERE user_id = 'test-user-1'
UNION ALL
SELECT 
  'emotion_records' as type,
  COUNT(*)::text as count,
  MAX(created_at) as latest
FROM emotion_records e
JOIN sessions s ON e.session_id = s.id
WHERE s.user_id = 'test-user-1';

-- ============================================
-- TEST 8: ROW LEVEL SECURITY (RLS)
-- ============================================
-- Note: RLS tests should be run with actual authenticated users
-- These queries show what data structure to expect

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'sessions', 'emotion_records', 'video_sessions', 'voice_journals');

-- List all policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ============================================
-- TEST 9: Data Validation
-- ============================================

-- Test confidence value constraints (should fail if outside 0-100)
-- This should FAIL
-- INSERT INTO emotion_records (session_id, emotion, confidence, stress_level) VALUES
-- ('test-session-1', 'happy', 150.0, 20.0);

-- Test session status constraints (should fail if invalid status)
-- This should FAIL
-- INSERT INTO sessions (user_id, status) VALUES
-- ('test-user-1', 'invalid-status');

-- ============================================
-- TEST 10: Cascade Deletes
-- ============================================
-- Test that deleting a session deletes related emotion records

-- Count emotion records before
SELECT COUNT(*) as records_before_delete FROM emotion_records WHERE session_id = 'test-session-2';

-- Delete a session
DELETE FROM sessions WHERE id = 'test-session-2';

-- Count emotion records after (should be 0 for deleted session)
SELECT COUNT(*) as records_after_delete FROM emotion_records WHERE session_id = 'test-session-2';

-- ============================================
-- CLEANUP (Optional)
-- ============================================
-- Uncomment to clean up test data

-- DELETE FROM voice_journals WHERE user_id LIKE 'test-user-%';
-- DELETE FROM video_sessions WHERE user_id LIKE 'test-user-%';
-- DELETE FROM emotion_records WHERE session_id LIKE 'test-session-%';
-- DELETE FROM sessions WHERE user_id LIKE 'test-user-%';
-- DELETE FROM users WHERE id LIKE 'test-user-%';

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Count all records
SELECT 
  'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'emotion_records', COUNT(*) FROM emotion_records
UNION ALL
SELECT 'video_sessions', COUNT(*) FROM video_sessions
UNION ALL
SELECT 'voice_journals', COUNT(*) FROM voice_journals;

-- Show table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'sessions', 'emotion_records', 'video_sessions', 'voice_journals')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
