#!/bin/bash

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
CYN='\033[0;36m'
NC='\033[0m' # No Color


# Count passes and fails.  FAIL is used as exit code.
PASS=0
FAIL=0

# test-values.yaml sets ENABLED_POLICIES as an environmental variable
read -a POLICIES <<< "$ENABLED_POLICIES"

# Find existing pull secret (in any namespace) and apply it to the test namespace
echo -e "${CYN}Setup: Cloning pull secret into test namespace${NC}"
NAMESPACE="kyverno-policies-bbtest"
PSNAME="private-registry"
PSNAMESPACE=$(kubectl get secret -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name | grep -m 1 -oP ".*(?=$PSNAME)" | tr -d ' ')
kubectl get secret $PSNAME -n $PSNAMESPACE -o yaml | sed "s/namespace: $PSNAMESPACE/namespace: $NAMESPACE/" | kubectl apply -f -

# Patch the default service account with the pull secret
kubectl patch serviceaccount default -n $NAMESPACE -p "{\"imagePullSecrets\": [{\"name\": \"$PSNAME\"}]}"

#######################################
echo ---
echo -e "${CYN}Test: Enabled cluster policies are deployed and ready${NC}"
for POLICY in "${POLICIES[@]}"; do
  echo -n "- $POLICY: "
  STATUS=$(kubectl get clusterpolicy "$POLICY" -o jsonpath='{.status.ready}')
  if [ "$STATUS" == "true" ]; then
    echo -e "${GRN}PASS${NC}"
    ((PASS+=1))
  else
    echo -e "${RED}FAIL${NC}"
    ((FAIL+=1))
  fi
done

#######################################
echo ---
echo -e "${CYN}Test: Disabled cluster policies are not deployed${NC}"
echo -n "- enabled policies >= deployed policies: "
DEPLOYED_POLICIES=( $(kubectl get cpol --no-headers -o custom-columns=":metadata.name") )
# Get deployed policies that are not in our enabled policies list
DELTA=( $(echo ${POLICIES[@]} ${POLICIES[@]} ${DEPLOYED_POLICIES[@]} | tr ' ' '\n' | sort | uniq -u) )
if [ -z $DELTA ]; then
  echo -e "${GRN}PASS${NC}"
  ((PASS+=1))
else
  echo -e "${RED}FAIL${NC}"
  echo "Policies causing failure: ${DELTA[@]}"
  ((FAIL+=1))
fi

#######################################
echo ---
echo -e "${CYN}Test: All enabled policies have at least one test${NC}"

# Deploy manifests
kubectl apply -n $NAMESPACE -f /yaml/

# Wait up to 5 minutes for all our resources to be ready
timeout 1m sh -c "until kubectl wait --for condition=Ready pods -n $NAMESPACE --all > /dev/null 2>&1; do sleep 2; done"
if [ $? -ne 0 ]; then
  echo "ERROR: Some manifests did not deploy correctly"
  kubectl get -n $NAMESPACE -f /yaml/
  ((FAIL+=1))
fi

# Output is "resource_kind;resource_name;test_type;expected_result;"
EXPECTED_RESULTS=( $(kubectl get -f /yaml/ -n $NAMESPACE -o jsonpath='{range .items[*]}{@.kind};{range @.metadata}{@.name};{range @.annotations}{@.kyverno-policies-bbtest/type};{@.kyverno-policies-bbtest/expected}{"\n"}{end}') )
for POLICY in "${POLICIES[@]}"; do
  echo -n "- $POLICY: "
  # Count unique results from array that contain the policy name
  UNIQ_RESULTS=$(printf '%s\n' "${EXPECTED_RESULTS[@]}" | sed "/$POLICY/!d" | sed 's/.*;//' | uniq)
  if [ -z "$UNIQ_RESULTS" ]; then
    echo -e "${RED}FAIL${NC} "
    ((FAIL+=1))
  else
    echo -e "${GRN}PASS${NC}"
    ((PASS+=1))
  fi
done

#######################################
echo ---
echo -e "${CYN}Test: Policies perform the expected actions${NC}"

for EXPECTED_RESULT in "${EXPECTED_RESULTS[@]}"; do
  # Split the values
  IFS=';' read KIND MANIFEST TESTTYPE EXPECTED <<< $EXPECTED_RESULT
  if [ "$TESTTYPE" != "ignore" ]; then
    echo -n "- $MANIFEST ($TESTTYPE): "
    # Policy derived from manifest name minus the '-#' suffix
    POLICY="${MANIFEST%-*}"
  fi

  #######################################
  ##### Validate Test
  if [ "$TESTTYPE" == "validate" ]; then
    # Lookup manifest in policy report to get actual result and compare to expected

    ACTUAL=$(kubectl get -n $NAMESPACE polr -o jsonpath="{range .items[*].results[?(.policy==\"$POLICY\")]}{..name};{.result}{\"\n\"}{end}" | grep -oP "(?<=$MANIFEST;).*")
    if [ -z "$ACTUAL" ]; then
      echo -e "${RED}FAIL${NC} (No result found in policy report)"
      ((FAIL +=1))
    elif [ "$ACTUAL" != "$EXPECTED" ]; then
      echo -e "${RED}FAIL${NC} (Expected $EXPECTED, but found $ACTUAL)"
      ((FAIL +=1))
    else
      echo -e "${GRN}PASS${NC}"
      ((PASS +=1))
    fi

  #######################################
  ##### Generate Test
  elif [ "$TESTTYPE" == "generate" ]; then
    # Get more information from the test annotations
    TARGET=$(kubectl get $KIND $MANIFEST -n $NAMESPACE -o jsonpath='{range .metadata.annotations}{@.kyverno-policies-bbtest/kind};{@.kyverno-policies-bbtest/name};{@.kyverno-policies-bbtest/namespace}{end}')
    IFS=';' read TARGKIND TARGNAME TARGNS <<< $TARGET
    ACTUAL=$(kubectl get $TARGKIND $TARGNAME -n $TARGNS --ignore-not-found)
    if [ -z "$ACTUAL" ]; then
      if [ "$EXPECTED" != "ignore" ]; then
        echo -e "${RED}FAIL${NC} (Could not find $TARGKIND/$TARGNAME in namespace $TARGNS)"
        ((FAIL +=1))
      else
        echo -e "${GRN}PASS${NC}"
        ((PASS +=1))
      fi
    else
      if [ "$EXPECTED" == "ignore" ]; then
        echo -e "${RED}FAIL${NC} (Found $TARGKIND/$TARGNAME in namespace $TARGNS, but did not expect it)"
        ((FAIL +=1))
      else
        echo -e "${GRN}PASS${NC}"
        ((PASS +=1))
      fi
    fi

  #######################################
  ##### Mutate Test
  elif [ "$TESTTYPE" == "mutate" ]; then
    # Get more information from the test annotations
    TARGET=$(kubectl get $KIND $MANIFEST -n $NAMESPACE -o jsonpath='{range .metadata.annotations}{@.kyverno-policies-bbtest/key};{@.kyverno-policies-bbtest/value}{end}')
    IFS=';' read TARGKEY TARGVALUE <<< $TARGET
    ACTUAL=$(kubectl get $KIND $MANIFEST -n $NAMESPACE -o jsonpath="{$TARGKEY}")
    if [ -z "$ACTUAL" ]; then
      if [ "$EXPECTED" != "ignore" ]; then
        echo -e "${RED}FAIL${NC} (Could not find $TARGKEY in $KIND/$MANIFEST)"
        ((FAIL +=1))
      else
        echo -e "${GRN}PASS${NC}"
        ((PASS +=1))
      fi
    elif [ "$ACTUAL" != "$TARGVALUE" ]; then
      if [ "$EXPECTED" != "ignore" ]; then
        echo -e "${RED}FAIL${NC} (In $KIND/$MANIFEST, $TARGKEY is $ACTUAL, but expected it to be $TARGVALUE)"
        ((FAIL +=1))
      else
        echo -e "${GRN}PASS${NC}"
        ((PASS +=1))
      fi
    else
      if [ "$EXPECTED" == "ignore" ]; then
        echo -e "${RED}FAIL${NC} (In $KIND/$MANIFEST, did not expect $TARGKEY to be $ACTUAL)"
        ((FAIL +=1))
      else
        echo -e "${GRN}PASS${NC}"
        ((PASS +=1))
      fi
    fi


  #######################################
  ##### Unknown Test
  elif [ "$TESTTYPE" != "ignore" ]; then
    echo -e "${RED}FAIL${NC} (Invalid test type)"
    ((FAIL +=1))
  fi
done

#######################################
# Cleanup manifests
echo ---
echo -e "${CYN}Clean Test Resources${NC}"
kubectl delete -n $NAMESPACE -f /yaml/ --now
kubectl delete ns $NAMESPACE
echo ---
((TOTAL=PASS+FAIL))
echo -e "${CYN}Test Summary:${NC}"
echo -e "  Passing: $PASS"
echo -e "  Failing: $FAIL"
echo -e "  Total  : $TOTAL"
exit $FAIL

#########################