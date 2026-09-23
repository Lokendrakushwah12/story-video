# Import the cards into a bin and lay them out on a new timeline via the in-Resolve bridge.
# Re-running replaces this video's own timeline and bin (matched by name), never anything else.
import json
import os
import sys
from pathlib import Path

MCP = Path(os.environ.get("DAVINCI_RESOLVE_MCP", Path.home() / "davinci-resolve-mcp")).expanduser()
sys.path.insert(0, str(MCP))


def connect_resolve():
    """Studio: direct external scripting. Free edition: the in-app bridge from davinci-resolve-mcp."""
    try:
        import DaVinciResolveScript as dvr  # on PYTHONPATH when Studio's scripting env is set up
        resolve = dvr.scriptapp("Resolve")
        if resolve:
            return resolve
    except ImportError:
        pass
    from src.utils.resolve_bridge_client import connect
    return connect(require_enabled=False)

HERE = Path(__file__).resolve().parent
NAME = sys.argv[1] if len(sys.argv) > 1 else HERE.name.replace("-", " ").title()
manifest = json.loads((HERE / "cards/manifest.json").read_text())

resolve = connect_resolve()
project = resolve.GetProjectManager().GetCurrentProject()
pool = project.GetMediaPool()
fps = float(project.GetSetting("timelineFrameRate"))

old = [tl for tl in (project.GetTimelineByIndex(i + 1) for i in range(project.GetTimelineCount())) if tl.GetName() == NAME]
old_bins = [f for f in pool.GetRootFolder().GetSubFolderList() if f.GetName() == f"{NAME} Cards"]
if old:
    pool.DeleteTimelines(old)
if old_bins:
    pool.DeleteFolders(old_bins)

bin_ = pool.AddSubFolder(pool.GetRootFolder(), f"{NAME} Cards")
pool.SetCurrentFolder(bin_)
items = pool.ImportMedia([m["path"] for m in manifest])
by_name = {it.GetName(): it for it in items}
assert len(by_name) == len(manifest), f"imported {len(by_name)} of {len(manifest)}"

timeline = pool.CreateEmptyTimeline(NAME)
project.SetCurrentTimeline(timeline)
pool.AppendToTimeline([by_name[Path(m["path"]).name] for m in manifest])

audio = HERE / "audio.wav"  # from make_audio.py; skipped if not rendered
if audio.exists():
    wav = pool.ImportMedia([str(audio)])[0]
    pool.AppendToTimeline([{"mediaPoolItem": wav, "mediaType": 2, "trackIndex": 1,
                            "recordFrame": timeline.GetStartFrame()}])
    print("audio on A1:", len(timeline.GetItemListInTrack("audio", 1)), "clip")

placed = timeline.GetItemListInTrack("video", 1)
print(f"'{NAME}': {len(placed)} clips on V1, {timeline.GetEndFrame() - timeline.GetStartFrame()} frames @ {fps} fps")
