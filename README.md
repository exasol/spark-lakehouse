# spark-lakehouse

Apache Spark Docker images with the Iceberg or Delta Lake jars baked in. Use them instead of `apache/spark` with
`--packages`, which downloads the jars from Maven Central on every container start, e.g. as Spark Connect server in
integration tests.

| Image | Directory | Contents |
|---|---|---|
| `exadockerci4/spark-lakehouse:<spark-version>-iceberg-<build-number>` | [`iceberg/`](iceberg) | Iceberg, S3, ADLS |
| `exadockerci4/spark-lakehouse:<spark-version>-delta-<build-number>` | [`delta/`](delta) | Delta Lake, S3 |

The packages and their versions are build arguments in each `Dockerfile`. Iceberg and Delta Lake have separate images
because they depend on different versions of shared libraries.

## How the Jars Are Added

* A build stage resolves the packages with `spark-submit --packages`, so the image contains exactly the jars
  `--packages` would download at runtime.
* The jars are in `/opt/spark/lakehouse-jars/` and are loaded through `spark.jars` in
  `/opt/spark/conf/spark-defaults.conf`. As with `--packages`, Spark's own jars take precedence over other versions of
  the same libraries.
* `--jars` and `--packages` given at submit time are added to them. Replacing `/opt/spark/conf` or setting
  `spark.jars` removes them.

## Usage

Use the image like `apache/spark`, without `--packages`:

```yaml
spark:
  image: exadockerci4/spark-lakehouse:<tag>
  command:
    - /opt/spark/bin/spark-submit
    - --conf
    - spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
    # ... catalog and storage configuration ...
    - --class
    - org.apache.spark.sql.connect.service.SparkConnectServer
```

## Building and Testing

From the repository root:

```bash
for format in iceberg delta; do
  docker build -t "exadockerci4/spark-lakehouse:$(scripts/image-tag.sh "$format")" "$format"
  scripts/smoke-test.sh "$format"
done
```

[`image-tag.sh`](scripts/image-tag.sh) prints the image's current tag. [`smoke-test.sh`](scripts/smoke-test.sh)
creates, modifies and queries a table with the image, without `--packages`.

## Publishing

The [Spark Images workflow](.github/workflows/spark-images.yml) runs for pull requests and pushes to `main`. It builds
each image for `linux/amd64` and `linux/arm64`, runs the smoke test and, on `main` only, pushes the image to Docker Hub
with the organization secrets `CI4_DOCKERHUB_USERNAME` and `CI4_DOCKERHUB_TOKEN`.

An existing tag is never overwritten: the push is skipped with a warning.

## Versioning

Tags have the form `<spark-version>-<table-format>-<build-number>`. The build number is `IMAGE_BUILD_NUMBER` in the
image's `Dockerfile`, and each image has its own:

* **Any change to an image that keeps its Spark version must increase its build number by one**, e.g.
  `<spark-version>-iceberg-1` becomes `<spark-version>-iceberg-2`.
* **A new Spark version restarts the build number at 1.**

When updating versions:

* `HADOOP_VERSION` must match the `hadoop-client-api` jar in the `apache/spark` base image.
* The Iceberg and Delta Lake releases must support the Spark version.
