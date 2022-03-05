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
POLICIES=($ENABLED_POLICIES)

#######################################

# Test for disabled cluster policies
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

# Set all policies to audit so we can test them one at a time
echo ---
echo -e "${CYN}Setup: Set all policies to audit${NC}"
POLICY_FAILACTIONS=()
for POLICY in "${POLICIES[@]}"; do

  # Save current validation failure action for restoring
  POLICY_FAILACTIONS+=($(kubectl get cpol $POLICY -o jsonpath="{.spec.validationFailureAction}"))

  # Patch policy validation failure action
  if [ "${POLICY_FAILACTIONS[-1]}" != "audit" ]; then
    kubectl patch cpol $POLICY -p '{"spec":{"validationFailureAction":"audit"}}' --type=merge
  fi
done

#######################################

# Get initial status of deployed policies
READY=$(kubectl get cpol -o jsonpath='{.items[?(.status.ready==true)].metadata.name}')

# Test each policy individually
for POLICY in "${POLICIES[@]}"; do
  echo ---
  echo -e "${CYN}Test: $POLICY${NC}"

  # Initialize variables
  ACTUAL_RESULTS=()
  EXPECTED_RESULTS=()
  TESTTYPE="UNK"
  ATTEMPT=0
  ALLOWED=()

  # Read in YAML file into an array for each resource
  IFS=? YAMLS=( $(cat /yaml/$POLICY.yaml | sed -e 's/?/ /g' -e 's/---/?/g') )

  # Create an array with expected results
  # Format is "resource_kind;resource_namespace;resource_name;test_type;expected_result"
  for YAML in "${YAMLS[@]}"; do
    TESTTYPE=$(echo $YAML | grep -m 1 -oP '(?<=kyverno-policies-bbtest/type: ).*')
    KIND=$(echo $YAML | grep -m 1 -oP '(?<=^kind: ).*')
    NAME=$(echo $YAML | grep -m 1 -oP '(?<=^  name: ).*')
    NAMESPACE=$(echo $YAML | grep -m 1 -oP '(?<=^  namespace: ).*')
    EXPECTED=$(echo $YAML | grep -m 1 -oP '(?<=kyverno-policies-bbtest/expected: ).*')
    EXPECTED_RESULTS+=("$KIND;$NAMESPACE;$NAME;$TESTTYPE;$EXPECTED")
  done

  if [ "$TESTTYPE" == "validate" ]; then
    # Patch policy under test to enforce
    echo -n "Setting policy to enforce: "
    kubectl patch cpol $POLICY -p '{"spec":{"validationFailureAction":"enforce"}}' --type=merge
  fi

  # Verify policy is ready
  echo -n "- Policy deployed and ready: "
  while [ "$ATTEMPT" -le 240 ] && ! echo $READY | grep $POLICY > /dev/null; do
    ((ATTEMPT+=1))
    sleep 1
    READY=$(kubectl get cpol -o jsonpath='{.items[?(.status.ready==true)].metadata.name}')
  done
  if [ "$ATTEMPT" -gt 240 ]; then
    echo -e "${RED}FAIL${NC}"
    ((FAIL+=1))
    kubectl get cpol $POLICY
  else
    echo -e "${GRN}PASS${NC}"
    ((PASS+=1))
  fi

  # Apply test vectors and verify no errors
  echo -n "- Test vectors deployed: "
  DEPLOYS=$(kubectl apply -f /yaml/$POLICY.yaml 2>&1)

  # Verify resources were deployed
  NUM_DEPLOYS=$(echo $DEPLOYS | grep -oP "created$|configured$|blocked" | wc -l)
  if [ "${#EXPECTED_RESULTS[@]}" -eq "$NUM_DEPLOYS" ]; then
    echo -e "${GRN}PASS${NC}"
    ((PASS+=1))
  else
    echo -e "${RED}FAIL${NC}"
    ((FAIL+=1))
    echo "Deployment results:"
    echo $DEPLOYS
  fi

  echo -n "- At least two test vectors: "
  # Count unique results from array that contain the policy name
  UNIQ_RESULTS=$(printf -- '%s\n' "${EXPECTED_RESULTS[@]}" | sed "/$POLICY/!d" | sed 's/.*;//' | uniq)
  if [ -z "$UNIQ_RESULTS" ]; then
    echo -e "${RED}FAIL${NC}"
    ((FAIL+=1))
  else
    echo -e "${GRN}PASS${NC}"
    ((PASS+=1))
  fi

  for EXPECTED_RESULT in "${EXPECTED_RESULTS[@]}"; do
    # Split the values
    unset NSOPT
    IFS=';' read KIND NAMESPACE MANIFEST TESTTYPE EXPECTED <<< $EXPECTED_RESULT
    if [ -n "$NAMESPACE" ]; then
      NSOPT="-n"
    fi
    if [ "$TESTTYPE" != "ignore" ]; then
      echo -n "- Test vector $MANIFEST ($TESTTYPE): "
    fi

    #######################################
    ##### Validate Test
    if [ "$TESTTYPE" == "validate" ]; then
      ALLOW=$(echo $DEPLOYS | grep -oP "$MANIFEST(?= created)")
      BLOCK=$(echo $DEPLOYS | grep -oP "$MANIFEST(?= was blocked)")
      if [ "$EXPECTED" == "pass" ]; then
        # Verify manifest is in the allowed list and not in the blocked list
        if [ -n "$ALLOW" ] && [ -z "$BLOCK" ]; then
          echo -e "${GRN}PASS${NC}"
          ((PASS+=1))
        else
          echo -e "${RED}FAIL${NC} (Expected allowed, but was blocked)"
          ((FAIL+=1))
        fi
      elif [ "$EXPECTED" == "fail" ]; then
        # Verify manifest is in the blocked list and not in the allowed list
        if [ -z "$ALLOW" ] && [ -n "$BLOCK" ]; then
          echo -e "${GRN}PASS${NC}"
          ((PASS+=1))
        else
          echo -e "${RED}FAIL${NC} (Expected blocked, but was allowed)"
          ((FAIL+=1))
        fi
      fi

    #######################################
    ##### Generate Test
    elif [ "$TESTTYPE" == "generate" ]; then
      # Get more information from the test annotations
      TARGET=$(kubectl get $KIND $MANIFEST $NSOPT $NAMESPACE -o jsonpath='{range .metadata.annotations}{@.kyverno-policies-bbtest/kind};{@.kyverno-policies-bbtest/name};{@.kyverno-policies-bbtest/namespace}{end}')
      IFS=';' read TARGKIND TARGNAME TARGNS <<< $TARGET

      ATTEMPT=0
      ACTUAL=$(kubectl get $TARGKIND $TARGNAME -n $TARGNS --ignore-not-found)
      while [ -z "$ACTUAL" ] && [ "$ATTEMPT" -le 60 ]; do
        ((ATTEMPT+=1))
        sleep 1
        ACTUAL=$(kubectl get $TARGKIND $TARGNAME -n $TARGNS --ignore-not-found)
      done

      # Resource not found
      if [ -z "$ACTUAL" ]; then
        if [ "$EXPECTED" != "ignore" ]; then
          echo -e "${RED}FAIL${NC} (Could not find $TARGKIND/$TARGNAME in namespace $TARGNS)"
          ((FAIL +=1))
        else
          echo -e "${GRN}PASS${NC}"
          ((PASS +=1))
        fi

      # Resource found
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
      TARGET=$(kubectl get $KIND $MANIFEST $NSOPT $NAMESPACE -o jsonpath='{range .metadata.annotations}{@.kyverno-policies-bbtest/key};{@.kyverno-policies-bbtest/value};{@.kyverno-policies-bbtest/kind};{@.kyverno-policies-bbtest/name};{@.kyverno-policies-bbtest/namespace}{end}')
      IFS=';' read TARGKEY TARGVALUE TARGKIND TARGNAME TARGNS <<< $TARGET

      # Override default target if annotations defined a different one
      if [ -n "$TARGKIND" ]; then KIND=$TARGKIND; fi
      if [ -n "$TARGNAME" ]; then MANIFEST=$TARGNAME; fi
      if [ -n "$TARGNS" ]; then NAMESPACE=$TARGNS; NSOPT="-n"; fi

      # Retrieve values to check if they are mutated
      ATTEMPT=0
      ACTUAL=$(kubectl get $KIND $MANIFEST $NSOPT $NAMESPACE -o jsonpath="{$TARGKEY}")
      while [ -z "$ACTUAL" ] && [ "$ATTEMPT" -le 60 ]; do
        ((ATTEMPT+=1))
        sleep 1
        ACTUAL=$(kubectl get $KIND $MANIFEST $NSOPT $NAMESPACE -o jsonpath="{$TARGKEY}")
      done

      # Key not found
      if [ -z "$ACTUAL" ]; then
        if [ "$EXPECTED" != "ignore" ]; then
          echo -e "${RED}FAIL${NC} (Could not find $TARGKEY in $KIND/$MANIFEST)"
          ((FAIL +=1))
        else
          echo -e "${GRN}PASS${NC}"
          ((PASS +=1))
        fi

      # Key found, but value did not match
      elif [ "$ACTUAL" != "$TARGVALUE" ]; then
        if [ "$EXPECTED" != "ignore" ]; then
          echo -e "${RED}FAIL${NC} (In $KIND/$MANIFEST, $TARGKEY is $ACTUAL, but expected it to be $TARGVALUE)"
          ((FAIL +=1))
        else
          echo -e "${GRN}PASS${NC}"
          ((PASS +=1))
        fi

      # Key found and value matched
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

  if [ "$TESTTYPE" == "validate" ]; then
    # Unpatch policy
    echo -n "Setting policy to audit: "
    kubectl patch cpol $POLICY -p '{"spec":{"validationFailureAction":"audit"}}' --type=merge
  fi

  echo "Cleaning up Test Resources"
  kubectl delete -f /yaml/$POLICY.yaml --force 2>/dev/null
done

#######################################

# Restore policy settings
echo ---
echo -e "${CYN}Cleanup: Restore policy's validation failure action${NC}"
for POLICY in "${POLICIES[@]}"; do

  # Patch policy validation failure action
  if [ "${POLICY_FAILACTIONS[0]}" != "audit" ]; then
    kubectl patch cpol $POLICY -p "{\"spec\":{\"validationFailureAction\":\"${POLICY_FAILACTIONS[0]}\"}}" --type=merge
  fi

  # Remove first element from array
  POLICY_FAILACTIONS=("${POLICY_FAILACTIONS[@]:1}")
done

#######################################
##### Summary
echo ---
((TOTAL=PASS+FAIL))
echo -e "${CYN}Test Summary:${NC}"
echo -e "  Passing: $PASS"
echo -e "  Failing: $FAIL"
echo -e "  Total  : $TOTAL"
exit $FAIL