# Bootstrap Support Tools

1. Install sealed secrets controller manually
    ```sh
    kubectl apply -k manifests/tools/sealed-secrets
    ```
2. Create and seal the argo repo secret //TODO more info needed here
    - Create the unsealed secret yaml somehow
    - Make sure to do the thing so the sealed secret contains the label argocd expects
    ```sh
    kubeseal --format yaml <manifests/argocd/secret.yaml >secret.yaml
    ```
    or
    
    ```powershell
    Get-Content .\secret.yaml | kubeseal --format yaml >.\lgtm\secret-grafana.yaml
    ```
3. Install argo manually
    - Copy `secret.yaml` into `./manifests/argocd/.`
    - Apply the kustomized manifests:
    ```sh
    kubectl apply -k manifests/argocd
    ```
    Verify all the ArgoCD pods have started up.
4. Take over both sealed-secrets controller and ArgoCD by installing both the ArgoCD and Tools namespace root applications.
    ```sh
    kubectl apply -f root-apps/argocd.yaml
    kubectl apply -f root-apps/tools.yaml
    ```
    Consider whether to keep ArgoCD in the same root app.
5. Consider keeping secrets in a separate repository? (https://argo-cd.readthedocs.io/en/stable/user-guide/multiple_sources/)

# Maintain Tools
Should be able to just push changes to the manifests repo(s) in order for things to update.
