<?php

require_once "./Couchbase/autoload.php";

function getCollection(
    string $connectionString,
    string $username,
    string $password): array
{
    $options = new \Couchbase\ClusterOptions();
    $options->credentials($username, $password);
    $cluster = new \Couchbase\Cluster($connectionString, $options);
    $bucket = $cluster->bucket("default");
    return [$bucket, $bucket->defaultCollection()];
}

$addresses = [
    "couchbase://172.17.0.2",
    "couchbase://172.17.0.3",
    "couchbase://172.17.0.4",
    "couchbase://172.17.0.5",
];

$globalCollection = null;
(function() use ($addresses, &$globalCollection) {
    $connectionString = $addresses[0];
    [$bucket, $collection] = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
    $globalCollection = $collection;
})();
fprintf(STDERR, "\n\n\n\n");
(function() use ($addresses, &$globalCollection) {
    $collection = $globalCollection;
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent (global 1), CAS: %s\n", $res->cas());
})();
if ($globalCollection != null) {
    $tmp = $globalCollection;
    $res = $tmp->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent (global 2), CAS: %s\n", $res->cas());
}

fprintf(STDERR, "\n\n\n\n");
(function() use ($addresses) {
    $connectionString = $addresses[1];
    [$bucket, $collection] = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
})();
fprintf(STDERR, "\n\n\n\n");
(function() use ($addresses) {
    $connectionString = $addresses[2];
    [$bucket, $collection] = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
})();
fprintf(STDERR, "\n\n\n\n");
(function() use ($addresses) {
    $connectionString = $addresses[3];
    [$bucket, $collection] = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
})();
fprintf(STDERR, "\n\n\n\n");

if ($globalCollection != null) {
    $res = $globalCollection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent (global 3): CAS: %s\n", $res->cas());
}
