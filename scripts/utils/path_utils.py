"""Path and dictionary utility functions."""

from pathlib import Path


def get_repo_root() -> Path:
    """Determine the repository root directory.
    
    Assumes the script is in a subdirectory of the repo root.
    """
    script_dir = Path(__file__).resolve().parent.parent
    # Go up one level from scripts/ to get repo root
    repo_root = script_dir.parent
    return repo_root


def merge_dicts(base, override):
    """Recursively merge two dictionaries, with override taking precedence.
    
    Args:
        base: Base dictionary
        override: Dictionary to merge on top of base (takes precedence)
    
    Returns:
        Merged dictionary
    """
    result = base.copy()
    for key, value in override.items():
        if key in result and isinstance(result[key], dict) and isinstance(value, dict):
            result[key] = merge_dicts(result[key], value)
        else:
            result[key] = value
    return result
