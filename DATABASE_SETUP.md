# 🗄️ AuraLog Database Setup Guide

Complete guide for setting up and testing the AuraLog database in Supabase.

## 📋 Table of Contents
1. [Database Schema Overview](#database-schema-overview)
2. [Setup Instructions](#setup-instructions)
3. [Testing Each Table](#testing-each-table)
4. [Common Issues](#common-issues)

---

## 🏗️ Database Schema Overview

### Tables Structure

```
┌─────────────────────────────────────────────────────────┐
│                         USERS                            │
│  - User profile and preferences                         │
│  - Links to Supabase Auth                               │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ user_id (FK)
                 │
        ┌────────▼────────┐
        │    SESSIONS     │ ◄─── Main tracking sessions
        │  - Start/End    │
        │  - Status       │
        │  - Stats        │
        └────┬───────┬────┘
             │       │
             │       └─────────────────┐
             │                         │
    ┌────────▼──────────┐    ┌────────▼──────────┐
    │  EMOTION_RECORDS  │    │  VIDEO_SESSIONS   │
    │  - Time-series    │    │  - Summaries      │
    │  - Real-time data │    │  - Aggregates     │
    └───────────────────┘    └───────────────────┘
             
             ┌──────────────────┐
             │  VOICE_JOURNALS  │
             │  - Journal       │
             │  - Audio notes   │
             └──────────────────┘
```

### 1. **USERS** Table
- **Purpose**: Store user profile information
- **Key Fields**:
  - `id`: Matches Supabase Auth user ID
  - `email`: User email (unique)
  - `name`: Display name
  - `preferences`: JSON object for user settings

### 2. **SESSIONS** Table
- **Purpose**: Track emotion analysis sessions
- **Key Fields**:
  - `id`: Unique session identifier
  - `user_id`: Links to users table
  - `start_time`, `end_time`: Session duration
  - `status`: active | paused | completed
  - `dominant_emotion`: Most common emotion
  - `average_confidence`: 0-100
  - `average_stress`: 0-100
  - `journal_entry`: Optional user notes

### 3. **EMOTION_RECORDS** Table
- **Purpose**: Store time-series emotion data
- **Key Fields**:
  - `session_id`: Links to sessions table
  - `timestamp`: When emotion was captured
  - `emotion`: Current emotion (happy, sad, etc.)
  - `confidence`: Analysis confidence (0-100)
  - `stress_level`: Stress level (0-100)
  - `emotion_scores`: Detailed scores for all emotions
  - `face_data`: Age, gender, race detection data

### 4. **VIDEO_SESSIONS** Table
- **Purpose**: Store summarized video session data
- **Key Fields**:
  - `user_id`: Links to users table
  - `session_id`: Optional link to sessions
  - `duration`: Session length in seconds
  - `dominant_emotion`: Most common emotion
  - `emotion_data`: JSON with emotion percentages

### 5. **VOICE_JOURNALS** Table
- **Purpose**: Store voice journal entries
- **Key Fields**:
  - `user_id`: Links to users table
  - `title`: Journal entry title
  - `content`: Transcribed or written content
  - `emotion`: Detected emotion
  - `audio_url`: Link to audio file
  - `transcription`: Optional voice-to-text

---

## 🚀 Setup Instructions

### Step 1: Access Supabase SQL Editor

1. Go to your Supabase project dashboard
2. Click on **SQL Editor** in the left sidebar
3. Click **New Query**

### Step 2: Run Initial Schema

1. Open the file: `migrations/001_initial_schema.sql`
2. Copy the entire content
3. Paste into Supabase SQL Editor
4. Click **Run** or press `Ctrl+Enter`

**Expected Result**: All tables created successfully with message:
```
Success. No rows returned
```

### Step 3: Verify Tables Created

Run this query:
```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
```

**Expected Output**:
```
emotion_records
sessions
users
video_sessions
voice_journals
```

### Step 4: Verify Row Level Security

Run this query:
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';
```

**Expected**: `rowsecurity` should be `true` for all tables.

---

## 🧪 Testing Each Table

### Test 1: Users Table

#### Create Test Users
```sql
INSERT INTO users (id, email, name, preferences) VALUES
('test-user-1', 'alice@example.com', 'Alice Smith', '{"theme": "dark"}'),
('test-user-2', 'bob@example.com', 'Bob Johnson', '{"theme": "light"}');

SELECT * FROM users;
```

**✅ Expected**: 2 users created successfully

#### Update User
```sql
UPDATE users 
SET name = 'Alice M. Smith', 
    avatar_url = 'https://example.com/avatar.jpg'
WHERE id = 'test-user-1';

SELECT * FROM users WHERE id = 'test-user-1';
```

**✅ Expected**: User updated with new name and avatar

---

### Test 2: Sessions Table

#### Create Test Session
```sql
INSERT INTO sessions (id, user_id, status) VALUES
('test-session-1', 'test-user-1', 'active');

SELECT * FROM sessions WHERE user_id = 'test-user-1';
```

**✅ Expected**: Session created with status 'active'

#### Complete a Session
```sql
UPDATE sessions 
SET 
  status = 'completed',
  end_time = NOW(),
  journal_entry = 'Felt relaxed during meditation'
WHERE id = 'test-session-1';
```

**✅ Expected**: Session marked as completed

---

### Test 3: Emotion Records Table

#### Add Emotion Records
```sql
INSERT INTO emotion_records 
  (session_id, emotion, confidence, stress_level, emotion_scores) 
VALUES
  ('test-session-1', 'happy', 85.5, 20.0, 
   '{"happy": 85.5, "sad": 5.2, "neutral": 9.3}'),
  ('test-session-1', 'happy', 88.0, 18.5, 
   '{"happy": 88.0, "sad": 4.0, "neutral": 8.0}'),
  ('test-session-1', 'neutral', 75.0, 25.0, 
   '{"happy": 60.0, "sad": 10.0, "neutral": 75.0}');

SELECT * FROM emotion_records 
WHERE session_id = 'test-session-1' 
ORDER BY timestamp;
```

**✅ Expected**: 3 emotion records created with timestamps

#### Analyze Emotion Distribution
```sql
SELECT 
  emotion, 
  COUNT(*) as count, 
  ROUND(AVG(confidence)::numeric, 2) as avg_confidence,
  ROUND(AVG(stress_level)::numeric, 2) as avg_stress
FROM emotion_records 
WHERE session_id = 'test-session-1'
GROUP BY emotion
ORDER BY count DESC;
```

**✅ Expected**: Summary showing 'happy' as dominant emotion

---

### Test 4: Calculate Session Statistics

```sql
-- First, set end time
UPDATE sessions 
SET end_time = NOW() + INTERVAL '5 minutes'
WHERE id = 'test-session-1';

-- Run calculation
SELECT calculate_session_stats('test-session-1');

-- Check results
SELECT 
  id, dominant_emotion, average_confidence, 
  average_stress, duration
FROM sessions 
WHERE id = 'test-session-1';
```

**✅ Expected**: 
- `dominant_emotion`: 'happy'
- `average_confidence`: ~82.83
- `average_stress`: ~21.17
- `duration`: 300 (seconds)

---

### Test 5: Video Sessions Table

```sql
INSERT INTO video_sessions 
  (user_id, session_id, duration, dominant_emotion, emotion_data) 
VALUES
  ('test-user-1', 'test-session-1', 300, 'happy', 
   '{"happy": 75.5, "sad": 8.2, "neutral": 13.2}');

SELECT * FROM video_sessions WHERE user_id = 'test-user-1';
```

**✅ Expected**: Video session created and linked to session

---

### Test 6: Voice Journals Table

```sql
INSERT INTO voice_journals 
  (user_id, title, content, emotion, confidence, duration) 
VALUES
  ('test-user-1', 'Morning Reflection', 
   'Today I feel energized and ready to tackle my goals.', 
   'happy', 85.0, 120);

SELECT * FROM voice_journals WHERE user_id = 'test-user-1';
```

**✅ Expected**: Voice journal created successfully

---

### Test 7: Complex Analytics Queries

#### User's Emotion Distribution
```sql
SELECT 
  e.emotion,
  COUNT(*) as total_records,
  ROUND(AVG(e.confidence)::numeric, 2) as avg_confidence
FROM emotion_records e
JOIN sessions s ON e.session_id = s.id
WHERE s.user_id = 'test-user-1'
GROUP BY e.emotion
ORDER BY total_records DESC;
```

#### Session Summary with Counts
```sql
SELECT 
  s.id,
  s.dominant_emotion,
  s.average_confidence,
  COUNT(e.id) as emotion_record_count
FROM sessions s
LEFT JOIN emotion_records e ON s.id = e.session_id
WHERE s.user_id = 'test-user-1'
GROUP BY s.id, s.dominant_emotion, s.average_confidence;
```

---

### Test 8: Cascade Deletes

```sql
-- Create test session with records
INSERT INTO sessions (id, user_id) VALUES 
  ('test-delete-session', 'test-user-1');

INSERT INTO emotion_records (session_id, emotion, confidence, stress_level)
VALUES ('test-delete-session', 'happy', 80.0, 20.0);

-- Check record exists
SELECT COUNT(*) FROM emotion_records 
WHERE session_id = 'test-delete-session';

-- Delete session
DELETE FROM sessions WHERE id = 'test-delete-session';

-- Verify cascade delete worked
SELECT COUNT(*) FROM emotion_records 
WHERE session_id = 'test-delete-session';
```

**✅ Expected**: Count should be 0 after delete (cascade worked)

---

## 🔐 Testing Row Level Security (RLS)

**Note**: RLS testing requires actual Supabase Auth users. Here's how to test:

### 1. Create Test User via Supabase Auth
```javascript
// In your frontend or Supabase console
const { data, error } = await supabase.auth.signUp({
  email: 'testuser@example.com',
  password: 'securepassword123'
});
```

### 2. Test RLS Policies
Once authenticated, queries should automatically filter by user ID:

```sql
-- This will only return data for the authenticated user
SELECT * FROM sessions;
SELECT * FROM emotion_records;
SELECT * FROM voice_journals;
```

---

## 🧹 Cleanup Test Data

After testing, clean up:

```sql
-- Clean up test data
DELETE FROM voice_journals WHERE user_id LIKE 'test-user-%';
DELETE FROM video_sessions WHERE user_id LIKE 'test-user-%';
DELETE FROM emotion_records WHERE session_id LIKE 'test-session-%';
DELETE FROM sessions WHERE user_id LIKE 'test-user-%';
DELETE FROM users WHERE id LIKE 'test-user-%';

-- Verify cleanup
SELECT 
  'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL
SELECT 'emotion_records', COUNT(*) FROM emotion_records;
```

---

## ❌ Common Issues & Solutions

### Issue 1: "relation already exists"
**Solution**: Tables already created. Either drop them first or skip creation:
```sql
DROP TABLE IF EXISTS emotion_records CASCADE;
DROP TABLE IF EXISTS video_sessions CASCADE;
DROP TABLE IF EXISTS voice_journals CASCADE;
DROP TABLE IF EXISTS sessions CASCADE;
DROP TABLE IF EXISTS users CASCADE;
```

### Issue 2: "violates foreign key constraint"
**Solution**: Ensure parent records exist before inserting child records.
```sql
-- Always create user first, then sessions, then emotion records
```

### Issue 3: "value violates check constraint"
**Solution**: Ensure values are within allowed ranges:
- Confidence: 0-100
- Stress: 0-100
- Status: 'active', 'paused', or 'completed'

### Issue 4: RLS blocking inserts
**Solution**: Temporarily disable RLS for testing:
```sql
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Run your tests
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

### Issue 5: "function calculate_session_stats does not exist"
**Solution**: Re-run the initial schema to create the function.

---

## ✅ Verification Checklist

Before moving to frontend integration:

- [ ] All 5 tables created successfully
- [ ] RLS enabled on all tables
- [ ] All indexes created
- [ ] All foreign keys working
- [ ] Cascade deletes working
- [ ] Check constraints enforced
- [ ] `calculate_session_stats()` function works
- [ ] Test data inserted and queried successfully
- [ ] Analytics queries return expected results
- [ ] Test data cleaned up

---

## 📊 Quick Stats Query

Run this to see your database status:

```sql
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  (SELECT COUNT(*) FROM information_schema.columns 
   WHERE table_name = pt.tablename) as column_count
FROM pg_tables pt
WHERE schemaname = 'public'
  AND tablename IN ('users', 'sessions', 'emotion_records', 
                    'video_sessions', 'voice_journals')
ORDER BY tablename;
```

---

## 🎯 Next Steps

Once all tests pass:

1. ✅ Update `.env` with your `DATABASE_URL`
2. ✅ Update frontend to use real Supabase queries
3. ✅ Test authentication flow with real users
4. ✅ Implement real-time emotion recording
5. ✅ Build analytics dashboard

---

**Need Help?** Check the main [README.md](../README.md) or [PROJECT_STRUCTURE.md](../PROJECT_STRUCTURE.md)
