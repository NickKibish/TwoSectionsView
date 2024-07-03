import SwiftUI

struct ResizableSheet: ViewModifier {
    var style: ResizableSheetStyle
    @ObservedObject private var manager: ModalPresenter
    
    init(manager: ModalPresenter, style: ResizableSheetStyle = .defaultStyle()) {
        self.manager = manager
        self.style = style
    }
    
    @State private var presenterContentRect: CGRect = .zero
    @State private var sheetContentRect: CGRect = .zero
    @State private var keyboardOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    
    private var drag: some Gesture {
        DragGesture(minimumDistance: 0.1, coordinateSpace: .local)
            .onChanged(onDragChanged)
            .onEnded(onDragEnded)
    }
    
    private var keyWindow: UIWindow? {
        if #available(iOS 15, *) {
            return UIApplication.shared.connectedScenes
                .filter { $0.activationState == .foregroundActive }
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: \.isKeyWindow)
        } else {
            return UIApplication.shared.windows.first(where: \.isKeyWindow)
        }
    }

    private var screenFrame: CGRect? {
        return keyWindow?.frame
    }

    private var safeAreaInsets: UIEdgeInsets? {
        return keyWindow?.safeAreaInsets
    }
    
    /// The point for the top anchor
    private var topAnchor: CGFloat {
        switch manager.presentationStyle {
        case .dismissed:
            return screenFrame?.height ?? CGFloat.greatestFiniteMagnitude
        case .full:
            return style.minTopDistance
        }
    }
    
    /// The he point for the bottom anchor
    private var bottomAnchor: CGFloat {
        return UIScreen.main.bounds.height + 5
    }
    
    /// The height of the handler bar section
    private var handlerSectionHeight: CGFloat {
        switch style.handlerBarStyle {
        case .solid: return 30
        case .none: return 0
        }
    }
    
    /// Calculates the sheets y position
    private var sheetPosition: CGFloat {
        let topInset = safeAreaInsets?.top ?? 20.0
        
        switch manager.presentationStyle {
        case .dismissed:
            return self.bottomAnchor - self.dragOffset
        case /*.half,*/ .full:
            let position = self.topAnchor + self.dragOffset - self.keyboardOffset
            
            if position < topInset {
                return topInset
            }
            
            return position
        }
    }
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if manager.presentationStyle != .dismissed {
                Group {
                    Rectangle()
                        .foregroundColor(style.coverColor)
                }
                .edgesIgnoringSafeArea(.vertical)
                .onTapGesture {
                    withAnimation(manager.defaultAnimation) {
                        self.manager.presentationStyle = .dismissed
                        self.manager.onDismiss?()
                    }
                }
            }
            Group {
                VStack(spacing: 0) {
                    switch style.handlerBarStyle {
                    case .solid(let handlerBarColor):
                        VStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: CGFloat(5.0) / 2.0)
                                .frame(width: 40, height: 5)
                                .foregroundColor(handlerBarColor)
                            Spacer()
                        }
                        .frame(height: handlerSectionHeight)
                    case .none: SwiftUI.EmptyView()
                    }
                    
                    VStack {
                        self.manager.content
                            .frame(height: max((screenFrame?.height ?? 500) - topAnchor - dragOffset - (safeAreaInsets?.bottom ?? 0) - 50, 300))
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: SheetPreferenceKey.self,
                                        value: [PreferenceData(bounds: proxy.frame(in: .global))]
                                    )
                                }
                            )
                    }
                    Spacer()
                }
                .onPreferenceChange(SheetPreferenceKey.self, perform: { (prefData) in
                    DispatchQueue.main.async {
                        withAnimation(manager.defaultAnimation) {
                            self.sheetContentRect = prefData.first?.bounds ?? .zero
                        }
                    }
                })
//#warning("set correct color")
                .frame(width: UIScreen.main.bounds.width)
                .background(Color(.bg))
                .cornerRadius(style.cornerRadius)
                .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.13), radius: 10.0)
                .offset(y: self.sheetPosition)
                .gesture(drag)
            }
            .edgesIgnoringSafeArea(.vertical)
        }
    }
}

extension ResizableSheet {
    
    private func onDragChanged(drag: DragGesture.Value) {
        let yOffset = drag.translation.height
        let threshold = CGFloat(-50)
        let stiffness = CGFloat(0.3)
        if yOffset > threshold {
            dragOffset = drag.translation.height
        } else if
            -yOffset + self.sheetContentRect.height <
                UIScreen.main.bounds.height + self.handlerSectionHeight
        {
            let distance = yOffset - threshold
            let translationHeight = threshold + (distance * stiffness)
            dragOffset = translationHeight
        }
    }
    
    private func setStateWithAnimation(_ state: ModalPresenter.SheetState) {
        DispatchQueue.main.async {
            withAnimation(manager.defaultAnimation) {
                dragOffset = 0
                self.manager.presentationStyle = state
                if case .dismissed = state {
                    self.manager.onDismiss?()
                }
            }
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
        
        switch manager.presentationStyle {
        case .full where verticalDirection < 0:
            setStateWithAnimation(.full)
        case .full where verticalDirection > 50:
            setStateWithAnimation(.dismissed)
        default:
            setStateWithAnimation(.full)
        }
    }
}

// MARK: - PreferenceKeys Handlers
extension ResizableSheet {
    struct SheetPreferenceKey: PreferenceKey {
        static var defaultValue: [PreferenceData] = []

        static func reduce(value: inout [PreferenceData], nextValue: () -> [PreferenceData]) {
            value.append(contentsOf: nextValue())
        }
    }

    struct PreferenceData: Equatable {
        let bounds: CGRect
    }
}

extension View {
    func modalPresenter(
        _ presenter: ModalPresenter,
        style: ResizableSheetStyle = ResizableSheetStyle.defaultStyle()) -> some View {
        self.modifier(
            ResizableSheet(manager: presenter, style: style)
        )
    }
}
