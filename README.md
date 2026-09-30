# AWS Robotics Hospital environment in Godot

Just checkout the repository with all its submodules and open it in Godot 4.7+.
`git submodule update --init -r`

## Model sources
Note that this repo already comes with all downloaded models, they are Licensed under Creative Commons with or without Attribution, see the [MODEL_LICENSES.md](MODEL_LICENSES.md) file for details.

If you like to re-download them, all of them run:
```bash
python3 ./addons/godot_sdformat/tools/download_fuel_models.py aws-robomaker-hospital-world/worlds/hospital.world -m gazebo_builtin_models/ -m aws-robomaker-hospital-world/models/ -d fuel_models

python3 ./addons/godot_sdformat/tools/write_license_notice.py -m aws-robomaker-hospital-world/models/ -m gazebo_builtin_models/ -m fuel_models/
````

## Architecture
The SDF-parsing part always follows the same pattern, first we generate a data structure for each element in the `parse(parser: SDFParser)`-function. This structure then gets hand over to the GodotSDFRoot that creates Godot Node3D-based elements from the sdf_godot folder using the `to_godot(...)`-function.

## AI Usage
As the parser always follows the same pattern and SDF is strictly defined in sdformat.org Anthropics Claude Opus 5.5 has been used to generate parts of the code.

## Screenshot
![](docs/screenshots/hospital_env.png)