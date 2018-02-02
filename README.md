# Sundial

UICollectionView layout for paging navigation with header, which contains titles and selection marker on it.

[![CI Status](http://img.shields.io/travis/sergeimikhan/Sundial.svg?style=flat)](https://travis-ci.org/sergeimikhan/Sundial)
[![Version](https://img.shields.io/cocoapods/v/Sundial.svg?style=flat)](http://cocoapods.org/pods/Sundial)
[![License](https://img.shields.io/cocoapods/l/Sundial.svg?style=flat)](http://cocoapods.org/pods/Sundial)
[![Platform](https://img.shields.io/cocoapods/p/Sundial.svg?style=flat)](http://cocoapods.org/pods/Sundial)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

Sundial is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Sundial'
```

# Usage

## 1. Getting started

Sundial layout integrated in the same with regular UICollectionViewLayout:

```swift
let collectionView = CollectionView<CollectionViewPagerSource>()

    collectionView.source.pager = self
    collectionView.collectionViewLayout = CollectionViewLayout(hostPagerSource: collectionView.source) { [weak self] in
      return ["Title1", "Title2", "Title3"]
    }
```

The only thing you need to do is to return array of titles and provide implementation of ```Selectable``` protocol. Pager sources of Astrolabe are conforms to this protocols out of box.

### 1.1 Settings

Sundial provides basic UI and behavior customization over Setting structure:

```swift
public struct Settings {
  public var stripHeight: CGFloat
  public var markerHeight: CGFloat
  public var itemMargin: CGFloat
  public var bottomStripSpacing: CGFloat
  public var backgroundColor: UIColor
  public var anchor: Anchor
  public var inset: UIEdgeInsets
  public var alignment: DecorationAlignment
  public var pagesOnScreen: Int
  public var jumpingPolicy: JumpingPolicy
 }
```

Cool feature of Sundial is 'jumping'. You can set jumping policy to skip pages when you are switching between pages which located far from each other and it looks like you are switching between neighbors:


Here is the list of possible anchors:

```swift
public enum Anchor {
  case content
  case centered
  case fillEqual
  case equal(size: CGFloat)
  case left(offset: CGFloat)
  case right(offset: CGFloat)
}
```

## 2. Collapsing Header 

## 0. Missing points 



## License

Sundial is available under the MIT license. See the LICENSE file for more info.
