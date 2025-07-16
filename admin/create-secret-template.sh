kubectl create secret generic test-secret \
--from-literal=type=git \
--from-literal=url=git@github.com:matt328/bootstrap \
--from-literal=username=matt328 \
--from-literal=password= \
--namespace=management \
--dry-run=client \
-o yaml | kubeseal --format yaml > test-sealed-secret.yaml