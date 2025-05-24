# (Photos)
This is a simple app written to publish personal photos at [https://maltemueller.com/photos](https://maltemueller.com/photos). Feel free to explore, fork and implement for yourself!

## Usage
1. Run `npm install` to setup the environment.
2. Feel free to adapt site description, title or add further content. This is just a demo.
3. The app serves photos and their thumbnails from the `img` and `img/thumb` directories. It also creates an RSS feed available via `/feed.php`.
4. To publish new photos, copy them to the `src/input` directory and run `grunt make`. This will resize and web-optimize the photos, create thumbnails and copy them to the distribution directory. Obviously, you can also add a cronjob to run this grunt script on your server.