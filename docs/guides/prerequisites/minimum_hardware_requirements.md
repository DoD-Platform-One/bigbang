# Big Bang Minimum Hardware Requirements

To calculate the minimum CPU, memory, and disk storage required to run Big Bang, open the [minimum hardware requirements Excel spreadsheet](./minimum_hardware_requirements.xlsx) and follow the instructions there.  This will allow you to select exactly which packages and pods are enabled.  In addition, it includes extra considerations to help you with sizing your cluster.  The final values will be for the entire cluster and can be split between multiple nodes.

When running across multiple availability zones, keep in mind that some of your nodes may be down for zone maintenance and the remaining nodes need to be able to handle the CPU, memory, and disk space for your cluster.
