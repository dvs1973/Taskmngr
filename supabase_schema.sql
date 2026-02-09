-- ================================================================
-- TaskFlow Supabase Database Schema
-- ================================================================
-- Run this SQL in Supabase SQL Editor after creating your project
-- This creates all tables, indexes, and security policies

-- ================================================================
-- TABLES
-- ================================================================

-- Projects table
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  "order" INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tags table
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL
);

-- Tasks table
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  project_id TEXT REFERENCES projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  priority TEXT DEFAULT 'none',
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  "order" INTEGER DEFAULT 9999,
  tags TEXT[] DEFAULT '{}',
  subtasks JSONB DEFAULT '[]',
  recurrence JSONB DEFAULT '{"type":"none","interval":1}'
);

-- User Preferences table
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_project_id TEXT,
  filters JSONB DEFAULT '{}',
  theme TEXT DEFAULT 'light',
  sidebar_open BOOLEAN DEFAULT TRUE,
  view_mode TEXT DEFAULT 'list',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================================
-- INDEXES (voor betere query performance)
-- ================================================================

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_projects_user_id ON projects(user_id);
CREATE INDEX idx_tags_user_id ON tags(user_id);

-- ================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ================================================================
-- Dit zorgt ervoor dat gebruikers alleen hun eigen data kunnen zien/bewerken

-- Enable RLS op alle tables
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Gebruikers kunnen ALLE operaties uitvoeren op hun eigen data
CREATE POLICY "Users access own projects" ON projects
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users access own tags" ON tags
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users access own tasks" ON tasks
  FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Users access own prefs" ON user_preferences
  FOR ALL
  USING (auth.uid() = user_id);

-- ================================================================
-- VERIFICATIE QUERIES
-- ================================================================
-- Run deze queries om te checken of alles correct is aangemaakt

-- Check tables
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- Check RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Check policies
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ================================================================
-- NOTES
-- ================================================================
-- 1. De "order" kolom heet "order" met quotes omdat ORDER een SQL keyword is
-- 2. JSONB columns (subtasks, recurrence, filters) accepteren JSON data
-- 3. TEXT[] is een PostgreSQL array voor tags (bijv. ['urgent', 'work'])
-- 4. CASCADE DELETE zorgt dat tasks worden verwijderd als project wordt verwijderd
-- 5. auth.uid() is een Supabase function die de ingelogde user ID returnt
-- 6. RLS policies gebruiken USING clause voor SELECT/UPDATE/DELETE permissions
-- 7. FOR ALL betekent de policy geldt voor SELECT, INSERT, UPDATE, en DELETE

-- ================================================================
-- OPTIONAL: Sample Data voor Testing
-- ================================================================
-- Uncomment deze queries om test data te maken (na eerste login)

/*
-- Voeg sample project toe (vervang USER_ID met je eigen user ID)
INSERT INTO projects (id, user_id, name, color, "order", created_at, updated_at)
VALUES ('test-project-1', 'YOUR_USER_ID', 'Sample Project', '#5b6af0', 0, NOW(), NOW());

-- Voeg sample task toe
INSERT INTO tasks (id, user_id, project_id, title, description, priority, "order", created_at, updated_at)
VALUES ('test-task-1', 'YOUR_USER_ID', 'test-project-1', 'Sample Task', 'This is a test task', 'high', 0, NOW(), NOW());

-- Check data
SELECT * FROM projects;
SELECT * FROM tasks;
*/
