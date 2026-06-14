"""Deployment fabric registry used by app_init."""

import yaml

from scripts.utils.path_utils import get_repo_root

DEFAULT_DEPLOYMENT_FABRIC = "k8s"
FABRICS_PATH = get_repo_root() / "__cookie_cutter__" / "deployment_fabrics.yaml"


def load_deployment_fabrics() -> dict:
    with open(FABRICS_PATH) as fabrics_file:
        return yaml.safe_load(fabrics_file)


def get_deployment_fabric_choices() -> tuple[str, ...]:
    return tuple(load_deployment_fabrics().keys())
