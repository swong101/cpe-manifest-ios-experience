# CPEExperience
An enhanced 'extras' experience around user owned content, built for iOS in accordance with a variety of [MovieLabs Specifications & Standards](http://movielabs.com/md/manifest/index.html). This reference library is built to allow implementators to accelerate their Cross-Platform Extras iOS implementation.

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate CPEExperience into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'CPEExperience', '~> 4.0'
end
```

Then, run the following command:

```bash
$ pod install
```

## Usage

Open `Example/CPEExperienceExampleWorkspace.xcworkspace` in Xcode to build and run the sample project, which contains a reference to the required calls and delegate hooks to integrate the Cross-Platform Extras Experience into your video platform.