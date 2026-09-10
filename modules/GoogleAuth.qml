pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Owns the whole Google OAuth lifecycle for this shell:
//   1. syncNow() launches the consent flow (browser + local catcher)
//   2. once a code arrives, exchanges it for tokens via curl
//   3. persists the refresh token to disk
//   4. getAccessToken(callback) hands CalendarService a live access
//      token, refreshing first if needed
//
// Requires: python3 (stdlib http.server — no pip packages), curl,
// xdg-open. All near-universal on a Linux desktop.
//
// Credentials come from ~/.config/Aki-Shell/google-credentials.json (you
// create this yourself per GOOGLE_CALENDAR_SETUP.md — it's your app's
// public client id/secret, not a per-login secret).
// Tokens are stored in ~/.config/Aki-Shell/google-tokens.json.
QtObject {
    id: root

    readonly property string configDir: Quickshell.env("HOME") + "/.config/Aki-Shell"
    readonly property string credentialsPath: configDir + "/google-credentials.json"
    readonly property string tokensPath: configDir + "/google-tokens.json"
    readonly property string codeCatcherScript: Quickshell.shellDir + "/scripts/oauth_catch.py"
    readonly property string codeOutPath: "/tmp/myshell-google-oauth-code"

    property string clientId: ""
    property string clientSecret: ""
    property string accessToken: ""
    property string refreshToken: ""
    property string email: ""
    property real accessTokenExpiryEpochMs: 0

    property bool credentialsLoaded: false
    readonly property bool hasCredentials: clientId.length > 0 && clientSecret.length > 0
    readonly property bool isSignedIn: refreshToken.length > 0

    property bool syncInProgress: false
    property string lastError: ""

    signal signedIn()
    signal signInFailed(string reason)

    Component.onCompleted: {
        _loadCredentials()
        _loadTokens()
    }

    function _loadCredentials() {
        credProc.running = true
    }
    function _loadTokens() {
        tokenProc.running = true
    }

    property Process credProc: Process {
        command: ["sh", "-c", "cat '" + root.credentialsPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.credentialsLoaded = true
                if (text.trim().length === 0) {
                    console.log("[GoogleAuth] no credentials file found at", root.credentialsPath,
                                "(or it's empty) — create it per GOOGLE_CALENDAR_SETUP.md")
                    return
                }
                try {
                    const parsed = JSON.parse(text)
                    root.clientId = parsed.client_id ?? ""
                    root.clientSecret = parsed.client_secret ?? ""
                    console.log("[GoogleAuth] credentials loaded, clientId present:", root.clientId.length > 0,
                                "clientSecret present:", root.clientSecret.length > 0)
                } catch (e) {
                    console.log("[GoogleAuth] failed to parse google-credentials.json — check it's valid JSON:", e)
                }
            }
        }
    }

    property Process tokenProc: Process {
        command: ["sh", "-c", "cat '" + root.tokensPath + "' 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim().length === 0) return
                try {
                    const parsed = JSON.parse(text)
                    root.refreshToken = parsed.refresh_token ?? ""
                    root.accessToken = parsed.access_token ?? ""
                    root.email = parsed.email ?? ""
                    root.accessTokenExpiryEpochMs = parsed.access_token_expiry ?? 0
                    if (root.refreshToken.length > 0 && root.email.length === 0 && root.accessToken.length > 0) {
                        root._fetchEmail()
                    }
                } catch (e) {
                    console.log("[GoogleAuth] failed to parse google-tokens.json:", e)
                }
            }
        }
    }

    function _saveTokens() {
        const payload = JSON.stringify({
            refresh_token: root.refreshToken,
            access_token: root.accessToken,
            email: root.email,
            access_token_expiry: root.accessTokenExpiryEpochMs
        })
        saveProc.command = ["sh", "-c",
            "mkdir -p '" + root.configDir + "' && cat > '" + root.tokensPath + "' << 'MYSHELL_EOF'\n" +
            payload + "\nMYSHELL_EOF\n"]
        saveProc.running = true
    }
    property Process saveProc: Process {}

    function syncNow() {
        console.log("[GoogleAuth] syncNow() called. hasCredentials:", hasCredentials,
                    "clientId set:", clientId.length > 0, "credentialsLoaded:", credentialsLoaded)
        if (!hasCredentials) {
            lastError = "No Google credentials found at " + credentialsPath +
                        " — see GOOGLE_CALENDAR_SETUP.md"
            console.log("[GoogleAuth]", lastError)
            signInFailed(lastError)
            return
        }
        syncInProgress = true
        lastError = ""

        const port = 34117 + Math.floor(Math.random() * 500)
        const redirectUri = "http://127.0.0.1:" + port
        _authPort = port

        console.log("[GoogleAuth] starting catcher on port", port, "script:", root.codeCatcherScript)
        catcherProc.command = ["python3", root.codeCatcherScript, String(port), root.codeOutPath]
        catcherProc.running = true

        const scope = encodeURIComponent("https://www.googleapis.com/auth/calendar.readonly")
        const authUrl = "https://accounts.google.com/o/oauth2/v2/auth" +
            "?client_id=" + encodeURIComponent(root.clientId) +
            "&redirect_uri=" + encodeURIComponent(redirectUri) +
            "&response_type=code" +
            "&scope=" + scope +
            "&access_type=offline" +
            "&prompt=consent"

        console.log("[GoogleAuth] opening browser to consent URL")
        Quickshell.execDetached({ command: ["xdg-open", authUrl] })
    }

    property int _authPort: 0

    property Process catcherProc: Process {
        running: false
        onExited: (exitCode, exitStatus) => {
            console.log("[GoogleAuth] catcher process exited, code:", exitCode)
            root._readAuthCode()
        }
    }

    function _readAuthCode() {
        readCodeProc.running = true
    }

    property Process readCodeProc: Process {
        command: ["sh", "-c", "cat '" + root.codeOutPath + "' 2>/dev/null; rm -f '" + root.codeOutPath + "'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const code = text.trim()
                console.log("[GoogleAuth] read code file, got", code.length, "chars")
                if (code.length === 0) {
                    root.syncInProgress = false
                    root.lastError = "No authorization code received (login may have been cancelled, or the local catcher failed to start — check that python3 is installed)."
                    signInFailed(root.lastError)
                    return
                }
                root._exchangeCode(code)
            }
        }
    }

    function _exchangeCode(code) {
        const redirectUri = "http://127.0.0.1:" + root._authPort
        const data = "code=" + encodeURIComponent(code) +
            "&client_id=" + encodeURIComponent(root.clientId) +
            "&client_secret=" + encodeURIComponent(root.clientSecret) +
            "&redirect_uri=" + encodeURIComponent(redirectUri) +
            "&grant_type=authorization_code"

        exchangeProc.command = ["curl", "-s", "-X", "POST",
            "https://oauth2.googleapis.com/token",
            "-d", data]
        exchangeProc.running = true
    }

    property Process exchangeProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.syncInProgress = false
                try {
                    const parsed = JSON.parse(text)
                    if (parsed.error) {
                        root.lastError = "Google rejected the request: " + (parsed.error_description ?? parsed.error)
                        root.signInFailed(root.lastError)
                        return
                    }
                    root.accessToken = parsed.access_token ?? ""
                    root.refreshToken = parsed.refresh_token ?? root.refreshToken
                    root.accessTokenExpiryEpochMs = Date.now() + ((parsed.expires_in ?? 3600) * 1000)
                    root._saveTokens()
                    root._fetchEmail()
                    root.signedIn()
                } catch (e) {
                    root.lastError = "Failed to parse Google's token response."
                    root.signInFailed(root.lastError)
                }
            }
        }
    }

    // Queue of callbacks waiting on the in-flight refresh, instead of a
    // single slot — calling getAccessToken() again before the first
    // refresh finishes used to silently overwrite (and lose) the first
    // caller's callback.
    property var _pendingCallbacks: []

    function getAccessToken(callback) {
        if (!isSignedIn) {
            callback(null)
            return
        }
        const stillValid = accessToken.length > 0 &&
            Date.now() < (accessTokenExpiryEpochMs - 60000)
        if (stillValid) {
            callback(accessToken)
            return
        }

        root._pendingCallbacks.push(callback)
        if (refreshProc.running) return // already refreshing — this callback will be flushed when it finishes

        const data = "client_id=" + encodeURIComponent(clientId) +
            "&client_secret=" + encodeURIComponent(clientSecret) +
            "&refresh_token=" + encodeURIComponent(refreshToken) +
            "&grant_type=refresh_token"
        refreshProc.command = ["curl", "-s", "-X", "POST",
            "https://oauth2.googleapis.com/token",
            "-d", data]
        refreshProc.running = true
    }

    property Process refreshProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const callbacks = root._pendingCallbacks
                root._pendingCallbacks = []
                try {
                    const parsed = JSON.parse(text)
                    if (parsed.error) {
                        const reason = parsed.error_description ?? parsed.error
                        console.log("[GoogleAuth] refresh failed:", reason)
                        root.lastError = "Token refresh failed: " + reason
                        if (parsed.error === "invalid_grant") {
                            // The refresh token itself is dead (revoked or
                            // expired) — no amount of retrying fixes this,
                            // only a fresh sign-in will. Clear it so
                            // isSignedIn correctly flips back to false
                            // instead of pretending to be signed in forever.
                            root.refreshToken = ""
                            root._saveTokens()
                            root.lastError += " — please sign in again."
                        }
                        callbacks.forEach(cb => cb(null))
                        return
                    }
                    root.accessToken = parsed.access_token ?? ""
                    root.accessTokenExpiryEpochMs = Date.now() + ((parsed.expires_in ?? 3600) * 1000)
                    root._saveTokens()
                    callbacks.forEach(cb => cb(root.accessToken))
                } catch (e) {
                    root.lastError = "Failed to parse Google's token refresh response."
                    callbacks.forEach(cb => cb(null))
                }
            }
        }
    }

    function signOut() {
        accessToken = ""
        refreshToken = ""
        email = ""
        accessTokenExpiryEpochMs = 0
        _saveTokens()
    }

    function _fetchEmail() {
        if (accessToken.length === 0) return
        emailFetchProc.command = ["curl", "-s", "-H", "Authorization: Bearer " + accessToken,
            "https://www.googleapis.com/oauth2/v2/userinfo"]
        emailFetchProc.running = true
    }

    property Process emailFetchProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    if (parsed.email) {
                        root.email = parsed.email
                        root._saveTokens()
                    }
                } catch (e) {}
            }
        }
    }
}
