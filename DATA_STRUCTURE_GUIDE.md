# Agency OS - Complete Data Structure Guide

**Last Updated:** October 16, 2025
**Database:** SQLite (development), PostgreSQL (production-ready)
**System:** Directus headless CMS with n8n workflow automation

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Core Hierarchy](#core-hierarchy)
3. [Collection Groups](#collection-groups)
4. [Detailed Collection Reference](#detailed-collection-reference)
5. [Relationship Map](#relationship-map)
6. [Key Workflows](#key-workflows)
7. [Data Flow Diagrams](#data-flow-diagrams)

---

## System Overview

Agency OS is an agentic workplace system designed for AI + human collaboration on client projects. The data structure supports:

- **Sales Pipeline:** Organizations → Opportunities → Projects
- **Project Management:** Templates → Projects → Tasks → Executions
- **Artifact Management:** Tasks generate versioned artifacts (files + metadata) that flow into project context
- **Approval Workflows:** Human review and approval of AI-generated outputs
- **Audit Trail:** Complete history of changes, executions, and approvals

### Design Principles

1. **Loose Coupling:** Tasks read from `project.context`, not from other tasks
2. **Immutable History:** Never delete versions; status changes only
3. **Optimistic Locking:** `context_version` prevents race conditions
4. **Hybrid Storage:** JSON cache + relational tables + file storage
5. **Pull Model:** Tasks pull approved artifacts from context (not pushed)

---

## Core Hierarchy

```
┌─────────────────────────────────────────────────────────────────┐
│  SALES LAYER                                                    │
│  Organizations → Opportunities → Companies → Clients            │
└─────────────────────────────────────────────────────────────────┘
                            ↓ win
┌─────────────────────────────────────────────────────────────────┐
│  PROJECT LAYER                                                  │
│  Templates → Template Versions → Projects                       │
└─────────────────────────────────────────────────────────────────┘
                            ↓ spawns
┌─────────────────────────────────────────────────────────────────┐
│  EXECUTION LAYER                                                │
│  Tasks → Task Executions → Jobs                                 │
└─────────────────────────────────────────────────────────────────┘
                            ↓ produces
┌─────────────────────────────────────────────────────────────────┐
│  ARTIFACT LAYER                                                 │
│  Artifact Versions → Artifact Approvals → Project Context       │
└─────────────────────────────────────────────────────────────────┘
                            ↓ references
┌─────────────────────────────────────────────────────────────────┐
│  STORAGE LAYER                                                  │
│  directus_files (physical files) + Documents (metadata)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Collection Groups

### 1. Sales & CRM (4 collections)
- **organizations** - Client companies and partners
- **companies** - Global company registry
- **clients** - Individual contacts
- **opportunities** - Sales deals and pipeline

### 2. Project Structure (3 collections)
- **templates** - Project templates (parent)
- **template_versions** - Versioned template definitions
- **projects** - Active client projects with context cache

### 3. Task Execution (4 collections)
- **tasks** - Work items (AI or human)
- **task_dependencies** - Task ordering and prerequisites
- **task_executions** - AI execution metrics and SLA tracking
- **jobs** - Background job queue and monitoring

### 4. Artifact System (5 collections)
- **artifact_versions** - Version registry for all task outputs
- **artifact_approvals** - Audit log of approval actions
- **artifact_files** - M2M junction (artifacts ↔ files)
- **task_artifacts** - M2M junction (tasks ↔ artifacts)
- **documents** - Document metadata and lineage

### 5. System Collections (Directus Built-in)
- **directus_files** - Physical file storage
- **directus_users** - System users
- **directus_roles** - Permission management

---

## Detailed Collection Reference

### Sales & CRM Layer

#### **organizations**
**Purpose:** Client companies and partners in the sales pipeline

**Key Fields:**
- `name` (string, required) - Organization name
- `slug` (string, unique) - URL-friendly identifier
- `status` (enum) - lead, prospect, customer, partner, inactive
- `industry` (enum) - technology, finance, healthcare, etc.
- `company_size` (enum) - 1-10, 11-50, 51-200, etc.
- `website`, `email`, `phone` - Contact info
- `address_*` - Street, city, state, postal, country
- `annual_revenue` (decimal) - USD
- `logo` (UUID → directus_files) - Company logo
- `tags` (JSON array) - Flexible tagging

**Use Cases:**
- Lead generation and qualification
- Sales pipeline tracking
- Client segmentation

**View:** http://localhost:8055/admin/content/organizations

---

#### **companies**
**Purpose:** Global company registry (clients, suppliers, partners)

**Key Fields:**
- `name` (string, required)
- `legal_name` (string) - Official legal name
- `type` (enum) - client, supplier, partner, competitor, other
- `industry` (enum) - Same as organizations
- `website`, `email`, `phone`
- `address`, `city`, `state`, `postal_code`, `country`
- `employee_count` (integer)
- `annual_revenue` (decimal)
- `logo` (UUID → directus_files)
- `status` (enum) - active, inactive, prospect

**Difference from Organizations:**
- More general purpose (not just clients)
- Single address field vs structured address
- Employee count vs size range

**View:** http://localhost:8055/admin/content/companies

---

#### **clients**
**Purpose:** Individual contacts within organizations

**Key Fields:**
- `first_name`, `last_name` (string, required)
- `email` (string, unique, required)
- `phone` (string)
- `company_id` (UUID → companies) - Employer
- `title` (string) - Job title
- `status` (enum) - active, inactive, lead
- `avatar` (UUID → directus_files) - Profile photo
- `linkedin` (string) - Profile URL
- `tags` (JSON array)

**Relationships:**
- M2O → companies (via company_id)
- Referenced by opportunities, projects

**View:** http://localhost:8055/admin/content/clients

---

#### **opportunities**
**Purpose:** Sales deals and pipeline management

**Key Fields:**
- `title` (string, required) - Deal name
- `company_id` (UUID → companies)
- `client_id` (UUID → clients) - Primary contact
- `value` (decimal, required) - Deal value in USD
- `stage` (enum) - lead, qualified, proposal, negotiation, closed_won, closed_lost
- `probability` (integer) - Win probability 0-100%
- `expected_close_date`, `actual_close_date` (date)
- `description`, `notes` (text)
- `tags` (JSON array)

**Workflow:**
- Lead → Qualified → Proposal → Negotiation → Closed Won → Project Created

**View:** http://localhost:8055/admin/content/opportunities

---

### Project Structure Layer

#### **templates**
**Purpose:** Parent collection for versioned project workflows

**Key Fields:**
- `name` (string, required) - Template name
- `slug` (string, unique)
- `description` (text)
- `category` (enum) - client_work, internal_project, sales_process, operations, custom
- `icon` (string) - Material icon name for UI
- `status` (enum) - draft, active, deprecated, archived
- `owner_id` (UUID → directus_users)
- `is_public` (boolean) - Available to all users?
- `usage_count` (integer) - Total projects created
- `tags` (JSON array)

**Relationships:**
- O2M → template_versions (has many versions)
- Referenced by projects

**View:** http://localhost:8055/admin/content/templates

---

#### **template_versions**
**Purpose:** Immutable template snapshots with changelog

**Key Fields:**
- `template_id` (UUID → templates, required)
- `version_number` (string, required) - Semantic version (1.0.0, 1.1.0, 2.0.0)
- `status` (enum) - draft, published, deprecated, archived
- `is_latest` (boolean) - Current recommended version
- `published_at`, `published_by` (timestamp, UUID → directus_users)
- `deprecated_at` (timestamp)
- `changelog` (rich text) - What changed
- `breaking_changes` (boolean)
- `template_definition` (JSON) - Immutable structure snapshot
- `pre_seeded_tasks` (JSON) - Default tasks to create
- `database_schemas` (JSON) - Schemas to initialize
- `automation_hooks` (JSON) - Workflow triggers
- `form_inputs` (JSON) - User inputs during project creation
- `usage_count` (integer) - Projects using this version
- `min_client_version` (string) - Minimum app version required

**Immutability:**
- Once published, template_definition CANNOT be edited
- Create new version for changes
- Old versions remain available for project history

**View:** http://localhost:8055/admin/content/template_versions

---

#### **projects**
**Purpose:** Active client projects with accumulated knowledge

**Key Fields:**
- `title` (string, required) - Project name
- `slug` (string, unique)
- `description` (rich text)
- `company_id` (UUID → companies) - Client company
- `opportunity_id` (UUID → opportunities) - Related sales deal
- `lifecycle_status` (enum) - draft, active, on_hold, done, archived
- `template_id` (UUID → template_versions) - Template used
- `template_version` (string) - Version pinned at creation
- `start_date`, `due_date`, `completed_date` (date)
- `budget` (decimal) - USD
- `priority` (enum) - low, medium, high, critical
- `context` (JSON) - **PROJECT KNOWLEDGE BASE** (see below)
- `context_version` (integer, default 0) - **Optimistic locking version**
- `notes`, `tags` (text, JSON array)

**Context Structure (JSON):**
```json
{
  "brand": {
    "logo": {
      "artifact_version_id": "uuid-123",
      "file_id": "uuid-456",
      "approved_at": "2025-10-16T10:30:00Z",
      "version": 1,
      "metadata": {"dimensions": "1000x1000", "format": "PNG"}
    },
    "colors": {
      "artifact_version_id": "uuid-789",
      "primary": "#1A365D",
      "secondary": "#2C7A7B",
      "accent": "#ED8936"
    }
  },
  "deliverables": {
    "business_card": {
      "artifact_version_id": "uuid-101",
      "file_id": "uuid-102"
    }
  },
  "_meta": {
    "schema_version": "1.0.0",
    "last_updated": "2025-10-16T14:00:00Z",
    "context_version": 5,
    "total_artifacts": 3
  }
}
```

**Context Version (Optimistic Locking):**
- Every update increments `context_version`
- Concurrent updates check: `WHERE context_version = expected_version`
- If mismatch → 409 Conflict → client must refresh and retry
- Prevents "last write wins" bugs

**Relationships:**
- M2O → companies, opportunities, template_versions
- O2M → tasks, documents, artifact_versions

**View:** http://localhost:8055/admin/content/projects

---

### Task Execution Layer

#### **tasks**
**Purpose:** Work items executed by AI or humans

**Key Fields:**
- `title` (string, required)
- `description` (rich text)
- `project_id` (UUID → projects, required)
- `status` (enum) - new, in_progress, needs_review, done, rejected
- `assigned_to` (UUID → directus_users)
- `execution_type` (enum) - ai, human, hybrid
- `due_date` (timestamp)
- `sla_minutes` (integer) - Target completion time
- `priority` (enum) - low, medium, high, critical
- `output` (rich text) - Task result
- `artifacts` (M2M → artifact_versions via task_artifacts) - **Generated artifacts**
- `notes`, `tags` (text, JSON array)

**Status Workflow:**
```
new → in_progress → needs_review → done
                         ↓
                    rejected → (loops back to in_progress)
```

**Relationships:**
- M2O → projects
- O2M → task_executions, artifact_versions
- M2M → artifact_versions (via task_artifacts junction)
- Self-referencing via task_dependencies

**View:** http://localhost:8055/admin/content/tasks

---

#### **task_dependencies**
**Purpose:** Define task ordering and prerequisites

**Key Fields:**
- `task_id` (UUID → tasks, required) - Dependent task
- `depends_on_task_id` (UUID → tasks, required) - Prerequisite task
- `dependency_type` (enum) - finish_to_start, start_to_start, finish_to_finish, soft
- `lag_time_hours` (integer, default 0) - Wait time after prerequisite
- `is_blocking` (boolean, default true) - Blocks task start?
- `notes` (text)

**Dependency Types:**
- **finish_to_start:** Task B starts after Task A finishes (most common)
- **start_to_start:** Task B starts when Task A starts (parallel work)
- **finish_to_finish:** Task B finishes when Task A finishes
- **soft:** Recommended order but not enforced

**View:** http://localhost:8055/admin/content/task_dependencies

---

#### **task_executions**
**Purpose:** AI execution metrics, SLA tracking, and quality measurements

**Key Fields:**
- `task_id` (UUID → tasks, required)
- `job_id` (UUID → jobs) - Background job reference
- `execution_type` (enum) - ai_single, ai_multi, human, hybrid
- `template_version` (string) - Prompt version used
- `started_at`, `completed_at` (timestamp)
- `duration_seconds` (integer)
- `sla_target_seconds` (integer)
- `met_sla` (boolean)
- `accuracy_band` (enum) - exact, high (95%+), medium (80-95%), low (<80%), failed
- `acceptance_status` (enum) - accepted_first, accepted_edited, rejected, pending
- `correction_count` (integer) - Number of edits made
- `corrections` (JSON array) - [{field, old_value, new_value}]
- `checker_user_id` (UUID → directus_users) - Reviewer
- `escalated` (boolean) - Escalated to human?
- `escalation_reason` (text)
- `automation_percentage` (decimal) - % of steps automated
- `cost_usd` (decimal) - AI API cost
- `tokens_used` (integer)
- `model_used` (string) - gpt-4, claude-3-sonnet, etc.
- `feedback_score` (integer 1-5) - User rating
- `feedback_text` (text)
- `training_data` (boolean) - Use for fine-tuning?
- `tags` (JSON array)

**Use Cases:**
- SLA monitoring and alerting
- Quality tracking and improvement
- Cost analysis per task type
- AI model performance comparison
- Training data collection

**View:** http://localhost:8055/admin/content/task_executions

---

#### **jobs**
**Purpose:** Background job queue and monitoring (n8n integration)

**Key Fields:**
- `job_id` (string, unique, required) - Idempotency key
- `type` (enum) - ai_task, internal_workflow, external_workflow, data_processing, template_execution
- `status` (enum) - pending, running, waiting, succeeded, failed, cancelled
- `progress_percent` (integer 0-100)
- `task_id` (UUID → tasks)
- `project_id` (UUID → projects)
- `template_id` (UUID → template_versions)
- `started_at`, `completed_at`, `last_heartbeat` (timestamp)
- `retry_count`, `max_retries` (integer)
- `input_payload`, `output_payload` (JSON)
- `error_message` (text)
- `logs` (JSON array)
- `callback_url` (string) - Webhook for external workflows
- `external_job_id` (string) - n8n execution ID
- `priority` (enum) - low, normal, high, critical
- `tags` (JSON array)

**Workflow Integration:**
- Directus creates job record
- n8n picks up job from queue
- n8n updates job status via API
- On completion, n8n calls callback_url
- Directus processes results

**View:** http://localhost:8055/admin/content/jobs

---

### Artifact System Layer

#### **artifact_versions**
**Purpose:** Complete version registry for all task outputs (files + metadata)

**Key Fields:**
- `project_id` (UUID → projects, required)
- `schema_key` (string, required) - Dot-notation path (e.g., "brand.logo", "deliverables.business_card")
- `status` (enum, required) - pending, approved, rejected, superseded
- `value` (JSON) - Structured data (colors, dimensions, extracted metadata)
- `primary_file_id` (UUID → directus_files) - Main/primary file
- `files` (M2M → directus_files via artifact_files) - All related files
- `source_task_id` (UUID → tasks) - Task that created this
- `execution_id` (UUID → task_executions) - Specific AI run
- `version_number` (integer, default 1) - Sequential version
- `approved_at` (timestamp)
- `approved_by` (UUID → directus_users)
- `rejection_reason` (text) - Learning data for AI
- `metadata` (JSON) - Additional metadata (dimensions, format, model used)
- `tags` (JSON array)

**Status Lifecycle:**
```
pending → approved (promoted to project.context)
     ↓
  rejected (learning data)

approved → superseded (when new version approved for same schema_key)
```

**Partial Unique Index:**
```sql
CREATE UNIQUE INDEX idx_one_approved_per_path
ON artifact_versions (project_id, schema_key)
WHERE status = 'approved';
```
Ensures only ONE approved artifact per schema_key per project.

**Relationships:**
- M2O → projects, tasks, task_executions, directus_files (primary_file_id)
- M2M → directus_files (via artifact_files junction)
- Referenced by artifact_approvals, documents

**View:** http://localhost:8055/admin/content/artifact_versions

---

#### **artifact_approvals**
**Purpose:** Complete audit trail of all approval/rejection actions

**Key Fields:**
- `artifact_version_id` (UUID → artifact_versions, required)
- `project_id` (UUID → projects, required)
- `task_id` (UUID → tasks)
- `action` (enum, required) - approve, reject, supersede, request_changes
- `actor_id` (UUID → directus_users, required) - Who performed action
- `actor_type` (enum) - human, ai, system, rule
- `reason` (text) - Why approved/rejected (learning data)
- `feedback` (JSON) - Structured feedback: {issues: ["color too dark", "logo unclear"]}
- `notes` (text)

**Use Cases:**
- Compliance and audit requirements
- AI learning from human feedback
- Understanding approval patterns
- Tracking who approved what and when

**Query Examples:**
```sql
-- All rejected logos for learning
SELECT av.file_ids, av.rejection_reason, aa.reason, aa.feedback
FROM artifact_versions av
LEFT JOIN artifact_approvals aa ON aa.artifact_version_id = av.id
WHERE av.schema_key = 'brand.logo' AND av.status = 'rejected';

-- Approval history for a project
SELECT av.schema_key, av.status, aa.actor_id, aa.reason
FROM artifact_versions av
LEFT JOIN artifact_approvals aa ON aa.artifact_version_id = av.id
WHERE av.project_id = 'project-uuid'
ORDER BY av.created_at DESC;
```

**View:** http://localhost:8055/admin/content/artifact_approvals

---

#### **artifact_files** (M2M Junction)
**Purpose:** Many-to-many relationship between artifact_versions and directus_files

**Key Fields:**
- `artifact_version_id` (UUID → artifact_versions, required)
- `directus_files_id` (UUID → directus_files, required)
- `sort` (integer) - Display order of files

**Why M2M instead of JSON array?**
- Foreign key constraints ensure referential integrity
- Can't delete files if they're linked to artifacts
- Efficient querying with JOINs (no JSON parsing)
- Proper indexing for performance
- Sort order for multi-file artifacts

**Hidden:** Yes (not shown in main navigation)

**View:** http://localhost:8055/admin/content/artifact_files

---

#### **task_artifacts** (M2M Junction)
**Purpose:** Many-to-many relationship between tasks and artifact_versions

**Key Fields:**
- `task_id` (UUID → tasks, required)
- `artifact_version_id` (UUID → artifact_versions, required)
- `sort` (integer) - Display order

**Replaces:** Previous `artifact_version_ids` JSON array in tasks

**Use Case:**
- Task generates 5 logo concepts → 5 artifact_versions
- All linked to task via this junction
- Human approves 1 → that artifact promoted to project.context
- Other 4 remain as "rejected" versions (learning data)

**Hidden:** Yes

**View:** http://localhost:8055/admin/content/task_artifacts

---

#### **documents**
**Purpose:** Document metadata registry with lineage tracking

**Key Fields:**
- `title` (string, required)
- `description` (text)
- `file_id` (UUID → directus_files, required) - Actual file
- `category` (enum) - contract, proposal, spec, report, legal, brand, other
- `project_id` (UUID → projects)
- `company_id` (UUID → companies)
- `version` (string) - v1.0, v2.1, etc.
- `status` (enum) - draft, review, approved, archived
- `created_by_ai` (boolean) - AI-generated?
- `artifact_version_id` (UUID → artifact_versions) - **Lineage tracking**
- `notes`, `tags` (text, JSON array)

**Artifact Lineage:**
- When artifact approved, optionally create document record
- `artifact_version_id` links document back to source artifact
- Enables tracking: "This contract was generated by Task X, Execution Y"

**Difference from artifact_versions:**
- Documents are for "final deliverables" or "important files"
- artifact_versions tracks ALL outputs (including rejected ones)
- Documents are user-facing, artifacts are system-level

**View:** http://localhost:8055/admin/content/documents

---

### Storage Layer

#### **directus_files** (Directus Built-in)
**Purpose:** Physical file storage with CDN

**Key Fields (auto-managed by Directus):**
- `id` (UUID, primary key)
- `filename_disk` (string) - Actual filename on disk
- `filename_download` (string) - User-friendly name
- `title` (string)
- `type` (string) - MIME type (image/png, application/pdf)
- `filesize` (integer) - Bytes
- `width`, `height` (integer) - For images
- `uploaded_by` (UUID → directus_users)
- `uploaded_on` (timestamp)
- `storage` (string) - local, s3, gcs, etc.
- `location` (string) - File path or cloud URL

**Storage Backends:**
- Local filesystem (development)
- Amazon S3 (production)
- Google Cloud Storage
- Azure Blob Storage

**Referenced By:**
- organizations.logo
- companies.logo
- clients.avatar
- documents.file_id
- artifact_versions.primary_file_id
- artifact_files.directus_files_id (M2M)

---

## Relationship Map

### Complete Relationship Matrix

| From Collection      | Field                  | To Collection        | Type | Description |
|----------------------|------------------------|----------------------|------|-------------|
| **Sales & CRM** |
| clients              | company_id             | companies            | M2O  | Client's employer |
| opportunities        | company_id             | companies            | M2O  | Deal company |
| opportunities        | client_id              | clients              | M2O  | Primary contact |
| **Projects** |
| projects             | company_id             | companies            | M2O  | Client company |
| projects             | opportunity_id         | opportunities        | M2O  | Source deal |
| projects             | template_id            | template_versions    | M2O  | Template used |
| template_versions    | template_id            | templates            | M2O  | Parent template |
| **Tasks** |
| tasks                | project_id             | projects             | M2O  | Parent project |
| tasks                | assigned_to            | directus_users       | M2O  | Assignee |
| task_dependencies    | task_id                | tasks                | M2O  | Dependent task |
| task_dependencies    | depends_on_task_id     | tasks                | M2O  | Prerequisite task |
| task_executions      | task_id                | tasks                | M2O  | Executed task |
| task_executions      | job_id                 | jobs                 | M2O  | Background job |
| task_executions      | checker_user_id        | directus_users       | M2O  | Reviewer |
| jobs                 | task_id                | tasks                | M2O  | Related task |
| jobs                 | project_id             | projects             | M2O  | Related project |
| **Artifacts** |
| artifact_versions    | project_id             | projects             | M2O  | Parent project |
| artifact_versions    | primary_file_id        | directus_files       | M2O  | Main file |
| artifact_versions    | source_task_id         | tasks                | M2O  | Creator task |
| artifact_versions    | execution_id           | task_executions      | M2O  | Specific execution |
| artifact_approvals   | artifact_version_id    | artifact_versions    | M2O  | Approved artifact |
| artifact_approvals   | project_id             | projects             | M2O  | Project context |
| artifact_approvals   | task_id                | tasks                | M2O  | Source task |
| artifact_approvals   | actor_id               | directus_users       | M2O  | Who approved |
| documents            | project_id             | projects             | M2O  | Related project |
| documents            | company_id             | companies            | M2O  | Related company |
| documents            | file_id                | directus_files       | M2O  | Physical file |
| documents            | artifact_version_id    | artifact_versions    | M2O  | Source artifact |
| **M2M Junctions** |
| artifact_files       | artifact_version_id    | artifact_versions    | M2O  | Artifact side |
| artifact_files       | directus_files_id      | directus_files       | M2O  | File side |
| task_artifacts       | task_id                | tasks                | M2O  | Task side |
| task_artifacts       | artifact_version_id    | artifact_versions    | M2O  | Artifact side |

### Virtual M2M Fields

These are automatically available via Directus M2M relationships:

- `artifact_versions.files` → Access all files via artifact_files junction
- `tasks.artifacts` → Access all artifacts via task_artifacts junction

**Usage Example:**
```javascript
// Get artifact with all files
const artifact = await directus.items('artifact_versions').readOne(id, {
  fields: ['*', 'files.*']  // Expands M2M relationship
});
// artifact.files = [{id, filename, type, ...}, ...]

// Get task with all artifacts
const task = await directus.items('tasks').readOne(id, {
  fields: ['*', 'artifacts.*']
});
// task.artifacts = [{id, schema_key, status, ...}, ...]
```

---

## Key Workflows

### 1. Project Creation from Template

```
1. User selects template (template_versions)
2. System reads template_definition
3. Create project record:
   - Set template_id = selected template version
   - Set context = {} (empty)
   - Set context_version = 0
4. Create pre_seeded_tasks from template
5. Initialize project databases if specified
6. Set up automation hooks
7. Redirect user to project dashboard
```

### 2. AI Task Execution with Artifact Creation

```
┌──────────────────────────────────────────────────────────────┐
│ 1. n8n reads task from queue                                 │
│    - task.execution_type = 'ai'                              │
│    - task.status = 'new'                                      │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. Read project.context for task inputs                      │
│    - GET /projects/:id?fields=context,context_version        │
│    - Extract required data (e.g., brand.logo, colors)        │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Execute AI task (e.g., generate 5 logo concepts)          │
│    - Create task_execution record                            │
│    - Call AI API with context as input                       │
│    - Upload generated files to directus_files                │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Create artifact_versions for each output                  │
│    FOR EACH generated file:                                  │
│      - Create artifact_versions:                             │
│        {                                                      │
│          project_id: project_id,                             │
│          schema_key: "brand.logo",                           │
│          status: 'pending',                                  │
│          primary_file_id: file_id,                           │
│          source_task_id: task_id,                            │
│          execution_id: execution_id,                         │
│          version_number: i+1                                 │
│        }                                                      │
│      - Create artifact_files junction record                 │
│      - Create task_artifacts junction record                 │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Update task.status = 'needs_review'                       │
│    - Notify assigned user                                    │
│    - User reviews outputs in Directus UI                     │
└──────────────────────────────────────────────────────────────┘
```

### 3. Human Approval Workflow

```
┌──────────────────────────────────────────────────────────────┐
│ 1. User reviews pending artifacts                            │
│    - GET /artifact_versions?filter[status]=pending           │
│    - View files, metadata                                    │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. User selects ONE artifact to approve                      │
│    - PATCH /artifact_versions/:id                            │
│      {status: 'approved', approved_at: now, approved_by: uid}│
│    - Unique index ensures only one approved per schema_key   │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. Create artifact_approvals record                          │
│    - POST /artifact_approvals                                │
│      {                                                        │
│        artifact_version_id: approved_id,                     │
│        action: 'approve',                                    │
│        actor_id: user_id,                                    │
│        actor_type: 'human',                                  │
│        reason: 'Meets brand guidelines'                      │
│      }                                                        │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. Reject other pending artifacts (optional)                 │
│    - PATCH /artifact_versions/:id                            │
│      {status: 'rejected', rejection_reason: '...'}           │
│    - Creates learning data for AI                            │
└──────────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. Mark task.status = 'done'                                 │
│    - Triggers promotion flow (see next workflow)             │
└──────────────────────────────────────────────────────────────┘
```

### 4. Artifact Promotion to Project Context

**Trigger:** Task status changes to "done"
**Mechanism:** Directus Flow or Custom Hook

```javascript
// Directus Flow: "Promote Approved Artifacts"

// 1. Get task and approved artifacts
const task = await directus.items('tasks').readOne(task_id, {
  fields: ['*', 'artifacts.*']
});

const approvedArtifacts = task.artifacts.filter(a => a.status === 'approved');

if (approvedArtifacts.length === 0) return;

// 2. Read project with optimistic lock
const project = await db.query(
  'SELECT id, context, context_version FROM projects WHERE id = $1 FOR UPDATE',
  [project_id]
);

const expectedVersion = project.context_version;

// 3. For each approved artifact, supersede old version
for (const artifact of approvedArtifacts) {
  await db.query(
    `UPDATE artifact_versions
     SET status = 'superseded'
     WHERE project_id = $1
       AND schema_key = $2
       AND status = 'approved'
       AND id != $3`,
    [project_id, artifact.schema_key, artifact.id]
  );
}

// 4. Update project.context cache
const newContext = { ...project.context };

for (const artifact of approvedArtifacts) {
  // Use lodash _.set for nested path
  _.set(newContext, artifact.schema_key, {
    artifact_version_id: artifact.id,
    file_id: artifact.primary_file_id,
    ...artifact.value,  // Structured data
    approved_at: artifact.approved_at,
    version: artifact.version_number
  });
}

newContext._meta = {
  ...newContext._meta,
  last_updated: new Date().toISOString(),
  context_version: expectedVersion + 1,
  total_artifacts: (newContext._meta?.total_artifacts || 0) + approvedArtifacts.length
};

// 5. Atomic update with optimistic lock check
const result = await db.query(
  `UPDATE projects
   SET context = $1, context_version = context_version + 1
   WHERE id = $2 AND context_version = $3`,
  [JSON.stringify(newContext), project_id, expectedVersion]
);

if (result.rowCount === 0) {
  throw new Error('409 Conflict: Context was updated by another process');
}

// 6. Optionally create document records
for (const artifact of approvedArtifacts) {
  if (shouldCreateDocument(artifact.schema_key)) {
    await directus.items('documents').createOne({
      title: `${project.title} - ${artifact.schema_key}`,
      file_id: artifact.primary_file_id,
      project_id: project_id,
      artifact_version_id: artifact.id,
      status: 'approved',
      created_by_ai: true,
      category: inferCategory(artifact.schema_key)
    });
  }
}
```

### 5. Next Task Reads from Context

```javascript
// Task: Generate business card using approved logo

// 1. Read project context
const project = await directus.items('projects').readOne(project_id, {
  fields: ['id', 'context', 'context_version']
});

// 2. Extract required artifacts
const logoFileId = project.context.brand?.logo?.file_id;
const primaryColor = project.context.brand?.colors?.primary;

if (!logoFileId) {
  throw new Error('Logo not found in project context. Please complete logo task first.');
}

// 3. Download logo file
const logoFile = await directus.files.readOne(logoFileId);
const logoBlob = await fetch(logoFile.data.full_url).then(r => r.blob());

// 4. Execute AI task with context
const businessCard = await generateBusinessCard({
  logo: logoBlob,
  primaryColor: primaryColor,
  companyName: project.company.name
});

// 5. Save as new artifact (repeat artifact creation workflow)
```

---

## Data Flow Diagrams

### Complete System Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        SALES PIPELINE                           │
│  Organization → Opportunity (closed_won) → Project Created      │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      PROJECT INITIALIZATION                     │
│  Template Version → Pre-seeded Tasks → Empty Context           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                       TASK EXECUTION LOOP                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. n8n picks task from queue                             │  │
│  │ 2. Read project.context                                  │  │
│  │ 3. Execute AI with context as input                      │  │
│  │ 4. Upload files to directus_files                        │  │
│  │ 5. Create artifact_versions (status: pending)            │  │
│  │ 6. Link via artifact_files, task_artifacts junctions     │  │
│  │ 7. Set task.status = 'needs_review'                      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 8. Human reviews artifacts                               │  │
│  │ 9. Approve ONE, reject others                            │  │
│  │ 10. Create artifact_approvals records                    │  │
│  │ 11. Set task.status = 'done'                             │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 12. Promotion Flow (Directus Flow)                       │  │
│  │     - Supersede old approved versions                    │  │
│  │     - Update project.context (with optimistic lock)      │  │
│  │     - Increment context_version                          │  │
│  │     - Optionally create documents                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 13. Next task reads from updated context                 │  │
│  │     - Loop back to step 1                                │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      PROJECT COMPLETION                         │
│  All tasks done → Final deliverables in documents collection    │
│  Project context = complete knowledge base                      │
└─────────────────────────────────────────────────────────────────┘
```

### Context Evolution Over Time

```
Project Created (context_version = 0)
context = {}

                    ↓

Task 1: Generate Logo Concepts
- Creates 5 artifact_versions (pending)
- Human approves 1
- Promotion flow runs

                    ↓

context_version = 1
context = {
  "brand": {
    "logo": {
      "artifact_version_id": "v1",
      "file_id": "f1"
    }
  }
}

                    ↓

Task 2: Define Brand Colors
- Reads logo from context
- Creates 3 color palettes (pending)
- Human approves 1
- Promotion flow runs

                    ↓

context_version = 2
context = {
  "brand": {
    "logo": {...},
    "colors": {
      "artifact_version_id": "v2",
      "primary": "#1A365D",
      "secondary": "#2C7A7B"
    }
  }
}

                    ↓

Task 3: Generate Business Card
- Reads logo + colors from context
- Creates business card designs (pending)
- Human approves 1
- Promotion flow runs

                    ↓

context_version = 3
context = {
  "brand": {
    "logo": {...},
    "colors": {...}
  },
  "deliverables": {
    "business_card": {
      "artifact_version_id": "v3",
      "file_id": "f2"
    }
  }
}

... and so on, building up project knowledge
```

---

## Best Practices

### 1. Context Schema Design

**Use hierarchical namespaces:**
```
✅ Good:
  brand.logo
  brand.colors.primary
  deliverables.business_card

❌ Bad:
  logo
  color1
  businesscard
```

**Define schema in template_versions.template_definition:**
```json
{
  "context_schema": {
    "brand": {
      "logo": { "type": "file", "required": true },
      "colors": {
        "primary": { "type": "color", "required": true },
        "secondary": { "type": "color", "required": false }
      }
    },
    "deliverables": {
      "business_card": { "type": "file", "required": true }
    }
  }
}
```

### 2. Optimistic Locking Usage

**Always use If-Match for context updates:**
```javascript
// ❌ BAD: Race condition
const project = await directus.items('projects').readOne(id);
project.context.brand.logo = newLogo;
await directus.items('projects').updateOne(id, { context: project.context });

// ✅ GOOD: Optimistic lock
const project = await directus.items('projects').readOne(id);
const expectedVersion = project.context_version;

try {
  await db.query(
    'UPDATE projects SET context = $1, context_version = context_version + 1 WHERE id = $2 AND context_version = $3',
    [newContext, id, expectedVersion]
  );
} catch (error) {
  if (error.code === '409') {
    // Refresh and retry
    return await retryUpdate(id);
  }
  throw error;
}
```

### 3. Artifact Versioning

**Never delete artifact_versions:**
```javascript
// ❌ BAD
await directus.items('artifact_versions').deleteOne(id);

// ✅ GOOD: Status change only
await directus.items('artifact_versions').updateOne(id, {
  status: 'rejected',
  rejection_reason: 'Did not meet brand guidelines'
});
```

**Benefit:** Complete audit trail, learning data for AI

### 4. File Management

**Always set primary_file_id for single-file artifacts:**
```javascript
const artifact = await directus.items('artifact_versions').createOne({
  project_id: pid,
  schema_key: 'brand.logo',
  primary_file_id: fileId,  // Quick access to main file
  status: 'pending'
});

// Link via M2M for completeness
await directus.items('artifact_files').createOne({
  artifact_version_id: artifact.id,
  directus_files_id: fileId,
  sort: 1
});
```

**For multi-file artifacts:**
```javascript
// Logo with multiple formats (PNG, SVG, PDF)
const artifact = await directus.items('artifact_versions').createOne({
  schema_key: 'brand.logo_pack',
  primary_file_id: pngFileId,  // Primary = PNG for preview
  ...
});

// Link all formats
await directus.items('artifact_files').createMany([
  { artifact_version_id: artifact.id, directus_files_id: pngFileId, sort: 1 },
  { artifact_version_id: artifact.id, directus_files_id: svgFileId, sort: 2 },
  { artifact_version_id: artifact.id, directus_files_id: pdfFileId, sort: 3 }
]);
```

### 5. Query Optimization

**Use field selection to reduce payload:**
```javascript
// ❌ BAD: Fetches everything
const projects = await directus.items('projects').readMany();

// ✅ GOOD: Only what you need
const projects = await directus.items('projects').readMany({
  fields: ['id', 'title', 'status', 'due_date'],
  filter: { status: { _eq: 'active' } },
  limit: 50
});
```

**Expand relationships selectively:**
```javascript
// Get project with specific context data
const project = await directus.items('projects').readOne(id, {
  fields: ['id', 'title', 'context.brand.logo', 'context_version']
});

// Get task with artifacts and their primary files
const task = await directus.items('tasks').readOne(id, {
  fields: ['*', 'artifacts.*', 'artifacts.primary_file_id.*']
});
```

---

## Migration Path (Development → Production)

### Current State (SQLite)
- Development database: `/Users/parijat/Desktop/Directus/database/data.db`
- Single partial unique index created
- M2M junctions in place
- Optimistic locking ready

### Production Checklist

1. **Database Migration:**
   ```bash
   # Export SQLite schema
   curl "http://localhost:8055/schema/snapshot?access_token=TOKEN" > schema.json

   # Set up PostgreSQL in .env
   DB_CLIENT=pg
   DB_HOST=your-postgres-host
   DB_PORT=5432
   DB_DATABASE=agency_os
   DB_USER=directus
   DB_PASSWORD=your-password

   # Import schema
   npx directus schema apply ./schema.json
   ```

2. **Add Production Indexes (after profiling):**
   ```sql
   -- GIN index for JSON context queries
   CREATE INDEX idx_projects_context_gin ON projects USING GIN (context);

   -- Expression indexes for hot paths (add after profiling)
   CREATE INDEX idx_projects_logo_exists
     ON projects ((context ? 'brand'))
     WHERE context ? 'brand';

   -- Artifact lookup performance
   CREATE INDEX idx_artifact_lookup
     ON artifact_versions (project_id, schema_key, status);
   ```

3. **Implement Promotion Flow:**
   - Create Directus Flow in admin UI
   - OR write Custom Hook extension
   - Test optimistic locking behavior
   - Handle 409 Conflicts gracefully

4. **Update n8n Workflows:**
   - Use production Directus URL
   - Update authentication tokens
   - Test artifact creation flow
   - Verify M2M junction creation

5. **Set Up Monitoring:**
   - SLA alerts (task_executions.met_sla = false)
   - Job failures (jobs.status = 'failed')
   - Context conflicts (409 responses)
   - File storage usage

---

## Support & Resources

**Directus Admin:**
- Dashboard: http://localhost:8055/admin
- Data Model: http://localhost:8055/admin/settings/data-model
- API Docs: http://localhost:8055/admin/settings/documentation

**Key Documentation:**
- Artifact System: `/Users/parijat/Desktop/Directus/ARTIFACT_SYSTEM_COMPLETE.md`
- M2M Migration: `/Users/parijat/Desktop/Directus/M2M_MIGRATION_COMPLETE.md`
- Template Format: `/Users/parijat/Desktop/Directus/schemas/TASK_TEMPLATE_FORMAT.md`

**Schema Backups:**
- Latest: `/Users/parijat/Desktop/Directus/backups/schema_backup_m2m_2025-10-16_19-42-01.json`
- All backups: `/Users/parijat/Desktop/Directus/backups/`

**Database:**
- Location: `/Users/parijat/Desktop/Directus/database/data.db`
- Type: SQLite (dev) → PostgreSQL (prod)

---

## Appendix: Collection Summary Table

| Collection | Purpose | Key Relationships | Status |
|------------|---------|-------------------|--------|
| **organizations** | Client companies | → directus_files (logo) | ✅ Active |
| **companies** | Global company registry | → directus_files (logo) | ✅ Active |
| **clients** | Individual contacts | → companies | ✅ Active |
| **opportunities** | Sales pipeline | → companies, clients | ✅ Active |
| **templates** | Project templates | ← template_versions | ✅ Active |
| **template_versions** | Versioned workflows | → templates | ✅ Active |
| **projects** | Active projects | → companies, opportunities, template_versions | ✅ Active |
| **tasks** | Work items | → projects, ← task_executions | ✅ Active |
| **task_dependencies** | Task ordering | → tasks (x2) | ✅ Active |
| **task_executions** | AI metrics | → tasks, jobs | ✅ Active |
| **jobs** | Background queue | → tasks, projects | ✅ Active |
| **artifact_versions** | Output registry | → projects, tasks, directus_files | ✅ Active |
| **artifact_approvals** | Audit log | → artifact_versions | ✅ Active |
| **artifact_files** | M2M junction | → artifact_versions, directus_files | ✅ Active |
| **task_artifacts** | M2M junction | → tasks, artifact_versions | ✅ Active |
| **documents** | Document metadata | → projects, companies, artifact_versions | ✅ Active |
| **directus_files** | File storage | Referenced by many | ✅ Active (Built-in) |

**Total Collections:** 17 (16 custom + 1 built-in shown)

---

**End of Data Structure Guide**
