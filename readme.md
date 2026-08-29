# (Photos)
This is a simple app written to publish personal photos at [https://maltemueller.com/photos](https://maltemueller.com/photos).

## Usage
1. Run `npm install` to setup the environment.
2. Feel free to adapt site description, title or add further content. This is just a demo.
3. The app serves photos and their thumbnails from the `img` and `img/thumb` directories. It also creates an RSS feed available via `/feed.php`.

## Preparing and uploading photos
This repo includes `photos.sh`, a shell script which helps optimizing and posting photos to a (photos) instance. It does so by:
- Consolidating file name extensions to `.jpg`
- Removing all EXIF data but `Date/Time Original`
- Creating thumbnails
- Compressing and web-optimizing photos
- Uploading the photos to a specified web server
You can run `photos.sh --help` for a full list of commands