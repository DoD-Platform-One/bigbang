# New Methodology for images.txt, package-images.yaml, oci_package_list.txt, and Others

## BLUF (Bottom Line Up Front)

1. Big Bang image metadata now comes from explicit declarations (no more cluster scraping)
2. New `images-v2-*` artifacts show the dependency graph so you can pre-pull or allowlist exactly what you need—no Istio/Kyverno/Flux noise unless they are actual dependencies.
3. `images.txt` is now a copy of `images-v2-with-dependencies.txt` (which uses the explicit declarations)
4. The `smoke tests` stage and its jobs (`clean install all-packages` and `clean install oci all-packages`) have been eliminated from the Big Bang release pipeline since each package is tested individually as part of the individual package pipeline.
5. The Big Bang release pipeline now [completes in around 20 minutes rather than multiple hours](../docs/adrs/0008-generate-images-metadata-from-explicit-container-image-references.md#comparing-old-and-new-pipelines), saving the release engineers considerable time on every release.

## Terms / Glossary

Throughout this article, the terms core, umbrella, and Big Bang chart are all used interchangeably.

## Breaking Changes

None

## What changed and when?

The changes were introduced in [Big Bang 3.4.0](https://repo1.dso.mil/big-bang/bigbang/-/releases/3.4.0) on August
7, 2025.

The methodology used to compute the contents of the following files changed:

1. `images.txt`
2. `package-images.yaml`
3. `oci_package_list.txt`

Three (3) new files are being generated:

1. `images-v2-dependencies.yaml`
2. `images-v2-with-dependencies.txt`
3. `images-v2-no-dependencies.txt`

The old methodology spun up the package on a cluster and then pulled a list of all images running in the cluster,
whether they were for that package or not.
Therefore, the list of images contained references to Istio, Kyverno, Flux CD, the package of concern, and sometimes
more.
This was an implicit approach and led to an imprecise list of images.

The new methodology uses an explicit approach where all images are defined purposefully in the following locations:

| Source / Location                                                          | Key Path                       | Scope                 | Example                                                                                                                |
|----------------------------------------------------------------------------|--------------------------------|-----------------------|------------------------------------------------------------------------------------------------------------------------|
| Package's `chart/Chart.yaml`                                               | `annotations."helm.sh/images"` | `package`, `umbrella` | [Example](https://repo1.dso.mil/big-bang/product/packages/argocd/-/blob/8.3.4-bb.0/chart/Chart.yaml?ref_type=tags#L42) |
| Subcharts listed in `chart/Chart.yaml` that contain their own `Chart.yaml` | `annotations."helm.sh/images"` | `package`, `umbrella` |                                                                                                                        |
| Flux kustomization in `base/flux/kustomization.yaml`                       | `images`                       | `umbrella`            | [Example](https://repo1.dso.mil/big-bang/bigbang/-/blob/3.6.0/base/flux/kustomization.yaml?ref_type=tags#L6)           |
| Test images in `tests/images.txt`                                          | N/A                            | `umbrella`            | [Example](https://repo1.dso.mil/big-bang/bigbang/-/blob/3.6.0/tests/images.txt?ref_type=tags)                          |

If you are looking at the `images.txt` from a Big Bang release and you do not see the image you expect, it is likely not
explicitly defined in one of these locations.
If it is defined and you still do not see it, please
[create an issue](https://repo1.dso.mil/big-bang/bigbang/-/issues/new).

## What are the `images-v2-*` files and should I care about them?

1. `images-v2-dependencies.yaml`
2. `images-v2-with-dependencies.txt`
3. `images-v2-no-dependencies.txt`

These new files were created from the ground up to take a true dependency graph approach that will be fully leveraged in
the future.

They are available in both the package repos and the umbrella release level.

See [an example of the `images-v2-dependencies.yaml` from the Big Bang 3.6.0 release](https://umbrella-bigbang-releases.s3-us-gov-west-1.amazonaws.com/umbrella/3.6.0/images-v2-dependencies.yaml).

For more technical details, please review [ADR 8: Generate Images Metadata from Explicit References](../docs/adrs/0008-generate-images-metadata-from-explicit-container-image-references.md)

## Where does `images.txt` come from now?

1. The new dependency graph model is used to generate `images-v2-dependencies.yaml`.
2. `images-v2-with-dependencies.txt` is created.
3. A copy of `images-v2-with-dependencies.txt` is saved as `images.txt`

Therefore, `images.txt` is an exact replica of `images-v2-with-dependencies.txt`.

## Is there anything I need to do differently?

No. If you were using `images.txt` before, keep on using it, but know that the images listed in it only show up because
they are explicitly defined in one of the locations detailed above.

If you want to begin leveraging images metadata and are not already using `images.txt`, the recommendation is to use
`images-v2-dependencies.yaml` directly to get as close as possible to the source of truth.

## Deprecation Plan

`images.txt` will remain for the foreseeable future. If you are already using it, keep doing so.

## Questions?

If you have any questions, concerns, or ideas about this shift, please reach out to the
[Pipelines channel on MatterMost IL4](https://chat.il4.dso.mil/p1-big-bang/channels/pipelines--infrastructure).
