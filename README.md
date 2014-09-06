MapUtil
=======

This repository contains custom map annotation and map overlay classes for use in iOS 6 and iOS 7 apps, as well as utility code to simplify the use of these classes. These are contained in the files:

* MapOverlay.[h/m] - Classes implementing MKAnnotation and MKOverlay protocols for all subclasses of MKShape: points, circles, polygons, and polylines, as well as polygons based on MKRegions.

* MapUtil.[h/m] - Utility functions to aid the use of these classes, as well as test code to illustrate their use.

My 'DebugUtil' public repository, also on GitHub, contains debug code to log information from use of these classes and other MapKit and CoreLocation code: 

* Debug_MapKit.[h/m] - code to write data of various CoreLocation and MapKit structs and classes to Xcode's debugger console.

In addition, this repository contains a simple app to demonstrate the use of this code. It is designed to work where this repository and the 'DebugUtil' repository have been cloned side-by-side in the same folder on the developer's Mac. 

To use the demo:

- Open MapDemo app project.

- Select iPad Simulator in top-left popup menu (or iOS device if an iPad is attached to your development Mac).

- For the simulator, open 'Edit Scheme' dialog ('Cmd-Shift-,'), select the 'Options' tab, and make a selection in the 'Default Location' popup menu under the 'Allow Location Simulation' checkbox (make sure checkbox is checked). Besides the standard locations Xcode offers, two .gpx files are included in this project to simulate the locations of Harvard Square in Cambridge MA and the White House in Washington DC.

- Build & run the app. App will display a world map.

- Tap 'Go' button at bottom of iPad screen. App will zoom in on selected location and display red, green, blue, cyan, and yellow annotations, red circle overlay, blue polygon overlay, green polyline overlay, and yellow region overlay (a rectangular polygon). The user's location (simulated or real) will have a red dot annotation with a "You Are Here!" callout displayed. Tapping on other dot annotations will display their callout titles and subtitles.

This code is distributed under the terms of the MIT license. See file "LICENSE" in this repository for details.

Copyright (c) 2014 Steve Caine.
@SteveCaine on github.com
