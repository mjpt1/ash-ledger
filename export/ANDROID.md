## Android export checklist for Ash Ledger

Preset: `export_presets.cfg` → **Android**  
Package: `com.ashledger.game`  
Output: `export/AshLedger-debug.apk`

### One-time setup in Godot

1. Open **Editor → Manage Export Templates** and install templates for **4.7.stable**.
2. Open **Editor → Editor Settings → Export → Android**:
   - set Android SDK path
   - set debug keystore (Godot can create one)
3. Install JDK 17+ if prompted.

### Command line (after templates + SDK)

```bat
godot --headless --path . --export-debug "Android" export/AshLedger-debug.apk
```

### Without Android SDK yet

Use the in-editor **Play** button (`F5`) on Windows, or export **Windows Desktop** preset for a quick smoke test.
