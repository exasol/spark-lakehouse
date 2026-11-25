# syntax=docker/dockerfile:1

# Apache Spark with the Iceberg, S3 and ADLS jars baked in, so containers start without resolving `--packages` from
# Maven Central on every run.
#
# HADOOP_VERSION must match the hadoop-client-api jar shipped in the base image.
# The Iceberg Spark runtime artifact is derived from SPARK_VERSION (e.g. 4.1.1 -> iceberg-spark-runtime-4.1_2.13).

ARG SPARK_VERSION=4.1.1
# Build number for this SPARK_VERSION, the last part of the image tag (<spark-version>-iceberg-<build-number>).
# Increase it with every change to this image; reset it to 1 when SPARK_VERSION changes. See ../README.md.
ARG IMAGE_BUILD_NUMBER=1

# The jars are platform-independent, so they are resolved once on the build platform.
FROM --platform=$BUILDPLATFORM apache/spark:${SPARK_VERSION} AS resolver

ARG SPARK_VERSION
ARG SCALA_VERSION=2.13
ARG ICEBERG_VERSION=1.11.0
ARG HADOOP_VERSION=3.4.2
ARG AWS_SDK_VERSION=2.42.35
ARG AZURE_DATALAKE_VERSION=12.26.2

# Resolve the packages with spark-submit itself (running SparkPi as a no-op job), so the jar set is exactly what
# `spark-submit --packages ...` would produce at container start.
# The AWS SDK v2 `bundle` is excluded in favour of the individual SDK modules listed explicitly.
RUN SPARK_MINOR="${SPARK_VERSION%.*}" \
    && /opt/spark/bin/spark-submit \
        --packages "\
org.apache.iceberg:iceberg-spark-runtime-${SPARK_MINOR}_${SCALA_VERSION}:${ICEBERG_VERSION},\
org.apache.iceberg:iceberg-aws:${ICEBERG_VERSION},\
org.apache.iceberg:iceberg-azure:${ICEBERG_VERSION},\
org.apache.spark:spark-hadoop-cloud_${SCALA_VERSION}:${SPARK_VERSION},\
org.apache.hadoop:hadoop-aws:${HADOOP_VERSION},\
org.apache.hadoop:hadoop-azure:${HADOOP_VERSION},\
software.amazon.awssdk:s3-transfer-manager:${AWS_SDK_VERSION},\
software.amazon.awssdk:kms:${AWS_SDK_VERSION},\
software.amazon.awssdk:sts:${AWS_SDK_VERSION},\
com.azure:azure-storage-file-datalake:${AZURE_DATALAKE_VERSION}" \
        --exclude-packages software.amazon.awssdk:bundle \
        --conf spark.jars.ivy=/tmp/ivy \
        --class org.apache.spark.examples.SparkPi \
        /opt/spark/examples/jars/spark-examples.jar 1 \
    && test -n "$(ls /tmp/ivy/jars/*.jar)"

FROM apache/spark:${SPARK_VERSION}

ARG SPARK_VERSION
ARG IMAGE_BUILD_NUMBER
ARG ICEBERG_VERSION=1.11.0

LABEL org.opencontainers.image.title="exasol/spark-lakehouse" \
      org.opencontainers.image.version="${SPARK_VERSION}-iceberg-${IMAGE_BUILD_NUMBER}" \
      org.opencontainers.image.description="Apache Spark ${SPARK_VERSION} with Iceberg ${ICEBERG_VERSION}, S3 and ADLS support" \
      org.opencontainers.image.base.name="docker.io/apache/spark:${SPARK_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0"

# The jars go into a separate directory, not /opt/spark/jars: many of them (Jackson, Netty, commons-*) also exist in
# /opt/spark/jars in other versions. Listing them in `spark.jars` loads them in Spark's child class loader, the same
# way `--packages` does, so Spark's own jars keep precedence.
COPY --from=resolver /tmp/ivy/jars/ /opt/spark/lakehouse-jars/
COPY spark-defaults.conf /opt/spark/conf/spark-defaults.conf
