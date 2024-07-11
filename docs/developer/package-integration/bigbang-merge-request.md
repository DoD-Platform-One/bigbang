# Create a Big Bang Merge Request

Following the steps in the [flux integration](flux.md), create a Merge Request (MR) into Big Bang for your package.
When ready, add the all-packages label to the MR and run the pipeline. This will trigger a pipeline with all big bang packages installed to a k3d cluster.

A passing all-packages pipeline is required prior to merging the new package. This validates that the additional package works with existing packages.
