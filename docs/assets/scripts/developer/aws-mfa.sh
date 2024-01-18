#!/bin/bash
##################################################################################
# This MFA authentication script will add temporary access keys to your credentials file plus an additional AWS Session Token which is valid for a maximum of 12 hours.
# Pass parameters in like so... temporary profile must already exist with region configured in your CLI profile. See example in docs.
# bash aws-mfa.sh --user <username> --profile <temporary profile> --token <token-code>
# You can hard code your username after the - on line 9
# profile_long variable is your long term access keys

user=${user:-}
profile=${profile:-default}
profile_long=bigbang
token=${token:-}
serial="arn:aws-us-gov:iam::141078740716:mfa/${user}"

echo "If having issues with this script please see example ~/.aws/credentials file for setup @ https://repo1.dso.mil/big-bang/bigbang/-/blob/add-aws-mfa-scripting-to-k3d-dev/docs/assets/scripts/developer/mfa-aws-creds-example"

while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare $param="$2"
    # echo $1 $2 # Optional to see the parameter:value result
  fi
  shift
done

if [ ${#token} -ne 6 ]; then
  echo "Please provide a six digit token code with --token <token-code>"
  exit 1
fi

echo "user: $user"
echo "profile: $profile"
echo "profile-long-term: $profile_long"
echo "token: $token"
echo "serial: $serial"

##################################################################################
# Remove existing environment variable values
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# Get temporary MFA credentials
creds=$(aws sts get-session-token --token-code $token --profile $profile_long --serial-number $serial --query 'Credentials')
aws configure set aws_access_key_id $(echo $creds | python3 -c "import sys, json; print(json.load(sys.stdin)['AccessKeyId'])") --profile=$profile
aws configure set aws_secret_access_key $(echo $creds | python3 -c "import sys, json; print(json.load(sys.stdin)['SecretAccessKey'])") --profile=$profile
aws configure set aws_session_token $(echo $creds | python3 -c "import sys, json; print(json.load(sys.stdin)['SessionToken'])") --profile=$profile
aws sts get-caller-identity --profile $profile
