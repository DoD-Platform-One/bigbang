#!/bin/sh
wait_project() {
    timeElapsed=0
    POLICIES=($(kubectl get cpol -o jsonpath='{.items[*].metadata.name}'))
    READY=$(kubectl get cpol -o jsonpath='{.items[?(.status.ready==true)].metadata.name}')
    echo
    for POLICY in "${POLICIES[@]}"; do
        echo -n "$POLICY:"
        until echo $READY | grep $POLICY > /dev/null; do
            sleep 1
            timeElapsed=$(($timeElapsed+1))
            if [[ $timeElapsed -ge 600 ]]; then
                echo "Timeout"
                exit 1
            fi
            READY=$(kubectl get cpol -o jsonpath='{.items[?(.status.ready==true)].metadata.name}')
        done
        echo "Ready"
    done
    echo All policies are ready!
}