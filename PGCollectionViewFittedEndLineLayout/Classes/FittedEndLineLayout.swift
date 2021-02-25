//
//  CollectionViewFittedEndLineLayout.swift
//  PGCollectionViewFittedEndLineLayout
//
//  Created by ipagong on 2021/02/24.
//

import UIKit

public struct PageAttributesAnimator: LayoutAttributesAnimator {
    /// The max scale that would be applied to the current cell. 0 means no scale. 0.2 by default.
    public var scaleRate: CGFloat
    
    public init(scaleRate: CGFloat = 0.2) {
        self.scaleRate = scaleRate
    }
    
    public func animate(collectionView: UICollectionView, attributes: AnimatedCollectionViewLayoutAttributes) {
        let position = attributes.middleOffset
        let contentOffset = collectionView.contentOffset
        let itemOrigin = attributes.frame.origin
        let scaleFactor = scaleRate * min(position, 0) + 1.0
        var transform = CGAffineTransform(scaleX: scaleFactor, y: scaleFactor)
        
        transform = transform.concatenating(CGAffineTransform(translationX: position < 0 ? contentOffset.x - itemOrigin.x : 0, y: 0))
        
        attributes.transform = transform
        attributes.zIndex = attributes.indexPath.row
    }
}

public protocol LayoutAttributesAnimator {
    func animate(collectionView: UICollectionView, attributes: AnimatedCollectionViewLayoutAttributes)
}

public protocol FittedEndLineLayoutDelegate: class {
    // MARK: - Required
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, sizeForItemAt indexPath: IndexPath) -> CGSize

    // MARK: - Optional
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, numberOfRowInSection: Int) -> Int
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, minimumInteritemSpacingFor section: Int) -> CGFloat?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, minimumLineSpacingFor section: Int) -> CGFloat?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, sectionInsetFor section: Int) -> UIEdgeInsets?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, headerHeightFor section: Int) -> CGFloat?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, headerInsetFor section: Int) -> UIEdgeInsets?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, footerHeightFor section: Int) -> CGFloat?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, footerInsetFor section: Int) -> UIEdgeInsets?
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, estimatedSizeForItemAt indexPath: IndexPath) -> CGSize?
}

extension FittedEndLineLayoutDelegate {
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, numberOfRowInSection: Int) -> Int { return 2 }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, minimumInteritemSpacingFor section: Int) -> CGFloat? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, minimumLineSpacingFor section: Int) -> CGFloat? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, sectionInsetFor section: Int) -> UIEdgeInsets? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, headerHeightFor section: Int) -> CGFloat? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, headerInsetFor section: Int) -> UIEdgeInsets? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, footerHeightFor section: Int) -> CGFloat? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, footerInsetFor section: Int) -> UIEdgeInsets? { return nil }
    public func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, estimatedSizeForItemAt indexPath: IndexPath) -> CGSize? { return nil }
}

public class FittedEndLineLayout: UICollectionViewLayout {
    public struct Const {
        static let minimumLineSpacing: CGFloat = 2.0
        static let minimumInteritemSpacing: CGFloat = 2.0
        static let sectionInset: UIEdgeInsets = .zero
        static let headerWidth: CGFloat = 0.0
        static let headerInset: UIEdgeInsets = .zero
        static let footerWidth: CGFloat = 0.0
        static let footerInset: UIEdgeInsets = .zero
        static let estimatedItemSize: CGSize = CGSize(width: 300.0, height: 300.0)
    }

    public var minimumLineSpacing: CGFloat = Const.minimumLineSpacing {
        didSet { invalidateLayoutIfChanged(oldValue, minimumLineSpacing) }
    }

    public var minimumInteritemSpacing: CGFloat = Const.minimumInteritemSpacing {
        didSet { invalidateLayoutIfChanged(oldValue, minimumInteritemSpacing) }
    }

    public var sectionInset: UIEdgeInsets = Const.sectionInset {
        didSet { invalidateLayoutIfChanged(oldValue, sectionInset) }
    }

    public var headerWidth: CGFloat = Const.headerWidth {
        didSet { invalidateLayoutIfChanged(oldValue, headerWidth) }
    }

    public var headerInset: UIEdgeInsets = Const.headerInset {
        didSet { invalidateLayoutIfChanged(oldValue, headerInset) }
    }

    public var footerWidth: CGFloat = Const.footerWidth {
        didSet { invalidateLayoutIfChanged(oldValue, footerWidth) }
    }

    public var footerInset: UIEdgeInsets = Const.footerInset {
        didSet { invalidateLayoutIfChanged(oldValue, footerInset) }
    }

    public var estimatedItemSize: CGSize = Const.estimatedItemSize {
        didSet { invalidateLayoutIfChanged(oldValue, estimatedItemSize) }
    }
    
    private lazy var headersAttribute = [Int: UICollectionViewLayoutAttributes]()
    private lazy var footersAttribute = [Int: UICollectionViewLayoutAttributes]()
    private lazy var rowWidths = [[CGFloat]]()
    private lazy var allItemAttributes = [UICollectionViewLayoutAttributes]()
    private lazy var sectionItemAttributes = [[UICollectionViewLayoutAttributes]]()
    private lazy var cachedItemSizes = [IndexPath: CGSize]()

    /// The animator that would actually handle the transitions.
    public var animator: LayoutAttributesAnimator? = PageAttributesAnimator()
    
    public override class var layoutAttributesClass: AnyClass { AnimatedCollectionViewLayoutAttributes.self }
    
    public weak var delegate: FittedEndLineLayoutDelegate?

    public override func prepare() {
        super.prepare()
        cleaunup()

        guard let collectionView = collectionView else { return }
        guard let delegate = delegate else { return }

        let numberOfSections = collectionView.numberOfSections
        if numberOfSections == 0 { return }

        for section in (0..<numberOfSections) {
            let rowCount = delegate.collectionView(collectionView, layout: self, numberOfRowInSection: section)
            rowWidths.append(Array(repeating: 0.0, count: rowCount))
        }

        var position: CGFloat = 0.0
        
        for section in (0..<numberOfSections) {
            layoutHeader(position: &position, collectionView: collectionView, delegate: delegate, section: section)
            layoutItems(position: position, collectionView: collectionView, delegate: delegate, section: section)
            layoutFooter(position: &position, collectionView: collectionView, delegate: delegate, section: section)
        }
    }

    public override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView, collectionView.numberOfSections > 0  else { return .zero }
        
        return CGSize(width: rowWidths.last?.max() ?? 0, height: collectionView.bounds.height)
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        if indexPath.section >= sectionItemAttributes.count { return nil }
        
        if indexPath.item >= sectionItemAttributes[indexPath.section].count { return nil }
        
        return sectionItemAttributes[indexPath.section][indexPath.item]
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allItemAttributes.filter { rect.intersects($0.frame) }
            .flatMap { $0.copy() as? AnimatedCollectionViewLayoutAttributes }.map { self.transformLayoutAttributes($0) }
    }

    public override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return newBounds.height != (collectionView?.bounds ?? .zero).height
    }

    public override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
        return false
    }

    public override func invalidationContext(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forPreferredLayoutAttributes: preferredAttributes, withOriginalAttributes: originalAttributes)

        guard let _ = collectionView else { return context }

        let oldContentSize = self.collectionViewContentSize
        cachedItemSizes[originalAttributes.indexPath] = preferredAttributes.size
        let newContentSize = self.collectionViewContentSize
        context.contentSizeAdjustment = CGSize(width: newContentSize.width - oldContentSize.width, height: 0)

        _ = context.invalidateEverything
        return context
    }
}

extension FittedEndLineLayout {

    private func cleaunup() {
        headersAttribute.removeAll()
        footersAttribute.removeAll()
        rowWidths.removeAll()
        allItemAttributes.removeAll()
        sectionItemAttributes.removeAll()
    }

    private func invalidateLayoutIfChanged<T: Equatable>(_ old: T, _ new: T) {
        if old != new { invalidateLayout() }
    }

    private func layoutHeader(position: inout CGFloat, collectionView: UICollectionView,  delegate: FittedEndLineLayoutDelegate, section: Int) {
        let rowCount = delegate.collectionView(collectionView, layout: self, numberOfRowInSection: section)
        let headerWidth = self.headerWidth(for: section)
        let headerInset = self.headerInset(for: section)

        position += headerInset.top

        if headerWidth > 0 {
            let attributes = AnimatedCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, with: [section, 0])
            attributes.frame = CGRect(
                x: position,
                y: headerInset.top,
                width: headerWidth,
                height: collectionView.bounds.height - (headerInset.top + headerInset.bottom)
            )
            headersAttribute[section] = attributes
            allItemAttributes.append(attributes)

            position = attributes.frame.maxY + headerInset.bottom
        }

        position += sectionInset(for: section).top
        rowWidths[section] = Array(repeating: position, count: rowCount)
    }

    private func pickRow(itemIndex: Int,
                         delegate: FittedEndLineLayoutDelegate,
                         section: Int) -> Int {
        var minIndex: Int = 0
        var minValue = CGFloat.greatestFiniteMagnitude
        
        rowWidths[section].enumerated().forEach { (index, element) in
            if element < minValue {
                minIndex = index
                minValue = element
            }
        }
        return minIndex
    }

    private func layoutItems(position: CGFloat, collectionView: UICollectionView, delegate: FittedEndLineLayoutDelegate, section: Int) {
        let sectionInset = self.sectionInset(for: section)
        let minimumInteritemSpacing = self.minimumInteritemSpacing(for: section)
        let minimumLineSpacing = self.minimumInteritemSpacing(for: section)

        let rowCount = delegate.collectionView(collectionView, layout: self, numberOfRowInSection: section)
        let itemCount = collectionView.numberOfItems(inSection: section)
        let _height = collectionView.bounds.height - (sectionInset.top + sectionInset.bottom)
        let _itemHeight = floor((_height - CGFloat(rowCount - 1) * minimumLineSpacing) / CGFloat(rowCount))
        let _paddingTop = _itemHeight + minimumLineSpacing

        var itemAttributes: [UICollectionViewLayoutAttributes] = []

        for index in (0..<itemCount) {
            let indexPath: IndexPath = [section, index]
            let columnIndex = pickRow(itemIndex: index, delegate: delegate, section: section)

            let itemWidth: CGFloat
            let itemSize = delegate.collectionView(collectionView, layout: self, sizeForItemAt: indexPath)

            cachedItemSizes[indexPath] = itemSize
            itemWidth = itemSize.isValid == true ? floor(itemSize.width * _itemHeight / itemSize.height) : 0.0

            let offsetX: CGFloat = rowWidths[section][columnIndex]

            let attributes = AnimatedCollectionViewLayoutAttributes(forCellWith: indexPath)
            
            attributes.frame = CGRect(
                x: offsetX,
                y: sectionInset.top + _paddingTop * CGFloat(columnIndex),
                width: itemWidth,
                height: _itemHeight
            )
            
            itemAttributes.append(attributes)
            rowWidths[section][columnIndex] = attributes.frame.maxX + minimumInteritemSpacing
        }
        
        allItemAttributes.append(contentsOf: itemAttributes)
        sectionItemAttributes.append(itemAttributes)
    }

    private func layoutFooter(position: inout CGFloat, collectionView: UICollectionView, delegate: FittedEndLineLayoutDelegate, section: Int) {
        let sectionInset = self.sectionInset(for: section)
        let minimumInteritemSpacing = self.minimumInteritemSpacing(for: section)
        let rowCount = delegate.collectionView(collectionView, layout: self, numberOfRowInSection: section)
        let longestRowIndex = rowWidths[section].enumerated().sorted { $0.element > $1.element }.first?.offset ?? 0

        if rowWidths[section].count > 0 {
            position = rowWidths[section][longestRowIndex] - minimumInteritemSpacing + sectionInset.bottom
        } else {
            position = 0.0
        }
        let footerWidth = self.footerWidth(for: section)
        let footerInset = self.footerInset(for: section)
        
        position += footerInset.top

        if footerWidth > 0.0 {
            let attributes = AnimatedCollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, with: [section, 0])
            attributes.frame = CGRect(x: position,
                                      y: footerInset.top,
                                      width: footerWidth,
                                      height: collectionView.bounds.height - (footerInset.top + footerInset.bottom) )
            footersAttribute[section] = attributes
            allItemAttributes.append(attributes)
            position = attributes.frame.maxY + footerInset.bottom
        }
        rowWidths[section] = Array(repeating: position, count: rowCount)
    }
    
    private func transformLayoutAttributes(_ attributes: AnimatedCollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        guard let collectionView = self.collectionView else { return attributes }
        
        let a = attributes
        
        /**
         The position for each cell is defined as the ratio of the distance between
         the center of the cell and the center of the collectionView and the collectionView width/height
         depending on the scroll direction. It can be negative if the cell is, for instance,
         on the left of the screen if you're scrolling horizontally.
         */
        
        let distance: CGFloat
        let itemOffset: CGFloat
        
        distance = collectionView.frame.width
        itemOffset = a.center.x - collectionView.contentOffset.x
        a.startOffset = (a.frame.origin.x - collectionView.contentOffset.x) / a.frame.width
        a.endOffset = (a.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / a.frame.width
        
        a.middleOffset = itemOffset / distance - 0.5
        
        // Cache the contentView since we're going to use it a lot.
        if a.contentView == nil,
            let c = collectionView.cellForItem(at: attributes.indexPath)?.contentView {
            a.contentView = c
        }
        
        animator?.animate(collectionView: collectionView, attributes: a)
        
        return a
    }
}

extension FittedEndLineLayout {

    private func minimumInteritemSpacing(for section: Int) -> CGFloat {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, minimumInteritemSpacingFor: section) } ?? minimumInteritemSpacing
    }

    private func minimumLineSpacing(for section: Int) -> CGFloat {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, minimumLineSpacingFor: section) } ?? minimumLineSpacing
    }

    private func sectionInset(for section: Int) -> UIEdgeInsets {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, sectionInsetFor: section) } ?? sectionInset
    }

    private func headerWidth(for section: Int) -> CGFloat {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, headerHeightFor: section) } ?? headerWidth
    }

    private func headerInset(for section: Int) -> UIEdgeInsets {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, headerInsetFor: section) } ?? headerInset
    }

    private func footerWidth(for section: Int) -> CGFloat {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, footerHeightFor: section) } ?? footerWidth
    }

    private func footerInset(for section: Int) -> UIEdgeInsets {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, footerInsetFor: section) } ?? footerInset
    }

    private func estimatedSizeForItemAt(_ indexPath: IndexPath) -> CGSize {
        return collectionView.flatMap { delegate?.collectionView($0, layout: self, estimatedSizeForItemAt: indexPath) } ?? estimatedItemSize
    }
}

extension CGSize {
    fileprivate var isValid: Bool { self.height > 0 && self.width > 0 }
}

extension UICollectionViewCell {
    fileprivate var fitIntrinsicContentSize: CGSize? {
        self.sizeToFit()
        return self.intrinsicContentSize
    }
}


/// A custom layout attributes that contains extra information.
open class AnimatedCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    public var contentView: UIView?
    
    /// The ratio of the distance between the start of the cell and the start of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the start of the cell aligns the start of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var startOffset: CGFloat = 0
    
    /// The ratio of the distance between the center of the cell and the center of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the center of the cell aligns the center of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var middleOffset: CGFloat = 0
    
    /// The ratio of the distance between the **start** of the cell and the end of the collectionView and the height/width of the cell depending on the scrollDirection. It's 0 when the **start** of the cell aligns the end of the collectionView. It gets positive when the cell moves towards the scrolling direction (right/down) while getting negative when moves opposite.
    public var endOffset: CGFloat = 0
    
    open override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! AnimatedCollectionViewLayoutAttributes
        copy.contentView = contentView
        copy.startOffset = startOffset
        copy.middleOffset = middleOffset
        copy.endOffset = endOffset
        return copy
    }
    
    open override func isEqual(_ object: Any?) -> Bool {
        guard let o = object as? AnimatedCollectionViewLayoutAttributes else { return false }
        
        return super.isEqual(o)
            && o.contentView == contentView
            && o.startOffset == startOffset
            && o.middleOffset == middleOffset
            && o.endOffset == endOffset
    }
}
