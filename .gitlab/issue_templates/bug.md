# Bug

## Description

Describe the problem, what were you doing when you noticed the bug?

Provide any steps possible used to reproduce the error (ideally in an isolated fashion).

## BigBang Version

What version of BigBang were you running?

This can be retrieved multiple ways:

```bash
# via helm
helm ls -n bigbang

# via the deployed umbrella git tag
kubectl get gitrepository -n bigbang
```