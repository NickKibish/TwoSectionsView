import SwiftUI

class ModalPresenter: ObservableObject {
    enum SheetState {
        case dismissed
//        case half,
        case full
    }
    
    @Published var presentationStyle: SheetState = .dismissed {
        didSet {
            if case .dismissed = presentationStyle {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    self?.content = AnyView(SwiftUI.EmptyView())
                }
            }
        }
    }
    
    @Published private(set) var content: AnyView
    var onDismiss: (() -> Void)?
    public var defaultAnimation: Animation = .interpolatingSpring(stiffness: 300.0, damping: 30.0, initialVelocity: 10.0)
    
    init(onDismiss: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.content = AnyView(SwiftUI.EmptyView())
    }
    
    func dismiss() {
        setStateWithAnimation(.dismissed)
    }
    
    func sheet<T: View>(style: SheetState = .full, @ViewBuilder content: @escaping () -> T) {
        guard case .dismissed = presentationStyle else {
            withAnimation(defaultAnimation) {
                updateSheet(content: content)
            }
            return
        }
        
        self.content = AnyView(content())
        DispatchQueue.main.async {
            withAnimation(self.defaultAnimation) {
                self.presentationStyle = style
            }
        }
    }
    
    func updateSheet<T: View>(style: SheetState? = nil, content: (() -> T)? = nil) {
        if let content = content {
            self.content = AnyView(content())
        }
        if let style {
            withAnimation(defaultAnimation) {
                self.presentationStyle = style
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setStateWithAnimation(_ state: SheetState) {
        DispatchQueue.main.async {
            withAnimation(self.defaultAnimation) {
                self.presentationStyle = state
                if case .dismissed = state {
                    self.onDismiss?()
                }
            }
        }
    }
    
    private func onDragEnded(drag: DragGesture.Value) {
        let verticalDirection = drag.predictedEndLocation.y - drag.location.y
        
        switch presentationStyle {
//        case .half where verticalDirection > 1:
//            setStateWithAnimation(.dismissed)
//        case .half where verticalDirection < 0:
//            setStateWithAnimation(.full)
        case .full where verticalDirection < 0:
            setStateWithAnimation(.full)
        case .full where verticalDirection > 1:
            setStateWithAnimation(.dismissed)
        default:
            break
        }
    }
}
