<?php


require_once 'Couchbase/autoload.php';

$e = new \Couchbase\Exception\TimeoutException("foo");
var_dump(get_class($e));
/* var_dump((new ReflectionClass('\\\\Couchbase\\\\Cluster'))->getFileName()); */
