import SwiftUI

struct ResizableSheetStyle {
    enum PartialSheetHanderBarStyle {
        case solid(Color)
        case none
    }
    
    var handlerBarStyle: PartialSheetHanderBarStyle
    var coverColor: Color = Color.black.opacity(0.3)
    
    var cornerRadius: CGFloat
    var minTopDistance: CGFloat
    
    init(accentColor: Color,
         cornerRadius: CGFloat,
         minTopDistance: CGFloat
    ) {
        self.init(
            handlerBarStyle: .solid(accentColor),
            cornerRadius: cornerRadius,
            minTopDistance: minTopDistance
        )
    }
    
    init(handlerBarStyle: PartialSheetHanderBarStyle,
         cornerRadius: CGFloat,
         minTopDistance: CGFloat
    ) {
        self.handlerBarStyle = handlerBarStyle
        self.cornerRadius = cornerRadius
        self.minTopDistance = minTopDistance
    }
}

extension ResizableSheetStyle {
    static func defaultStyle() -> ResizableSheetStyle {
        return ResizableSheetStyle(
            accentColor: Color(UIColor.systemGray2),
            cornerRadius: 10,
            minTopDistance: 110
        )
    }
}

