#!/bin/bash

# Collections to KEEP (the ones we created)
KEEP_COLLECTIONS=(
  "jobs"
  "global_databases"
  "project_databases"
  "database_rows"
  "file_attachments"
  "approvals"
  "task_dependencies"
  "template_versions"
  "task_executions"
  "test_tasks"
)

# Collections to REMOVE (all Agency OS collections)
REMOVE_COLLECTIONS=(
  "categories"
  "contacts"
  "conversations"
  "help"
  "help_articles"
  "help_collections"
  "help_feedback"
  "inbox"
  "messages"
  "navigation_items"
  "organization_addresses"
  "organizations"
  "organizations_contacts"
  "os_activities"
  "os_activity_contacts"
  "os_deal_contacts"
  "os_deal_stages"
  "os_deals"
  "os_email_templates"
  "os_expenses"
  "os_invoice_items"
  "os_invoices"
  "os_items"
  "os_payment_terms"
  "os_payments"
  "os_project_contacts"
  "os_project_templates"
  "os_project_updates"
  "os_projects"
  "os_proposal_approvals"
  "os_proposal_blocks"
  "os_proposal_contacts"
  "os_proposals"
  "os_settings"
  "os_task_files"
  "os_tasks"
  "os_tax_rates"
  "page_blocks"
  "pages"
  "pages_blog"
  "pages_projects"
  "post_gallery_items"
  "posts"
  "redirects"
  "sales"
  "seo"
  "team"
  "testimonials"
  "website"
  "billing"
  "blocks"
  "forms"
  "globals"
  "navigation"
)

DIRECTUS_URL="http://localhost:8055"
DIRECTUS_TOKEN="agency-os-static-token-12345"

echo "🗑️  Starting cleanup of Agency OS collections..."
echo ""

REMOVED_COUNT=0
FAILED_COUNT=0

for collection in "${REMOVE_COLLECTIONS[@]}"; do
  echo -n "Removing $collection... "

  RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE \
    "$DIRECTUS_URL/collections/$collection" \
    -H "Authorization: Bearer $DIRECTUS_TOKEN" \
    2>&1)

  HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

  if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Removed"
    ((REMOVED_COUNT++))
  elif [ "$HTTP_CODE" = "404" ]; then
    echo "⏭️  Not found (already removed or doesn't exist)"
  else
    echo "❌ Failed (HTTP $HTTP_CODE)"
    ((FAILED_COUNT++))
  fi

  sleep 0.1  # Small delay to avoid rate limiting
done

echo ""
echo "=========================================="
echo "✨ Cleanup Complete!"
echo "   Removed: $REMOVED_COUNT collections"
echo "   Failed: $FAILED_COUNT collections"
echo "=========================================="
echo ""
echo "🎯 Remaining collections (our new schema):"
for collection in "${KEEP_COLLECTIONS[@]}"; do
  echo "   ✓ $collection"
done
echo ""
echo "View at: http://localhost:8055/admin/content"
