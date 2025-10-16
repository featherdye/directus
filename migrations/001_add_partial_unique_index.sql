-- Migration: Add partial unique index for one approved artifact per path
-- Purpose: Ensures only ONE approved artifact exists per (project_id, schema_key)
-- Database: PostgreSQL (for production) or SQLite (for dev)

-- PostgreSQL version:
CREATE UNIQUE INDEX IF NOT EXISTS idx_one_approved_per_path
ON artifact_versions (project_id, schema_key)
WHERE status = 'approved';

-- SQLite version (if needed for dev):
-- CREATE UNIQUE INDEX IF NOT EXISTS idx_one_approved_per_path
-- ON artifact_versions (project_id, schema_key)
-- WHERE status = 'approved';

-- This index prevents race conditions where two artifacts could be approved
-- for the same schema_key (e.g., brand.logo) within the same project.
-- The promotion flow must handle 409 Conflicts gracefully when this constraint is violated.
