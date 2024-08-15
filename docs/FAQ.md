# Frequently Asked Questions

## Costs and licensing Fees

> Will a user, Government program, or support contract incur any costs, other
than their own labor, for installing and using Big Bang?

Big Bang itself is open-source. You do not need to pay Platform One
to use it in your environment.

Our baseline includes multiple software components, with a variety
of open-source and commercial licenses. Details of these components and
their licensing models can be found in
[Big Bang Licensing Model Overview.](./understanding-bigbang/licensing-model.md)

In Big Bang 2.0, our default core components will be open source; however, paid
alternatives will remain available.

You are in complete control over which components you install in your
environment, and choose whether or not to use commercial software.
However, your Approving Official may require certain commercial applications for a continuous Authority to Operate (cATO).

> Are users required to set up a contract with Platform One in order to
use Big Bang?

No. Big Bang is open source, and can be used by you and your organization
without payment to Platform One.

Platform One does offer optional hosting and support contracts. These are listed in the following:

- Our Big Bang Integration Team helps customers install, upgrade, and operate Big Bang on customer hardware and in customer environments.
- Our Digital Twin service will deploy an instance of your application to
  our testing clusters, so we can ensure that changes to our baseline won't break your integration tests. Providing you with customized release notes for your environment.
- [Party Bus](https://p1.dso.mil/products/party-bus) is a managed environment and
  instance of Big Bang, which an application can be hosted on. Party Bus removes the
  need for you to operate a cluster entirely.

For more information on services, [contact us](https://p1.dso.mil/contact-us) or email platformone@dso.mil.

> Do we need a government PM to send a formal request to Platform One in order
to get started?

No. Big Bang is Open Source, and you do not need our permission to use it.
However, we always like to hear from our users, both to know how large an
impact this effort is making, and to make sure we are addressing our users'
most pressing needs.

<!--
TODO: reach out link
-->

## Security

> Is Big Bang secure? What about its plugins?

Big Bang is compliant with the
[DevSecOps Reference Architecture](https://dodcio.defense.gov/Portals/0/Documents/Library/DoD%20Enterprise%20DevSecOps%20Reference%20Design%20-%20CNCF%20Kubernetes%20w-DD1910_cleared_20211022.pdf), and is used at all impact levels and classifications.

[Iron Bank](https://p1.dso.mil/products/iron-bank) performs automated scans of all image
components used in Big Bang, and patches vulnerabilities as they are found. Big Bang
pulls all hardened images from Iron Bank.

<!--
TODO: link to cATO docs - Cyber is working on a Care Package at IL4 to link here
-->

## Deployment

> Can we stand up our own instance of Big Bang in AWS GovCloud?

Yes. Big Bang strives to be vendor-agnostic, and will run on Cloud One,
AWS GovCloud, Microsoft Azure, on-prem hardware, and in air-gapped
environments.

> Do we have to set up a full Kubernetes distribution? Can we just deploy Big Bang to a Virtural Machine?

Big Bang is, at its core, a Helm chart, which creates templates for Kubernetes
resources. As such, Big Bang requires a full Kubernetes environment.

If your organization is unable to support a full Kubernetes environment, you may wish to
consider [Party Bus](https://p1.dso.mil/products/party-bus), which is Platform One's
managed Big Bang Platform as a Service (PaaS) solution, or one of the [Big Bang Resellers](https://p1.dso.mil/resellers).

## Change Control

> How do you manage change control on Big Bang? How can we be notified of changes?

Big Bang has a two-week release cadence. You can view our
[release schedule](https://docs-bigbang.dso.mil/latest/#Navigating-our-documentation),
our [project milestones](https://repo1.dso.mil/groups/big-bang/-/milestones),
and our [release notes](https://repo1.dso.mil/big-bang/bigbang/-/releases)
for more information.

## Documentation and Briefings

> Can you provide the latest documentation and briefings?

The most up-to-date information on BigBang can be found on
[Big Bang Docs.](https://docs-bigbang.dso.mil/latest/docs)

An overview of BigBang's architecture, and the packages available, can be found
on the [Big Bang Universe.](https://universe.bigbang.dso.mil/)

It would also be useful to review
[Understanding Big Bang.](https://docs-bigbang.dso.mil/latest/docs/understanding-bigbang/?h=understanding+bigbang%2F)
