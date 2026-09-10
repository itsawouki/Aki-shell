import json
import urllib.request
import sys
import os

config_path = os.path.expanduser("~/.config/Aki-Shell/yt-settings.json")

try:
    with open(config_path) as f:
        settings = json.load(f)
    channel_id = settings.get("channelId", "")
    api_key = settings.get("apiKey", "")
    goal = settings.get("subGoal", 2000)
except Exception:
    print(json.dumps({"subs": 0, "views": 0, "goal": 2000}))
    sys.stdout.flush()
    sys.exit(0)

if not channel_id or not api_key:
    print(json.dumps({"subs": 0, "views": 0, "goal": goal}))
    sys.stdout.flush()
    sys.exit(0)

url = f"https://www.googleapis.com/youtube/v3/channels?part=statistics&id={channel_id}&key={api_key}"

try:
    req = urllib.request.urlopen(url)
    data = json.loads(req.read().decode('utf-8'))
    stats = data['items'][0]['statistics']
    
    output = {
        "subs": int(stats['subscriberCount']),
        "views": int(stats['viewCount']),
        "goal": goal
    }
    print(json.dumps(output))
    sys.stdout.flush()
except Exception as e:
    print(json.dumps({"subs": 0, "views": 0, "goal": goal}))
    sys.stdout.flush()
