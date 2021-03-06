Instagram Stories
=================

## Sample Screenshots
<a href="url"><img src="https://github.com/drawRect/Instagram_Stories/blob/Boomi/Optimisation/InstagramStories/Sample%20Screenshots/xrjpeg-1.jpg" width="240" height="480" title="Home Screen"></a> <a href="url"><img src="https://github.com/drawRect/Instagram_Stories/blob/Boomi/Optimisation/InstagramStories/Sample%20Screenshots/demo.gif" height="480" width="240"></a> <a href="url"><img src="https://github.com/drawRect/Instagram_Stories/blob/Boomi/Optimisation/InstagramStories/Sample%20Screenshots/xrjpeg-2.jpg" width="240" height="480" title="Story Snaps Screen"></a>

## Features
* Image Support
* Video Support
* Long Press pause and play
* Manual swipe between stories
* Left tap and Right tap gestures to switch between snaps and stories
* If there is no user interruption, it will automatically move to next snap or next story, once progress bar completes.

## Usage
* Open the project(InstagramStories) folder. You can find the Source folder inside.
* Copy the Source folder and paste it on your project.
* After paste and build, you will get error SDWebImage module not found.
* Add this line **pod 'SDWebImage', '~>3.7'** in your Podfile and do pod install.
* In your project use same IGStoryPreviewController.
* But don't change default code what we wrote inside IGStoryPreviewController. You can add code on top of that.
* Also don't change CollectionView's custom cell. Use the same IGStoryPreviewCell.
* Because all the functionalities are handled in the IGStoryPreviewCell only.
* If there is any issue or stuck somewhere on configuring Source folder on your project, please raise issues on github. We will reply back as soon as possible.

## We
* Hi! We are two people joined together and spent weekends and free time to make this repo as a example of how Instagram stories built in our assumption.
* Ranjith(https://github.com/ranmyfriend), Boominadha Prakash(https://github.com/boominadhaprakash)
* That's all you need to know.
#Spread the word

## License

All the code here is under MIT license. Which means you could do virtually anything with the code.
I will appreciate it very much if you keep an attribution where appropriate.

    The MIT License (MIT)
    
    Copyright (c) 2013 ranjit (ranjithkumar2010a@live.com)
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.