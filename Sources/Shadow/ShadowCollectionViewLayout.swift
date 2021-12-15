//
//  ShadowCollectionViewLayout.swift
//
//  Created by Eugen Filipkov on 2/10/20.
//

import UIKit
import Astrolabe
import SwiftUI

public struct ShadowLayoutOptions {
	public struct ShadowOptions: Equatable {
		let backgroundColor: UIColor
		let shadowColor: UIColor
		let shadowRadius: CGFloat
		let shadowPath: CGPath?
		let shadowOpacity: Float
		let shadowOffset: CGSize

		// default values is ~ sketch shadow options
		public init(backgroundColor: UIColor = .white, shadowColor: UIColor = UIColor.black, shadowRadius: CGFloat = 4 * 0.5,
								shadowPath: CGPath? = nil, shadowOpacity: Float = 0.15, shadowOffset: CGSize = CGSize(width: 0, height: 2)) {
			self.backgroundColor = backgroundColor
			self.shadowColor = shadowColor
			self.shadowRadius = shadowRadius
			self.shadowPath = shadowPath
			self.shadowOpacity = shadowOpacity
			self.shadowOffset = shadowOffset
		}
	}
  
  public enum ShadowOptionsApplicability {
    case section
    case allCellsSeparately
    case specificCells(indexes: [Int])
    case excludingCells(indexes: [Int])
    case cellRanges(ranges: [Range<Int>])
  }
  
  public let section: Int
	public let shadowOptions: ShadowOptions?
  public let applicability: ShadowOptionsApplicability?

  public init(section: Int, shadowOptions: ShadowOptions? = .init(), applicability: ShadowOptionsApplicability = .section) {
    self.section = section
		self.shadowOptions = shadowOptions
    self.applicability = applicability
  }
}

open class ShadowDecorationViewLayoutAttributes: UICollectionViewLayoutAttributes {
	public var shadowOptions: ShadowLayoutOptions.ShadowOptions?

  open override func copy(with zone: NSZone? = nil) -> Any {
    let copy = super.copy(with: zone)
    guard let typedCopy = copy as? ShadowDecorationViewLayoutAttributes else {
      return copy
    }
    typedCopy.shadowOptions = shadowOptions
    return typedCopy
  }

  open override func isEqual(_ object: Any?) -> Bool {
    if super.isEqual(object) == false {
      return false
    }

    guard let typedObject = object as? ShadowDecorationViewLayoutAttributes else {
      return false
    }

    if typedObject.shadowOptions == nil && self.shadowOptions == nil {
      return true
    }

    return typedObject.shadowOptions == self.shadowOptions
  }
}

open class ShadowDecorationView: UICollectionReusableView, Decorationable {
	public static var zIndex: Int {
    return Int.max
  }
	public static var kind: String {
    return "shadow_decoration_view"
  }

	required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

	public override init(frame: CGRect) {
		super.init(frame: frame)
	}

	open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
		super.apply(layoutAttributes)
		if let layoutAttributes = layoutAttributes as? ShadowDecorationViewLayoutAttributes,
			let options = layoutAttributes.shadowOptions {
			backgroundColor = options.backgroundColor
			layer.shadowColor = options.shadowColor.cgColor
			layer.shadowRadius = options.shadowRadius
			layer.shadowPath = options.shadowPath
			layer.shadowOpacity = options.shadowOpacity
			layer.shadowOffset = options.shadowOffset
		}
	}
}

// swiftlint:disable line_length
open class ShadowCollectionViewLayout<DecorationView: UICollectionReusableView>: EmptyViewCollectionViewLayout where DecorationView: Decorationable {
	public var options: [ShadowLayoutOptions]? {
		didSet {
			invalidateLayout()
		}
	}

  public init(options: [ShadowLayoutOptions]? = nil) {
    self.options = options
    super.init()
  }

	public override init() {
		super.init()
	}

	required public init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func prepare() {
    super.prepare()

    register(DecorationView.self,
             forDecorationViewOfKind: DecorationView.kind)
  }
  
  open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let attributes = super.layoutAttributesForElements(in: rect)
    guard let attributes = attributes, let options = options else { return attributes }
    
    var allAttributes = [UICollectionViewLayoutAttributes]()
    let cellsAttributes = attributes.filter { attr in
      attr.representedElementCategory == .cell &&
      options.contains(where: { $0.section == attr.indexPath.section })
    }
    
    
    let sections = Dictionary(grouping: cellsAttributes, by: { $0.indexPath.section })
    sections.forEach { (sectionIndex, sectionCellsAttributes) in
      let sectionOptions = options.first(where: {$0.section == sectionIndex})
      switch sectionOptions?.applicability {
      case .section:
        if let entireSectionShadowAttributes =  shadowAttributesGroup(behindSourceAttributes: sectionCellsAttributes,
                                                                      shadowOptions: sectionOptions?.shadowOptions) {
          allAttributes.append(entireSectionShadowAttributes)
        }
      case .allCellsSeparately:
        sectionCellsAttributes.forEach { attribute in
          allAttributes.append(shadowAttributes(behindSourceAttributes: attribute,
                                                shadowOptions: sectionOptions?.shadowOptions))
        }
      case .specificCells(indexes: let cellsIndexes):
        cellsIndexes.forEach { index in
          if let attribute = sectionCellsAttributes.first(where: { $0.indexPath.row == index }) {
            allAttributes.append(shadowAttributes(behindSourceAttributes: attribute,
                                                  shadowOptions: sectionOptions?.shadowOptions))
          }
        }
      case .excludingCells(indexes: let cellsIndexes):
        sectionCellsAttributes.filter { !cellsIndexes.contains($0.indexPath.row)}.forEach { attribute in
          allAttributes.append(shadowAttributes(behindSourceAttributes: attribute,
                                                shadowOptions: sectionOptions?.shadowOptions))
        }
      case .cellRanges(ranges: let cellsRanges):
        cellsRanges.map { range in sectionCellsAttributes.filter { range.contains($0.indexPath.row)}}.forEach { attributesInRange in
          if let cellRangeAttributes = shadowAttributesGroup(behindSourceAttributes: attributesInRange, shadowOptions: sectionOptions?.shadowOptions) {
            allAttributes.append(cellRangeAttributes)
          }
        }
      default: break
      }
    }
    allAttributes.append(contentsOf: attributes)
    return allAttributes
  }
  
  private func shadowAttributes(behindSourceAttributes attributes: UICollectionViewLayoutAttributes, shadowOptions: ShadowLayoutOptions.ShadowOptions?, customSize: CGSize? = nil) -> ShadowDecorationViewLayoutAttributes {
    let decorationAttributes = ShadowDecorationViewLayoutAttributes(forDecorationViewOfKind: DecorationView.kind,
                                                                    with: attributes.indexPath)
    decorationAttributes.shadowOptions = shadowOptions
    decorationAttributes.frame = customSize.map({ CGRect(origin: attributes.frame.origin, size: $0) }) ?? attributes.frame
    decorationAttributes.zIndex = attributes.zIndex - 1
    return decorationAttributes
  }
  
  private func shadowAttributesGroup(behindSourceAttributes attributesGroup: [UICollectionViewLayoutAttributes], shadowOptions: ShadowLayoutOptions.ShadowOptions?) -> ShadowDecorationViewLayoutAttributes? {
    
    guard let attribute = attributesGroup.first,
          let cellWidth = attributesGroup
            .filter({ $0.frame.width != collectionView?.frame.width })
            .compactMap({ $0.frame.width }).max() ?? attributesGroup.first?.frame.width,
          let cellHeight = attributesGroup
            .filter({ $0.frame.height != collectionView?.frame.height })
            .compactMap({ $0.frame.height }).max() ?? attributesGroup.first?.frame.height else {
              return nil
            }
    let height = scrollDirection == .vertical ? attributesGroup.reduce(0) { $0 + $1.frame.height } : cellHeight
    let width = scrollDirection == .horizontal ? attributesGroup.reduce(0) { $0 + $1.frame.width } : cellWidth
    
    return shadowAttributes(behindSourceAttributes: attribute,
                            shadowOptions: shadowOptions,
                            customSize: CGSize(width: width, height: height))
  }
}
