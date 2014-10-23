MapUtil
=======

This repository contains custom map annotation and map overlay classes for use in apps running iOS 6 and higher, including iOS 8, as well as utility code to simplify the use of these classes. These are contained in the files:

* MapOverlay.[h/m] - Classes implementing MKAnnotation and MKOverlay protocols for all subclasses of MKShape: points, circles, polygons, and polylines, as well as polygons based on MKRegions.

* MapUtil.[h/m] - Utility functions to aid the use of these classes, as well as test code to illustrate their use.

* MapDemo.[h/m] - Example subclasses of the above to show how their implementation details can hidden for use in specific cases. One of these (MapUserTrail), to display a growing polyline overlay following a user's changing location over time, is not yet implemented. 

My 'DebugUtil' public repository, also on GitHub, contains debug code to log information from use of these classes and other MapKit and CoreLocation code: 

* Debug_MapKit.[h/m] - code to write data of various CoreLocation and MapKit structs and classes to Xcode's debugger console.

In addition, this repository contains a simple app to demonstrate the use of this code. It is designed to work where this repository and the 'DebugUtil' repository have been cloned side-by-side in the same folder on the developer's Mac. To simplify this, my GitHub repository 'unix-scripts' includes a script named 'cloneall' to automate the download of all my public repositories to a single Mac folder; the script contains detailed instructions on its use. 

To use the demo:

- Open MapDemo app project.

- Select iPad Simulator in top-left popup menu (or iOS device if an iPad is attached to your development Mac). 

- For the simulator, there are two ways to get location updates:

	1. In iOS Simulator, under the 'Debug' menu, click on the 'Locations' item and select 'Apple' to get location updates for Apple Inc. HQ in Cupertino CA. (Or select one of the items for simulated location updates from a moving device. This app will just use the first update.)

	2. In Xcode, open the  'Edit Scheme' dialog ('Cmd-Shift-,'), select the 'Options' tab, and make a selection in the 'Default Location' popup menu under the 'Allow Location Simulation' checkbox (make sure checkbox is checked). Besides the standard locations Xcode offers, two .gpx files are included in this project to simulate the locations of Harvard Square in Cambridge MA and the White House in Washington DC.

- A device will use its built-in location hardware and software. 

- Build & run the app. App will display a map with your current (simulated?) location marked with a "You Are Here!" annotation that also displays its latitude and longitude.

- Tapping the 'Demo 1' button at bottom of iPad screen will add a random collection of red, green, blue, cyan, and yellow annotations, a red circle overlay, a blue polygon overlay, a green polyline overlay, and a yellow region overlay (a rectangular polygon). Tapping on any of these dot annotations will display their callout titles and subtitles. Tapping again on 'Demo 1' will add another collection of annotations and overlays ... and again, and again. 

- Tapping the 'Demo 2' button will add a green polygon annotation based on the map's current region (scaled down by 5%), as well as a red circle annotation based on the estimated accuracy of the location determined by the iPad. (This may be so small, especially on the Simulator, that you have to zoom in on the map to see it.) It will also disable this button until the 'Clear' button is tapped. 

- Tapping the 'Clear' button will remove all but the "You Are Here!" annotation. 

This code is distributed under the terms of the MIT license. See file "LICENSE" in this repository for details.

Copyright (c) 2014 Steve Caine.<br>
@SteveCaine on github.com
