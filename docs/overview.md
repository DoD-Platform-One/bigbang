# Mattermost

## Overview

This package contains an installation of Mattermost using a helm chart built by Big Bang that leverages the operator.

## Mattermost

[Mattermost](https://mattermost.com/) is an open-source, self-hostable online chat service with file sharing, search, and integrations.
This repo provides an implementation of Mattermost for Big Bang. Installation requires that the [Mattermost Operator](https://repo1.dso.mil/platform-one/big-bang/apps/collaboration-tools/mattermost-operator) be installed in your cluster as a prerequisite.

## How it works

Mattermost is a single pane for collaboration, installed and configured via a `mattermost` CustomResource and reconciled by the operator. You can visit your installation via browser or connect through one of their Desktop apps available for many operating systems.

Please review the BigBang [Architecture Document](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/packages/mattermost/Architecture.md) for more information about it's role within BigBang.
