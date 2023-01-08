
import SwiftUI
import Toolbox
import Panorama

public enum ChartMarker {
    /// A point marker.
    case point(style: PointStyle, position: DataPoint)
    
    /// A line marker.
    case line(style: StrokeStyle, color: Color, start: DataPoint, end: DataPoint)
    
    /// A text label.
    case label(_ text: String,
               font: Font,
               foregroundColor: Color,
               backgroundColor: Color = .clear,
               position: DataPoint)
    
    /// A custom view.
    case view(_ view: AnyView, position: DataPoint)
}

extension ChartMarker {
    /// Whether this marker is contained within the given x-axis range.
    public func isLocatedInRange<E>(xrange: E) -> Bool
        where E: RangeExpression, E.Bound == Double
    {
        switch self {
        case .point(_, let position):
            return xrange.contains(position.x)
        case .line(_, _, let start, let end):
            return xrange.contains(start.x) && xrange.contains(end.x)
        case .label(_, _, _, _, let position):
            return xrange.contains(position.x)
        case .view(_, let position):
            return xrange.contains(position.x)
        }
    }
    
    /// Whether this marker is contained within the given y-axis range.
    public func isLocatedInRange<E>(yrange: E) -> Bool
        where E: RangeExpression, E.Bound == Double
    {
        switch self {
        case .point(_, let position):
            return yrange.contains(position.y)
        case .line(_, _, let start, let end):
            return yrange.contains(start.y) && yrange.contains(end.y)
        case .label(_, _, _, _, let position):
            return yrange.contains(position.y)
        case .view(_, let position):
            return yrange.contains(position.y)
        }
    }
}

extension ChartMarker {
    /// Get the position of a data point in the given rect.
    private static func project(_ pt: DataPoint, dataRect: CGRect, viewRect: CGRect) -> CGSize {
        let x = ((CGFloat(pt.x) - dataRect.minX) / dataRect.width) * viewRect.width
        let y = (1 - ((CGFloat(pt.y) - dataRect.minY) / dataRect.height)) * viewRect.height
        
        return .init(width: x - viewRect.width * 0.5, height: y - viewRect.height * 0.5)
    }
    
    /// Create the view for this marker.
    public func view(dataRect: CGRect, viewRect: CGRect) -> some View {
        ZStack {
            switch self {
            case .point(let style, let position):
                style.view.offset(Self.project(position, dataRect: dataRect, viewRect: viewRect))
            case .line(let style, let color, let start, let end):
                ShapeFromPath { rect in
                    let start = Self.project(start, dataRect: dataRect, viewRect: rect)
                    let end = Self.project(end, dataRect: dataRect, viewRect: rect)
                    
                    var path = Path()
                    path.move(to: .init(x: start.width + viewRect.width * 0.5, y: start.height + viewRect.height * 0.5))
                    path.addLine(to: .init(x: end.width + viewRect.width * 0.5, y: end.height + viewRect.height * 0.5))
                    
                    return path
                }
                .stroke(color, style: style)
                .frame(width: viewRect.width, height: viewRect.height)
            case .label(let text, let font, let foregroundColor, let backgroundColor, let position):
                Text(verbatim: text)
                    .font(font)
                    .foregroundColor(foregroundColor)
                    .background(backgroundColor)
                    .offset(Self.project(position, dataRect: dataRect, viewRect: viewRect))
            case .view(let view, let position):
                view.offset(Self.project(position, dataRect: dataRect, viewRect: viewRect))
            }
        }
    }
}
