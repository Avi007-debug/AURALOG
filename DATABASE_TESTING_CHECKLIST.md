# ✅ Database Testing Checklist

Use this checklist to systematically test each table in your Supabase database.

## 🎯 Pre-Testing Setup

- [ ] Supabase project created
- [ ] Supabase SQL Editor accessible
- [ ] `.env` file configured with correct credentials
- [ ] Initial schema (`001_initial_schema.sql`) ready to run

---

## 📝 Step-by-Step Testing Process

### Phase 1: Initial Schema Setup

#### ☐ Step 1.1: Run Initial Schema
1. Open Supabase SQL Editor
2. Copy content from `migrations/001_initial_schema.sql`
3. Paste and run in SQL Editor
4. **Expected**: "Success. No rows returned"

#### ☐ Step 1.2: Verify Tables Created
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```
**Expected Result**: Should show 5 tables:
- [ ] emotion_records
- [ ] sessions
- [ ] users
- [ ] video_sessions
- [ ] voice_journals

#### ☐ Step 1.3: Verify RLS Enabled
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```
**Expected**: All tables should have `rowsecurity = true`

#### ☐ Step 1.4: Verify Indexes Created
```sql
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```
**Expected**: Multiple indexes per table

---

### Phase 2: Test USERS Table

#### ☐ Step 2.1: Insert Test Users
```sql
INSERT INTO users (id, email, name, preferences) VALUES
('test-user-1', 'alice@example.com', 'Alice Smith', '{"theme": "dark"}'),
('test-user-2', 'bob@example.com', 'Bob Johnson', '{"theme": "light"}');
```
**Result**: [ ] Pass / [ ] Fail
**Notes**: _______________________________

#### ☐ Step 2.2: Query Users
```sql
SELECT * FROM users;
```
**Expected**: 2 users with correct data
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 2.3: Update User
```sql
UPDATE users 
SET name = 'Alice M. Smith', avatar_url = 'https://example.com/avatar.jpg'
WHERE id = 'test-user-1';
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 2.4: Verify Update
```sql
SELECT * FROM users WHERE id = 'test-user-1';
```
**Expected**: Name and avatar_url updated
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 2.5: Test Email Uniqueness
```sql
-- This should FAIL
INSERT INTO users (id, email, name) VALUES
('test-user-3', 'alice@example.com', 'Another Alice');
```
**Expected**: Error (duplicate email)
**Result**: [ ] Pass (error occurred) / [ ] Fail (no error)

---

### Phase 3: Test SESSIONS Table

#### ☐ Step 3.1: Create Active Session
```sql
INSERT INTO sessions (id, user_id, status) VALUES
('test-session-1', 'test-user-1', 'active');
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 3.2: Query Session
```sql
SELECT * FROM sessions WHERE user_id = 'test-user-1';
```
**Expected**: 1 session with status 'active'
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 3.3: Update to Completed
```sql
UPDATE sessions 
SET 
  status = 'completed',
  end_time = NOW(),
  journal_entry = 'Test journal entry'
WHERE id = 'test-session-1';
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 3.4: Verify Updated At Trigger
```sql
SELECT created_at, updated_at FROM sessions WHERE id = 'test-session-1';
```
**Expected**: updated_at > created_at
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 3.5: Test Invalid Status
```sql
-- This should FAIL
INSERT INTO sessions (user_id, status) VALUES
('test-user-1', 'invalid-status');
```
**Expected**: Error (invalid status)
**Result**: [ ] Pass (error occurred) / [ ] Fail

---

### Phase 4: Test EMOTION_RECORDS Table

#### ☐ Step 4.1: Insert Emotion Records
```sql
INSERT INTO emotion_records 
  (session_id, emotion, confidence, stress_level, emotion_scores) 
VALUES
  ('test-session-1', 'happy', 85.5, 20.0, '{"happy": 85.5, "sad": 5.2}'),
  ('test-session-1', 'happy', 88.0, 18.5, '{"happy": 88.0, "sad": 4.0}'),
  ('test-session-1', 'neutral', 75.0, 25.0, '{"happy": 60.0, "neutral": 75.0}'),
  ('test-session-1', 'happy', 90.0, 15.0, '{"happy": 90.0, "sad": 3.0}');
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 4.2: Query Records
```sql
SELECT * FROM emotion_records 
WHERE session_id = 'test-session-1' 
ORDER BY timestamp;
```
**Expected**: 4 records in chronological order
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 4.3: Test Aggregation
```sql
SELECT 
  emotion, 
  COUNT(*) as count, 
  AVG(confidence) as avg_conf
FROM emotion_records 
WHERE session_id = 'test-session-1'
GROUP BY emotion;
```
**Expected**: 'happy' = 3, 'neutral' = 1
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 4.4: Test Invalid Confidence
```sql
-- This should FAIL
INSERT INTO emotion_records 
  (session_id, emotion, confidence, stress_level)
VALUES ('test-session-1', 'happy', 150.0, 20.0);
```
**Expected**: Error (confidence > 100)
**Result**: [ ] Pass (error occurred) / [ ] Fail

---

### Phase 5: Test Session Statistics Function

#### ☐ Step 5.1: Set Session End Time
```sql
UPDATE sessions 
SET end_time = start_time + INTERVAL '5 minutes'
WHERE id = 'test-session-1';
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 5.2: Run Calculation Function
```sql
SELECT calculate_session_stats('test-session-1');
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 5.3: Verify Calculated Values
```sql
SELECT 
  dominant_emotion,
  average_confidence,
  average_stress,
  duration
FROM sessions 
WHERE id = 'test-session-1';
```
**Expected**:
- dominant_emotion: 'happy' (appears 3 times)
- average_confidence: ~84.625
- average_stress: ~19.625
- duration: 300 seconds

**Actual Results**:
- dominant_emotion: ___________
- average_confidence: ___________
- average_stress: ___________
- duration: ___________

**Result**: [ ] Pass / [ ] Fail

---

### Phase 6: Test VIDEO_SESSIONS Table

#### ☐ Step 6.1: Insert Video Session
```sql
INSERT INTO video_sessions 
  (user_id, session_id, duration, dominant_emotion, emotion_data, average_confidence) 
VALUES
  ('test-user-1', 'test-session-1', 300, 'happy', 
   '{"happy": 75.5, "sad": 8.2, "neutral": 13.2}', 82.5);
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 6.2: Query Video Session
```sql
SELECT * FROM video_sessions WHERE user_id = 'test-user-1';
```
**Expected**: 1 video session
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 6.3: Verify Foreign Key Constraint
```sql
-- This should FAIL (non-existent user)
INSERT INTO video_sessions 
  (user_id, duration, dominant_emotion, emotion_data)
VALUES ('non-existent-user', 60, 'happy', '{}');
```
**Expected**: Foreign key error
**Result**: [ ] Pass (error occurred) / [ ] Fail

---

### Phase 7: Test VOICE_JOURNALS Table

#### ☐ Step 7.1: Insert Voice Journal
```sql
INSERT INTO voice_journals 
  (user_id, title, content, emotion, confidence, duration) 
VALUES
  ('test-user-1', 'Morning Reflection', 
   'Today I feel energized and ready.', 
   'happy', 85.0, 120);
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 7.2: Query Voice Journals
```sql
SELECT * FROM voice_journals WHERE user_id = 'test-user-1';
```
**Expected**: 1 journal entry
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 7.3: Test with Session Link
```sql
INSERT INTO voice_journals 
  (user_id, session_id, title, content, emotion, confidence, duration) 
VALUES
  ('test-user-1', 'test-session-1', 'Post-Session Notes', 
   'Reflecting on the session.', 'neutral', 75.0, 90);
```
**Result**: [ ] Pass / [ ] Fail

---

### Phase 8: Test Cascade Deletes

#### ☐ Step 8.1: Create Test Data for Deletion
```sql
INSERT INTO sessions (id, user_id, status) VALUES 
  ('test-delete-session', 'test-user-1', 'active');

INSERT INTO emotion_records (session_id, emotion, confidence, stress_level)
VALUES ('test-delete-session', 'happy', 80.0, 20.0);
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 8.2: Verify Records Exist
```sql
SELECT COUNT(*) FROM emotion_records 
WHERE session_id = 'test-delete-session';
```
**Expected**: Count = 1
**Actual**: ___________
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 8.3: Delete Parent Session
```sql
DELETE FROM sessions WHERE id = 'test-delete-session';
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 8.4: Verify Cascade Delete
```sql
SELECT COUNT(*) FROM emotion_records 
WHERE session_id = 'test-delete-session';
```
**Expected**: Count = 0 (records deleted)
**Actual**: ___________
**Result**: [ ] Pass / [ ] Fail

---

### Phase 9: Test Complex Analytics Queries

#### ☐ Step 9.1: User Emotion Distribution
```sql
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
```
**Expected**: 'happy' with highest count
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 9.2: Session Summary with Counts
```sql
SELECT 
  s.id,
  s.dominant_emotion,
  COUNT(e.id) as record_count
FROM sessions s
LEFT JOIN emotion_records e ON s.id = e.session_id
WHERE s.user_id = 'test-user-1'
GROUP BY s.id, s.dominant_emotion;
```
**Expected**: Each session with its record count
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 9.3: User Activity Summary
```sql
SELECT 
  'sessions' as type, COUNT(*)::text as count
FROM sessions WHERE user_id = 'test-user-1'
UNION ALL
SELECT 'voice_journals', COUNT(*)::text
FROM voice_journals WHERE user_id = 'test-user-1'
UNION ALL
SELECT 'video_sessions', COUNT(*)::text
FROM video_sessions WHERE user_id = 'test-user-1';
```
**Expected**: Count for each type
**Result**: [ ] Pass / [ ] Fail

---

### Phase 10: Test Row Level Security (RLS)

**Note**: This requires actual Supabase Auth users

#### ☐ Step 10.1: Verify RLS Policies Exist
```sql
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```
**Expected**: Multiple policies per table
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 10.2: Test with Authenticated User
*This must be done via frontend or Supabase client*
```javascript
// After user authentication
const { data, error } = await supabase
  .from('sessions')
  .select('*');
// Should only return current user's sessions
```
**Result**: [ ] Pass / [ ] Fail / [ ] Not Tested Yet

---

## 🧹 Cleanup

#### ☐ Step 11.1: Delete Test Data
```sql
DELETE FROM voice_journals WHERE user_id LIKE 'test-user-%';
DELETE FROM video_sessions WHERE user_id LIKE 'test-user-%';
DELETE FROM emotion_records WHERE session_id LIKE 'test-session-%';
DELETE FROM sessions WHERE user_id LIKE 'test-user-%';
DELETE FROM users WHERE id LIKE 'test-user-%';
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Step 11.2: Verify Cleanup
```sql
SELECT 
  'users' as table_name, COUNT(*) as count FROM users WHERE id LIKE 'test-user-%'
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions WHERE id LIKE 'test-session-%';
```
**Expected**: All counts = 0
**Result**: [ ] Pass / [ ] Fail

---

## 📊 Final Verification

### Overall Database Health Check

#### ☐ Table Counts
```sql
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
```
**Result**: [ ] Pass / [ ] Fail

#### ☐ Table Sizes
```sql
SELECT 
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```
**Result**: [ ] Pass / [ ] Fail

---

## ✅ Final Checklist

- [ ] All tables created successfully
- [ ] All indexes created
- [ ] All foreign keys working
- [ ] RLS enabled on all tables
- [ ] RLS policies created
- [ ] Triggers working (updated_at)
- [ ] Check constraints enforced
- [ ] Cascade deletes working
- [ ] `calculate_session_stats()` function works
- [ ] All test data inserted successfully
- [ ] All queries return expected results
- [ ] Test data cleaned up
- [ ] Ready for frontend integration

---

## 📝 Notes & Issues

### Issues Encountered:
```
Issue 1: _________________________________________________
Solution: ________________________________________________

Issue 2: _________________________________________________
Solution: ________________________________________________
```

### Performance Notes:
```
_________________________________________________________
_________________________________________________________
```

---

**Testing Completed By**: ___________________  
**Date**: ___________________  
**Time Taken**: ___________________  
**Overall Status**: [ ] Pass / [ ] Fail / [ ] Needs Review
