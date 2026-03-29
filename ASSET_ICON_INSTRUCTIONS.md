Add Ispilo.png as app launcher icon

1) Copy the PNG provided into the project:
   - Copy your file from:
     C:\Users\Admin\Downloads\Ispilo.png
   - To this project location:
     c:\Users\Admin\ispilo\assets\images\Ispilo.png

2) Optional: create a padded/artboard-safe version
   - If the artwork touches the edges, create a version with transparent padding so the icon looks correct on all launchers.
   - Example quick PowerShell command (requires ImageMagick `magick` on PATH):

     # create a padded 1024x1024 icon with 20% padding around the original
     magick convert assets\images\Ispilo.png -resize 80% -gravity center -background none -extent 1024x1024 assets\images\Ispilo_padded.png

   - If you do not have ImageMagick you can use any image editor to create a 1024x1024 PNG with padding.

3) Update pubspec (already updated by this script)
   - The project contains a `flutter_icons` section configured to use `assets/images/Ispilo.png`.

4) Run icon generator (PowerShell)
   - From the project root (c:\Users\Admin\ispilo):

     flutter pub get
     flutter pub run flutter_launcher_icons:main

   - This will overwrite the Android and iOS launcher icons. Review results in:
     - android/app/src/main/res/mipmap-*/ic_launcher.png (and round icons)
     - ios/Runner/Assets.xcassets/AppIcon.appiconset/

5) Rebuild app
   - For Android:

       flutter clean; flutter pub get; flutter build apk --release

   - For iOS (macOS required):

       flutter clean; flutter pub get; flutter build ipa

Notes
- If you prefer a padded asset, set `flutter_icons.image_path` to `assets/images/Ispilo_padded.png` in `pubspec.yaml` before running the generator.
- I didn't run the generator here because this environment doesn't run external build tools; run the two commands above locally.
- If you want, I can also add a 1024x1024 padded asset into the repo automatically if you give me permission to use the downloaded PNG from your Downloads folder. Otherwise, copy the file into assets/images and run the commands above.
