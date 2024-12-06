<?php

require_once "./Couchbase/autoload.php";

function getCollection(
    string $connectionString,
    string $username,
    string $password): \Couchbase\Collection
{
    $options = new \Couchbase\ClusterOptions();
    $options->credentials($username, $password);
    $cluster = new \Couchbase\Cluster($connectionString, $options);
    return $cluster->bucket("default")->defaultCollection();
}

$globalCollection = null;
{
    $connectionString = "couchbase://192.168.106.128";
    $collection = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
    /* $globalCollection = $collection; */
}
fprintf(STDERR, "\n\n\n\n");
{
    $connectionString = "couchbase://192.168.106.129";
    $collection = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
}
fprintf(STDERR, "\n\n\n\n");
{
    $connectionString = "couchbase://192.168.106.130";
    $collection = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
}
fprintf(STDERR, "\n\n\n\n");
{
    $connectionString = "couchbase://192.168.106.131";
    $collection = getCollection($connectionString, "Administrator", "password");
    $res = $collection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent: %s, CAS: %s\n", $connectionString, $res->cas());
}
fprintf(STDERR, "\n\n\n\n");

if ($globalCollection != null) {
    $res = $globalCollection->upsert("foo", ["answer" => 42]);
    fprintf(STDERR, "UPSERT using persistent(global): %s, CAS: %s\n", $connectionString, $res->cas());
}
