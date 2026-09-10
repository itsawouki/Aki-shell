#!/usr/bin/env python3
import os
import sys
import json
import fcntl

HOME = os.path.expanduser("~")
MOVIES_DIR = os.path.join(HOME, "Videos/Movies/")
DATA_FILE = os.path.join(HOME, ".config/Aki-Shell/movies_data.json")
VIDEO_EXTS = ('.mp4', '.mkv', '.avi', '.webm', '.m4v', '.mov', '.flv', '.ts')

def load_data():
    if os.path.exists(DATA_FILE):
        try:
            with open(DATA_FILE, 'r') as f:
                data = json.load(f)
            return data
        except Exception:
            pass
    return {"watched": [], "custom_movies": {}, "covers": {}, "next_id": 1}

def save_data(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    tmp_path = DATA_FILE + ".tmp"
    with open(tmp_path, 'w') as f:
        json.dump(data, f, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, DATA_FILE)

def next_movie_id(data):
    mid = data.get("next_id", 1)
    data["next_id"] = mid + 1
    return mid

def purge_watched(data, urls):
    # Deleted episodes/seasons/movies must lose their watched status,
    # otherwise re-adding the same link shows up as already watched.
    drop = {u for u in urls if u}
    if drop:
        data["watched"] = [p for p in data.get("watched", []) if p not in drop]

def ensure_seasons_entry(entry):
    if "seasons" not in entry:
        entry["seasons"] = {}
    # Repair season names that picked up leading/trailing whitespace
    # (e.g. a newline pasted into the name field).
    for name in list(entry["seasons"].keys()):
        trimmed = name.strip()
        if not trimmed or trimmed == name:
            continue
        target = entry["seasons"].setdefault(trimmed, [])
        target.extend(entry["seasons"].pop(name))
    if "extra_episodes" in entry and entry["extra_episodes"]:
        if "Stream" not in entry["seasons"]:
            entry["seasons"]["Stream"] = []
        for ep in entry["extra_episodes"]:
            entry["seasons"]["Stream"].append(ep)
        entry["extra_episodes"] = []

def scan_library():
    data = load_data()
    library = []

    # 1. Scan Local Directory
    if os.path.exists(MOVIES_DIR):
        for entry in sorted(os.listdir(MOVIES_DIR)):
            full_path = os.path.join(MOVIES_DIR, entry)
            if os.path.isdir(full_path):
                title = entry
                seasons = {}
                local_episodes = []
                cover = data["covers"].get(title, "")

                # Auto-detect local image if cover art isn't set
                if not cover:
                    for img in ["poster.jpg", "cover.jpg", "folder.jpg", "poster.png", "cover.png"]:
                        img_path = os.path.join(full_path, img)
                        if os.path.exists(img_path):
                            cover = "file://" + img_path
                            break

                # Subdirectory scan: Any folder containing video files becomes a Season
                for sub in sorted(os.listdir(full_path)):
                    sub_path = os.path.join(full_path, sub)
                    if os.path.isdir(sub_path):
                        episodes = []
                        for ep in sorted(os.listdir(sub_path)):
                            if ep.lower().endswith(VIDEO_EXTS):
                                ep_path = os.path.join(sub_path, ep)
                                episodes.append({
                                    "title": ep,
                                    "path": ep_path,
                                    "watched": ep_path in data["watched"]
                                })
                        if episodes:
                            seasons[sub] = episodes
                    elif sub.lower().endswith(VIDEO_EXTS):
                        local_episodes.append({
                            "title": sub,
                            "path": sub_path,
                            "watched": sub_path in data["watched"]
                        })

                if local_episodes:
                    seasons["Main"] = local_episodes

                # Append custom online links assigned to this local title
                custom_info = data["custom_movies"].get(title, {})
                movie_id = custom_info.get("id")
                if custom_info:
                    ensure_seasons_entry(custom_info)
                    custom_seasons = custom_info.get("seasons", {})
                    for sname, eps in custom_seasons.items():
                        if sname not in seasons:
                            seasons[sname] = []
                        for c_ep in eps:
                            seasons[sname].append({
                                "title": c_ep["title"],
                                "path": c_ep["url"],
                                "watched": c_ep["url"] in data["watched"]
                            })

                library.append({
                    "title": title,
                    "id": movie_id,
                    "cover": cover,
                    "is_online": False,
                    "seasons": seasons
                })

    # 2. Append Purely Custom / Online Movies
    for title, info in data["custom_movies"].items():
        if not any(item["title"] == title for item in library):
            ensure_seasons_entry(info)
            seasons = {}
            if info.get("url"):
                seasons["Stream"] = [{
                    "title": info.get("stream_title", "Watch Stream"),
                    "path": info["url"],
                    "watched": info["url"] in data["watched"]
                }]
            custom_seasons = info.get("seasons", {})
            for sname, eps in custom_seasons.items():
                if sname not in seasons:
                    seasons[sname] = []
                for c_ep in eps:
                    seasons[sname].append({
                        "title": c_ep["title"],
                        "path": c_ep["url"],
                        "watched": c_ep["url"] in data["watched"]
                    })

            library.append({
                "title": title,
                "id": info.get("id"),
                "cover": info.get("cover", ""),
                "is_online": True,
                "seasons": seasons
            })

    return library

def main():
    # Serialize command execution: every mutation is a read-modify-write of
    # the whole data file, so concurrent invocations (e.g. bulk episode adds)
    # would clobber each other's changes. The lock is released automatically
    # when the process exits.
    if len(sys.argv) > 1:
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        lock_fd = open(DATA_FILE + ".lock", "w")
        fcntl.flock(lock_fd, fcntl.LOCK_EX)

        data = load_data()
        cmd = sys.argv[1]

        if cmd == "mark_watched" and len(sys.argv) > 2:
            path = sys.argv[2]
            if path not in data["watched"]:
                data["watched"].append(path)
            else:
                data["watched"].remove(path) # Toggle watched status
            save_data(data)
            print("OK")
            return

        elif cmd == "add_online_movie" and len(sys.argv) >= 4:
            title = sys.argv[2]
            url = sys.argv[3]
            cover = sys.argv[4] if len(sys.argv) > 4 else ""
            mid = next_movie_id(data)
            data["custom_movies"][title] = {
                "id": mid, "url": url, "cover": cover,
                "extra_episodes": [], "seasons": {}
            }
            save_data(data)
            print("OK")
            return

        elif cmd == "add_show" and len(sys.argv) >= 3:
            title = sys.argv[2]
            cover = sys.argv[3] if len(sys.argv) > 3 else ""
            if title in data["custom_movies"]:
                data["custom_movies"][title]["cover"] = cover
            else:
                mid = next_movie_id(data)
                data["custom_movies"][title] = {
                    "id": mid, "url": "", "cover": cover,
                    "extra_episodes": [], "seasons": {}
                }
            save_data(data)
            print("OK")
            return

        elif cmd == "add_season" and len(sys.argv) >= 4:
            title = sys.argv[2]
            season_name = sys.argv[3].strip()
            if not season_name:
                print("OK")
                return
            entry = data["custom_movies"].setdefault(title, {
                "id": next_movie_id(data), "url": "", "cover": "",
                "extra_episodes": [], "seasons": {}
            })
            ensure_seasons_entry(entry)
            if season_name not in entry["seasons"]:
                entry["seasons"][season_name] = []
            save_data(data)
            print("OK")
            return

        elif cmd == "rename_season" and len(sys.argv) >= 5:
            title = sys.argv[2]
            old_name = sys.argv[3]
            new_name = sys.argv[4].strip()
            entry = data["custom_movies"].get(title)
            if entry:
                ensure_seasons_entry(entry)
                seasons = entry.get("seasons", {})
                if old_name in seasons and new_name not in seasons:
                    seasons[new_name] = seasons.pop(old_name)
                    save_data(data)
            print("OK")
            return

        elif cmd == "remove_season" and len(sys.argv) >= 4:
            title = sys.argv[2]
            season_name = sys.argv[3]
            entry = data["custom_movies"].get(title)
            if entry:
                ensure_seasons_entry(entry)
                seasons = entry.get("seasons", {})
                if season_name in seasons:
                    purge_watched(data, [e.get("url") for e in seasons[season_name]])
                    del seasons[season_name]
                    save_data(data)
            print("OK")
            return

        elif cmd == "set_watched" and len(sys.argv) > 2:
            path = sys.argv[2]
            if path not in data["watched"]:
                data["watched"].append(path)
            save_data(data)
            print("OK")
            return

        elif cmd == "add_online_episode" and len(sys.argv) >= 5:
            title = sys.argv[2]
            ep_title = sys.argv[3]
            url = sys.argv[4]
            season = sys.argv[5].strip() if len(sys.argv) > 5 else ""
            entry = data["custom_movies"].setdefault(title, {
                "id": next_movie_id(data), "url": "", "cover": "",
                "extra_episodes": [], "seasons": {}
            })
            ensure_seasons_entry(entry)
            if "id" not in entry:
                entry["id"] = next_movie_id(data)
            if not season:
                if entry.get("url"):
                    season = "Stream"
                else:
                    season = next(iter(entry["seasons"]), "Season 1")
            if season not in entry["seasons"]:
                entry["seasons"][season] = []
            entry["seasons"][season].append({"title": ep_title, "url": url})
            save_data(data)
            print("OK")
            return

        elif cmd == "add_online_episodes" and len(sys.argv) >= 5:
            # Bulk variant: receives every episode in one shot as a JSON
            # array so a multi-episode add is a single atomic transaction.
            title = sys.argv[2]
            season = sys.argv[3].strip()
            try:
                incoming = json.loads(sys.argv[4])
            except Exception:
                incoming = []
            if not isinstance(incoming, list):
                incoming = []
            entry = data["custom_movies"].setdefault(title, {
                "id": next_movie_id(data), "url": "", "cover": "",
                "extra_episodes": [], "seasons": {}
            })
            ensure_seasons_entry(entry)
            if "id" not in entry:
                entry["id"] = next_movie_id(data)
            if not season:
                if entry.get("url"):
                    season = "Stream"
                else:
                    season = next(iter(entry["seasons"]), "")
            if not season:
                season = "Season 1"
            if season not in entry["seasons"]:
                entry["seasons"][season] = []
            added = 0
            for ep in incoming:
                if not isinstance(ep, dict):
                    continue
                url = str(ep.get("url", "")).strip()
                if not url:
                    continue
                ep_title = str(ep.get("title", "")).strip() or "Episode"
                entry["seasons"][season].append({"title": ep_title, "url": url})
                added += 1
            save_data(data)
            print("OK", added)
            return

        elif cmd == "set_cover" and len(sys.argv) >= 4:
            title = sys.argv[2]
            cover_url = sys.argv[3]
            data["covers"][title] = cover_url
            if title in data["custom_movies"]:
                data["custom_movies"][title]["cover"] = cover_url
            save_data(data)
            print("OK")
            return

        elif cmd == "remove_movie" and len(sys.argv) > 2:
            movie_id = int(sys.argv[2])
            for title, info in list(data["custom_movies"].items()):
                if info.get("id") == movie_id:
                    ensure_seasons_entry(info)
                    urls = []
                    if info.get("url"):
                        urls.append(info["url"])
                    for eps in info.get("seasons", {}).values():
                        urls.extend(e.get("url") for e in eps)
                    purge_watched(data, urls)
                    del data["custom_movies"][title]
                    save_data(data)
                    break
            print("OK")
            return

        elif cmd == "remove_episode" and len(sys.argv) > 3:
            movie_id = int(sys.argv[2])
            ep_url = sys.argv[3]
            for title, info in data["custom_movies"].items():
                if info.get("id") == movie_id:
                    ensure_seasons_entry(info)
                    for sname, eps in info.get("seasons", {}).items():
                        info["seasons"][sname] = [e for e in eps if e.get("url") != ep_url]
                    if info.get("url") == ep_url:
                        info["url"] = ""
                    purge_watched(data, [ep_url])
                    save_data(data)
                    break
            print("OK")
            return

    print(json.dumps(scan_library()))

if __name__ == "__main__":
    main()
