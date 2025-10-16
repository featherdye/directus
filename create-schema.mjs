#!/usr/bin/env node

/**
 * Directus Schema Creator
 * Conversational schema creation tool for Directus
 */

const DIRECTUS_URL = 'http://localhost:8055';
const DIRECTUS_TOKEN = 'agency-os-static-token-12345';

/**
 * Create a collection in Directus
 */
async function createCollection(collectionName, options = {}) {
  const { icon = 'box', hidden = false, singleton = false, note = '' } = options;

  const response = await fetch(`${DIRECTUS_URL}/collections`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${DIRECTUS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      collection: collectionName,
      meta: {
        icon,
        hidden,
        singleton,
        note,
      },
      schema: {
        name: collectionName,
      },
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to create collection: ${JSON.stringify(error)}`);
  }

  return await response.json();
}

/**
 * Create a field in a collection
 */
async function createField(collectionName, fieldConfig) {
  const {
    field,
    type,
    interface: interfaceType = 'input',
    required = false,
    defaultValue = null,
    unique = false,
    note = '',
    options = {},
  } = fieldConfig;

  const response = await fetch(`${DIRECTUS_URL}/fields/${collectionName}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${DIRECTUS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      field,
      type,
      meta: {
        interface: interfaceType,
        required,
        note,
        options,
      },
      schema: {
        default_value: defaultValue,
        is_unique: unique,
      },
    }),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to create field ${field}: ${JSON.stringify(error)}`);
  }

  return await response.json();
}

/**
 * Create a relation between collections
 */
async function createRelation(relationConfig) {
  const response = await fetch(`${DIRECTUS_URL}/relations`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${DIRECTUS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(relationConfig),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(`Failed to create relation: ${JSON.stringify(error)}`);
  }

  return await response.json();
}

/**
 * Main schema creation function
 */
async function createSchema(schemaDefinition) {
  const { collection, fields, relations = [], options = {} } = schemaDefinition;

  try {
    console.log(`\n🚀 Creating collection: ${collection}`);
    await createCollection(collection, options);
    console.log(`✅ Collection "${collection}" created`);

    // Create fields
    for (const fieldConfig of fields) {
      console.log(`   Adding field: ${fieldConfig.field} (${fieldConfig.type})`);
      await createField(collection, fieldConfig);
    }
    console.log(`✅ All fields created`);

    // Create relations
    for (const relationConfig of relations) {
      console.log(`   Creating relation: ${relationConfig.field}`);
      await createRelation(relationConfig);
    }

    if (relations.length > 0) {
      console.log(`✅ All relations created`);
    }

    console.log(`\n✨ Schema created successfully!`);
    console.log(`   View it at: ${DIRECTUS_URL}/admin/content/${collection}\n`);

    return { success: true };
  } catch (error) {
    console.error(`\n❌ Error creating schema:`, error.message);
    return { success: false, error: error.message };
  }
}

// Export for use as module
export { createSchema, createCollection, createField, createRelation };

// CLI usage
if (import.meta.url === `file://${process.argv[1]}`) {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    console.log(`
Directus Schema Creator

Usage: node create-schema.mjs [schema-file.json]

Or use as a module:
  import { createSchema } from './create-schema.mjs';

  await createSchema({
    collection: 'my_collection',
    fields: [
      { field: 'title', type: 'string', interface: 'input', required: true },
      { field: 'description', type: 'text', interface: 'textarea' }
    ]
  });
`);
    process.exit(0);
  }

  // Load schema from file
  const schemaFile = args[0];
  const fs = await import('fs');
  const schemaDefinition = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));

  await createSchema(schemaDefinition);
}
