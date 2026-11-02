# Integration tests: deploy real resources, check them, then destroy them.
# This costs money and needs cloud credentials.
# Run: tofu test -test-directory=tests/integration
# Test case catalog: tests/README.md

variables {
  name_prefix = "itest"
  # Documentation range, nobody can reach the API. The test only reads the Azure API.
  allowed_api_cidrs = ["203.0.113.0/24"]
  tags = {
    Purpose = "integration-test"
  }
}

# I-01, I-03
run "deploy" {
  command = apply

  assert {
    condition     = output.cluster_fqdn != "" && output.kubernetes_version != ""
    error_message = "The cluster was not created."
  }

  assert {
    condition     = startswith(output.oidc_issuer_url, "https://")
    error_message = "The OIDC issuer URL output must be set."
  }
}

# I-02
run "system_node_pool_is_ready" {
  module {
    source = "./tests/integration/cluster-check"
  }

  variables {
    cluster_name        = run.deploy.cluster_name
    resource_group_name = run.deploy.resource_group_name
    node_pool_name      = run.deploy.node_pool_name
  }

  assert {
    condition     = output.node_count == 2 && output.mode == "System"
    error_message = "The system node pool does not have the desired node count."
  }
}
