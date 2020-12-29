# RKE2 Packer

An _extremely_ simple packer script to pre-load rke2 dependencies for airgapped deployment.

This packer script is __not__ intended to be used as a standard for airgapped rke2 deployments, it is simply a quick and dirty way to enable airgap deployments in the context of BigBang's CI.

## Future Work

This is currently baselined off of a vanilla RHEL8.3 ami, we should base this off of a P1 gold standard stig'd ami.
