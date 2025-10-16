# Template System - Setup Complete

## Overview

The template system has been redesigned to support automatic task creation when projects are initialized from templates. The system now uses a proper hierarchical structure with parent templates and versioned implementations.

## Architecture

### Collection Hierarchy

```
templates (parent templates)
    ↓ (one-to-many: "versions")
template_versions (versioned implementations)
    ↓ (one-to-many: projects reference specific versions)
projects (work containers)
    ↓ (one-to-many: "tasks")
tasks (work items)
```

### Relationships

1. **templates → template_versions**
   - Relationship: One-to-Many
   - Field: `template_versions.template_id` → `templates.id`
   - Reverse field: `templates.versions` (O2M alias)
   - Purpose: A template can have multiple versions (v1.0, v1.1, v2.0, etc.)

2. **template_versions → projects**
   - Relationship: One-to-Many
   - Field: `projects.template_id` → `template_versions.id`
   - Purpose: Projects pin a specific template version at creation time

3. **projects → tasks**
   - Relationship: One-to-Many
   - Field: `tasks.project_id` → `projects.id`
   - Purpose: Tasks belong to projects

## Collections

### 1. templates

**Purpose:** Parent collection for organizing project templates

**Key Fields:**
- `name` (string, required): Template name
- `slug` (string, unique): URL-friendly identifier
- `description` (text): Template description
- `category` (dropdown): client_work, internal_project, sales_process, operations, custom
- `status` (dropdown): draft, active, deprecated, archived
- `owner_id` (uuid): Links to directus_users
- `is_public` (boolean): Whether available to all users
- `usage_count` (integer): Total projects created from this template

**UI:** http://localhost:8055/admin/content/templates

### 2. template_versions

**Purpose:** Immutable versioned implementations of templates

**Key Fields:**
- `template_id` (uuid, required): Parent template (links to templates)
- `version_number` (string, required): Semantic version (e.g., "1.0.0", "1.1.0")
- `status` (dropdown): draft, published, deprecated, archived
- `is_latest` (boolean): Flag for current recommended version
- `published_at` (timestamp): When this version was published
- `changelog` (text): What changed in this version
- `breaking_changes` (boolean): Whether this version has breaking changes

**Template Definition Fields (JSON):**
- `pre_seeded_tasks` (json): **Default tasks created with this template** ⭐
- `database_schemas` (json): Database schemas to create
- `automation_hooks` (json): Workflow triggers for this template
- `form_inputs` (json): User input fields during project creation

**Metrics:**
- `usage_count` (integer): Number of projects using this version
- `min_client_version` (string): Minimum app version required

**UI:** http://localhost:8055/admin/content/template_versions

### 3. projects

**Purpose:** Work containers - all work lives inside projects

**Template Fields:**
- `template_id` (uuid): **Template version used** (links to template_versions)
- `template_version` (string): Template version pinned at creation (e.g., "1.2.0")

When a project is created with `template_id` set, the system should read the referenced `template_versions.pre_seeded_tasks` and automatically create task records.

**UI:** http://localhost:8055/admin/content/projects

## Task Template Format

The `template_versions.pre_seeded_tasks` field contains a JSON array of task definitions. See `schemas/TASK_TEMPLATE_FORMAT.md` for detailed specification.

### Quick Example

```json
[
  {
    "title": "Initial Client Data Collection",
    "description": "Gather basic client information",
    "execution_type": "human",
    "status": "new",
    "priority": "high",
    "order": 1,
    "tags": ["onboarding", "intake"]
  },
  {
    "title": "Generate Welcome Email",
    "description": "AI generates personalized welcome email",
    "execution_type": "ai",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 2,
    "order": 2,
    "depends_on": ["Initial Client Data Collection"],
    "tags": ["onboarding", "ai-generated"]
  }
]
```

### Field Mapping

When creating tasks from template:

| Template JSON Field | Tasks Collection Field | Notes |
|---------------------|------------------------|-------|
| `title` | `title` | Required |
| `description` | `description` | Optional |
| `execution_type` | `execution_type` | ai/human/hybrid |
| `status` | `status` | Default: "new" |
| `priority` | `priority` | Default: "medium" |
| `sla_minutes` | `sla_minutes` | For AI tasks, typically 2 min |
| `order` | (custom sorting) | Display order |
| `depends_on` | Creates records in `task_dependencies` | Task title references |
| `notes` | `notes` | Internal notes |
| `tags` | `tags` | Array of strings |

## Implementation Next Steps

### ⚠️ Task Automation Not Yet Implemented

The data structure is complete, but **automatic task creation is not yet implemented**. When a user creates a project with a template, tasks are NOT automatically created.

To implement automatic task creation, choose one of these approaches:

### Option 1: Directus Flow (No-Code)

**Best for:** Quick implementation without coding

**Steps:**
1. Navigate to Settings → Flows in Directus admin
2. Create new Flow: "Auto-Create Tasks from Template"
3. Trigger: `items.create` event on `projects` collection
4. Filter: Only when `template_id` is not null
5. Operations:
   - Read Item: Get the template_version data
   - Condition: Check if `pre_seeded_tasks` exists
   - Run Script: Parse JSON and create tasks
   - Create Items: Create task records
   - Create Dependencies: Create task_dependencies records

**Pros:**
- No code required
- Visual workflow builder
- Built into Directus

**Cons:**
- Complex logic harder to implement
- Limited error handling
- Debugging can be challenging

### Option 2: Custom Hook Extension (Recommended)

**Best for:** Production use with proper error handling

**Steps:**
1. Create extension directory:
   ```bash
   mkdir -p extensions/hooks/auto-create-tasks
   cd extensions/hooks/auto-create-tasks
   ```

2. Create `index.js`:
   ```javascript
   export default ({ action }, { services, exceptions }) => {
     const { ItemsService } = services;

     action('items.create', async (meta, context) => {
       if (meta.collection !== 'projects') return;

       const { payload, schema } = meta;
       if (!payload.template_id) return;

       // Read template version
       const templateVersionService = new ItemsService('template_versions', {
         schema,
         accountability: context.accountability
       });

       const templateVersion = await templateVersionService.readOne(payload.template_id);
       if (!templateVersion?.pre_seeded_tasks) return;

       // Create tasks
       const tasksService = new ItemsService('tasks', {
         schema,
         accountability: context.accountability
       });

       const tasks = JSON.parse(templateVersion.pre_seeded_tasks);
       const createdTasks = [];

       for (const taskDef of tasks) {
         const task = await tasksService.createOne({
           project_id: payload.id,
           title: taskDef.title,
           description: taskDef.description,
           execution_type: taskDef.execution_type,
           status: taskDef.status || 'new',
           priority: taskDef.priority || 'medium',
           sla_minutes: taskDef.sla_minutes,
           notes: taskDef.notes,
           tags: taskDef.tags
         });

         createdTasks.push({ ...task, originalTitle: taskDef.title });
       }

       // Create dependencies
       const dependenciesService = new ItemsService('task_dependencies', {
         schema,
         accountability: context.accountability
       });

       for (let i = 0; i < tasks.length; i++) {
         const taskDef = tasks[i];
         if (!taskDef.depends_on || taskDef.depends_on.length === 0) continue;

         const currentTask = createdTasks[i];

         for (const dependencyTitle of taskDef.depends_on) {
           const dependentTask = createdTasks.find(
             t => t.originalTitle === dependencyTitle
           );

           if (dependentTask) {
             await dependenciesService.createOne({
               task_id: currentTask.id,
               depends_on_task_id: dependentTask.id
             });
           }
         }
       }
     });
   };
   ```

3. Restart Directus to load the extension

**Pros:**
- Full control over logic
- Proper error handling
- Can add logging, validation
- Works with Directus permissions
- Runs in transaction

**Cons:**
- Requires Node.js/JavaScript knowledge
- Need to manage extension code

### Option 3: External API Service

**Best for:** Complex workflows or external integrations

**Steps:**
1. Create separate API service that handles project creation
2. Frontend calls your API instead of directly creating projects
3. Your API:
   - Creates project in Directus
   - Reads template version
   - Creates tasks
   - Returns complete project

**Pros:**
- Most flexibility
- Can integrate with external systems
- Full control over business logic

**Cons:**
- Most complex setup
- Requires custom frontend changes
- Additional service to maintain

## Testing Template System

### 1. Create a Template

1. Navigate to http://localhost:8055/admin/content/templates
2. Create new template:
   - Name: "Client Onboarding"
   - Slug: "client-onboarding"
   - Category: "client_work"
   - Status: "active"

### 2. Create a Template Version

1. Navigate to http://localhost:8055/admin/content/template_versions
2. Create new version:
   - Template: Select "Client Onboarding"
   - Version Number: "1.0.0"
   - Status: "published"
   - Is Latest: true
   - Pre-seeded Tasks: (paste example JSON from TASK_TEMPLATE_FORMAT.md)

### 3. Create a Project from Template

1. Navigate to http://localhost:8055/admin/content/projects
2. Create new project:
   - Title: "Acme Corp Onboarding"
   - Template: Select "Client Onboarding v1.0.0"
   - Template Version: "1.0.0"

### 4. Verify (Once Automation is Implemented)

1. Navigate to http://localhost:8055/admin/content/tasks
2. Filter by Project: "Acme Corp Onboarding"
3. Should see all pre-seeded tasks created automatically
4. Check task_dependencies for dependency relationships

## Workflow Example: Updating a Template

### Scenario: Add New Task to Onboarding Template

1. **Navigate to template_versions**
2. **Find current version** (e.g., "Client Onboarding v1.0.0")
3. **Duplicate the version** to create v1.1.0
4. **Edit pre_seeded_tasks JSON** in new version
5. **Add new task to the array:**
   ```json
   {
     "title": "Create Slack Channel",
     "description": "Create dedicated Slack channel for client",
     "execution_type": "ai",
     "status": "new",
     "priority": "medium",
     "sla_minutes": 1,
     "order": 6,
     "depends_on": ["Send Welcome Email"],
     "tags": ["onboarding", "communication"]
   }
   ```
6. **Update is_latest flags:**
   - Set v1.0.0 `is_latest` to `false`
   - Set v1.1.0 `is_latest` to `true`
7. **Publish** the new version

**Result:**
- Existing projects using v1.0.0 are unchanged (immutable)
- New projects will use v1.1.0 with the additional task
- Old version remains available for reference

### Scenario: Breaking Change (New Required Field)

1. Create new version with **major version bump**: v2.0.0
2. Set `breaking_changes` to `true`
3. Document changes in `changelog` field
4. Users see warning that v2.0.0 has breaking changes
5. Can choose to stay on v1.x or migrate to v2.x

## Database Schema

```sql
-- Templates table
CREATE TABLE templates (
  id UUID PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE,
  description TEXT,
  category VARCHAR(50),
  icon VARCHAR(50),
  status VARCHAR(20) DEFAULT 'draft',
  owner_id UUID REFERENCES directus_users(id),
  is_public BOOLEAN DEFAULT false,
  usage_count INTEGER DEFAULT 0,
  notes TEXT,
  tags JSON,
  date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_updated TIMESTAMP,
  user_created UUID,
  user_updated UUID
);

-- Template versions table (already exists, now properly linked)
CREATE TABLE template_versions (
  id UUID PRIMARY KEY,
  template_id UUID REFERENCES templates(id) ON DELETE CASCADE, -- Updated!
  version_number VARCHAR(50) NOT NULL,
  status VARCHAR(20) DEFAULT 'draft',
  is_latest BOOLEAN DEFAULT false,
  published_at TIMESTAMP,
  published_by UUID REFERENCES directus_users(id),
  deprecated_at TIMESTAMP,
  changelog TEXT,
  breaking_changes BOOLEAN DEFAULT false,
  pre_seeded_tasks JSON,  -- ⭐ Task definitions
  database_schemas JSON,
  automation_hooks JSON,
  form_inputs JSON,
  usage_count INTEGER DEFAULT 0,
  min_client_version VARCHAR(50),
  date_created TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  date_updated TIMESTAMP,
  user_created UUID,
  user_updated UUID
);

-- Projects table (no schema changes needed)
-- Already has: template_id UUID REFERENCES template_versions(id)

-- Tasks table (no schema changes needed)
-- Already has all fields needed for task creation
```

## Files Modified/Created

### Created:
- `/Users/parijat/Desktop/Directus/schemas/templates.json` - Template collection schema
- `/Users/parijat/Desktop/Directus/schemas/TASK_TEMPLATE_FORMAT.md` - Task template specification
- `/Users/parijat/Desktop/Directus/TEMPLATE_SYSTEM_SETUP.md` - This document

### Modified:
- `/Users/parijat/Desktop/Directus/schemas/template_versions.json` - Updated to reference templates
- `/Users/paријat/Desktop/Directus/schemas/projects.json` - Clarified template_id note

### API Changes:
- Created `templates` collection via Directus API
- Created M2O relationship: `template_versions.template_id` → `templates.id`
- Updated field notes for clarity

## Summary

✅ **Completed:**
- Parent `templates` collection created
- Proper hierarchical structure: templates → template_versions → projects
- All relationships configured correctly
- Task template format documented with examples
- Schema files updated

⚠️ **Pending:**
- **Automatic task creation not yet implemented**
- Need to choose and implement one of the three automation approaches
- Test workflow end-to-end once automation is in place

The data structure is now production-ready and follows best practices for versioned templates with immutability. The next step is to implement the automation mechanism for creating tasks when projects are initialized from templates.
