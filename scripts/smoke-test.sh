#!/usr/bin/env bash
# Checks that the table format works from the baked-in jars, without --packages.
# Usage: scripts/smoke-test.sh iceberg|delta [IMAGE]
set -euo pipefail

readonly flavor="${1:?usage: $0 iceberg|delta [IMAGE]}"
readonly image="${2:-exasol/spark-lakehouse:$("$(dirname "$0")/image-tag.sh" "$flavor")}"

case "$flavor" in
    iceberg)
        conf=(
            --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions
            --conf spark.sql.catalog.ice=org.apache.iceberg.spark.SparkCatalog
            --conf spark.sql.catalog.ice.type=hadoop
            --conf spark.sql.catalog.ice.warehouse=/tmp/iceberg-warehouse
        )
        table="ice.db.smoke"
        ;;
    delta)
        conf=(
            --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension
            --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog
            --conf spark.sql.warehouse.dir=/tmp/spark-warehouse
        )
        table="smoke"
        ;;
    *)
        echo "Unknown flavor '$flavor', expected iceberg or delta" >&2
        exit 2
        ;;
esac

readonly sql="
CREATE TABLE ${table} (id INT, name STRING) USING ${flavor};
INSERT INTO ${table} VALUES (1, 'a'), (2, 'b');
DELETE FROM ${table} WHERE id = 1;
SELECT 'RESULT', id, name FROM ${table};
"

output="$(docker run --rm "$image" /opt/spark/bin/spark-sql "${conf[@]}" -e "$sql" 2>&1)" \
    || { echo "$output"; echo "FAILED: spark-sql exited with an error" >&2; exit 1; }

expected=$'RESULT\t2\tb'
actual="$(grep '^RESULT' <<<"$output" || true)"
if [[ "$actual" != "$expected" ]]; then
    echo "$output"
    echo "FAILED: unexpected result:" >&2
    echo "$actual" >&2
    exit 1
fi
echo "OK: ${flavor} table created, modified and queried with $image"
