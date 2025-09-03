application_deployer_roles = {
    "staging" = {
        name = "AppDeployerRole-staging"
        namespaces = ["staging"]
    }
    "prod" = {
        name = "AppDeployerRole-prod"
        namespaces = ["prod"]
    }
}