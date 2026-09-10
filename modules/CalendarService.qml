pragma Singleton
import Quickshell
import Quickshell.Io
import "." as Modules
import QtQuick

QtObject {
    id: root

    property var events: []
    property bool loading: false
    property string lastError: ""

    function fetchCurrentWeek() {
        const now = new Date()
        const day = now.getDay()
        const diffToMon = now.getDate() - day + (day === 0 ? -6 : 1)
        
        const mon = new Date(now.getFullYear(), now.getMonth(), diffToMon, 0, 0, 0)
        const sun = new Date(mon.getFullYear(), mon.getMonth(), mon.getDate() + 6, 23, 59, 59)

        fetchRange(mon.toISOString(), sun.toISOString())
    }

    function fetchRange(rangeStartIso, rangeEndIso) {
        if (!Modules.GoogleAuth.isSignedIn) {
            root.events = []
            return
        }
        root.loading = true
        root.lastError = ""
        Modules.GoogleAuth.getAccessToken((token) => {
            if (!token) {
                root.loading = false
                root.lastError = "Could not get access token."
                root.events = []
                return
            }
            const url = "https://www.googleapis.com/calendar/v3/calendars/primary/events" +
                "?timeMin=" + encodeURIComponent(rangeStartIso) +
                "&timeMax=" + encodeURIComponent(rangeEndIso) +
                "&singleEvents=true&orderBy=startTime&maxResults=100"

            fetchProc.command = ["curl", "-s", "-H", "Authorization: Bearer " + token, url]
            fetchProc.running = true
        })
    }

    property Process fetchProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false
                try {
                    const parsed = JSON.parse(text)
                    if (parsed.error) {
                        root.lastError = parsed.error.message ?? "Google API error"
                        root.events = []
                        return
                    }
                    const items = parsed.items ?? []
                    root.events = items.map(item => {
                        const startDateTime = item.start?.dateTime
                        const startDate = item.start?.date
                        const endDateTime = item.end?.dateTime
                        const endDate = item.end?.date
                        return {
                            id: item.id ?? "",
                            summary: item.summary ?? "(No title)",
                            start: startDateTime ?? startDate ?? "",
                            end: endDateTime ?? endDate ?? "",
                            allDay: !startDateTime,
                            location: item.location ?? ""
                        }
                    })
                } catch (e) {
                    root.lastError = "Failed to parse Google response."
                    root.events = []
                }
            }
        }
    }
}
