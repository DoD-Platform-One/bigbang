# Kiali

## Overview

This package consists of a helm chart which bundles the kiali operator and server.

## Kiali

Kiali is an application that allows for monitoring and management related to the [Istio](https://repo1.dso.mil/platform-one/big-bang/apps/core/istio-controlplane) mesh. Kiali can show you mesh topology, details, health, and can also help you determine misconfigurations.

## How it works

Kiali connects with Prometheus, Grafana, Jaeger, and Istio to collect and aggregate data. Please reference the [architecture document](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/packages/kiali/Architecture.md) for more information.

## Prerequisites

Because Kiali is used to aggregate data about the Istio service mesh, it will always be dependent on Istio.  In the Big Bang implementation, Kiali is also coupled with and dependent on Prometheus, Grafana, and Jaeger.