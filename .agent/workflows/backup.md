---
description: Create backup of Mindora project
---

# Backup Mindora Project

This workflow creates a timestamped backup of all critical project files including storyboards, Swift files, and project configuration.

## Steps

// turbo
1. **Run the backup script**
   ```bash
   cd "/Users/pawanpreetsingh/Downloads/Mindora original 3"
   ./backup_project.sh
   ```

The script will:
- Create a timestamped backup in `.backups/backup_YYYYMMDD_HHMMSS/`
- Backup `Main.storyboard`
- Backup all Swift source files
- Backup project configuration (`project.pbxproj`)
- Backup `Info.plist`
- Keep only the last 10 backups (auto-cleanup)
- Create a manifest file with backup details

## Backup Location

All backups are stored in:
```
/Users/pawanpreetsingh/Downloads/Mindora original 3/.backups/
```

## When to Run

**Run this backup before:**
- Making major changes to storyboards
- Refactoring Swift code
- Updating project configuration
- Installing new dependencies
- Before each work session (recommended)

## Restoring from Backup

To restore from a backup, use the restore script:
```bash
cd "/Users/pawanpreetsingh/Downloads/Mindora original 3"
./restore_backup.sh
```

The restore script will:
1. Show you all available backups
2. Let you select which backup to restore
3. Create a safety backup of your current state
4. Restore the selected files
5. Prompt you to close and reopen Xcode
