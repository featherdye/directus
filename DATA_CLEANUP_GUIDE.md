# Agency OS Data Cleanup Guide

## Current Situation

The Agency OS template was installed with **data integrity issues** due to Node.js version incompatibility (Node 24 vs required Node 22). This caused "Invalid foreign key" errors during import, resulting in many null references throughout the content.

## What Went Wrong

During template installation, you saw:
```
-- Request failed with status 400. Invalid foreign key.
```

This means:
- ✅ Database schema created successfully
- ✅ Collections and fields created successfully
- ✅ Files uploaded successfully (49 files)
- ❌ Relationships between content and files failed
- ❌ Junction table entries have null foreign keys

## Affected Components

Based on errors encountered:
1. **Gallery blocks** - null file references
2. **Testimonials** - null testimonial references
3. **Hero blocks** - null button/image references
4. **Team blocks** - null team member references
5. **Logo clouds** - null logo references
6. **Button groups** - null button references

## The Root Cause

**Node.js 24 incompatibility:**
- Directus officially requires Node.js 22
- Node 24 is too new - some dependencies don't have compiled binaries yet
- This causes the template import process to fail on foreign key creation

## Solutions

### Option 1: Clean Up All Broken Data (Current Approach)

**What you did:**
- Deleted null entries from affected collections ✓

**What still needs to be done:**
You need to check and clean these collections in Directus admin (http://localhost:8055):

1. **Hero Blocks** (`block_hero`)
   - Check for entries with null `buttons` or `image` references
   - Either delete them or fix the references

2. **Button Groups** (`block_button_group`)
   - Check for null `buttons` references

3. **Logo Clouds** (`block_logocloud`)
   - Check for null `logos` references

4. **Team Blocks** (`block_team`)
   - Check for null `team_members` references

**How to clean in admin panel:**
1. Go to http://localhost:8055
2. Login: `admin@example.com` / `d1r3ctu5`
3. For each collection:
   - Navigate to Content → [Collection Name]
   - Filter or find entries with empty/null relations
   - Delete or fix them

### Option 2: Remove Problematic Blocks from Homepage (Quickest)

Instead of cleaning all data, just remove the broken blocks from the Home page:

1. Go to http://localhost:8055
2. Navigate to Content → Pages
3. Find "Home" page
4. Edit the page
5. Remove blocks that are causing errors:
   - Any Hero blocks with issues
   - Gallery blocks
   - Testimonial blocks
   - Team blocks
6. Save the page

The homepage will load with fewer blocks, but it will work.

### Option 3: Start Fresh with Node 22 (Best Long-term)

This gives you a clean install without data issues:

**Steps:**
1. Install Node Version Manager (fnm or nvm)
   ```bash
   # Using fnm (recommended for macOS)
   brew install fnm
   fnm install 22
   fnm use 22
   ```

2. Stop current services
   ```bash
   cd /Users/parijat/Desktop/Directus
   docker-compose down
   ```

3. Clean up and reinstall
   ```bash
   # Remove database and start fresh
   rm -rf database/ uploads/

   # Restart Directus
   docker-compose up -d

   # Reapply template
   npx directus-template-cli@latest apply -p \
     --directusUrl="http://localhost:8055" \
     --directusToken="agency-os-static-token-12345" \
     --templateLocation="agency-os" \
     --templateType="community"
   ```

4. Frontend will work properly with complete data

### Option 4: Fix Components with Null Checks (Development Fix)

Add defensive null checks to all Vue components (what I started doing):
- Prevents crashes but galleries/testimonials remain empty
- Good for development but not ideal for production

## Recommended Approach

**For learning/testing:**
→ **Option 2** (Remove broken blocks from homepage)
- Fastest way to see Agency OS working
- Can add content manually later

**For production/serious use:**
→ **Option 3** (Fresh install with Node 22)
- Clean data from the start
- No null reference issues
- Official supported environment

## Quick Commands

### Check for null references
```bash
# Check gallery files
curl -s "http://localhost:8055/items/block_gallery_files?filter[directus_files_id][_null]=true" \
  -H "Authorization: Bearer agency-os-static-token-12345"

# Check testimonials
curl -s "http://localhost:8055/items/block_testimonial_items?filter[testimonials_id][_null]=true" \
  -H "Authorization: Bearer agency-os-static-token-12345"
```

### Access Admin Panel
```
URL: http://localhost:8055
Email: admin@example.com
Password: d1r3ctu5
```

### Check Node Version
```bash
node --version
# Current: v24.6.0
# Needed: v22.x.x
```

## Next Steps

Choose your approach:
1. ☐ Option 1: Manually clean all collections (tedious but keeps current setup)
2. ☑ Option 2: Remove broken blocks (quick win)
3. ☐ Option 3: Fresh install with Node 22 (best long-term)
4. ☐ Option 4: Fix all components with null checks (developer workaround)

Let me know which path you'd like to take!

---

**Current Status:**
- Backend: Running at http://localhost:8055 ✓
- Frontend: Running at http://localhost:3000 ✓
- Data: Partially broken due to Node version incompatibility ⚠️
- Files: Uploaded successfully (49 files) ✓
