{{- define "fortify.postRenderers" }}
- kustomize:
    patches:
      - patch: |
          apiVersion: apps/v1
          kind: StatefulSet
          metadata:
            name: fortify-ssc-webapp
          spec:
            template:
              spec:
                initContainers:
                  - name: mysql-wait
                    image: "registry1.dso.mil/ironbank/bitnami/mysql8:8.0.36-debian-11-r1"
                    imagePullPolicy: IfNotPresent
                    command:
                      - sh
                      - -c
                      - |
                        MAX=120; ELAPSED=0
                        echo "Waiting for MySQL (fortify-mysql:3306) to accept connections..."
                        until mysqladmin ping -h fortify-mysql --silent 2>/dev/null; do
                          ELAPSED=$((ELAPSED+3)); sleep 3
                          echo "MySQL not ready (${ELAPSED}s/${MAX}s)..."
                          if [ $ELAPSED -ge $MAX ]; then echo "ERROR: MySQL not reachable after ${MAX}s"; exit 1; fi
                        done
                        echo "MySQL accepting connections after ${ELAPSED}s"
                    resources:
                      limits:
                        cpu: 100m
                        memory: 32Mi
                      requests:
                        cpu: 50m
                        memory: 16Mi
                    securityContext:
                      allowPrivilegeEscalation: false
                      capabilities:
                        drop: ["ALL"]
                      readOnlyRootFilesystem: false
                      runAsNonRoot: true
                      runAsUser: 1001
                      runAsGroup: 1001
        target:
          kind: StatefulSet
          name: .*-webapp$
{{- end }}
