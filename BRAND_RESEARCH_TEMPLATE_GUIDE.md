# Brand Research Template - Usage Guide

**Template Name:** Brand Research & Competitive Analysis
**Template ID:** 1
**Version:** 1.0.0
**Status:** Published ✅
**Created:** October 16, 2025

---

## Overview

This template automates competitive brand research by orchestrating 4 existing n8n workflows to gather and analyze competitor data from multiple sources. It creates a structured workflow with 6 tasks that flow from data collection to analysis and reporting.

### What It Does

1. **Identifies competitors** and gathers basic company information
2. **Extracts social media links** from competitor websites
3. **Analyzes Instagram content** (last 20 posts per competitor)
4. **Analyzes LinkedIn content** (last 20 posts per competitor)
5. **Human review gate** for quality control
6. **Generates analysis report** with insights and recommendations

---

## Template Structure

### Collections Created

- **Template:** `templates` (ID: 1)
- **Template Version:** `template_versions` (ID: 1)

**View in Directus:**
- Templates: http://localhost:8055/admin/content/templates
- Template Versions: http://localhost:8055/admin/content/template_versions

---

## Pre-Seeded Tasks

When you create a project from this template, 6 tasks are automatically created:

### Task 1: Identify Competitors & Gather Basic Info
- **Type:** AI (automated)
- **Priority:** Critical
- **SLA:** 5 minutes
- **n8n Workflow:** `get_competitors_and_about`
- **Dependencies:** None (starts automatically)
- **Output:** `research.competitors`

**What it does:**
Scrapes competitor data to collect:
- Company name
- Website URL
- About/description
- Industry
- Company size

**Input Required:**
Initial list of competitor names (from project creation form)

---

### Task 2: Extract Competitor Links & Social Profiles
- **Type:** AI (automated)
- **Priority:** High
- **SLA:** 5 minutes
- **n8n Workflow:** `get_competitor_links`
- **Dependencies:** Task 1
- **Output:** `research.competitor_links`

**What it does:**
Crawls each competitor's website to find:
- Instagram profile URL
- LinkedIn profile URL
- Twitter profile URL
- Facebook page URL

**Input:** Uses competitor list from Task 1

---

### Task 3: Analyze Competitor Instagram Content (Last 20 Posts)
- **Type:** AI (automated)
- **Priority:** High
- **SLA:** 10 minutes
- **n8n Workflow:** `get_competitor_instagram_posts`
- **Dependencies:** Task 2
- **Output:** `research.social_media.instagram`

**What it does:**
For each competitor's Instagram, extracts:
- Post URLs
- Captions
- Likes count
- Comments count
- Posting dates
- Hashtags used
- Media types (image/video)
- Engagement summary (avg engagement, posting frequency, top hashtags, content themes)

**Runs in parallel with:** Task 4 (LinkedIn analysis)

---

### Task 4: Analyze Competitor LinkedIn Content (Last 20 Posts)
- **Type:** AI (automated)
- **Priority:** High
- **SLA:** 10 minutes
- **n8n Workflow:** `get_competitor_linkedin_posts`
- **Dependencies:** Task 2
- **Output:** `research.social_media.linkedin`

**What it does:**
For each competitor's LinkedIn, extracts:
- Post URLs
- Post content
- Likes count
- Comments count
- Shares count
- Posting dates
- Post types
- Engagement summary (avg engagement, posting frequency, content topics, engagement rate)

**Runs in parallel with:** Task 3 (Instagram analysis)

---

### Task 5: Review & Approve Research Data
- **Type:** Human (manual)
- **Priority:** High
- **SLA:** N/A
- **Dependencies:** Tasks 3 AND 4 (both must complete)

**What to do:**
Quality control gate - review all collected data:
- Verify competitor information is accurate
- Check that social media links are correct
- Flag any missing or incomplete data
- Approve artifacts before proceeding to analysis

**This is a checkpoint** to ensure data quality before generating the final report.

---

### Task 6: Generate Competitive Analysis Report
- **Type:** AI (automated)
- **Priority:** Medium
- **SLA:** 3 minutes
- **n8n Workflow:** `generate_analysis_report`
- **Dependencies:** Task 5
- **Output:** `analysis.summary` (document)

**What it does:**
Synthesizes all collected data into a comprehensive report:
- Competitor positioning analysis
- Content strategy insights
- Engagement patterns and benchmarks
- Identified opportunities
- Strategic recommendations

**Output Format:** Markdown document (can be converted to PDF)

---

## Task Dependencies Diagram

```
Task 1: Identify Competitors
         ↓
Task 2: Extract Links
         ↓
    ┌────┴────┐
    ↓         ↓
Task 3:    Task 4:
Instagram  LinkedIn
    └────┬────┘
         ↓
Task 5: Human Review
         ↓
Task 6: Generate Report
```

**Parallel Execution:** Tasks 3 and 4 run simultaneously after Task 2 completes.

---

## Context Schema

The template defines a structured schema for storing research outputs in `project.context`:

```json
{
  "research": {
    "competitors": {
      // Output from Task 1
      "list": [
        {
          "name": "Competitor Name",
          "website": "https://example.com",
          "about": "Company description",
          "industry": "Technology",
          "size": "51-200"
        }
      ]
    },
    "competitor_links": {
      // Output from Task 2
      "Competitor Name": {
        "website": "https://example.com",
        "instagram": "https://instagram.com/competitor",
        "linkedin": "https://linkedin.com/company/competitor",
        "twitter": "https://twitter.com/competitor",
        "facebook": "https://facebook.com/competitor"
      }
    },
    "social_media": {
      "instagram": {
        // Output from Task 3
        "Competitor Name": {
          "posts": [...],
          "summary": {
            "avg_engagement": 1250,
            "posting_frequency": "3x per week",
            "top_hashtags": ["#brand", "#product"],
            "content_themes": ["product launches", "behind-the-scenes"]
          }
        }
      },
      "linkedin": {
        // Output from Task 4
        "Competitor Name": {
          "posts": [...],
          "summary": {
            "avg_engagement": 850,
            "posting_frequency": "2x per week",
            "content_topics": ["thought leadership", "company news"],
            "engagement_rate": 3.5
          }
        }
      }
    }
  },
  "analysis": {
    "summary": {
      // Output from Task 6 (artifact_version_id reference)
      "artifact_version_id": "uuid",
      "file_id": "uuid",
      "approved_at": "2025-10-16T20:30:00Z"
    }
  }
}
```

---

## How to Use This Template

### Step 1: Create a Project from Template

**Via Directus UI:**
1. Go to Projects: http://localhost:8055/admin/content/projects
2. Click "Create Item" (+)
3. Fill in project details:
   - **Title:** e.g., "Acme Corp Brand Research"
   - **Template ID:** Select "Brand Research & Competitive Analysis"
   - **Template Version:** "1.0.0"
   - **Company ID:** Select client company
4. In the custom form (if implemented), enter:
   - **Competitor Names:** One per line (e.g., "Nike", "Adidas", "Puma")
   - **Research Focus:** Select focus areas (optional)
5. Click "Save"

**Via API:**
```javascript
const project = await directus.items('projects').createOne({
  title: "Acme Corp Brand Research",
  company_id: "company-uuid",
  template_id: 1, // Brand Research template version
  template_version: "1.0.0",
  lifecycle_status: "active",
  context: {},
  context_version: 0
});
```

### Step 2: Tasks Are Auto-Created

After project creation, the system should automatically:
1. Create 6 tasks based on `pre_seeded_tasks`
2. Set up task dependencies
3. Start Task 1 after 10 seconds (if automation hooks are implemented)

**Note:** Task auto-creation requires implementing one of:
- Directus Flow (recommended)
- Custom Hook extension
- External API endpoint

See `/Users/parijat/Desktop/Directus/schemas/TASK_TEMPLATE_FORMAT.md` for implementation details.

### Step 3: Monitor Task Execution

**View tasks:**
1. Go to project detail page
2. Navigate to "Tasks" tab
3. Monitor task status and progress

**Task statuses:**
- `new` → Not started
- `in_progress` → Currently running
- `needs_review` → Completed, awaiting approval
- `done` → Approved and complete

### Step 4: Integrate n8n Workflows

Each automated task needs to trigger its corresponding n8n workflow:

**Option A: Directus Flow Trigger**
- Create Flow that monitors `tasks` collection
- When task status → `in_progress` and `execution_type` = `ai`
- Call n8n webhook with task details

**Option B: n8n Polling**
- n8n workflow polls Directus for `new` tasks
- Filters by specific task title
- Executes workflow and updates task

**Option C: Manual Trigger (for testing)**
- Manually trigger n8n workflow
- Pass task_id and project_id
- n8n creates artifact_versions when complete

**n8n Workflow Mapping:**
```
Task Title → n8n Workflow Name
----------------------------------------------------------------
"Identify Competitors & Gather Basic Info" → get_competitors_and_about
"Extract Competitor Links & Social Profiles" → get_competitor_links
"Analyze Competitor Instagram Content" → get_competitor_instagram_posts
"Analyze Competitor LinkedIn Content" → get_competitor_linkedin_posts
"Generate Competitive Analysis Report" → generate_analysis_report
```

### Step 5: Review and Approve Artifacts

When tasks complete, they create `artifact_versions` with status `pending`:

1. Go to Artifacts: http://localhost:8055/admin/content/artifact_versions
2. Filter by `project_id` and `status=pending`
3. Review data quality
4. Approve ONE artifact per schema_key:
   ```javascript
   await directus.items('artifact_versions').updateOne(artifact_id, {
     status: 'approved',
     approved_at: new Date(),
     approved_by: user_id
   });
   ```
5. Update task status to `done`

### Step 6: Promotion to Context

When task status → `done`, the promotion flow should:
1. Read approved artifacts for that task
2. Update `project.context` with artifact data
3. Increment `context_version`
4. Supersede old versions

See `/Users/parijat/Desktop/Directus/ARTIFACT_SYSTEM_COMPLETE.md` for promotion flow details.

### Step 7: Final Report

After Task 6 completes:
1. Final report is saved as `artifact_version`
2. Optionally creates a `document` record
3. Report is available in project context at `analysis.summary`
4. Download or view report from Documents collection

---

## Project Timeline

**Estimated Duration:** 1-3 hours (automated) + human review time

| Task | Type | Duration | Notes |
|------|------|----------|-------|
| 1. Identify Competitors | AI | 5 min | Starts automatically |
| 2. Extract Links | AI | 5 min | Auto-starts after Task 1 |
| 3. Instagram Analysis | AI | 10 min | Parallel with Task 4 |
| 4. LinkedIn Analysis | AI | 10 min | Parallel with Task 3 |
| 5. Human Review | Human | Variable | Quality gate |
| 6. Generate Report | AI | 3 min | Final synthesis |

**Total AI Time:** ~33 minutes
**Total with Review:** 1-3 hours depending on review thoroughness

---

## Expected Outputs

### After Task 1
**artifact_versions with:**
- `schema_key`: `research.competitors`
- `value`: JSON with competitor list
- `status`: `pending`

**Example:**
```json
{
  "competitors": [
    {
      "name": "Nike",
      "website": "https://nike.com",
      "about": "Athletic footwear and apparel company",
      "industry": "Retail/Sports",
      "size": "10000+"
    },
    ...
  ]
}
```

### After Task 2
**artifact_versions with:**
- `schema_key`: `research.competitor_links`
- `value`: JSON with social links per competitor

### After Tasks 3 & 4
**Two artifact_versions:**
1. Instagram analysis (`research.social_media.instagram`)
2. LinkedIn analysis (`research.social_media.linkedin`)

Each contains posts array + summary metrics

### After Task 6
**artifact_version + document with:**
- `schema_key`: `analysis.summary`
- `primary_file_id`: Markdown/PDF report
- `value`: Report metadata
- Document record created automatically

---

## n8n Integration Points

### Required n8n Workflows

You mentioned having these workflows already:

1. ✅ **Get competitors and about them**
   - Maps to: Task 1
   - Input: Competitor names list
   - Output: Competitor profiles with basic info

2. ✅ **Get competitor links**
   - Maps to: Task 2
   - Input: Competitor names + websites
   - Output: Social media URLs

3. ✅ **Get competitors Instagram last 20 posts**
   - Maps to: Task 3
   - Input: Instagram URLs
   - Output: Posts + engagement metrics

4. ✅ **Get competitor last 20 LinkedIn posts**
   - Maps to: Task 4
   - Input: LinkedIn URLs
   - Output: Posts + engagement metrics

### Additional n8n Workflow Needed

5. ⚠️ **Generate analysis report** (Task 6)
   - Not mentioned in your list
   - Input: All research data from project.context
   - Output: Markdown report with insights
   - Can use AI (GPT-4, Claude) to synthesize data

**If you don't have #5:**
- Task 6 can be marked as `human` execution type
- User manually writes report
- Or create a simple n8n workflow with AI prompt template

### n8n Workflow Template for Report Generation

```javascript
// n8n workflow "generate_analysis_report"

// 1. Webhook Trigger (receives task_id, project_id)
const { task_id, project_id } = $input.all();

// 2. Get Project Context
const project = await $http.request({
  url: `http://localhost:8055/items/projects/${project_id}`,
  headers: { Authorization: 'Bearer TOKEN' },
  params: { fields: 'context' }
});

const context = project.data.context;

// 3. Extract Research Data
const competitors = context.research.competitors;
const instagram = context.research.social_media.instagram;
const linkedin = context.research.social_media.linkedin;

// 4. Generate Report with AI
const prompt = `
You are a competitive analysis expert. Generate a comprehensive brand research report based on the following data:

Competitors: ${JSON.stringify(competitors, null, 2)}

Instagram Analysis: ${JSON.stringify(instagram, null, 2)}

LinkedIn Analysis: ${JSON.stringify(linkedin, null, 2)}

Create a professional report with these sections:
1. Executive Summary
2. Competitor Overview
3. Social Media Presence Analysis
4. Content Strategy Insights
5. Engagement Benchmarks
6. Identified Opportunities
7. Strategic Recommendations

Format as Markdown with proper headings, bullet points, and tables.
`;

const report = await $http.request({
  url: 'https://api.openai.com/v1/chat/completions',
  method: 'POST',
  headers: {
    'Authorization': 'Bearer YOUR_OPENAI_KEY',
    'Content-Type': 'application/json'
  },
  body: {
    model: 'gpt-4',
    messages: [
      { role: 'system', content: 'You are a brand research analyst.' },
      { role: 'user', content: prompt }
    ]
  }
});

const reportText = report.data.choices[0].message.content;

// 5. Save Report as File
const file = await $http.request({
  url: 'http://localhost:8055/files',
  method: 'POST',
  headers: { Authorization: 'Bearer TOKEN' },
  body: {
    title: `${project.data.title} - Competitive Analysis Report`,
    type: 'text/markdown',
    filename_download: 'competitive-analysis-report.md'
  },
  file: Buffer.from(reportText)
});

// 6. Create artifact_version
await $http.request({
  url: 'http://localhost:8055/items/artifact_versions',
  method: 'POST',
  headers: { Authorization: 'Bearer TOKEN' },
  body: {
    project_id: project_id,
    schema_key: 'analysis.summary',
    status: 'pending',
    primary_file_id: file.data.id,
    source_task_id: task_id,
    value: {
      word_count: reportText.split(' ').length,
      sections: 7,
      generated_at: new Date().toISOString()
    }
  }
});

// 7. Update Task Status
await $http.request({
  url: `http://localhost:8055/items/tasks/${task_id}`,
  method: 'PATCH',
  headers: { Authorization: 'Bearer TOKEN' },
  body: { status: 'needs_review' }
});

return { success: true, report_length: reportText.length };
```

---

## Customization Options

### Adjust SLAs

Edit template_version → pre_seeded_tasks → `sla_minutes`:

```javascript
await directus.items('template_versions').updateOne(1, {
  pre_seeded_tasks: [
    { ...task1, sla_minutes: 10 },  // Increase to 10 min
    ...
  ]
});
```

### Add More Tasks

Append to `pre_seeded_tasks` array:

```json
{
  "title": "Analyze Competitor Website UX",
  "description": "Automated UX analysis of competitor websites",
  "execution_type": "ai",
  "order": 2.5,
  "depends_on": ["Extract Competitor Links & Social Profiles"],
  "notes": "n8n workflow: analyze_competitor_ux"
}
```

### Modify Context Schema

Update `template_definition.context_schema` to add new data paths:

```json
{
  "research": {
    "website_ux": {
      "type": "object",
      "description": "Website UX analysis per competitor",
      "required": false
    }
  }
}
```

---

## Troubleshooting

### Tasks Not Auto-Creating

**Problem:** Project created but no tasks appear

**Solutions:**
1. Check if task auto-creation is implemented (Flow/Hook)
2. Manually create tasks from template:
   ```javascript
   const template = await directus.items('template_versions').readOne(1);
   const tasks = JSON.parse(template.pre_seeded_tasks);

   for (const taskDef of tasks) {
     await directus.items('tasks').createOne({
       project_id: project_id,
       title: taskDef.title,
       description: taskDef.description,
       execution_type: taskDef.execution_type,
       status: taskDef.status,
       priority: taskDef.priority,
       sla_minutes: taskDef.sla_minutes
     });
   }
   ```

### n8n Workflows Not Triggering

**Problem:** Tasks stay in `new` status

**Solutions:**
1. Manually trigger n8n workflow with task_id
2. Check n8n webhook URLs are correct
3. Verify Directus Flow is active and configured
4. Check n8n workflow has proper Directus credentials

### Context Not Updating

**Problem:** Approved artifacts not appearing in project.context

**Solutions:**
1. Implement promotion flow (see ARTIFACT_SYSTEM_COMPLETE.md)
2. Manually promote artifact:
   ```javascript
   const project = await directus.items('projects').readOne(pid);
   const artifact = await directus.items('artifact_versions').readOne(aid);

   const newContext = { ...project.context };
   _.set(newContext, artifact.schema_key, artifact.value);
   newContext._meta.context_version += 1;

   await directus.items('projects').updateOne(pid, {
     context: newContext,
     context_version: project.context_version + 1
   });
   ```

### Partial Unique Index Violation

**Problem:** "duplicate key value violates unique constraint" error

**Cause:** Trying to approve second artifact for same schema_key

**Solution:**
1. First, set existing approved artifact to `superseded`:
   ```sql
   UPDATE artifact_versions
   SET status = 'superseded'
   WHERE project_id = $1 AND schema_key = $2 AND status = 'approved';
   ```
2. Then approve new artifact

---

## Next Steps

### 1. Implement Task Auto-Creation

**Recommended: Directus Flow**

Create Flow in admin UI:
- **Trigger:** Event Hook → `items.create` → `projects`
- **Filter:** `template_id` is not null
- **Operations:**
  1. Read template_version data
  2. Parse pre_seeded_tasks JSON
  3. Loop: Create each task
  4. Create task_dependencies

### 2. Connect n8n Workflows

For each task, set up n8n workflow to:
1. Listen for task status = `in_progress`
2. Execute your existing workflows
3. Create artifact_versions with results
4. Update task status to `needs_review`

### 3. Implement Promotion Flow

Create Flow for artifact → context promotion:
- **Trigger:** `items.update` → `tasks` → status = `done`
- **Operations:**
  1. Get approved artifacts for task
  2. Update project.context (with optimistic lock)
  3. Create document records if needed

### 4. Test End-to-End

1. Create test project from template
2. Monitor task execution
3. Review artifacts
4. Verify context updates
5. Check final report generation

### 5. Production Deployment

- Migrate to PostgreSQL
- Add indexes (see ARTIFACT_SYSTEM_COMPLETE.md)
- Set up monitoring and alerts
- Configure n8n for production

---

## Summary

✅ **Template Created:** ID 1, Version 1.0.0
✅ **Tasks Defined:** 6 tasks (4 AI automated, 1 human review, 1 AI report)
✅ **n8n Mapping:** Matches your 4 existing workflows
✅ **Context Schema:** Structured data paths for research outputs
✅ **Dependencies:** Proper task ordering with parallel execution

**What's Working:**
- Template and template_version records created in Directus
- Pre-seeded tasks defined with proper dependencies
- Context schema for data organization

**What Needs Implementation:**
- Task auto-creation (Flow or Hook)
- n8n workflow integration
- Artifact promotion flow
- Report generation workflow (Task 6)

**Files Created:**
- `/Users/parijat/Desktop/Directus/templates/brand_research_v1.json`
- `/Users/parijat/Desktop/Directus/BRAND_RESEARCH_TEMPLATE_GUIDE.md` (this file)

**Database Records:**
- `templates.id = 1`
- `template_versions.id = 1`

**Admin Links:**
- Template: http://localhost:8055/admin/content/templates/1
- Template Version: http://localhost:8055/admin/content/template_versions/1
