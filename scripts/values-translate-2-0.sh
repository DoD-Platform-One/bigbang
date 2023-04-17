values_file=$1

if [ -z $values_file ]; then
  echo "This script requires one parameter, the path to your values file. Rerun the script with that parameter, ex: './scripts/values-translate-2-0.sh my-values-file.yaml'."
  exit 1
fi

if [ ! -f $values_file ]; then
  echo "Values file not found, verify that the correct path was provided for your values."
  exit 1
fi

sed_gsed="sed"
# Verify sed version if on macOS
if [ "$(uname -s)" == "Darwin" ]; then
  if command -v gsed >/dev/null 2>&1; then
    sed_gsed="gsed"
  else
    echo "The 'gnu-sed' tool is not installed, but if required when running on macOS. 'gnu-sed' can be installed with 'brew install gnu-sed'."
    exit 1
  fi
fi

if ! command -v $sed_gsed >/dev/null 2>&1; then
  echo "The 'sed' tool is required to run this script. Please install 'sed' then re-run this script."
  exit 1
fi

# Update core packages
$sed_gsed -i 's/^istiooperator:$/istioOperator:/' $values_file
$sed_gsed -i 's/^kyvernopolicies:$/kyvernoPolicies:/' $values_file
$sed_gsed -i 's/^kyvernoreporter:$/kyvernoReporter:/' $values_file
$sed_gsed -i 's/^logging:$/elasticsearchKibana:/' $values_file
$sed_gsed -i 's/^eckoperator:$/eckOperator:/' $values_file
# Update addon packages
$sed_gsed -i 's/^\(\s*\)mattermostoperator:$/\1mattermostOperator:/' $values_file
$sed_gsed -i 's/^\(\s*\)nexus:$/\1nexusRepositoryManager:/' $values_file

echo "Values translation completed successfully - validate that the below translations were completed as expected:"
cat << EOF
  Core Packages:
    istiooperator -> istioOperator
    kyvernopolicies -> kyvernoPolicies
    kyvernoreporter -> kyvernoReporter
    logging -> elasticsearchKibana
    eckoperator -> eckOperator
  Addon Packages:
    mattermostoperator -> mattermostOperator
    nexus -> nexusRepositoryManager
EOF
echo "It is important to validate these and confirm that no other keys were affected."
