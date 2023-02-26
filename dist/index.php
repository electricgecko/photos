<?php
	include 'eml.php';
	// get most recent photo file name
	$photos = glob('img/*.{jpg,jpeg}', GLOB_BRACE);
	if ($photos) {
		array_multisort(array_map('filemtime', $photos),SORT_NUMERIC,SORT_DESC,$photos);
		$latestPhoto = $photos[0];
	}
?>
<!DOCTYPE html>
<head>
	<meta charset="UTF-8"/>
	<meta name="author" content="Malte Müller"/>
	<meta name="description" content="Personal photography website">
	<meta name="robots" content="index, follow">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
	<meta property="og:type" content="website" />
	<meta property="og:title" content="(Photos)">
	<meta property="og:site_name" content=(Photos)">
	<meta property="og:url" content="">
	<meta property="og:description" content="Personal photography website">
	<title>(Photos)</title>
	<link rel="stylesheet" href="m.css">
	<link type="application/atom+xml" rel="alternate" href="feed.php" title="(Photos)">
</head>

<body class="photos large">		
    <main class="large">
			<?php 
				$images = array();
				
				foreach ($photos as $photo) {
					$exif = exif_read_data($photo, 'IFD0');
					if ($exif) {
						$dateTaken = explode(' ', $exif['DateTimeOriginal']);
					} else {
						$dateTaken = false;
					}
					$images[$photo] = $dateTaken; 
				}
				
				arsort($images);

				$hash = 0;
				foreach ($images as $photo => $dateTaken): 
			?>
			<?php 
				$hash++;
				$size = getimagesize($photo);
			?>
			<figure class="invisible" id="photo<?= $hash ?>">
				<img data-highres="<?php echo $photo ?>" data-lowres="img/thumb/<?php echo substr($photo, 4) ?>" src="" loading="" width="<?php echo $size[0] ?>" height="<?php echo $size[1] ?>" alt="<?php echo str_replace(':', ' ',$dateTaken[0]).' '.$dateTaken[1] ?>"/>
				<template class="caption">
					<figcaption ><?php echo substr($photo, 4) ?><br/><?= ($dateTaken) ? str_replace(':', ' ',$dateTaken[0]).'&#8203; '.$dateTaken[1] : 'undated' ?>&#8203;</figcaption>
				</template>
			</figure>
			<?php endforeach ?>
			<aside>
				<span>photos to toggle view.</span>
			</aside>
    </main>
		<footer>
			<h2>Imprint</h2>
			<div class="col">
				<p>(Photos) does not deploy any cookies and does not collect user-specific data besides basic server logs, which are deleted regularly.
					I took all photos and retain their usage rights.</p>
				<p>This website is published by</p>
				<p>
					Publisher's address<br/>
					goes here<br/>
					00000 City<br/>
					Country
				</p>
			</div>
			<span>2022–</span>
		</footer>
		<script src="m.js" type="text/javascript"></script>
</body>