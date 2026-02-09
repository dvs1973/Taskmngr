# TaskFlow Supabase Setup Gids

## Stap 1: Maak een Supabase Project

1. Ga naar https://supabase.com
2. Klik op "New Project"
3. Vul in:
   - **Project name**: taskflow-db (of een andere naam naar keuze)
   - **Database Password**: Kies een sterk wachtwoord (bewaar dit veilig)
   - **Region**: Europe West (eu-west-1) - Amsterdam
4. Klik op "Create new project"
5. Wacht tot het project is aangemaakt (~2 minuten)

## Stap 2: Verkrijg API Credentials

1. Ga naar **Project Settings** (tandwiel icoon linksonder)
2. Klik op **API** in het menu
3. Kopieer de volgende waarden:
   - **Project URL** (bijv. `https://abcdefghijk.supabase.co`)
   - **anon public** key (lange string die begint met `eyJhb...`)

## Stap 3: Database Schema Aanmaken

1. Ga naar **SQL Editor** in het linker menu
2. Klik op **New query**
3. Plak de volgende SQL en klik op **Run**:

```sql
-- Projects
CREATE TABLE projects (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL,
  "order" INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tags
CREATE TABLE tags (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  color TEXT NOT NULL
);

-- Tasks
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

-- User Preferences
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  active_project_id TEXT,
  filters JSONB DEFAULT '{}',
  theme TEXT DEFAULT 'light',
  sidebar_open BOOLEAN DEFAULT TRUE,
  view_mode TEXT DEFAULT 'list',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes voor betere performance
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_project_id ON tasks(project_id);
CREATE INDEX idx_projects_user_id ON projects(user_id);

-- Row-Level Security (RLS) inschakelen
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Gebruikers kunnen alleen hun eigen data zien/bewerken
CREATE POLICY "Users access own projects" ON projects FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users access own tags" ON tags FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users access own tasks" ON tasks FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users access own prefs" ON user_preferences FOR ALL USING (auth.uid() = user_id);
```

## Stap 4: Email Authenticatie Inschakelen

1. Ga naar **Authentication** → **Providers** in het linker menu
2. Zoek **Email** en zet deze aan (toggle naar rechts)
3. Klik op **Save**

## Stap 5: (Optioneel) Google OAuth Inschakelen

1. Ga naar **Authentication** → **Providers**
2. Zoek **Google** en klik erop
3. Zet Google provider aan
4. Je moet een Google OAuth Client ID en Secret aanmaken:
   - Ga naar https://console.cloud.google.com/
   - Maak een nieuw project of selecteer een bestaand project
   - Ga naar **APIs & Services** → **Credentials**
   - Klik **Create Credentials** → **OAuth 2.0 Client ID**
   - Kies **Web application**
   - Voeg toe aan **Authorized redirect URIs**: `https://[jouw-project-id].supabase.co/auth/v1/callback`
   - Kopieer de Client ID en Client Secret naar Supabase
5. Klik op **Save**

## Stap 6: Update index.html met je Credentials

Open `C:\Users\danny\index.html` en zoek naar regels ~917-918:

```javascript
const SUPABASE_URL = 'https://jouwproject.supabase.co'; // Vervang met echte URL
const SUPABASE_ANON_KEY = 'eyJhb...'; // Vervang met echte key
```

Vervang deze waarden met de credentials uit Stap 2:

```javascript
const SUPABASE_URL = 'https://abcdefghijk.supabase.co'; // Jouw Project URL
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'; // Jouw anon key
```

## Stap 7: Test de Implementatie

1. Open TaskFlow in je browser (lokaal of op Vercel)
2. Je zou een **Sign In** knop moeten zien in de header
3. Klik op **Sign In**
4. Klik op **Sign Up**
5. Vul een email en wachtwoord in
6. Check je email voor de verificatie link
7. Klik op de link om je account te verifiëren
8. Log in met je email en wachtwoord
9. Je bestaande lokale taken worden automatisch gemigreerd naar de cloud!

## Stap 8: Test Multi-Device Sync

1. Log in op device 1 (bijv. laptop)
2. Maak een nieuwe taak
3. Open TaskFlow op device 2 (bijv. telefoon of incognito venster)
4. Log in met hetzelfde account
5. Je zou de taak binnen 2 seconden moeten zien verschijnen!

## Troubleshooting

### "Sync failed" melding
- Check of je API credentials correct zijn ingevuld
- Open Developer Console (F12) en check de Console tab voor errors
- Verifieer dat de database schema correct is aangemaakt in Supabase

### Email verificatie werkt niet
- Check je spam folder
- Ga naar Supabase → **Authentication** → **Email Templates** om de templates aan te passen
- Voor development kun je auto-confirm emails inschakelen in **Authentication** → **Settings**

### Taken verschijnen niet op andere devices
- Check of je bent ingelogd met hetzelfde account op beide devices
- Verifieer dat Real-time is ingeschakeld in Supabase (standaard aan)
- Open Console en check voor WebSocket connection errors

### "Cannot read property 'auth' of undefined"
- Supabase SDK is niet correct geladen
- Check of de CDN script tag correct is toegevoegd aan index.html (regel ~701)
- Probeer de pagina te refreshen

## Feature Flags

Je kunt cloud sync tijdelijk uitschakelen door in index.html te wijzigen:

```javascript
const ENABLE_SYNC = false; // Sync uitgeschakeld, werkt weer 100% lokaal
```

## Vercel Deployment

Als je TaskFlow al hebt gedeployed op Vercel:

1. Commit de wijzigingen aan index.html naar Git
2. Push naar GitHub
3. Vercel zal automatisch de nieuwe versie deployen
4. De applicatie werkt direct met cloud sync!

## Kosten

Supabase gratis tier:
- ✅ 500MB database storage
- ✅ 50K active users per maand
- ✅ Unlimited API requests
- ✅ Real-time subscriptions
- ✅ 2GB bandwidth per maand

Dit is **meer dan genoeg** voor persoonlijk gebruik! 🎉

## Veiligheid

- ✅ **Row-Level Security (RLS)**: Elke gebruiker kan alleen zijn eigen data zien
- ✅ **Anon key is veilig**: De anon key mag publiek zijn, RLS beschermt je data
- ✅ **HTTPS**: Alle communicatie is encrypted
- ✅ **JWT tokens**: Automatische authenticatie via secure tokens
- ✅ **Password hashing**: Wachtwoorden worden veilig opgeslagen door Supabase

## Volgende Stappen

Nu je cloud sync hebt, kun je overwegen:

- 📱 **Progressive Web App (PWA)**: Voeg een manifest.json toe om TaskFlow als app te installeren
- 🔔 **Push notifications**: Herinneringen voor taken met deadlines
- 👥 **Gedeelde projecten**: Werk samen met anderen aan taken
- 📊 **Analytics**: Track je productiviteit over tijd
- 🎨 **Custom themes**: Upload je eigen kleurenschema's naar de cloud

Veel plezier met je nieuwe cloud-synced TaskFlow! 🚀
