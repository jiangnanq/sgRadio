#Swift Radio

Swift Radio is an open source radio station player with robust and professional features. This is a fully realized Radio App built entirely in Swift 2. 

- LastFM API Integration to automatically download Album Art
- Loads and parses metadata (track & artist information)
- Current artist & track displayed on Stations page
- Displays Artist, Track and Album art on Lock Screen
- Ability to update playlist from server or locally. (Update stations anytime without resubmitting to app store!)
- Custom views optimized for iPhone 4s, 5, 6 and 6+ for backwards compatibility
- Compiles with Xcode 7 & Swift 2.0
- Background audio performance
- Supports local or hosted station images
- "About" page with ability to send email & visit website
- Uses industry standard SwiftyJSON library for easy JSON manipulation
- Pull to Refresh Stations
- Volume slider adjusted by volume +/- buttons on phone

##Notes

- Volume slider does not show up in Xcode simulator, only in device. Hopefully @Apple fixes that soon. 
- For a production product, you may want to swap out the MPMoviePlayerController for a more robust streaming library/SDK (with stream stitching, interruption handling, etc).
- Uses Meng To's SPRING library for animation, making it easy experiment with different UI/UX animations

## Requirements

- iOS 8.0+ / Mac OS X 10.9+
- Xcode 7

##Integration

Includes full Xcode Project that will jumpstart development.

##Setup

The "SwiftRadio-Settings.swift" file contains some project settings to get you started.

##Stations 

Includes an example "stations.json" file. You may upload the JSON file to a server, so that you can update the stations in the app without resubmitting to the app store. The following fields are supported in the app:

- name
The name of the station as you want it displayed (e.g. "Sub Pop Radio")

- streamURL
The url of the actual stream

- imageURL
Station image url. Station images in demo are 350x206. Image can be local or hosted. Leave out the "http" to use a local image (You can use either: "station-subpop" or "http://myurl.com/images/station-subpop.jpg")

- desc
Short 2 or 3 world description of the station as you want it displayed (e.g. "Outlaw Country")

- longDesc: Long description of the station to be used on the "info screen". This is optional.
