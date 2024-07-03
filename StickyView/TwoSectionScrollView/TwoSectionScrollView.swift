//
//  TwoSectionScrollView.swift
//  StickyView
//
//  Created by Nick Kibysh on 02/07/2024.
//

import SwiftUI
import UIKit

private protocol HostingLayoutDelegate: AnyObject {
    func topSectionHeight(for width: CGFloat) -> CGFloat
    func bottomSectionHeight(for width: CGFloat) -> CGFloat
}

private class TwoSectionLayout: UICollectionViewLayout, ObservableObject {
    private var firstCellAttributes: UICollectionViewLayoutAttributes?
    private var secondCellAttributes: UICollectionViewLayoutAttributes?

    weak var delegate: HostingLayoutDelegate?
    
    override func prepare() {
        super.prepare()
        
        guard let collectionView else { return }
        
        let cvWidth = collectionView.bounds.width
        let cvHeight = collectionView.bounds.height
        
        let firstCellSize = CGSize(width: cvWidth, height: delegate?.topSectionHeight(for: cvWidth) ?? .zero)
        let secondCellSize = CGSize(width: cvWidth, height: delegate?.bottomSectionHeight(for: cvWidth) ?? .zero)

        firstCellAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 0, section: 0))
        firstCellAttributes?.frame = CGRect(origin: .zero, size: firstCellSize)

        secondCellAttributes = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: 1, section: 0))
        let secondSectionPosition = max(cvHeight - secondCellSize.height, firstCellSize.height)
        secondCellAttributes?.frame = CGRect(origin: CGPoint(x: 0, y: secondSectionPosition), size: secondCellSize)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let firstRect = firstCellAttributes?.frame ?? .zero
        let secondRect = secondCellAttributes?.frame ?? .zero

        if rect.intersects(firstRect) && rect.intersects(secondRect) {
            return [firstCellAttributes!, secondCellAttributes!]
        } else if rect.intersects(firstRect) {
            return [firstCellAttributes!]
        } else if rect.intersects(secondRect) {
            return [secondCellAttributes!]
        } else {
            return nil
        }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch indexPath.item {
        case 0:
            return firstCellAttributes
        case 1:
            return secondCellAttributes
        default:
            return nil
        }
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        return CGSize(
            width: collectionView.bounds.width,
            height: max(collectionView.bounds.height, secondCellAttributes?.frame.maxY ?? .zero)
            )
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    override func invalidateLayout() {
        firstCellAttributes = nil
        secondCellAttributes = nil
        super.invalidateLayout()
    }
}


private class ContentCell<Content: View>: UICollectionViewCell {
    var hostController: UIHostingController<Content>! {
        didSet {
            contentView.addSubview(hostController.view)
            hostController.view.translatesAutoresizingMaskIntoConstraints = false
            hostController.view.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            hostController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            hostController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            hostController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        layoutAttributes.frame.size = size
        return layoutAttributes
    }
}

class ViewController<Top: View, Bottom: View>: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, HostingLayoutDelegate {
    let collectionView: UICollectionView
    private let layout = TwoSectionLayout()

    private let top: () -> Top
    private let bottom: () -> Bottom
    
    private var topHostingController: UIHostingController<Top>!
    private var bottomHostingController: UIHostingController<Bottom>!

    init(top: @escaping () -> Top, bottom: @escaping () -> Bottom) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        
        self.top = top
        self.bottom = bottom
        
        super.init(nibName: nil, bundle: nil)
        
        layout.delegate = self
        
        collectionView.dataSource = self
        collectionView.delegate = self

        collectionView.register(ContentCell<Top>.self, forCellWithReuseIdentifier: "top")
        collectionView.register(ContentCell<Bottom>.self, forCellWithReuseIdentifier: "bottom")

        self.topHostingController = UIHostingController(rootView: top())
        self.bottomHostingController = UIHostingController(rootView: bottom())

        self.addChild(topHostingController)
        self.addChild(bottomHostingController)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.item {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "top", for: indexPath) as! ContentCell<Top>
            cell.hostController = UIHostingController(rootView: top())
            return cell
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bottom", for: indexPath) as! ContentCell<Bottom>
            cell.hostController = UIHostingController(rootView: bottom())
            return cell
        default:
            fatalError()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        switch indexPath.section {
        case 0:
            return CGSize(width: width, height: topHostingController.view.intrinsicContentSize.height)
        case 1:
            return CGSize(width: width, height: bottomHostingController.view.intrinsicContentSize.height)
        default:
            fatalError()
        }
    }
    
    func topSectionHeight(for width: CGFloat) -> CGFloat {
        topHostingController.view.intrinsicContentSize.height
    }
    
    func bottomSectionHeight(for width: CGFloat) -> CGFloat {
        bottomHostingController.view.intrinsicContentSize.height
    }
}

struct TwoSectionScrollView<Top: View, Bottom: View>: UIViewControllerRepresentable {
    private let top: () -> Top
    private let bottom: () -> Bottom

    init(top: @escaping () -> Top, bottom: @escaping () -> Bottom) {
        self.top = top
        self.bottom = bottom
    }

    func makeUIViewController(context: Context) -> ViewController<Top, Bottom> {
        let vc = ViewController(top: top, bottom: bottom)
        return vc
    }

    func updateUIViewController(_ uiViewController: ViewController<Top, Bottom>, context: Context) {
        uiViewController.collectionView.collectionViewLayout.invalidateLayout()
    }
}
