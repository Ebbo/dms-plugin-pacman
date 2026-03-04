pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services

Singleton {
    id: root

    readonly property string pluginId: "archPackageManager"

    // Detected state
    property string aurHelper: ""
    property bool initialized: false
    property bool isChecking: false

    // Update data
    property var officialUpdates: []
    property var aurUpdates: []
    property int updateCount: 0
    property string lastCheckTime: ""
    property string errorMessage: ""
    property int previousUpdateCount: -1

    // Settings
    property string preferredHelper: "auto"  // "auto", "yay", or "paru"
    property string terminal: "foot"
    property int checkIntervalMinutes: 30
    property bool showVersions: true
    property bool notifyOnUpdates: true
    property string checkMethod: "auto"  // "auto", "checkupdates", "helper"

    // Internal buffer
    property var _lines: []

    // The single check script that does all the work
    readonly property string checkScript: {
        var pref = root.preferredHelper;
        var method = root.checkMethod;
        var lines = [];

        // Helper detection respecting preferred setting
        if (pref === "yay") {
            lines.push("if command -v yay >/dev/null 2>&1; then HELPER=yay");
            lines.push("else HELPER=none; fi");
        } else if (pref === "paru") {
            lines.push("if command -v paru >/dev/null 2>&1; then HELPER=paru");
            lines.push("else HELPER=none; fi");
        } else {
            // auto: prefer yay over paru
            lines.push("if command -v yay >/dev/null 2>&1; then HELPER=yay");
            lines.push("elif command -v paru >/dev/null 2>&1; then HELPER=paru");
            lines.push("else HELPER=none; fi");
        }

        // Detect checkupdates availability
        lines.push("HAS_CHECKUPDATES=0");
        lines.push("if command -v checkupdates >/dev/null 2>&1; then HAS_CHECKUPDATES=1; fi");

        lines.push("echo \"HELPER:$HELPER\"");

        if (method === "checkupdates") {
            // Prefer checkupdates for official repos, use helper only for AUR
            lines.push("if [ \"$HAS_CHECKUPDATES\" = \"1\" ]; then");
            lines.push("  checkupdates 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("  if [ \"$HELPER\" != \"none\" ]; then");
            lines.push("    $HELPER -Qua 2>/dev/null | while IFS= read -r line; do echo \"AUR:$line\"; done");
            lines.push("  fi");
            lines.push("elif [ \"$HELPER\" != \"none\" ]; then");
            lines.push("  $HELPER -Qu 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("  $HELPER -Qua 2>/dev/null | while IFS= read -r line; do echo \"AUR:$line\"; done");
            lines.push("fi");
        } else if (method === "helper") {
            // Use AUR helper for everything, fall back to checkupdates
            lines.push("if [ \"$HELPER\" != \"none\" ]; then");
            lines.push("  $HELPER -Qu 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("  $HELPER -Qua 2>/dev/null | while IFS= read -r line; do echo \"AUR:$line\"; done");
            lines.push("elif [ \"$HAS_CHECKUPDATES\" = \"1\" ]; then");
            lines.push("  checkupdates 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("fi");
        } else {
            // auto: prefer checkupdates for official repos (it syncs the db),
            // use helper only for AUR. Fall back to helper for everything if
            // checkupdates is not installed.
            lines.push("if [ \"$HAS_CHECKUPDATES\" = \"1\" ]; then");
            lines.push("  checkupdates 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("  if [ \"$HELPER\" != \"none\" ]; then");
            lines.push("    $HELPER -Qua 2>/dev/null | while IFS= read -r line; do echo \"AUR:$line\"; done");
            lines.push("  fi");
            lines.push("elif [ \"$HELPER\" != \"none\" ]; then");
            lines.push("  $HELPER -Qu 2>/dev/null | while IFS= read -r line; do echo \"PKG:$line\"; done");
            lines.push("  $HELPER -Qua 2>/dev/null | while IFS= read -r line; do echo \"AUR:$line\"; done");
            lines.push("fi");
        }
        lines.push("echo \"DONE\"");
        return lines.join("\n");
    }

    // --- Single process for checking updates ---
    Process {
        id: checkProc
        command: ["bash", "-c", root.checkScript]
        running: false

        stdout: SplitParser {
            onRead: data => {
                root._lines.push(data.trim());
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._processResults();
        }
    }

    // --- Terminal launch process ---
    Process {
        id: terminalProc
        running: false

        onExited: (exitCode, exitStatus) => {
            root.checkUpdates();
        }
    }

    // --- Periodic check timer ---
    Timer {
        id: checkTimer
        interval: root.checkIntervalMinutes * 60 * 1000
        repeat: true
        running: root.initialized
        onTriggered: root.checkUpdates()
    }

    // --- Parse all collected output ---
    function _processResults() {
        var official = [];
        var aur = [];
        var helper = "";

        for (var i = 0; i < _lines.length; i++) {
            var line = _lines[i];
            if (!line) continue;

            if (line.startsWith("HELPER:")) {
                var h = line.substring(7);
                helper = h === "none" ? "" : h;
            } else if (line.startsWith("PKG:")) {
                var pkg = _parsePkgLine(line.substring(4));
                if (pkg) {
                    pkg.source = "official";
                    official.push(pkg);
                }
            } else if (line.startsWith("AUR:")) {
                var aurPkg = _parsePkgLine(line.substring(4));
                if (aurPkg) {
                    aurPkg.source = "aur";
                    aur.push(aurPkg);
                    // Remove from official if present (avoid duplicates)
                    for (var j = official.length - 1; j >= 0; j--) {
                        if (official[j].name === aurPkg.name) {
                            official.splice(j, 1);
                        }
                    }
                }
            }
        }

        root._lines = [];
        root.aurHelper = helper;
        root.officialUpdates = official;
        root.aurUpdates = aur;

        if (!root.initialized) {
            root.initialized = true;
            PluginService.setGlobalVar(root.pluginId, "initialized", true);
        }
        PluginService.setGlobalVar(root.pluginId, "aurHelper", root.aurHelper);

        if (official.length === 0 && aur.length === 0 && !helper) {
            root.errorMessage = "No package manager found. Install yay, paru, or pacman-contrib.";
        }

        root._finishCheck();
    }

    // Parse a single "name oldver -> newver" line
    function _parsePkgLine(line) {
        line = line.trim();
        var arrowIdx = line.indexOf(" -> ");
        if (arrowIdx < 0) return null;

        var left = line.substring(0, arrowIdx);
        var newVersion = line.substring(arrowIdx + 4).trim();

        var lastSpace = left.lastIndexOf(" ");
        if (lastSpace < 0) return null;

        var name = left.substring(0, lastSpace).trim();
        var oldVersion = left.substring(lastSpace + 1).trim();

        if (name && oldVersion && newVersion) {
            return { name: name, oldVersion: oldVersion, newVersion: newVersion };
        }
        return null;
    }

    // --- Public API ---

    function checkUpdates() {
        if (root.isChecking) return;
        root.isChecking = true;
        root.errorMessage = "";
        root._lines = [];

        PluginService.setGlobalVar(root.pluginId, "isChecking", true);

        checkProc.running = true;
    }

    function _finishCheck() {
        root.isChecking = false;
        var prevCount = root.updateCount;
        root.updateCount = root.officialUpdates.length + root.aurUpdates.length;
        root.lastCheckTime = new Date().toLocaleTimeString(Qt.locale(), "hh:mm AP");

        var allUpdates = root.officialUpdates.concat(root.aurUpdates);

        PluginService.setGlobalVar(root.pluginId, "updates", allUpdates);
        PluginService.setGlobalVar(root.pluginId, "officialUpdates", root.officialUpdates);
        PluginService.setGlobalVar(root.pluginId, "aurUpdates", root.aurUpdates);
        PluginService.setGlobalVar(root.pluginId, "updateCount", root.updateCount);
        PluginService.setGlobalVar(root.pluginId, "lastCheckTime", root.lastCheckTime);
        PluginService.setGlobalVar(root.pluginId, "isChecking", false);
        PluginService.setGlobalVar(root.pluginId, "errorMessage", root.errorMessage);

        // Notify if new updates found
        if (root.notifyOnUpdates && root.previousUpdateCount >= 0 && root.updateCount > prevCount) {
            ToastService.showInfo(root.updateCount + " package update" + (root.updateCount !== 1 ? "s" : "") + " available");
        }
        root.previousUpdateCount = root.updateCount;
    }

    function launchUpdate() {
        var cmd = root.aurHelper ? root.aurHelper + " -Syu" : "sudo pacman -Syu";
        var termParts = root.terminal.split(" ");
        var fullCmd = termParts.concat(["bash", "-c", cmd + "; echo; echo 'Update complete. Press Enter to close...'; read"]);
        terminalProc.command = fullCmd;
        terminalProc.running = true;
    }

    function getUpdateCommand() {
        return root.aurHelper ? root.aurHelper + " -Syu" : "sudo pacman -Syu";
    }

    // --- Settings ---

    function loadSettings() {
        var ph = PluginService.loadPluginData(pluginId, "preferredHelper");
        if (ph !== undefined && ph !== "") root.preferredHelper = ph;

        var t = PluginService.loadPluginData(pluginId, "terminal");
        if (t !== undefined && t !== "") root.terminal = t;

        var interval = PluginService.loadPluginData(pluginId, "checkInterval");
        if (interval !== undefined && interval !== "") {
            var parsed = parseInt(interval);
            if (!isNaN(parsed) && parsed >= 5) {
                root.checkIntervalMinutes = parsed;
            }
        }

        var cm = PluginService.loadPluginData(pluginId, "checkMethod");
        if (cm !== undefined && cm !== "") root.checkMethod = cm;

        var sv = PluginService.loadPluginData(pluginId, "showVersions");
        if (sv !== undefined) root.showVersions = sv;

        var notify = PluginService.loadPluginData(pluginId, "notifyOnUpdates");
        if (notify !== undefined) root.notifyOnUpdates = notify;
    }

    Connections {
        target: PluginService
        function onPluginDataChanged(id, key, value) {
            if (id !== root.pluginId) return;
            if (key === "preferredHelper") {
                root.preferredHelper = value || "auto";
            } else if (key === "terminal" && value) {
                root.terminal = value;
            } else if (key === "checkInterval" && value) {
                var parsed = parseInt(value);
                if (!isNaN(parsed) && parsed >= 5) {
                    root.checkIntervalMinutes = parsed;
                }
            } else if (key === "checkMethod") {
                root.checkMethod = value || "auto";
            } else if (key === "showVersions") {
                root.showVersions = value;
            } else if (key === "notifyOnUpdates") {
                root.notifyOnUpdates = value;
            }
        }
    }

    Component.onCompleted: {
        loadSettings();
        checkUpdates();
    }
}
