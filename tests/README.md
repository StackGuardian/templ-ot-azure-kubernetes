# Tests

Tests use the built-in OpenTofu test framework (`tofu test`, OpenTofu 1.9 or later).

| Level | Folder | What it does | Cost | When it runs |
|---|---|---|---|---|
| Unit | `tests/unit` | Plan only with mocked providers. Checks configuration and security settings. | None | Merge requests into `development` or `main`, and tags |
| Integration | `tests/integration` | Deploys real resources, checks them, destroys them. | Cloud cost while running | Tags, when cloud credentials are set (`integration-tests` job) |

In the GitLab pipeline, the `unit-tests` job also publishes the results as a JUnit test report (**Tests** tab of the pipeline and of the merge request). The script `ci/tofu-json-to-junit.py` converts the output of `tofu test -json` to JUnit XML.

## Run locally

```bash
tofu init
tofu test -test-directory=tests/unit
tofu test -test-directory=tests/integration   # needs cloud credentials
```

## Test cases

| ID | Level | Description | Status |
|---|---|---|---|
| U-01 | Unit | Default variables produce a valid plan with all default tags | done |
| U-02 | Unit | Invalid `name_prefix` is rejected | done |
| U-03 | Unit | Custom `tags` are merged with the default tags | done |
| U-04 | Unit | API server is limited to `allowed_api_cidrs` | done |
| U-05 | Unit | `allowed_api_cidrs` containing `0.0.0.0/0` is rejected | done |
| U-06 | Unit | Local accounts are disabled, Entra ID with Azure RBAC is enabled | done |
| U-07 | Unit | OIDC issuer and workload identity are enabled | done |
| U-08 | Unit | Azure Policy add-on, Container Insights and `kube-audit-admin` logs are enabled | done |
| U-09 | Unit | Deploying identity gets the AKS RBAC Cluster Admin role on the cluster | done |
| U-10 | Unit | Nodes have no public IPs, are in the node subnet with an NSG, Cilium network policy is on | done |
| U-11 | Unit | `allowed_api_cidrs` broader than `/8` (for example `128.0.0.0/1`) is rejected | done |
| U-12 | Unit | The Log Analytics workspace name ends with a random 6 character suffix, so a redeployment does not collide with a soft-deleted workspace | done |
| U-13 | Unit | `advanced_settings.node_count` below 2 is rejected | done |
| I-01 | Integration | Cluster is created, FQDN and Kubernetes version are set | done |
| I-02 | Integration | System node pool has the desired node count | done |
| I-03 | Integration | OIDC issuer URL output is set | done |

Integration tests are written but have not run against a real cloud account yet.
