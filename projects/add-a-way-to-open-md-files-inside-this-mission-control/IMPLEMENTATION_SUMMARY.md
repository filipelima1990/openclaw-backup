# Markdown Preview Implementation for Mission Control

## Problem
Mission Control had no way to preview `.md` files directly in the browser. Users were getting errors like:
```
Could not open Finder Path /root/.openclaw/workspace/projects/review-forebet-website/COMPARISON_REPORT.md
```

This was because:
1. The "Reveal in Finder" feature only works on macOS/Windows, not Linux
2. There was no preview button for markdown files (only HTML files had preview)

## Solution
Added markdown preview support to Mission Control:

### 1. Enhanced Preview API
**File:** `/opt/mission-control/src/app/api/files/preview/route.ts`

- Added support for `.md` and `.markdown` file extensions
- Integrated the `marked` library to convert markdown to HTML
- Applied GitHub-style CSS styling for beautiful markdown rendering
- Maintained existing HTML file support

**Changes:**
```typescript
// Before: Only HTML files
if (!filePath.endsWith('.html') && !filePath.endsWith('.htm')) {
  return NextResponse.json({ error: 'Only HTML files can be previewed' }, { status: 400 });
}

// After: HTML and Markdown files
const isHtml = filePath.endsWith('.html') || filePath.endsWith('.htm');
const isMarkdown = filePath.endsWith('.md') || filePath.endsWith('.markdown');
```

For markdown files, the API now:
1. Reads the markdown content
2. Converts to HTML using `marked.parse()`
3. Wraps in a styled HTML template with GitHub-inspired CSS
4. Returns as a complete, renderable HTML page

### 2. Updated Deliverables List Component
**File:** `/opt/mission-control/src/components/DeliverablesList.tsx`

- Added `isPreviewable()` helper function to check if a file can be previewed
- Updated preview button visibility to include markdown files
- Maintains the "Reveal in Finder" button as a fallback

**Changes:**
```typescript
// New helper function
const isPreviewable = (deliverable: TaskDeliverable) => {
  if (!deliverable.path) return false;
  return deliverable.path.endsWith('.html') ||
         deliverable.path.endsWith('.htm') ||
         deliverable.path.endsWith('.md') ||
         deliverable.path.endsWith('.markdown');
};

// Updated preview button logic
{deliverable.deliverable_type === 'file' && isPreviewable(deliverable) && (
  <button
    onClick={() => handlePreview(deliverable)}
    className="flex-shrink-0 p-1.5 hover:bg-mc-bg-tertiary rounded text-mc-accent-cyan"
    title="Preview in browser"
  >
    <Eye className="w-4 h-4" />
  </button>
)}
```

### 3. Dependencies
Added `marked` package:
```bash
cd /opt/mission-control && npm install marked
```

## Features
✅ **Preview button now appears for .md files** - Click the eye icon to view markdown in browser
✅ **Beautiful GitHub-style rendering** - Syntax highlighting, tables, code blocks, headers
✅ **Responsive design** - Works on desktop and mobile
✅ **Security maintained** - Same path validation and allowed directory checks
✅ **Backward compatible** - Existing HTML preview functionality unchanged

## Testing
To test the implementation:
1. Open Mission Control at http://localhost:4000
2. Find a task with a .md file deliverable
3. Click the eye (preview) icon
4. The markdown file should open in a new tab with styled rendering

## Files Modified
- `/opt/mission-control/src/app/api/files/preview/route.ts` - Enhanced API
- `/opt/mission-control/src/components/DeliverablesList.tsx` - Updated UI
- `/opt/mission-control/package.json` - Added `marked` dependency
