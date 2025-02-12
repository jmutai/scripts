#!/bin/bash

# curl -sS https://raw.githubusercontent.com/jmutai/scripts/main/misc/kubectl-aliases.sh | bash
# wget -qO- https://raw.githubusercontent.com/jmutai/scripts/main/misc/kubectl-aliases.sh | bash
# Set shell
if [ "$SHELL" = "/bin/bash" ]; then
    shell_rc="$HOME/.bashrc"
elif [ "$SHELL" = "/bin/zsh" ]; then
    shell_rc="$HOME/.zshrc"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

echo "shell_rc is set to: $shell_rc"

# Install krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew &>/dev/null
)

# Add PATH modification for Krew if not already present
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
grep -qxF 'export PATH="~/.krew//bin:$PATH"' $shell_rc || echo 'export PATH="~/.krew//bin:$PATH"' >> $shell_rc
source $shell_rc

# Install kubectx and kubens
kubectl krew install ctx &>/dev/null
kubectl krew install ns &>/dev/null
kubectl krew install node-shell &>/dev/null
kubectl krew install view-secret &>/dev/null

# Add kubectl aliases to .bashrc if they are not already present
grep -qxF "alias k='kubectl'" $shell_rc || echo "alias k='kubectl'" >> $shell_rc
grep -qxF "alias kg='kubectl get'" $shell_rc || echo "alias kg='kubectl get'" >> $shell_rc
grep -qxF "alias kn='kubectl-ns'" $shell_rc || echo "alias kn='kubectl-ns'" >> $shell_rc
grep -qxF "alias kns='kubectl node-shell'" $shell_rc || echo "alias kns='kubectl node-shell'" >> $shell_rc
grep -qxF "alias kgns='kubectl get ns'" $shell_rc || echo "alias kgns='kubectl get ns'" >> $shell_rc
grep -qxF "alias kgp='kubectl get pods'" $shell_rc || echo "alias kgp='kubectl get pods'" >> $shell_rc
grep -qxF "alias kgd='kubectl get deploy'" $shell_rc || echo "alias kgd='kubectl get deploy'" >> $shell_rc
grep -qxF "alias kdd='kubectl describe deploy'" $shell_rc || echo "alias kdd='kubectl describe deploy'" >> $shell_rc
grep -qxF "alias kga='kubectl get apps -n argocd'" $shell_rc || echo "alias kga='kubectl get apps -n argocd'" >> $shell_rc
grep -qxF "alias kgas='kubectl get appset -n argocd'" $shell_rc || echo "alias kgas='kubectl get appset -n argocd'" >> $shell_rc
grep -qxF "alias kgsts='kubectl get sts'" $shell_rc || echo "alias kgsts='kubectl get sts'" >> $shell_rc
grep -qxF "alias kda='kubectl describe apps -n argocd'" $shell_rc || echo "alias kda='kubectl describe apps -n argocd'" >> $shell_rc
grep -qxF "alias kdas='kubectl describe appset -n argocd'" $shell_rc || echo "alias kdas='kubectl describe appset -n argocd'" >> $shell_rc
grep -qxF "alias kgpa='kubectl get pods --all-namespaces'" $shell_rc || echo "alias kgpa='kubectl get pods --all-namespaces'" >> $shell_rc
grep -qxF "alias kd='kubectl describe'" $shell_rc || echo "alias kdp='kubectl describe'" >> $shell_rc
grep -qxF "alias kdp='kubectl describe pod'" $shell_rc || echo "alias kdp='kubectl describe pod'" >> $shell_rc
grep -qxF "alias kl='kubectl logs'" $shell_rc || echo "alias kl='kubectl logs'" >> $shell_rc
grep -qxF "alias kdelp='kubectl delete pod'" $shell_rc || echo "alias kdelp='kubectl delete pod'" >> $shell_rc
grep -qxF "alias kaf='kubectl apply -f'" $shell_rc || echo "alias kaf='kubectl apply -f'" >> $shell_rc
grep -qxF "alias kgs='kubectl get services'" $shell_rc || echo "alias kgs='kubectl get services'" >> $shell_rc
grep -qxF "alias kgsec='kubectl get secrets'" $shell_rc || echo "alias kgsec='kubectl get secrets'" >> $shell_rc
grep -qxF "alias kgn='kubectl get nodes'" $shell_rc || echo "alias kgn='kubectl get nodes'" >> $shell_rc
grep -qxF "alias kexec='kubectl exec -it'" $shell_rc || echo "alias kexec='kubectl exec -it'" >> $shell_rc
grep -qxF "alias kge='kubectl get events'" $shell_rc || echo "alias kge='kubectl get events'" >> $shell_rc

grep -qxF "alias kvs='kubectl view-secret'" $shell_rc || echo "alias kvs='kubectl view-secret'" >> $shell_rc

grep -qxF "alias ktn='kubectl top nodes'" $shell_rc || echo "alias ktn='kubectl top nodes'" >> $shell_rc
grep -qxF "alias ktp='kubectl top pods'" $shell_rc || echo "alias ktp='kubectl top pods'" >> $shell_rc

# Reload .bashrc to apply the aliases
cp ~/.kube/kubeconfig ~/.kube/config 2>/dev/null
source $shell_rc
