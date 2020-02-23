# COPYRIGHT LeonSkills 2019-2020.

import json
import os
import shutil
import sys
import argparse
import time


def main():
    global mods_to_update, version_type, force_version_change
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--version",
                        help="Use major/0, minor/1 or patch/2 as argument to increase that version number",
                        choices=["0", "1", "2", "major", "minor", "patch"])
    parser.add_argument("-m", "--mods", help="The mods to update", nargs="+", type=str)
    parser.add_argument("-f", "--force", action="store_true",
                        help="Use to force change version number, requires MODS")
    # parser.add_argument("-h", "--help", help="shows this message")
    # try:
    #     opts, args = getopt.getopt(argv, "hbmp", ["help", "major", "minor", "patch", "mods="])
    # except getopt.GetoptError:
    #     show_help()
    #     sys.exit()
    #
    args = parser.parse_args()

    versions = {
        "major": 0,
        "minor": 1,
        "patch": 2
    }

    version_type = None
    if args.version:
        version_type = versions[args.version] if args.version in versions else int(args.version)
        assert 0 <= version_type <= 2
    mods_to_update = args.mods

    force_version_change = args.force
    if force_version_change:
        if not mods_to_update:
            print("Can't use force if no mods are provided")
            sys.exit()

        version_type = version_type or 2

    _read_mod_info()


def show_help():
    print("-b or --major to increase the major version of the mod\n"
          "-m or --minor to increase the minor version of the mod\n"
          "-p or --patch to increase the patch version of the mod\n"
          "=mods 'mod1 mod2 mod3' to update only mod1 mod2 mod3. Otherwise defaults to all\n"
          "not specifying a version type will keep the old version")


def copy_mod(from_folder, to_folder):
    # Replaces files whose data changed in to_folder. Removes files from to_folder not in from_folder.
    # to_folder will be the same as from_folder
    changed = False
    to_files = os.listdir(to_folder)
    from_files = os.listdir(from_folder)
    # loop over all files that are already in the destination
    for file in to_files:
        to_file_path = os.path.join(to_folder, file)
        from_file_path = os.path.join(from_folder, file)
        # if the file isn't in the from folder anymore, remove it
        if file not in from_files:
            if os.path.isfile(to_file_path):
                os.remove(to_file_path)
            else:
                shutil.rmtree(to_file_path)
        else:  # otherwise see if it has changed and should be overridden
            from_files.remove(file)
            # check if it has changed by checking if the from_folder time is newer
            if os.path.isfile(to_file_path):
                if os.path.getmtime(to_file_path) < os.path.getmtime(from_file_path):
                    print("Replaced", from_file_path)
                    shutil.copy2(from_file_path, to_file_path)
                    changed = True
            else:
                req_changed = copy_mod(from_file_path, to_file_path)  # call recursively in sub folders
                changed = changed or req_changed

    # for any files that weren't already in the to_folder, copy them over
    for file in from_files:
        to_file_path = os.path.join(to_folder, file)
        from_file_path = os.path.join(from_folder, file)
        if os.path.isfile(from_file_path):
            shutil.copy2(from_file_path, to_file_path)
        else:
            shutil.copytree(from_file_path, to_file_path)
        changed = True
    return changed


def get_last_modification_time(file):
    # We ignore auto generated files.
    if "auto_generated" in file:
        return 0
    if os.path.isfile(file):
        return os.path.getmtime(file)
    return max([get_last_modification_time(os.path.join(file, sub_file)) for sub_file in os.listdir(file)] or [0])


def get_dependencies(mod_folder):
    file = os.path.join(mod_folder, "dependencies.json")
    with open(file) as json_data:
        mod_data = json.load(json_data)

    # Kahn's algorithm
    mods = []
    available_mods = []  # set of mods with no incoming edge
    for mod, data in mod_data.items():
        if ("required" not in data or not data["required"]) and ("optional" not in data or not data["optional"]):
            available_mods.append(mod)
        else:
            if "required" in data:
                for required_mod in data["required"]:
                    if "required_by" not in mod_data[required_mod]:
                        mod_data[required_mod]["required_by"] = []
                    mod_data[required_mod]["required_by"].append(mod)
            if "optional" in data:
                for required_mod in data["optional"]:
                    if "optional_by" not in mod_data[required_mod]:
                        mod_data[required_mod]["optional_by"] = []
                    mod_data[required_mod]["optional_by"].append(mod)

    while available_mods:
        cur_mod = available_mods.pop(0)
        mods.append(cur_mod)
        if "required_by" in mod_data[cur_mod]:
            while mod_data[cur_mod]["required_by"]:
                required_mod = mod_data[cur_mod]["required_by"].pop(0)
                mod_data[required_mod]["required"].remove(cur_mod)
                if (not mod_data[required_mod]["required"]) and (
                        "optional" not in mod_data[required_mod] or not mod_data[required_mod]["optional"]):
                    available_mods.append(required_mod)
        if "optional_by" in mod_data[cur_mod]:
            while mod_data[cur_mod]["optional_by"]:
                optional_mod = mod_data[cur_mod]["optional_by"].pop(0)
                mod_data[optional_mod]["optional"].remove(cur_mod)
                if (not mod_data[optional_mod]["optional"]) and (
                        "required" not in mod_data[optional_mod] or not mod_data[optional_mod]["required"]):
                    available_mods.append(optional_mod)

    with open(file) as json_data:
        mod_data = json.load(json_data)
    return mods, mod_data


def _read_mod_info():
    mods_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "mods")

    # Get dependencies order
    mod_order, mod_data = get_dependencies(mods_folder)

    for mod in mod_order:
        mod_folder = os.path.join(mods_folder, mod)
        version = _update_mod(mod, mod_folder, mod_data)
        mod_data[mod]["version"] = version


def _update_mod(mod_name_folder, mod_folder, mod_data):
    global mods_to_update, version_type, force_version_change
    info_file = os.path.join(mod_folder, "mod", "info.json")

    # Get current version number and mod name
    with open(info_file, "r") as f:
        info_data = json.load(f)
    version = info_data["version"] or "0.0.0"
    mod_name = info_data["name"]
    mod_data[mod_name_folder]["mod_name"] = mod_name
    if mods_to_update is not None and mod_name_folder not in mods_to_update:
        return version
    print("Updating", mod_name_folder)

    folder_modified_time = get_last_modification_time(mod_folder)
    version_modified_time = os.path.getmtime(info_file)
    # Create mod folder in appdata folder if it doesn't exist yet
    appdata = os.getenv('APPDATA')  # Probably only works on windows?
    factorio_mod_folder = os.path.join(appdata, "Factorio", "mods", mod_name + "_" + version)
    if not os.path.exists(factorio_mod_folder):
        os.mkdir(factorio_mod_folder)
        folder_modified_time = time.time()
    # Nothing has changed in this mod since last modification. Skip
    is_changed = False
    if version_modified_time != folder_modified_time:
        # copy mod from repo over to appdata folder
        is_changed = copy_mod(os.path.join(mod_folder, "mod"), factorio_mod_folder)

    # change version number if things have changed
    if is_changed or force_version_change:
        # increase version number
        if version_type:
            version_split = version.split(".")
            version_split[version_type] = str(int(version_split[version_type]) + 1)
            for i in range(version_type + 1, 3):
                version_split[i] = str(0)

            new_version = ".".join(version_split)
            print("New version for " + mod_name + ": " + new_version)

            new_factorio_mod_folder = os.path.join(appdata, "Factorio", "mods", mod_name + "_" + new_version)

            os.rename(factorio_mod_folder, new_factorio_mod_folder)

            version = new_version

        factorio_mod_folder = os.path.join(appdata, "Factorio", "mods", mod_name + "_" + version)

        factorio_info_file = os.path.join(factorio_mod_folder, "info.json")
        with open(factorio_info_file) as info:
            mod_info = json.load(info)
        mod_info["version"] = version
        mod_info["author"] = "LeonSkills"
        mod_info["contact"] = "https://www.reddit.com/message/compose?to=LeonSkills&subject=RsFactorio" \
                              + mod_name + "_" + version
        mod_info["homepage"] = "https://github.com/LeonSkills/RsFactorio/tree/master/" + mod_name_folder
        mod_info["factorio_version"] = "0.17"

        mod_info["dependencies"] = mod_data[mod_name_folder]["extern_dependencies"] if \
            "extern_dependencies" in mod_data[mod_name_folder] else []
        # Update/set dependencies
        if "required" in mod_data[mod_name_folder]:
            for required_mod in mod_data[mod_name_folder]["required"]:
                mod_info["dependencies"].append(mod_data[required_mod]["mod_name"] +
                                                " >= " + mod_data[required_mod]["version"])
        if "optional" in mod_data[mod_name_folder]:
            for required_mod in mod_data[mod_name_folder]["optional"]:
                mod_info["dependencies"].append("?" + mod_data[required_mod]["mod_name"] +
                                                " >= " + mod_data[required_mod]["version"])

        mod_info["dependencies"].append("base >= 0.17")

        with open(factorio_info_file, "w") as f:
            json.dump(mod_info, f, indent=2)

        # write new version to folder
        with open(info_file, "w") as f:
            info_data["version"] = version
            json.dump(info_data, f, indent=2)

        return version
    return version


if __name__ == '__main__':
    main()
