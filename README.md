# LeanCloud Objective-C SDK

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
![platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-brightgreen.svg)

## Features
  * [x] Data Storage
  * [x] Object Query
  * [x] Cloud Engine
  * [x] File Storage
  * [x] Short Message Service
  * [x] Push Notification
  * [x] Search Query
  * [x] Analytics (iOS only)
  * [x] Instant Messaging (iOS, macOS only)

## Wanted Features
  * [ ] Your good idea we are looking forward to :)

## Communication
  * If you **have some advice**, open an issue.
  * If you **found a bug**, open an issue, or open a ticket in [LeanTicket][LeanTicket].
  * If you **want to contribute**, submit a pull request.

## Installation

In Podfile:

```
source 'git@github.com:hustlzp/Specs.git'
source 'https://github.com/CocoaPods/Specs.git'

pod 'AVOSCloud', '11.6.1.100'
pod 'AVOSCloudIM', '11.6.1.100'
```

## Fetch from upstream

```
git fetch upstream
git checkout master
git merge upstream/master
```

## Push to Private Repo

```
git tag xx.xx.xx.xx
git push --tags
pod repo push xcz-specs /var/www/objc-sdk/AVOSCloud.podspec --allow-warnings --verbose
pod repo push xcz-specs /var/www/objc-sdk/AVOSCloudIM.podspec --allow-warnings --verbose
```
