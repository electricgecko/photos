<?php
  header ("Content-Type: text/xml");
  $photos = glob('img/*.{jpg,jpeg}', GLOB_BRACE);
  array_multisort(array_map('filemtime', $photos),SORT_NUMERIC,SORT_DESC,$photos);
  
  $images = array();
  $hash = 0;
  $url = '';
    
  foreach ($photos as $photo) {
    $exif = exif_read_data($photo, 'IFD0');
    if ($exif) {
      $dateTaken = explode(' ', $exif['DateTimeOriginal']);
      $date = date_create(str_replace(':', '-',$dateTaken[0]).' '.$dateTaken[1]);
    } else {
      $date = false;
    }
    $images[$photo] = $date; 
  }
    
  arsort($images);
  
 echo '<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">';
?>
<channel>
   <title>(Photos)</title>
   <description>Personal photography</description>
   <link>https://yourdomain.com/photos</link>
   <atom:link href="https://yourdomain.com/photos/feed.php" rel="self" type="application/rss+xml" />
   <?php foreach ($images as $photo => $dateTaken): ?>
   <item>
      <?php 
        $hash++; 
        $url = 'img/'.substr($photo, 4);
      ?>
      <title><?php echo substr($photo, 4) ?></title>
      <link>https://yourdomain.com/photos</link>
      <pubDate><?php echo $dateTaken->format('D, d M Y H:i:s Z') ?></pubDate>
      <description>
        <![CDATA[<a href="https://yourdomain.com/photos"><img src="<?php echo 'https://yourdomain.com/photos/img/thumb/'.substr($photo, 4) ?>" /></a>]]>
      </description>
   </item>
   <? endforeach ?>
</channel>
</rss>