# LearningStudio Mobile Dashboard

## App Overview

This sample application aims to highlight what is possible with the LearningStudio RESTful APIs from a mobile device. It does not use any other web or data services.

The app delivers a snapshot of relevant info to a student including:

  * [Upcoming Events](http://developer.pearson.com/schedules/upcoming-events) (Due)
  * [What's Happening](http://developer.pearson.com/activity-feed/whats-happening-feed-version-2) (Done)
  * [Announcements](http://developer.pearson.com/announcements/announcements-course-users-readunread-status) (News) 
  * [Grades to Date](http://developer.pearson.com/grades-learningstudio/grade-date-student) (Grades)

Each of the above is displayed on a tab after successful login. The amount of presented information is based on the user preferences. These preferences, course visibility controls, manual data refresh, and logout are on the settings tab. The user's course data continues to be monitored for updates after the application goes into the background. New activity is indicated with a badge on the application icon. Opening the app while a badge is present will indicate where and how much new activity has occurred with a numbered badge on the applicable tabs.

### Scope of Functionality

This sample app is intended for demonstration purposes. It has been tested with minimal data in a controlled environment. Issues may exist if those circumstances change. There are also many features that could be added to make it more useful. You are encouraged to contribute back fixes or features with a pull request. 

## Prerequisites

### Build Environment 

  * XCode 6.3.1 or greater is required.
  * Swift 1.2 is required

### Server Environment

  * None.

## Installation

### Application Configuration

#### LearningStudio API and Environment Setup

  1. [Get Application Credentials and Sandbox](http://developer.pearson.com/learningstudio/get-learningstudio-api-key-and-sandbox)

#### Application Setup

  1. Configure Application and Environment Identifier

**LSDashboard/LearningStudio.plist**

~~~~~~~~~~~~~~~~~~~~~
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>app_id</key>
	<string>{Application Id}</string>
	<key>client_string</key>
	<string>{Client/Environment Identifier}</string>
</dict>
</plist>
~~~~~~~~~~~~~~~~~~~~~

Note: The application only uses OAuth2 with the user's credentials, so the secret required for other authentication methods is not needed.

### Deployment

The application can be run through the simulator from XCode. It's a universal app, so any device should work. We've tested with iPhone 6 and iPad Retina.

Note: Background refresh was not working in the simulator from XCode 6.3.1, but this feature works on a device. 

## License

Copyright (c) 2015 Pearson Education, Inc.
Created by Pearson Developer Services

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Portions of this work are reproduced from work created and 
shared by Apple and used according to the terms described in 
the License. Apple is not otherwise affiliated with the 
development of this work.
