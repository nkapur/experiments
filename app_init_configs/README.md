# Description 
This directory contains YAML files used by Cookiecutter to generate new FastAPI applications from predefined templates. Each YAML file defines configuration options like app name, slug, EKS cluster, terraform backend and others, thus enabling automated scaffolding of FastAPI app projects.

## How does this work?

### Initialize a new app using the app_init script

The `scripts/app_init.py` script automates the process of creating app configurations and initializing new apps.

#### Basic usage (uses default base config)
```bash
python scripts/app_init.py --app-name "my_app"
```

This will:
- Use the default base configuration from `__default_base__.yaml`
- Create a config file at `app_init_configs/my_app.yaml`
- Generate the app directory at `app/my_app/`

#### With additional configuration overrides
```bash
python scripts/app_init.py --app-name "my_app" \
    --additional-configs '{"base_domain": "example.com", "python_version": "3.11"}'
```

#### With a custom base config file
```bash
python scripts/app_init.py --app-name "my_app" \
    --base app_init_configs/custom_base.yaml
```

### Default base configuration

The default base config (`__default_base__.yaml`) includes:
```yaml
default_context:
  app_name: "__default_app__"
  python_version: "3.9"
  base_domain: "navneetkapur.com"
  terraform_backend_bucket: "experiments-infra-state"
  k8s_cluster_name: "experiments-kube-cluster"
```

Any values provided via `--additional-configs` will override these defaults.

### Output
The new app folder `app/my_app` is ready to go

<img width="357" height="329" alt="Soothe App Folder Added" src="https://github.com/user-attachments/assets/af60c7d1-121c-49e1-a49e-69a254549491" />


## What next?
This app can be built using the following command from repo root
```
common/shell/build_app.sh soothe
```
It can similarly be deployed using
```sh
./common/shell/bounce_app.sh up soothe
```

## End Result
<img width="514" height="259" alt="Screenshot 2025-09-03 at 3 23 08 PM" src="https://github.com/user-attachments/assets/eb9039f2-1ea4-4866-a664-529353c4b9a0" />
