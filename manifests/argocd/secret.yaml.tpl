apiVersion: v1
kind: Secret
metadata:
  name: matt328-apps-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
  annotations:
    sealedsecrets.bitnami.com/managed: "true"
stringData:
  type: git
  url: git@github.com:matt328/bootstrap
  sshPrivateKey: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <key here>
    -----END OPENSSH PRIVATE KEY-----
