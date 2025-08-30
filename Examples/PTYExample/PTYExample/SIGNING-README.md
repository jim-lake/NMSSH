# Signing Configuration

This project uses xcconfig files to manage code signing settings, keeping personal development team IDs out of version control.

## Setup

1. Copy `Signing.xcconfig` to `Signing-Local.xcconfig`
2. Edit `Signing-Local.xcconfig` and set your `DEVELOPMENT_TEAM` ID
3. The `Signing-Local.xcconfig` file is ignored by git and won't be committed

## Files

- `Signing.xcconfig` - Template configuration (committed to git)
- `Signing-Local.xcconfig` - Your personal settings (ignored by git)

## Finding Your Development Team ID

1. Open Xcode
2. Go to Xcode → Preferences → Accounts
3. Select your Apple ID
4. Your Team ID is shown next to your team name
