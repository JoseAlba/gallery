# Dartpad

Making the flutter demonstrations into runnable Dartpads.

## Overview

Gallery has a bunch of demo code. To help those who use the demos to learn we 
integrated the demos with Dartpad. This way users can interact with the demos 
and learn more.

This script grabs content from `lib/demos` and create a new folder in the home
directory called `dartpad`. The script adds the necessary pieces required to make 
each demo runnable. 

## How to generate code segments

From the home directory:
1. Make sure you have [grinder](https://pub.dev/packages/grinder) installed by
running `flutter pub get`.
2. Then run `flutter pub run grinder generate-dartpads` to generate runnable code
from the demos
