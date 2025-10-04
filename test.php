<?php
var_dump(confirm_raylib_compiled(), raylib_hello()); 
$p = new \raylib\Vector3(); 

$p->x = $p->x + 1;
// $p->z+= 1; // This crashes

var_dump($p);