ARG K3S_VERSION

FROM golang as base

WORKDIR /go/src/app
COPY kubeconfig_server.go .
RUN CGO_ENABLED=0 go build -o kubeconfig_server

FROM rancher/k3s:${K3S_VERSION}

COPY --from=base /go/src/app/kubeconfig_server /bin/
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh

# k3s port
EXPOSE 6443

# kubeconfig server port
EXPOSE 8081

# http(s) port
EXPOSE 80
EXPOSE 443

ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["server", "--tls-san=k3s"]
