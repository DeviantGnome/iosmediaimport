# iOS Media Import
<b>NOT QUITE DONE YET</b>
<br />
I'm still working on this, but hope to have a working version soon. Any and all suggestions are extremely welcome!

Bash script using ifuse to mount iOS device on Linux and import photos &amp; videos.

<b>Basic usage:</b>
<br />
Simply download this basic script (and optionally tifig), chmod +x both,
then run it.
<ul>
  <li>It will find (or create) the directory `.iosmediaimport/iosmountdir`.</li>
  <li>Using ifuse, it will mount the first detected connected iOS device.</li>
  <li>It recursively loops through the DCIM directory on the mounted device,
  finding and copying all found files to a directory in the current user's home directory.</li>
  <li>If tifig is located in the same directory as this script, it will convert HEIC files to JPG (otherwise they will be left as HEIC).</li>
  <li>If HandBrakeCLI is installed, it will convert MOV files to m4v (otherwise they will be left as MOV)</li>
</ul>

<b>Supported Platforms</b>

That bold text is a little misleading since at this point I'm not really "supporting"
anything. But, I want to tell you all what versions I'm running as I build this
so everyone knows what it should work on. If you've tried this on another version/flavor
of iOS or Linux (or anything else, for that matter), please let me know!

<ul>
    <li>iOS Device: iPhone X</li>
    <li>iOS Version: 12.1.4</li>
    <li>Machine: Linux Mint Cinnamon 19.1</li>
</ul>

<b>Limitations</b>

Too many to list! Hahaha...
<ul>
    <li>Uses the last modified date of the file to determine "age". Looking at
    utilizing exiftool to obtain the original create date.</li>
    <li>No way to set any options or a config file. That's in my mind, but is low priority since
    I've largely built this to suit my needs.</li>
</ul>
