# kubectl-kubeplugin

`kubectl-kubeplugin` is a simple `kubectl` plugin that displays CPU and memory usage for a specific Kubernetes resource type within a given namespace.

## Installation

1. Make the script executable:
    ```bash
    chmod +x scripts/kubeplugin
    ```

2. Create a symlink in your `$PATH` under the required name `kubectl-kubeplugin`:
    ```bash
    mkdir -p $HOME/bin
    ln -sf "$PWD/scripts/kubeplugin" "$HOME/bin/kubectl-kubeplugin"
    ```

3. Add `$HOME/bin` to your `PATH` if it's not already there (add this to `.zshrc` or `.bashrc`):
    ```bash
    export PATH="$HOME/bin:$PATH"
    ```

4. Reload your shell config:
    ```bash
    source ~/.zshrc  # or ~/.bashrc
    ```

5. Verify the plugin:
    ```bash
    kubectl kubeplugin --help  # or run with real args
    ```

## Usage

```bash
kubectl kubeplugin <namespace> <resource_type>
```

### Arguments:
- `namespace` — the Kubernetes namespace (e.g., `kube-system`)
- `resource_type` — the type of resource to query (`pod` or `node`)

### Example:
```bash
kubectl kubeplugin kube-system pod
```

### Example output:
```
Resource, Namespace, Name, CPU, Memory
pod, kube-system, coredns-697968c856-bkgqd, 2m, 23Mi
pod, kube-system, local-path-provisioner-774c6665dc-n8z5x, 1m, 9Mi
pod, kube-system, metrics-server-6f4c6675d5-kptjz, 7m, 23Mi
pod, kube-system, svclb-ingress-nginx-controller-36c7b31d-8zrhw, 0m, 0Mi
pod, kube-system, svclb-ingress-nginx-controller-36c7b31d-fzs6b, 0m, 0Mi
pod, kube-system, svclb-ingress-nginx-controller-36c7b31d-k4pcs, 0m, 0Mi
```

> ⚠️ This script relies on `kubectl top`, so make sure the **metrics-server** is installed and running in your cluster.

## Project structure

```
scripts/
├── kubectl-kubeplugin
└── README.md
```