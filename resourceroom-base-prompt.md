# ResourceRoom — Product Requirements Document (PRD) AGENT PROMPT

> **Version:** 0.1 (Initial Draft)
> **Date:** 6 February 2026

---

## Note to Coding Agent

This PRD outline defines the vision, features, and constraints for **ResourceRoom**, a teacher resource collation and sharing platform. Your task is to use this document to:

1. **Confirm the full PRD by going through an initial analysis of the below**
1. **Design the full technical architecture** — database schema, API routes, service layer, third-party integrations, and infrastructure.
2. **Design the UI/UX** — page structure, component hierarchy, user flows, and responsive layout considerations.
3. **Break the work into epics and user story summaries** — with clear acceptance criteria, ordered by priority and dependency.

This is a **showcase project** intended to demonstrate to teachers (with no coding experience) how AI coding tools can be used to build real, useful software. The codebase should therefore prioritise:

- **Clarity over cleverness** — readable, well-structured code that a non-developer could follow with guidance.
- **Small, composable patterns** — each feature should follow a recognisable "fetch → store → display" loop so the build process is teachable.
- **Progressive complexity** — the architecture should allow features to be built incrementally, with each addition reinforcing patterns learned in the previous step.

The platform will be built live in workshop settings using AI coding tools (Claude Code, etc.), so the architecture must support building features in isolation without breaking other parts of the system.

---

## 1. Product Overview

### 1.1 Vision

ResourceRoom is a **teacher-owned resource library** that combines content curation, AI-powered resource generation, and secure student sharing into a single platform. It solves the "scattered resources" problem — teachers currently spread materials across Google Drive folders, YouTube playlists, browser bookmarks, email attachments, and departmental shared drives with no unified way to organise, enhance, or share them with students.

### 1.2 Target Users

| User Type | Description | Auth Method |
|-----------|-------------|-------------|
| **Teacher** | Primary user. Creates, curates, organises, and shares resources. | Email/password, Google OAuth |
| **Student** | Consumer of shared resource collections. Read-only access with minimal interaction. | Magic link (no PII required — display name only) |

### 1.3 Key Principles

- **Curation over creation** — AI generation is valuable, but the core proposition is helping teachers organise and share what already exists alongside what they create.
- **Zero student PII** — students access shared collections via magic links with a self-chosen display name. No email, no password, no account.
- **Useful on day one** — a teacher should get value from uploading their first PDF and sharing it, before they ever touch an AI feature.
- **Teachable architecture** — every feature is a self-contained example of a common web development pattern.

---

## 2. Tech Stack

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| **Framework** | Next.js (App Router) | Industry standard, excellent DX, good for workshop teaching |
| **Auth** | NextAuth.js + Supabase Auth | Email/password, Google OAuth, magic links for students |
| **Database** | Supabase (PostgreSQL) | Hosted, generous free tier, real-time subscriptions, RLS for multi-tenancy |
| **File Storage** | Supabase Storage | Co-located with database, simple API, RLS-compatible |
| **AI Inference** | OpenRouter and/or Scaleway | Model-agnostic routing, cost-effective, good for demonstrating AI integration |
| **Styling** | Tailwind CSS + shadcn/ui | Rapid, consistent UI — good for workshops where design isn't the focus |
| **Deployment** | Vercel | Zero-config Next.js deployment, free tier suitable for demo |

---

## 3. Feature Specification

### 3.1 Authentication & User Management

#### 3.1.1 Teacher Authentication

- Email/password registration and login via NextAuth.js
- Google OAuth as alternative sign-in method
- Password reset flow via email
- Session management with JWT tokens
- Profile page: name, school/organisation (optional), subject areas (tags)

#### 3.1.2 Student Access (Magic Links)

- Teacher generates a **share link** (unique URL) or **QR code** for any resource collection
- Student clicks link → enters a self-chosen display name → gains read-only access to that specific collection
- No email, no password, no persistent account
- Access is scoped: a magic link grants access only to the specific collection it was created for
- Teacher can revoke any share link at any time
- Optional: share links can have an expiry date

#### 3.1.3 Access Control Model

- Teachers have full CRUD on their own resources and collections
- Students have read-only access to shared collections, plus optional lightweight interactions (starring, commenting)
- Row Level Security (RLS) in Supabase ensures teachers can never see each other's content
- Share links are validated server-side on every request

---

### 3.2 Resource Library (Core Feature)

The resource library is the heart of the platform. Every resource, regardless of source, is stored as a unified record with consistent metadata.

#### 3.2.1 Unified Resource Model

Every resource has:

- **Title** (editable)
- **Description** (editable, can be AI-generated)
- **Type** — one of: `document`, `link`, `video`, `podcast`, `ai_generated`, `image`
- **Source** — one of: `upload`, `youtube`, `podcast_search`, `web_link`, `rss_feed`, `ai_generated`
- **Tags** — subject, topic, year group, custom tags
- **Thumbnail** — auto-generated or fetched from source
- **AI Summary** — optional, generated on demand
- **AI Questions** — optional, generated on demand (comprehension/discussion questions)
- **Collections** — which collections this resource belongs to
- **Created/updated timestamps**
- **Owner** (teacher user ID)

#### 3.2.2 Resource Sources

##### A. File Uploads

- Drag-and-drop or file picker upload
- Supported types: PDF, DOCX, PPTX, images (PNG, JPG, GIF), plain text
- Files stored in Supabase Storage, scoped to the teacher's user ID
- Auto-extract filename as default title
- AI-assisted tagging: on upload, AI reads the document (or filename/metadata for images) and suggests subject/topic/year group tags

##### B. YouTube Video Search & Save

- In-app search using the **YouTube Data API v3**
- Display results with thumbnail, title, channel, duration, view count
- One-click save to library — stores video ID, metadata, and thumbnail URL
- On save, optionally fetch the video transcript (YouTube Transcript API) and pass to AI for:
  - Auto-generated summary
  - Comprehension questions at specified difficulty level
- **Clip support**: teacher can specify start and end timestamps to direct students to a specific segment
- Embedded playback within the platform (YouTube iframe embed)

##### C. Podcast Discovery & Save

- Search using **Podcast Index API** (free, open) or **Listen Notes API** (free tier)
- Display results with podcast name, episode title, description, duration
- One-click save to library — stores episode metadata and audio URL
- AI summary generated from episode description (or transcript if available via API)
- Audio playback embedded within the platform

##### D. Web Link Bookmarking

- Teacher pastes any URL
- Platform fetches **Open Graph metadata** (title, description, image) automatically
- Optionally fetches page content for AI summarisation
- AI suggests tags based on content
- Stored as a rich bookmark with preview card

##### E. RSS Feed Subscriptions

- Teacher subscribes to RSS/Atom feed URLs
- Suggested feeds provided for common educational sources (BBC Bitesize, TES, Guardian Education, subject-specific blogs)
- New feed items appear in a dedicated "Feed" view
- One-click save from feed to library
- AI can optionally scan new feed items and flag those matching the teacher's active topics/tags
- Feed refresh on configurable schedule (or on page load)

##### F. AI-Generated Resources

- Teacher provides a topic, year group, and resource type, and AI generates:
  - **Question sets** — multiple choice, short answer, extended response, with differentiation levels
  - **Discussion prompts** — open-ended questions for classroom discussion
  - **Vocabulary lists** — key terms with definitions and example sentences
  - **Reading comprehension tasks** — passages with accompanying questions (AI generates both)
  - **Starter/hook activities** — lesson opener ideas for a given topic
- Generated resources are saved to the library like any other resource
- Teacher can edit, regenerate, or refine any generated content before saving
- All generated content clearly labelled as AI-generated

---

### 3.3 Organisation & Discovery

#### 3.3.1 Tagging System

- **Predefined tag categories**: Subject, Topic, Year Group / Key Stage, Resource Type
- **Custom tags**: teachers can create any additional tags
- Tags are scoped to the individual teacher (no global tag namespace to manage)
- AI-assisted tagging on all resource types — suggestions presented on save, teacher confirms or edits
- Bulk tagging: select multiple resources and apply/remove tags

#### 3.3.2 Collections

- Named groups of resources, manually curated by the teacher
- A resource can belong to multiple collections
- Collections have: name, description (optional), cover image (optional), subject/topic tags
- Example: "Year 9 Climate Change Unit" containing a mix of uploaded PDFs, YouTube videos, podcast episodes, and AI-generated question sheets
- Collections are the **unit of sharing** — when a teacher shares with students, they share a collection

#### 3.3.3 Smart Collections (v1.5 — stretch goal)

- Auto-updating collections based on saved search criteria
- Example: "All Biology + KS4 resources added in the last 30 days"
- Implemented as stored filters applied at query time

#### 3.3.4 Search & Filter

- Full-text search across resource titles, descriptions, and AI summaries
- Filter by: tag, type, source, collection, date range
- Sort by: date added, title, most used (if tracking views)

---

### 3.4 Secure Sharing (Student-Facing)

#### 3.4.1 Share Links

- Teacher selects a collection and generates a share link
- Options when creating a share link:
  - **Expiry date** (optional) — link stops working after this date
  - **Require display name** (default: yes) — student must enter a name before accessing
  - **Allow interactions** (default: no) — if enabled, students can star resources and leave comments
- Share link generates both a URL and a QR code (displayed in-app, downloadable as image)
- Teacher dashboard shows all active share links with usage stats (number of accesses)

#### 3.4.2 Student View

- Clean, distraction-free read-only view of the collection
- Resources displayed as cards with consistent layout regardless of type
- Videos play inline (YouTube embed)
- Podcasts play inline (audio player)
- PDFs viewable inline (PDF viewer) or downloadable
- Links open in new tab
- AI-generated resources displayed as formatted text

#### 3.4.3 Student Interactions (Optional, Per-Collection)

- **Star/favourite**: students can mark resources they found helpful — anonymous signal back to the teacher
- **Comments/questions**: simple thread per resource — teacher can see and respond
- **Exit ticket**: teacher can attach a question to the collection — students respond, AI summarises responses and flags themes/misconceptions for the teacher

---

### 3.5 AI Features (Cross-Cutting)

All AI features use OpenRouter or Scaleway as the inference provider. The AI integration layer should be abstracted so the model and provider can be swapped without changing feature code.

#### 3.5.1 Resource Summarisation

- Available for: YouTube videos (via transcript), web links (via page content), uploaded documents (via text extraction), podcast episodes (via description/transcript)
- Triggered manually by teacher ("Summarise this") or optionally on save
- Summary stored alongside the resource for display and search indexing

#### 3.5.2 Question Generation

- Available for any resource with text content or a summary
- Teacher selects: number of questions, difficulty level / Bloom's taxonomy level, question type (MCQ, short answer, extended)
- Generated questions saved as a linked "AI-generated" resource or as metadata on the source resource

#### 3.5.3 Auto-Tagging

- On resource creation/save, AI analyses available content and suggests tags
- Presented as clickable suggestions the teacher can accept, reject, or edit
- Uses the teacher's existing tag vocabulary where possible (avoids creating redundant tags)

#### 3.5.4 Feed Relevance Scoring (v1.5 — stretch goal)

- When new RSS feed items arrive, AI scores them against the teacher's active topics
- High-relevance items surfaced with a highlight in the feed view

#### 3.5.5 Response Summarisation (Exit Tickets)

- When students submit exit ticket responses, AI generates:
  - A thematic summary of responses
  - Key misconceptions identified
  - Suggested follow-up actions
- Presented in the teacher dashboard alongside the raw responses

---

### 3.6 Teacher Dashboard

- **Library overview**: total resources by type, recent additions, quick access to collections
- **Active share links**: which collections are currently shared, how many students have accessed them, expiry dates
- **Feed updates**: recent items from subscribed RSS feeds, flagged items
- **Student activity** (when interactions are enabled): recent comments, exit ticket responses, star counts
- **Quick actions**: upload resource, search YouTube, create AI resource, create collection

---

## 4. Non-Functional Requirements

### 4.1 Performance

- Page loads under 2 seconds on standard broadband
- AI operations should show streaming responses where possible (summary generation, question generation)
- YouTube and podcast search results should feel near-instant (client-side debounced search)

### 4.2 Security

- All data access governed by Supabase RLS — teachers can only access their own resources
- Share links validated server-side on every request
- File uploads scanned for type validation (no executable files)
- AI prompts should not leak teacher or student data to third-party models beyond what is necessary for the feature (document this clearly)
- Student display names are the only student data stored — no analytics tracking, no cookies beyond session

### 4.3 Accessibility

- WCAG 2.1 AA compliance target
- Keyboard navigable throughout
- Screen reader compatible (proper ARIA labels, semantic HTML)
- Sufficient colour contrast in all UI states

### 4.4 Data Privacy & Compliance

- No student PII collected or stored
- Teacher data stored in Supabase (EU region available if needed for UK GDPR compliance)
- AI inference via OpenRouter/Scaleway — document which data is sent to which models
- Clear privacy notice explaining what data is stored and how AI features use content
- Teachers can export all their data (resources, collections, tags) and delete their account

### 4.5 Scalability Considerations

- Supabase free tier supports the workshop/demo context
- Architecture should not preclude scaling, but optimising for scale is not a v1 priority
- File storage limits should be documented and surfaced to users (e.g., 100MB per teacher on free tier)

---

## 5. Out of Scope (v1)

The following are explicitly **not** in scope for the initial build. They may be considered for future versions.

- Real-time collaboration between teachers
- School-level admin roles or multi-tenancy beyond individual teacher accounts
- Integration with school MIS (SIMS, Arbor, Bromcom, etc.)
- Native mobile app (responsive web is sufficient)
- Offline access
- Payment/subscription system
- Content moderation beyond AI safety guardrails
- Direct messaging between teachers and students
- LTI integration with VLEs (Google Classroom, Teams, etc.) — though share links serve a similar purpose
- Advanced analytics or reporting dashboards

---

## 6. Success Metrics

For the **workshop context** (primary use case):

- A teacher with no coding experience can understand how each feature was built after a guided walkthrough
- The full platform can be built incrementally across a series of workshop sessions (or independently with AI coding tools)
- Each feature addition takes under 2 hours to implement with AI coding assistance

For the **product context** (secondary — if teachers actually use it):

- Teacher creates their first collection within 10 minutes of signing up
- Teacher shares their first collection with students within their first session
- Average teacher library contains 20+ resources after one month of use
- Student access via magic link works first time, every time, with no support needed

---

## 7. Open Questions

1. **Naming**: "ResourceRoom" is a working title. Alternatives worth considering?
2. **YouTube API quotas**: The free tier is 10,000 units/day. Is this sufficient for a workshop demo? Do we need a fallback?
3. **AI cost management**: Should we implement per-teacher usage limits for AI features, or is this unnecessary for the demo context?
4. **File storage limits**: What's a reasonable per-teacher storage cap for the free tier?
5. **RSS feed refresh frequency**: Real-time vs. on-demand vs. scheduled (hourly/daily)?
6. **Podcast API choice**: Podcast Index (fully free/open) vs. Listen Notes (better search, limited free tier)?
7. **Should collections be shareable between teachers** (not just with students)? This adds complexity but could be valuable.
8. **Export formats**: Should teachers be able to export AI-generated resources as DOCX/PDF for offline use?

---

## 8. Appendix: Workshop Teaching Narrative

Each major feature maps to a teachable web development concept:

| Feature | Concepts Taught |
|---------|----------------|
| Auth (email/password) | User management, sessions, security basics |
| Auth (Google OAuth) | Third-party authentication, OAuth flow |
| Auth (magic links) | Passwordless auth, token-based access, QR codes |
| File uploads | File storage, blob handling, type validation |
| YouTube search | REST API integration, API keys, search UI patterns |
| Podcast search | Same pattern, different API — reinforces learning |
| Web link previews | Web scraping basics, Open Graph protocol |
| RSS feeds | Feed parsing, scheduled tasks, data pipelines |
| AI summarisation | LLM API calls, prompt engineering, streaming responses |
| AI question generation | Structured output from LLMs, prompt templates |
| Auto-tagging | AI-assisted metadata, human-in-the-loop design |
| Collections & sharing | Data relationships, access control, URL-based auth |
| Student view | Public-facing read-only views, security considerations |
| Dashboard | Data aggregation, charts/visualisation basics |

This sequence allows the workshop to build complexity gradually while each step produces a working, demonstrable feature.

---

*End of PRD v0.1*
