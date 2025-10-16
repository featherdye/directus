# Task Template Format

This document defines the JSON structure for `template_versions.pre_seeded_tasks` field, which contains task definitions that should be automatically created when a project is initialized from a template.

## Structure

The `pre_seeded_tasks` field should contain an array of task objects with the following schema:

```json
[
  {
    "title": "string (required)",
    "description": "string (optional)",
    "execution_type": "ai | human | hybrid",
    "status": "new | in_progress | needs_review | done | rejected",
    "priority": "low | medium | high | critical",
    "sla_minutes": "integer (optional)",
    "order": "integer (optional)",
    "depends_on": ["array of task titles (optional)"],
    "notes": "string (optional)",
    "tags": ["array of strings (optional)"]
  }
]
```

## Field Definitions

### Required Fields

- **title** (string): The task title/name. Must be unique within the template. Used as identifier for dependencies.
- **execution_type** (string): Who executes the task
  - `ai`: AI-driven task (target: ≤2 min, ≥95% acceptance)
  - `human`: Human-driven task
  - `hybrid`: Combination of AI and human work

### Optional Fields

- **description** (string): Detailed task description. Supports rich text/markdown.
- **status** (string): Initial task status. Default: `new`
  - `new`: Not yet started
  - `in_progress`: Currently being worked on
  - `needs_review`: Completed, awaiting review
  - `done`: Approved and complete
  - `rejected`: Rejected, needs rework
- **priority** (string): Task priority. Default: `medium`
  - `low`: Low priority
  - `medium`: Medium priority
  - `high`: High priority
  - `critical`: Critical priority
- **sla_minutes** (integer): Service Level Agreement target in minutes. For AI tasks, typically 2 minutes (120 seconds).
- **order** (integer): Display/execution order. Used for sorting tasks in UI.
- **depends_on** (array): Array of task titles that must be completed before this task can start. Creates task dependencies.
- **notes** (string): Internal notes about the task
- **tags** (array): Array of tag strings for categorization

## Example: Client Onboarding Template

```json
[
  {
    "title": "Initial Client Data Collection",
    "description": "Gather basic client information: company name, contact details, project scope",
    "execution_type": "human",
    "status": "new",
    "priority": "high",
    "order": 1,
    "notes": "Use the client intake form",
    "tags": ["onboarding", "intake"]
  },
  {
    "title": "Generate Welcome Email",
    "description": "AI generates personalized welcome email based on client data",
    "execution_type": "ai",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 2,
    "order": 2,
    "depends_on": ["Initial Client Data Collection"],
    "tags": ["onboarding", "communication", "ai-generated"]
  },
  {
    "title": "Review Welcome Email",
    "description": "Human reviews and approves AI-generated welcome email",
    "execution_type": "human",
    "status": "new",
    "priority": "medium",
    "order": 3,
    "depends_on": ["Generate Welcome Email"],
    "tags": ["onboarding", "review"]
  },
  {
    "title": "Send Welcome Email",
    "description": "Send approved welcome email to client",
    "execution_type": "ai",
    "status": "new",
    "priority": "high",
    "sla_minutes": 1,
    "order": 4,
    "depends_on": ["Review Welcome Email"],
    "tags": ["onboarding", "communication"]
  },
  {
    "title": "Schedule Kickoff Meeting",
    "description": "AI schedules kickoff meeting based on client and team availability",
    "execution_type": "hybrid",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 5,
    "order": 5,
    "depends_on": ["Send Welcome Email"],
    "tags": ["onboarding", "scheduling"]
  }
]
```

## Example: Content Creation Template

```json
[
  {
    "title": "Content Brief Creation",
    "description": "Create content brief with topic, keywords, target audience, and goals",
    "execution_type": "human",
    "status": "new",
    "priority": "high",
    "order": 1,
    "tags": ["content", "planning"]
  },
  {
    "title": "Research & Outline",
    "description": "AI researches topic and generates detailed outline",
    "execution_type": "ai",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 2,
    "order": 2,
    "depends_on": ["Content Brief Creation"],
    "tags": ["content", "research", "ai-generated"]
  },
  {
    "title": "Draft Content",
    "description": "AI generates first draft based on approved outline",
    "execution_type": "ai",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 2,
    "order": 3,
    "depends_on": ["Research & Outline"],
    "tags": ["content", "writing", "ai-generated"]
  },
  {
    "title": "Content Review & Editing",
    "description": "Human editor reviews and refines AI-generated content",
    "execution_type": "human",
    "status": "new",
    "priority": "high",
    "order": 4,
    "depends_on": ["Draft Content"],
    "tags": ["content", "editing", "review"]
  },
  {
    "title": "SEO Optimization",
    "description": "AI optimizes content for SEO: meta tags, keywords, structure",
    "execution_type": "ai",
    "status": "new",
    "priority": "medium",
    "sla_minutes": 1,
    "order": 5,
    "depends_on": ["Content Review & Editing"],
    "tags": ["content", "seo", "ai-generated"]
  },
  {
    "title": "Final Approval",
    "description": "Client or manager provides final approval",
    "execution_type": "human",
    "status": "new",
    "priority": "critical",
    "order": 6,
    "depends_on": ["SEO Optimization"],
    "tags": ["content", "approval"]
  }
]
```

## Implementation Notes

### Automatic Task Creation

When a project is created with a template (`projects.template_id` is set), the system should:

1. Read the `template_versions.pre_seeded_tasks` JSON array
2. For each task definition in the array:
   - Create a new record in the `tasks` collection
   - Set `task.project_id` to the newly created project ID
   - Map all fields from the JSON definition to the task record
   - Set `task.assigned_to` to null (or default assignee if specified in template)
3. After all tasks are created, process dependencies:
   - For each task with `depends_on` array:
     - Look up created task IDs by matching titles
     - Create records in `task_dependencies` collection linking tasks

### Recommended Implementation Approach

**Option 1: Directus Flow (Recommended for No-Code)**
- Create a Flow triggered on `items.create` event for `projects` collection
- Filter: Only when `template_id` is not null
- Operations:
  1. Read template version data
  2. Parse `pre_seeded_tasks` JSON
  3. Loop through tasks and create each one
  4. Create task dependencies

**Option 2: Custom Hook (Recommended for Flexibility)**
- Create a Directus extension hook in `extensions/hooks/auto-create-tasks/`
- Hook into `items.create:after` for `projects` collection
- Implement task creation logic in JavaScript/TypeScript
- Allows for complex validation, error handling, and transformations

**Option 3: External API Endpoint**
- Create custom API endpoint that handles project creation
- Frontend calls this endpoint instead of directly creating project
- Endpoint creates project + tasks in a transaction
- Most control but requires custom frontend integration

## Data Validation

When creating tasks from template, validate:

1. **Required fields**: `title` and `execution_type` must be present
2. **Enum values**: Validate `execution_type`, `status`, and `priority` against allowed values
3. **Dependencies**: Ensure all tasks referenced in `depends_on` arrays exist in the template
4. **Circular dependencies**: Check for circular references in `depends_on` chains
5. **SLA minutes**: Should be positive integer if provided
6. **Order**: Should be unique within template if provided

## Future Enhancements

### Potential Additional Fields

- **estimated_duration_minutes**: Estimated time to complete (separate from SLA)
- **assigned_role**: Auto-assign to user with specific role (e.g., "content_writer", "designer")
- **form_fields**: JSON schema for task-specific input fields
- **output_template**: Template for expected task output format
- **approval_required**: Boolean flag if task needs approval
- **automation_script**: Reference to automation script/flow to run
- **checklist**: Array of sub-items/checklist items within the task

### Template Variables

Future versions could support template variables that get filled during project creation:

```json
{
  "title": "Send welcome email to {{client_name}}",
  "description": "Welcome {{client_name}} to {{project_name}} project"
}
```

Variables would be replaced with actual project data when tasks are created.
