#!/usr/bin/php -f
<?php

/*
 * USAGE:
 * prog source-image destination-basename
 */

//debugging
error_reporting(E_ALL);
ini_set('display_errors', '1');

$chars = array("0", "3", "6", "9", "C", "F");
$colors = array();
foreach ($chars as &$a) {
  foreach ($chars as &$b) {
    foreach ($chars as &$c) {
      $colors[] = "0x" . $a . $a . $b . $b . $c . $c;
    }
  }
}
  
$source = imagecreatefromstring(file_get_contents($_SERVER['argv'][1]));
$width = imagesx($source);
$height = imagesy($source);
$filename = $_SERVER['argv'][2];

foreach ($colors as &$color) {
  $destination = imagecreatetruecolor($width, $height);
  imagefill($destination, 0, 0, $color);
  imagecopy($destination, $source, 0, 0, 0, 0, $width, $height);
  imagepng($destination, $filename . $color . ".png");
}

/* OLD VERSION
 
//usage php set_bg_color.php original.{png|jpg|...} color output.png
  $col = $_SERVER['argv'][2];
  $src_im = imagecreatefromstring( file_get_contents( $_SERVER['argv'][1] ) );
  $src_w = imagesx( $src_im );
  $src_h = imagesy( $src_im );
  $dst_im = imagecreatetruecolor( $src_w, $src_h );
  imagefill( $dst_im, 0, 0, $_SERVER['argv'][2] );
  imagecopy( $dst_im, $src_im, 0, 0, 0, 0, $src_w, $src_h );
  imagepng( $dst_im, $_SERVER['argv'][3] );

 */


?>
