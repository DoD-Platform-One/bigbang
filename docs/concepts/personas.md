# Personas that Interact with the Big Bang Product

## Overview

The following personas interact with the Big Bang product in different ways, each with distinct responsibilities, priorities, and concerns.

## Personas

| Persona | What they do | What they care about | What they don't care about |
|---|---|---|---|
| **Mission Platform Operator (SRE)** | - Maintain the Big Bang platform itself<br>- Keep Big Bang platforms up to date<br>- Support mission applications deployed on top of a Big Bang platform | - Ease of upgrades<br>- Ease of Big Bang configuration<br>- Observability of Big Bang platform components | - Specific compliance frameworks |
| **Mission Compliance Point-of-contact (Cyber)** | - Constantly evaluate compliance of mission components<br>- Communicate compliance to authorizing official (AO)<br>- Facilitate authority-to-operate (ATO) acquisition | - Patching vulnerabilities<br>- Gathering compliance evidence<br>- Security controls | - Ease of Big Bang configuration |
| **Mission Owner (PM)** | - Liaise between technical and non-technical stakeholders | - Whether or not the mission requirements are fulfilled | - Implementation details |
| **Mission Application Developer (Dev)** | - Develop applications deployed to existing or new Big Bang platforms | - Ease of application deployment<br>- Application runtime observability | - Runtime security of environment |
| **Package Vendor (Vendor)** | - Maintains their own package projects on repo1<br>- Maintains their product's package integration for Big Bang | - Ease of integration with Big Bang platform | - Any runtime concerns like platform security or ease of configuration |