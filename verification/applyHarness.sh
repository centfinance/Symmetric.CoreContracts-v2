# fix imports
find . -type f -name "*.sol" -exec sed -i 's/@balancer-labs\/v2-/pkg\//g' {} +
