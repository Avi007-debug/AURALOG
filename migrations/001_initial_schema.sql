-- ============================================
-- AuraLog Database Schema - Initial Setup
-- ============================================
-- This migration creates all the necessary tables for the AuraLog application
-- Run this in your Supabase SQL Editor

-- ============================================
-- USERS TABLE
-- ============================================
-- Stores user profile information
-- Note: user.id should match auth.users.id from Supabase Auth
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR PRIMARY KEY,  -- Matches Supabase Auth UUID
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  preferences JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ============================================
-- SESSIONS TABLE
-- ============================================
-- Tracks emotion analysis sessions
CREATE TABLE IF NOT EXISTS sessions (
  id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  duration INTEGER, -- in seconds
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
  dominant_emotion TEXT,
  average_confidence REAL CHECK (average_confidence >= 0 AND average_confidence <= 100),
  average_stress REAL CHECK (average_stress >= 0 AND average_stress <= 100),
  journal_entry TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions(start_time DESC);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);

-- ============================================
-- EMOTION_RECORDS TABLE
-- ============================================
-- Time-series data for emotion analysis
CREATE TABLE IF NOT EXISTS emotion_records (
  id SERIAL PRIMARY KEY,
  session_id VARCHAR NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  emotion TEXT NOT NULL,
  confidence REAL NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  stress_level REAL NOT NULL CHECK (stress_level >= 0 AND stress_level <= 100),
  emotion_scores JSONB DEFAULT '{}'::jsonb,
  face_data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_emotion_records_session_id ON emotion_records(session_id);
CREATE INDEX IF NOT EXISTS idx_emotion_records_timestamp ON emotion_records(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_emotion_records_emotion ON emotion_records(emotion);

-- ============================================
-- VIDEO_SESSIONS TABLE
-- ============================================
-- Stores summarized video session data
CREATE TABLE IF NOT EXISTS video_sessions (
  id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id VARCHAR REFERENCES sessions(id) ON DELETE SET NULL,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  duration INTEGER NOT NULL, -- in seconds
  dominant_emotion TEXT NOT NULL,
  emotion_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  average_confidence REAL CHECK (average_confidence >= 0 AND average_confidence <= 100),
  average_stress REAL CHECK (average_stress >= 0 AND average_stress <= 100),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_video_sessions_user_id ON video_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_video_sessions_date ON video_sessions(date DESC);

-- ============================================
-- VOICE_JOURNALS TABLE
-- ============================================
-- Stores voice journal entries
CREATE TABLE IF NOT EXISTS voice_journals (
  id VARCHAR PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id VARCHAR NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id VARCHAR REFERENCES sessions(id) ON DELETE SET NULL,
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  emotion TEXT NOT NULL,
  confidence REAL NOT NULL CHECK (confidence >= 0 AND confidence <= 100),
  duration INTEGER NOT NULL, -- in seconds
  audio_url TEXT,
  transcription TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_voice_journals_user_id ON voice_journals(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_journals_date ON voice_journals(date DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE emotion_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE video_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE voice_journals ENABLE ROW LEVEL SECURITY;

-- Users: Users can only access their own data
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid()::text = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = id);

CREATE POLICY "Users can insert own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid()::text = id);

-- Sessions: Users can only access their own sessions
CREATE POLICY "Users can view own sessions"
  ON sessions FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own sessions"
  ON sessions FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own sessions"
  ON sessions FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own sessions"
  ON sessions FOR DELETE
  USING (auth.uid()::text = user_id);

-- Emotion Records: Users can access records from their sessions
CREATE POLICY "Users can view own emotion records"
  ON emotion_records FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM sessions
    WHERE sessions.id = emotion_records.session_id
    AND sessions.user_id = auth.uid()::text
  ));

CREATE POLICY "Users can insert own emotion records"
  ON emotion_records FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM sessions
    WHERE sessions.id = emotion_records.session_id
    AND sessions.user_id = auth.uid()::text
  ));

-- Video Sessions: Users can only access their own video sessions
CREATE POLICY "Users can view own video sessions"
  ON video_sessions FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own video sessions"
  ON video_sessions FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own video sessions"
  ON video_sessions FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own video sessions"
  ON video_sessions FOR DELETE
  USING (auth.uid()::text = user_id);

-- Voice Journals: Users can only access their own journals
CREATE POLICY "Users can view own voice journals"
  ON voice_journals FOR SELECT
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own voice journals"
  ON voice_journals FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own voice journals"
  ON voice_journals FOR UPDATE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own voice journals"
  ON voice_journals FOR DELETE
  USING (auth.uid()::text = user_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sessions_updated_at
  BEFORE UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to calculate session statistics when a session is completed
CREATE OR REPLACE FUNCTION calculate_session_stats(session_id_param VARCHAR)
RETURNS VOID AS $$
DECLARE
  v_dominant_emotion TEXT;
  v_avg_confidence REAL;
  v_avg_stress REAL;
  v_duration INTEGER;
BEGIN
  -- Calculate dominant emotion (most frequent)
  SELECT emotion INTO v_dominant_emotion
  FROM emotion_records
  WHERE session_id = session_id_param
  GROUP BY emotion
  ORDER BY COUNT(*) DESC
  LIMIT 1;

  -- Calculate average confidence
  SELECT AVG(confidence) INTO v_avg_confidence
  FROM emotion_records
  WHERE session_id = session_id_param;

  -- Calculate average stress
  SELECT AVG(stress_level) INTO v_avg_stress
  FROM emotion_records
  WHERE session_id = session_id_param;

  -- Calculate duration from start to end time
  SELECT EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER INTO v_duration
  FROM sessions
  WHERE id = session_id_param;

  -- Update session with calculated values
  UPDATE sessions
  SET 
    dominant_emotion = v_dominant_emotion,
    average_confidence = v_avg_confidence,
    average_stress = v_avg_stress,
    duration = v_duration
  WHERE id = session_id_param;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- SEED DATA (Optional - for testing)
-- ============================================
-- Uncomment below to add test data

-- INSERT INTO users (id, email, name) VALUES
-- ('test-user-id-123', 'test@example.com', 'Test User')
-- ON CONFLICT (id) DO NOTHING;

COMMENT ON TABLE users IS 'User profile information';
COMMENT ON TABLE sessions IS 'Emotion analysis sessions';
COMMENT ON TABLE emotion_records IS 'Time-series emotion data during sessions';
COMMENT ON TABLE video_sessions IS 'Summarized video session data';
COMMENT ON TABLE voice_journals IS 'Voice journal entries';
