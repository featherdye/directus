# Directus Flat Tabs Interface ![NPM Version](https://img.shields.io/npm/v/directus-extension-flat-tabs-interface)

A tab group interface for Directus.

<img src="https://raw.githubusercontent.com/sofiaringstrom/directus-extension-flat-tabs-interface/refs/heads/main/docs/screenshot.png" width="100%" height="auto" style="border: 1px solid #d4d4d8; border-radius: 12px;">

<img src="https://raw.githubusercontent.com/sofiaringstrom/directus-extension-flat-tabs-interface/refs/heads/main/docs/screenshot-data-model.png" width="100%" height="auto" style="border: 1px solid #d4d4d8; border-radius: 12px;">

## Features

- **Flexible Alignment**: Choose from `Left`, `Right`, `Center`, `Between`, or `Stretch` alignment for tab positioning
- **Raw Group Support**: Works with Directus raw groups to create tabbed interfaces

## Installation

Install the extension from the Directus Marketplace. See the [Official Guide](https://docs.directus.io/extensions/installing-extensions.html) for more information.

Or if you prefer to install manually:

```bash
npm install directus-extension-flat-tabs-interface
```

## Usage

### Creating a Tab Group

1. **Create a Group Field**: In your Directus collection, create a new field with the "Flat Tabs" type. Alternatively, you can use the "Group" type and select "Flat Tabs" as the interface.
2. **Configure Alignment**: Set the tab alignment option (left, right, center, or cover)
3. **Add Raw Groups**: Add "Raw Group" fields as children of your Flat Tabs field - each raw group field will become a tab
4. **Add Fields to Tabs**: Add your desired fields as children of each raw group field

### Example Structure

```
My Collection
├── Tab Group (Group field with "Flat Tabs" interface)
│   ├── Tab 1 (Raw Group)
│   │   ├── Title (Input)
│   │   ├── Description (Textarea)
│   │   └── Image (File)
│   ├── Tab 2 (Raw Group)
│   │   ├── Settings (JSON)
│   │   └── Options (Checkboxes)
│   └── Tab 3 (Raw Group)
│       ├── Content (WYSIWYG)
```

### Configuration Options

- **Align Tabs**: Controls the horizontal alignment of the tab list

  - `Left`: Tabs aligned to the left (default)
  - `Right`: Tabs aligned to the right
  - `Center`: Tabs centered
  - `Between`: Tabs aligned to the left and right
  - `Stretch`: Tabs stretched to fill the full width

## Development

### Setup

1. [Load Extension volume](https://directus.io/docs/guides/extensions/quickstart#loading-an-extension-volume) in your project and clone the repository to it

2. Install dependencies:

```bash
cd extensions/directus-extension-flat-tabs-interface

npm install
```

3. Build the extension with auto rebuild on changes:

```bash
npm run dev
```

Make sure you've set `EXTENSIONS_AUTO_RELOAD` in your `.env` file.

You might need to restart your Directus instance for the extension to be loaded.

### Building

```bash
npm run build
```

## How It Works

This extension works by:

1. **Processing Raw Groups**: The interface looks for children fields with the "group-raw" interface type
2. **Creating Tabs**: Each raw group field becomes a tab in the interface
3. **Rendering Fields**: Fields within each raw group are rendered
