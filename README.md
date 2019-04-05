# iOS Media Import
<b>NOT QUITE DONE YET</b>
<br />
I'm still working on this, but hope to have a working version soon. Any and all suggestions are extremely welcome!

Bash script using ifuse to mount iOS device on Linux and import photos &amp; videos.

<b>Basic usage:</b>
<br />
Simply download this basic script, then run it with sudo priveleges.
<ul>
  <li>It will find (or create) the directory `.iosmediaimport/iosmountdir`.
  <li>Using ifuse, it will mount the first detected connected iOS device.
  <li>It recursively loops through the DCIM directory on the mounted device, finding and copying all found files to a directory in the current user's home directory.
  <li>If tifig is installed, it will convert HEIC files to JPG (otherwise they will be left as HEIC)
  <li>If HandBrakeCLI is installed, it will convert MOV files to m4v (otherwise they will be left as MOV)
</ul>
