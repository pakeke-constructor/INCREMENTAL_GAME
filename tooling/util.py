import pathlib

PARENT_ITER_DIR = 4  # How many parent iteration to find main.lua
SCRIPT_FILE = pathlib.Path(__file__)


# Find main.lua
def find_game_root():
    main_dir = None
    for i in range(PARENT_ITER_DIR):
        if (SCRIPT_FILE.parents[i] / "main.lua").is_file():
            main_dir = SCRIPT_FILE.parents[i]
            break
    if main_dir is None:
        raise RuntimeError("Cannot determine game project root")
    return main_dir
