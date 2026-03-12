import { sql } from "drizzle-orm";
import { pgTable, text, varchar, integer, jsonb, timestamp, boolean, real, serial } from "drizzle-orm/pg-core";
import { createInsertSchema, createSelectSchema } from "drizzle-zod";
import { z } from "zod";

// ============================================
// USERS TABLE - Store user profile information
// Note: Supabase Auth handles authentication, this is for profile data
// ============================================
export const users = pgTable("users", {
  id: varchar("id").primaryKey(), // Will match Supabase Auth user ID
  email: text("email").notNull().unique(),
  name: text("name").notNull(),
  avatarUrl: text("avatar_url"),
  preferences: jsonb("preferences").$type<{
    theme?: 'light' | 'dark';
    notifications?: boolean;
    reminderTime?: string;
  }>(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

// ============================================
// SESSIONS TABLE - Track analysis sessions
// Each session represents a continuous period of emotion tracking
// ============================================
export const sessions = pgTable("sessions", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: varchar("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  startTime: timestamp("start_time").defaultNow().notNull(),
  endTime: timestamp("end_time"),
  duration: integer("duration"), // in seconds, calculated when session ends
  status: text("status").notNull().default('active'), // 'active', 'paused', 'completed'
  dominantEmotion: text("dominant_emotion"), // calculated when session ends
  averageConfidence: real("average_confidence"), // 0-100
  averageStress: real("average_stress"), // 0-100
  journalEntry: text("journal_entry"), // optional user notes
  metadata: jsonb("metadata").$type<{
    pauseCount?: number;
    deviceInfo?: string;
    location?: string;
  }>(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
  updatedAt: timestamp("updated_at").defaultNow().notNull(),
});

// ============================================
// EMOTION_RECORDS TABLE - Time-series emotion data
// Stores individual emotion analysis results during a session
// ============================================
export const emotionRecords = pgTable("emotion_records", {
  id: serial("id").primaryKey(),
  sessionId: varchar("session_id").notNull().references(() => sessions.id, { onDelete: "cascade" }),
  timestamp: timestamp("timestamp").defaultNow().notNull(),
  emotion: text("emotion").notNull(), // 'happy', 'sad', 'angry', 'fear', 'surprise', 'neutral'
  confidence: real("confidence").notNull(), // 0-100
  stressLevel: real("stress_level").notNull(), // 0-100
  // Detailed emotion scores from DeepFace
  emotionScores: jsonb("emotion_scores").$type<{
    happy?: number;
    sad?: number;
    angry?: number;
    fear?: number;
    surprise?: number;
    neutral?: number;
    disgust?: number;
  }>(),
  // Additional face analysis data
  faceData: jsonb("face_data").$type<{
    age?: number;
    gender?: string;
    race?: string;
    faceConfidence?: number;
  }>(),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================
// VIDEO_SESSIONS TABLE - Legacy/Alternative video session tracking
// Can be used for storing summarized video sessions
// ============================================
export const videoSessions = pgTable("video_sessions", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: varchar("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  sessionId: varchar("session_id").references(() => sessions.id, { onDelete: "set null" }),
  date: timestamp("date").defaultNow().notNull(),
  duration: integer("duration").notNull(), // in seconds
  dominantEmotion: text("dominant_emotion").notNull(),
  emotionData: jsonb("emotion_data").$type<{
    happy?: number;
    sad?: number;
    angry?: number;
    fear?: number;
    surprise?: number;
    neutral?: number;
  }>().notNull(),
  averageConfidence: real("average_confidence"),
  averageStress: real("average_stress"),
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================
// VOICE_JOURNALS TABLE - Voice journal entries
// ============================================
export const voiceJournals = pgTable("voice_journals", {
  id: varchar("id").primaryKey().default(sql`gen_random_uuid()`),
  userId: varchar("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  sessionId: varchar("session_id").references(() => sessions.id, { onDelete: "set null" }),
  date: timestamp("date").defaultNow().notNull(),
  title: text("title").notNull(),
  content: text("content").notNull(),
  emotion: text("emotion").notNull(),
  confidence: real("confidence").notNull(), // changed from integer to real
  duration: integer("duration").notNull(), // in seconds
  audioUrl: text("audio_url"), // URL to stored audio file
  transcription: text("transcription"), // optional transcription
  createdAt: timestamp("created_at").defaultNow().notNull(),
});

// ============================================
// VALIDATION SCHEMAS
// ============================================

// Users
export const insertUserSchema = createInsertSchema(users).omit({
  createdAt: true,
  updatedAt: true,
});
export const selectUserSchema = createSelectSchema(users);

// Sessions
export const insertSessionSchema = createInsertSchema(sessions).omit({
  id: true,
  createdAt: true,
  updatedAt: true,
});
export const selectSessionSchema = createSelectSchema(sessions);

// Emotion Records
export const insertEmotionRecordSchema = createInsertSchema(emotionRecords).omit({
  id: true,
  createdAt: true,
});
export const selectEmotionRecordSchema = createSelectSchema(emotionRecords);

// Video Sessions
export const insertVideoSessionSchema = createInsertSchema(videoSessions).omit({
  id: true,
  createdAt: true,
});
export const selectVideoSessionSchema = createSelectSchema(videoSessions);

// Voice Journals
export const insertVoiceJournalSchema = createInsertSchema(voiceJournals).omit({
  id: true,
  createdAt: true,
});
export const selectVoiceJournalSchema = createSelectSchema(voiceJournals);

// ============================================
// TYPE EXPORTS
// ============================================

// User types
export type User = typeof users.$inferSelect;
export type InsertUser = z.infer<typeof insertUserSchema>;

// Session types
export type Session = typeof sessions.$inferSelect;
export type InsertSession = z.infer<typeof insertSessionSchema>;

// Emotion Record types
export type EmotionRecord = typeof emotionRecords.$inferSelect;
export type InsertEmotionRecord = z.infer<typeof insertEmotionRecordSchema>;

// Video Session types
export type VideoSession = typeof videoSessions.$inferSelect;
export type InsertVideoSession = z.infer<typeof insertVideoSessionSchema>;

// Voice Journal types
export type VoiceJournal = typeof voiceJournals.$inferSelect;
export type InsertVoiceJournal = z.infer<typeof insertVoiceJournalSchema>;

// ============================================
// UTILITY TYPES
// ============================================

// Emotion type for consistency
export type EmotionType = 'happy' | 'sad' | 'angry' | 'fear' | 'surprise' | 'neutral' | 'disgust';

// Session status type
export type SessionStatus = 'active' | 'paused' | 'completed';
