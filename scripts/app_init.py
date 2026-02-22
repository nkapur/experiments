import argparse
import logging
import json
import sys
import yaml

from pathlib import Path

# Add repo root to path for imports
_script_dir = Path(__file__).resolve().parent
_repo_root = _script_dir.parent
if str(_repo_root) not in sys.path:
    sys.path.insert(0, str(_repo_root))

from scripts.utils.path_utils import get_repo_root, merge_dicts
from scripts.utils.cookiecutter_utils import run_cookiecutter

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Configure console handler if not already configured
if not logger.handlers:
    handler = logging.StreamHandler()
    handler.setLevel(logging.INFO)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

APP_CONFIGS_PATH = get_repo_root() / "app_init_configs"
APP_PARENT_PATH = get_repo_root() / "app"
DEFAULT_BASE_PATH = APP_CONFIGS_PATH / "__default_base__.yaml"

def fetch_base_configs(base_yaml_path: str = None) -> dict:
    if base_yaml_path is None:
        base_yaml_path = DEFAULT_BASE_PATH
    else:
        # Convert to Path if it's a relative path, resolve it
        base_yaml_path = Path(base_yaml_path)
        if not base_yaml_path.is_absolute():
            base_yaml_path = get_repo_root() / base_yaml_path
    
    logger.debug(f"Loading base config from: {base_yaml_path}")
    with open(base_yaml_path) as base_file:
        return yaml.safe_load(base_file)


def fetch_app_configs(app_name: str, additional_configs: dict) -> dict:
    arg_configs = {}
    arg_configs["default_context"] = additional_configs
    additional_configs["app_name"] = app_name
    logger.info(f"Creating app configuration for app: {app_name}")
    return arg_configs


if __name__ == "__main__":
    
    parser = argparse.ArgumentParser(description="Init app")
    parser.add_argument("--base", type=str, help="(Optional) Path to the base YAML file")

    app_configs_group = parser.add_argument_group("App-specific configurations")
    app_configs_group.add_argument("--app-name", type=str, required=True, help="Name of the app")
    app_configs_group.add_argument("--additional-configs", type=json.loads, default={}, help="Additional configurations in JSON format")

    args = parser.parse_args()
    
    logger.info("Loading base configuration")
    base_configs = fetch_base_configs(args.base)
    app_configs = fetch_app_configs(args.app_name, args.additional_configs)
    
    project_slug = app_configs["default_context"]["app_name"].lower()
    logger.info(f"App '{args.app_name}' and base configurations loaded (base from: {args.base or 'default location'})")

    # Does the app already exist??
    target_path = APP_CONFIGS_PATH / f"{project_slug}.yaml"
    app_path = APP_PARENT_PATH / f"{project_slug}"
    assert not target_path.exists(), f"App configs file {project_slug} already exists!"
    assert not app_path.exists(), f"App {project_slug} directory already exists"

    configs_file_created = False
    app_inited = False

    try:
        with open(target_path, "w") as target_file:
            yaml.dump(merge_dicts(base_configs, app_configs), target_file)
        logger.info(f"App {project_slug} configs file recorded successfully at {target_path}")
        configs_file_created = True

        # Run the cookiecutter command here to create the app directory
        run_cookiecutter(
            template_path=str(get_repo_root() / "__cookie_cutter__"),
            config_file=target_path,
            output_dir=APP_PARENT_PATH
        )
        app_inited = True
    except Exception as e:
        logger.error(f"Error during app initialization: {e}")

        # Clean up config file if it was created
        if configs_file_created and target_path.exists():
            target_path.unlink()
            logger.info(f"Cleaned up config file: {target_path}")
        # Clean up app directory if it was partially created
        if app_inited and app_path.exists():
            import shutil
            shutil.rmtree(app_path)
            logger.info(f"Cleaned up app directory: {app_path}")
        raise e

    if (APP_PARENT_PATH / project_slug).exists():
        logger.info(f"App {project_slug} directory created successfully")
    else:
        logger.error(f"App {project_slug} directory creation failed")
        exit(1)
