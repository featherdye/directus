# Conversational Schema Creation System

## 🎯 What This Does

You describe what you want in plain English → I create it instantly in your Directus!

**Example:**
> **You:** "Create a `customers` collection with name, email, phone, and company"
>
> **Me:** *Generates and runs the schema* ✨
>
> **Result:** Collection appears at http://localhost:8055/admin/content/customers

## 🚀 Quick Start

### Method 1: You Describe, I Create (Fastest)

Just tell me what you need:
- "Create a tasks collection with title, status, and due date"
- "Add a products collection with name, price, description, and category"
- "I need a customers table with contact info and billing address"

I'll generate and run the commands instantly!

### Method 2: Use the Helper Script

```bash
cd /Users/parijat/Desktop/Directus
node create-schema.mjs your-schema.json
```

## 📝 Schema Definition Format

Create a JSON file describing your schema:

```json
{
  "collection": "my_collection",
  "options": {
    "icon": "box",
    "note": "Description of this collection"
  },
  "fields": [
    {
      "field": "name",
      "type": "string",
      "interface": "input",
      "required": true,
      "note": "Field description"
    }
  ]
}
```

## 🎨 Field Types & Interfaces

### Common Field Types

| Type | Description | Interface |
|------|-------------|-----------|
| `string` | Short text | `input` |
| `text` | Long text | `textarea` |
| `integer` | Whole numbers | `input` |
| `decimal` | Decimals | `input` |
| `boolean` | True/False | `boolean` |
| `date` | Date only | `datetime` |
| `timestamp` | Date & time | `datetime` |
| `json` | JSON data | `input-code` |
| `uuid` | Unique ID | `input` |

### Special Interfaces

**Dropdown (Select)**
```json
{
  "field": "status",
  "type": "string",
  "interface": "select-dropdown",
  "options": {
    "choices": [
      { "text": "Draft", "value": "draft" },
      { "text": "Published", "value": "published" }
    ]
  }
}
```

**File Upload**
```json
{
  "field": "avatar",
  "type": "uuid",
  "interface": "file"
}
```

**Rich Text Editor**
```json
{
  "field": "content",
  "type": "text",
  "interface": "wysiwyg"
}
```

**Tags**
```json
{
  "field": "tags",
  "type": "json",
  "interface": "tags"
}
```

## 🔗 Creating Relationships

### Many-to-One (Customer → Organization)

```json
{
  "field": "organization",
  "type": "uuid",
  "interface": "select-dropdown-m2o"
}
```

Then create the relation:
```javascript
{
  "collection": "customers",
  "field": "organization",
  "related_collection": "organizations"
}
```

### One-to-Many (Organization has many Customers)

Automatically created when you create the Many-to-One!

### Many-to-Many (Projects ←→ Tags)

Requires a junction table:
```json
{
  "collection": "projects_tags",
  "fields": [
    { "field": "projects_id", "type": "uuid" },
    { "field": "tags_id", "type": "uuid" }
  ]
}
```

## 📚 Complete Examples

### Example 1: Customer Management

```json
{
  "collection": "customers",
  "options": {
    "icon": "person",
    "note": "Customer database"
  },
  "fields": [
    {
      "field": "name",
      "type": "string",
      "interface": "input",
      "required": true
    },
    {
      "field": "email",
      "type": "string",
      "interface": "input",
      "required": true,
      "unique": true
    },
    {
      "field": "phone",
      "type": "string",
      "interface": "input"
    },
    {
      "field": "company",
      "type": "string",
      "interface": "input"
    },
    {
      "field": "status",
      "type": "string",
      "interface": "select-dropdown",
      "options": {
        "choices": [
          { "text": "Active", "value": "active" },
          { "text": "Inactive", "value": "inactive" }
        ]
      },
      "defaultValue": "active"
    }
  ]
}
```

### Example 2: Blog Posts

```json
{
  "collection": "blog_posts",
  "options": {
    "icon": "article",
    "note": "Blog content management"
  },
  "fields": [
    {
      "field": "title",
      "type": "string",
      "interface": "input",
      "required": true
    },
    {
      "field": "slug",
      "type": "string",
      "interface": "input",
      "unique": true,
      "required": true
    },
    {
      "field": "content",
      "type": "text",
      "interface": "wysiwyg"
    },
    {
      "field": "excerpt",
      "type": "text",
      "interface": "textarea"
    },
    {
      "field": "featured_image",
      "type": "uuid",
      "interface": "file"
    },
    {
      "field": "status",
      "type": "string",
      "interface": "select-dropdown",
      "options": {
        "choices": [
          { "text": "Draft", "value": "draft" },
          { "text": "Published", "value": "published" }
        ]
      },
      "defaultValue": "draft"
    },
    {
      "field": "publish_date",
      "type": "timestamp",
      "interface": "datetime"
    },
    {
      "field": "tags",
      "type": "json",
      "interface": "tags"
    }
  ]
}
```

### Example 3: E-commerce Products

```json
{
  "collection": "products",
  "options": {
    "icon": "shopping_cart",
    "note": "Product catalog"
  },
  "fields": [
    {
      "field": "name",
      "type": "string",
      "interface": "input",
      "required": true
    },
    {
      "field": "sku",
      "type": "string",
      "interface": "input",
      "unique": true,
      "required": true
    },
    {
      "field": "description",
      "type": "text",
      "interface": "wysiwyg"
    },
    {
      "field": "price",
      "type": "decimal",
      "interface": "input",
      "required": true
    },
    {
      "field": "stock",
      "type": "integer",
      "interface": "input",
      "defaultValue": 0
    },
    {
      "field": "images",
      "type": "json",
      "interface": "files"
    },
    {
      "field": "is_active",
      "type": "boolean",
      "interface": "boolean",
      "defaultValue": true
    },
    {
      "field": "category",
      "type": "string",
      "interface": "select-dropdown",
      "options": {
        "choices": [
          { "text": "Electronics", "value": "electronics" },
          { "text": "Clothing", "value": "clothing" },
          { "text": "Books", "value": "books" },
          { "text": "Home & Garden", "value": "home_garden" }
        ]
      }
    }
  ]
}
```

## 🎯 Workflow

### Standard Flow:

1. **You describe** what you need
2. **I create** the JSON schema
3. **I run** the command
4. **You verify** at http://localhost:8055

### Advanced Flow:

1. **You provide** detailed requirements
2. **I create** multiple related collections
3. **I set up** relationships between them
4. **We iterate** until perfect

## 🛠️ Helper Script Reference

### Create Collection
```javascript
import { createSchema } from './create-schema.mjs';

await createSchema({
  collection: 'my_collection',
  fields: [...]
});
```

### Available Functions
- `createCollection()` - Create a new collection
- `createField()` - Add a field to existing collection
- `createRelation()` - Create relationships
- `createSchema()` - Full schema creation (recommended)

## 💡 Tips

1. **ID Field** - Don't add an `id` field, Directus creates it automatically
2. **Timestamps** - Use `date_created` and `date_updated` for automatic timestamps
3. **User Tracking** - Use `user_created` and `user_updated` for automatic user tracking
4. **Icons** - Browse icons at https://fonts.google.com/icons
5. **Interfaces** - Check Directus docs for all interface types

## 🔄 Quick Commands

```bash
# Create from JSON file
node create-schema.mjs your-schema.json

# Delete a collection (start over)
curl -X DELETE "http://localhost:8055/collections/collection_name" \
  -H "Authorization: Bearer agency-os-static-token-12345"

# List all collections
curl -s "http://localhost:8055/collections" \
  -H "Authorization: Bearer agency-os-static-token-12345"
```

## ✅ Example Test Collection

We created a test collection to verify the system works:

**Collection:** `test_tasks`
**Fields:**
- title (string, required)
- description (text)
- status (dropdown: draft/in_progress/done)
- priority (dropdown: low/medium/high)
- due_date (date)

**View it:** http://localhost:8055/admin/content/test_tasks

## 🎓 Ready to Start!

Just tell me what collection you want to create! Examples:
- "Create a users collection with profile fields"
- "I need a products table for my store"
- "Set up a blog with posts and comments"
- "Create a CRM with leads, contacts, and deals"

I'll handle the rest! 🚀
