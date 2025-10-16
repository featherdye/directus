# Directus Schema Backups

This directory contains backups of the Directus schema configuration.

## Latest Backup

**File:** `schema_backup_2025-10-16T10-23-07.json` (817 KB)
**Created:** 2025-10-16 15:53

## Backup Contents

Each backup includes:

1. **Collections** (~40 KB)
   - All collection definitions
   - Icons, visibility, and metadata
   - System and custom collections

2. **Fields** (~425 KB)
   - All field definitions for every collection
   - Field types, interfaces, validation rules
   - Display options and metadata

3. **Relations** (~34 KB)
   - All M2O and O2M relationships
   - Foreign key constraints
   - Junction fields for M2M relations

## Current Schema Overview

### Custom Collections Created:
- `companies` - Client companies and organizations
- `clients` - Individual contacts
- `opportunities` - Sales pipeline and deals
- `projects` - Work containers (all work lives in projects)
- `tasks` - Work items with AI/human execution tracking
- `documents` - Document registry with file attachments
- `jobs` - AI automation job tracking
- `task_executions` - AI quality metrics and SLA tracking
- `task_dependencies` - Task ordering and dependencies
- `templates` - Parent collection for project templates
- `template_versions` - Versioned template implementations
- `approvals` - Maker-checker approval workflows
- `file_attachments` - Multi-parent file attachment system

### Key Relationships:
- `templates` → `template_versions` (one-to-many)
- `template_versions` → `projects` (one-to-many)
- `projects` → `tasks` (one-to-many)
- `tasks` → `task_dependencies` (self-referential)
- `tasks` → `task_executions` (one-to-many)
- `companies` → `clients`, `opportunities`, `projects`, `documents`
- `opportunities` → `projects`

## How to Restore

### Option 1: Using Directus CLI (Recommended)

```bash
# Install Directus schema tools
npm install -g @directus/schema

# Apply schema snapshot
npx directus schema apply --snapshot schema_backup_2025-10-16T10-23-07.json
```

### Option 2: Using API (Manual)

The backup is structured as:
```json
{
  "timestamp": "ISO 8601 timestamp",
  "collections": { /* Directus API response */ },
  "fields": { /* Directus API response */ },
  "relations": { /* Directus API response */ }
}
```

To restore manually:
1. Create collections first
2. Create fields for each collection
3. Create relationships last

### Option 3: Database Snapshot

For complete restoration including data, use Directus snapshots:

```bash
# Create snapshot (includes data)
npx directus schema snapshot ./snapshot.yaml

# Apply snapshot
npx directus schema apply ./snapshot.yaml
```

## Individual Files

If you only need specific parts:

- `collections.json` - Collection definitions only
- `fields.json` - Field definitions only
- `relations.json` - Relationship definitions only

## Backup Schedule

**Manual backups recommended:**
- Before major schema changes
- After adding new collections
- Before production deployment
- Monthly for disaster recovery

## Version History

| Date | File | Size | Notes |
|------|------|------|-------|
| 2025-10-16 | schema_backup_2025-10-16T10-23-07.json | 817 KB | After template system redesign |

## Notes

- Backups do NOT include actual data (records), only schema structure
- System collections (directus_*) are included but don't need manual restoration
- For data backup, use database dumps or Directus data export features
- Schema is SQLite-compatible (current dev environment)
- Production should use PostgreSQL - schema may need migration adjustments
