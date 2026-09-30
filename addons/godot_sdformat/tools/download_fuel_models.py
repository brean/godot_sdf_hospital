#!/usr/bin/env python3
"""Downloads the models an SDF world includes (model://<name>) from Gazebo Fuel,
if they are in none of the given model folders. Similar to fuel_utility.py of
https://github.com/aws-robotics/aws-robomaker-hospital-world, but it finds the
missing models itself and only needs the Python standard library.

Example, run in the Godot project folder:
  python3 addons/godot_sdformat/tools/download_fuel_models.py \\
      worlds/hospital.world -m models -m gazebo_models -d fuel_models

Then add the destination (res://fuel_models) to the model_folders of the loader.

The license of every downloaded model is written to <model>/ATTRIBUTION.txt,
also for models downloaded before, Fuel models are licensed per model.
write_license_notice.py collects them into one license overview.
"""
import argparse
import io
import json
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile

FUEL_URL = "https://fuel.gazebosim.org/1.0"
MODEL_URI = re.compile(r"model://([^/<\s]+)")
WAIT_BETWEEN_DOWNLOADS = 1.0  # seconds, like fuel_utility.py


def included_models(sdf_file: pathlib.Path) -> set[str]:
    return set(MODEL_URI.findall(sdf_file.read_text(encoding="utf-8", errors="replace")))


def find_model(name: str, folders: list[pathlib.Path]) -> pathlib.Path | None:
    for folder in folders:
        if (folder / name).is_dir():
            return folder / name
    return None


def model_url(name: str, owner: str, fuel_url: str) -> str:
    return "/".join([fuel_url, owner, "models", urllib.parse.quote(name)])


def fetch_metadata(name: str, owner: str, fuel_url: str) -> dict:
    with urllib.request.urlopen(model_url(name, owner, fuel_url)) as response:
        return json.load(response)


def download(name: str, owner: str, destination: pathlib.Path, fuel_url: str, metadata: dict):
    version = str(metadata.get("version", 1))
    zip_url = "/".join([model_url(name, owner, fuel_url), version, urllib.parse.quote(name) + ".zip"])
    with urllib.request.urlopen(zip_url) as response:
        zipfile.ZipFile(io.BytesIO(response.read())).extractall(destination / name)


def write_attribution(model: pathlib.Path, owner: str, fuel_url: str, metadata: dict):
    """One "key: value" per line, read by write_license_notice.py."""
    (model / "ATTRIBUTION.txt").write_text(
        f"Model: {model.name}\n"
        f"Version: {metadata.get('version', '')}\n"
        f"Owner: {metadata.get('owner', owner)}\n"
        f"Source: {model_url(model.name, owner, fuel_url)}\n"
        f"License: {metadata.get('license_name', 'unknown')}\n"
        f"License URL: {metadata.get('license_url', '')}\n"
        "Modifications: none, downloaded from Gazebo Fuel\n",
        encoding="utf-8")


def main() -> int:
    arguments = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    arguments.add_argument("world", type=pathlib.Path, help="SDF world or model file")
    arguments.add_argument("-m", "--model-folder", type=pathlib.Path, action="append",
                           default=[], help="existing model folder, can be repeated")
    arguments.add_argument("-d", "--destination", type=pathlib.Path, required=True,
                           help="folder for the downloaded models")
    arguments.add_argument("-o", "--owner", default="OpenRobotics", help="Fuel owner")
    arguments.add_argument("--fuel-url", default=FUEL_URL)
    args = arguments.parse_args()

    args.destination.mkdir(parents=True, exist_ok=True)
    folders = args.model_folder + [args.destination]
    missing = sorted(included_models(args.world))
    checked = set()
    failed = []
    licenses = {}  # license name -> downloaded models
    while missing:
        name = missing.pop(0)
        if name in checked:
            continue
        checked.add(name)
        model = find_model(name, folders)
        # models downloaded before this script wrote attributions get one now
        needs_attribution = model is None or (
            model.parent == args.destination and not (model / "ATTRIBUTION.txt").exists())
        if needs_attribution:
            print(f"{'Downloading' if model is None else 'Adding attribution to'} {name}")
            try:
                metadata = fetch_metadata(name, args.owner, args.fuel_url)
                if model is None:
                    download(name, args.owner, args.destination, args.fuel_url, metadata)
                    model = args.destination / name
                write_attribution(model, args.owner, args.fuel_url, metadata)
                licenses.setdefault(metadata.get("license_name", "unknown"), []).append(name)
            except (urllib.error.URLError, zipfile.BadZipFile, ValueError) as error:
                print(f"  failed: {error}", file=sys.stderr)
                failed.append(name)
                continue
            time.sleep(WAIT_BETWEEN_DOWNLOADS)
        # downloaded and existing models can include further models
        for sdf_file in model.rglob("*.sdf"):
            missing.extend(sorted(included_models(sdf_file) - checked))

    for license_name, names in licenses.items():
        print(f"{license_name}: {', '.join(names)}")
    if failed:
        print(f"Failed to download {len(failed)} models: {', '.join(failed)}", file=sys.stderr)
        return 1
    print("All included models are available.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
