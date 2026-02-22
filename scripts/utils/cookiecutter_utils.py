"""Cookiecutter execution utilities."""

import logging
import shutil
import subprocess
from pathlib import Path

logger = logging.getLogger(__name__)


def run_cookiecutter(
    template_path: str,
    config_file: Path,
    output_dir: Path,
    cookiecutter_path: str = None
) -> None:
    """Run cookiecutter command to generate project from template.
    
    Args:
        template_path: Path to the cookiecutter template directory
        config_file: Path to the cookiecutter config YAML file
        output_dir: Directory where the generated project should be created
        cookiecutter_path: Optional path to cookiecutter executable. If None, will search PATH.
    
    Raises:
        FileNotFoundError: If cookiecutter is not found
        subprocess.CalledProcessError: If cookiecutter command fails
    """
    # Find cookiecutter executable
    if cookiecutter_path is None:
        cookiecutter_path = shutil.which("cookiecutter")
    
    if not cookiecutter_path:
        logger.error("cookiecutter command not found in PATH")
        logger.error("Please install cookiecutter or ensure it's in your PATH")
        logger.error("You can install it with: pip install cookiecutter")
        raise FileNotFoundError("cookiecutter command not found")
    
    logger.info(f"Found cookiecutter at: {cookiecutter_path}")
    
    # Build command
    cookiecutter_command = [
        cookiecutter_path,
        template_path,
        "--no-input",
        "--config-file", str(config_file),
        "-o", str(output_dir)
    ]
    
    logger.info(f"Running cookiecutter command: {' '.join(cookiecutter_command)}")
    
    try:
        result = subprocess.run(
            cookiecutter_command,
            check=True,
            capture_output=True,
            text=True
        )
        if result.stdout:
            logger.debug(f"Cookiecutter output: {result.stdout}")
    except subprocess.CalledProcessError as e:
        logger.error(f"Cookiecutter command failed with exit code {e.returncode}")
        if e.stdout:
            logger.error(f"stdout: {e.stdout}")
        if e.stderr:
            logger.error(f"stderr: {e.stderr}")
        raise
