# Description 
This directory contains YAML files used by Cookiecutter to generate new FastAPI applications from predefined templates. Each YAML file defines configuration options like app name, slug, EKS cluster, terraform backend and others, thus enabling automated scaffolding of FastAPI app projects.

## How does this work?

### Create a yaml file for the app
app_init_configs/soothe.yaml
```yaml
default_context:
  app_name: "soothe"
  # project_slug will be auto-generated from app_name by the template
  python_version: "3.9"
  base_domain: "navneetkapur.com"
  terraform_backend_bucket: "experiments-infra-state"
  k8s_cluster_name: "experiments-kube-cluster"
```

### Run the following command 
to initialize app folder
```bash
cookiecutter __cookie_cutter__ --no-input \
    --config-file app_init_configs/soothe.yaml \
    -o app/
```

### Example Output
