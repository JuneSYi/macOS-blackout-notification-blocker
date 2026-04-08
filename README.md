# BlackoutNotiBlocker 🛡️🔕

**BlackoutNotiBlocker** is a lightweight macOS utility that ensures absolute silence by "freezing" the system's entire notification pipeline. It is designed for developers and power users who need a guaranteed, distraction-free environment.

## 🚀 How it Works (The 6-Pronged Strategy)

To ensure notifications are completely gone, silent, and unviewable, this app applies a multi-layered approach every 5 seconds:

1.  **Freeze UI:** Pauses `NotificationCenter` so no banners can be drawn.
2.  **Freeze Brains:** Pauses `usernoted` so the OS stops processing incoming notification requests entirely.
3.  **Preferences Lockdown:** Forces Do Not Disturb (DND) settings to `ON` (Modern & Legacy).
4.  **Control Center Sync:** Ensures the macOS UI stays in sync with the blackout state.
5.  **Acoustic Blackout:** Automatically mutes system "Alert Volume" to 0.
6.  **Auto-Persistence:** Registers as a Login Item on first launch.

---

## 🛠️ Quick Start

### 1. Build from Source
Ensure you have Swift installed, then run:
```bash
cd NotiBlocker
./build.sh
```

### 2. Run the App
Launch the newly created `BlackoutNotiBlocker.app`.
*   **Note:** Since this is an unsigned binary, you may need to **Right-Click -> Open** in Finder to bypass macOS Gatekeeper.

### 3. Grant Permissions (Recommended)
For the app to successfully modify system-wide preferences, grant it **Full Disk Access** in:
`System Settings > Privacy & Security > Full Disk Access`

---

## 📋 Important Details

-   **Zero-UI:** This is a "Menu Bar only" app. Look for the bell icon (`🔕`) in your top-right menu bar.
-   **Always On:** Once launched, the app will automatically start every time you log in or restart your Mac.
-   **Safe Recovery:** When you select **"Quit (Resume Everything)"** from the menu, the app automatically un-pauses all system processes, restores your volume, and resets your DND settings to normal.

## ⚠️ Disclaimer

This tool uses aggressive system-level signals (`SIGSTOP`). While it includes a graceful recovery on exit, use it at your own risk. You will miss critical system alerts (like low battery warnings) while the blackout is active.
