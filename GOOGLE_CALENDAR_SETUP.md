# Google Calendar Sync — one-time setup

Before the shell can sync your Google Calendar, you need to register it as
an app in Google Cloud Console and get a Client ID + Secret. This is a
one-time step; the shell handles login/token refresh itself after this.

## 1. Create a Google Cloud project
1. Go to https://console.cloud.google.com/
2. If you don't have a project yet, click the project dropdown (top left) →
   **New Project**. Name it anything (e.g. "myshell-calendar"). Create it.

## 2. Enable the Calendar API
1. In the left menu: **APIs & Services** → **Library**
2. Search "Google Calendar API" → open it → click **Enable**

## 3. Configure the OAuth consent screen
1. Left menu: **APIs & Services** → **OAuth consent screen** (may show as
   "Google Auth Platform" → **Branding** depending on when you're reading
   this — Google renames this UI periodically)
2. App name: anything (e.g. "myshell")
3. User support email: your email
4. Audience / User type: **External** (unless you have a Google Workspace
   org and want Internal — External is right for a personal Gmail account)
5. If External, add yourself as a **test user** under Audience → Test users
   — this matters, otherwise Google will refuse to let your own account
   log in since the app isn't published/verified
6. Fill in the remaining required fields (contact email, etc.), agree to
   the terms, continue through to the end

## 4. Add the Calendar scope
1. Still in the consent screen setup: **Data Access** / **Scopes**
2. Add or Remove Scopes → search "calendar" → select:
   - `.../auth/calendar.readonly` (enough for viewing events — this is all
     the shell needs since it only displays your calendar, it doesn't
     create/edit events)
3. Update / Save

## 5. Create the OAuth Client ID
1. Left menu: **APIs & Services** → **Credentials**
2. **Create Credentials** → **OAuth client ID**
3. Application type: **Desktop app** (important — this is the type that
   supports the loopback flow the shell uses; Web/Android/iOS won't work
   here)
4. Name: anything (e.g. "myshell desktop")
5. Click **Create**
6. You'll see a **Client ID** and **Client Secret** — copy both, you need
   them in the next step. You can also download the JSON if you prefer.

## 6. Put the credentials in the shell's config
Create `~/.config/Aki-Shell/google-credentials.json`:
```json
{
  "client_id": "YOUR_CLIENT_ID.apps.googleusercontent.com",
  "client_secret": "YOUR_CLIENT_SECRET"
}
```
Replace both values with what Google gave you in step 5. Keep this file
private — it's your app's identity, not a per-user secret, but there's no
reason to share it.

## 7. Sync from the shell
Click the calendar in the notch → **Sync with Google** → your default
browser opens to Google's login/consent page → approve access → the tab
will show a confirmation page and you can close it → the shell picks up
the token automatically and shows your events.

## Notes
- Test users on an unpublished/"Testing" app get a refresh token that
  Google documentation says can expire after 7 days in some
  configurations — if sync silently stops working after about a week,
  that's most likely why; just click "Sync with Google" again to
  re-authorize. Submitting the app for verification removes this limit,
  but that's a heavier process not worth it for a personal single-user
  shell.
- If you ever want to revoke access, go to
  https://myaccount.google.com/permissions and remove the app from there
  — that's independent of anything in this shell's config.
