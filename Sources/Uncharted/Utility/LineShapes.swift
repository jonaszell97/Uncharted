
import SwiftUI
import Toolbox
import Panorama

internal struct AnyLineShape: Shape {
    /// The points of the line.
    var points: [DataPoint]
    
    /// The animation progress.
    var animationProgress: Double
    var animationOffsets: [Double]
    
    /// The type of line.
    let lineType: LineStyle.LineType
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The lower bound of the y-axis.
    var yBoundLower: Double
    
    /// The upper bound of the y-axis.
    var yBoundUpper: Double
    
    /// Whether or not the path should be filled.
    let isFilled: Bool
    
    /// The animation progress.
    var animatableData: AnimatablePair<Double, AnimatableVector>
    {
        get {
            .init(animationProgress, .init(values: animationOffsets))
        }
        set {
            animationProgress = newValue.first
            animationOffsets = newValue.second.values
        }
    }
    
    /// Memberwise initializer.
    internal init(points: [DataPoint],
                  lineType: LineStyle.LineType,
                  xAxisParams: ComputedChartAxisData,
                  yBoundLower: Double,
                  yBoundUpper: Double,
                  isFilled: Bool,
                  animationProgress: Double,
                  animationOffsets: [Double]) {
        self.points = points
        self.lineType = lineType
        self.xAxisParams = xAxisParams
        self.yBoundLower = yBoundLower
        self.yBoundUpper = yBoundUpper
        self.isFilled = isFilled
        self.animationProgress = animationProgress
        self.animationOffsets = animationOffsets
    }
    
    private func getPointPosition(_ pt: DataPoint, ptIndex: Int, in rect: CGRect) -> CGPoint {
        let x = (pt.x - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
        let y = (((pt.y - yBoundLower) / (yBoundUpper - yBoundLower)) * animationProgress) + animationOffsets[ptIndex]
        
        return .init(x: x * rect.width, y: (1 - y) * rect.height)
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        var firstPoint = CGPoint()
        
        for i in 0..<points.count {
            let pt = getPointPosition(self.points[i], ptIndex: i, in: rect)
            
            if i == 0 {
                firstPoint = pt
                path.move(to: pt)
            }
            
            switch lineType {
            case .straight:
                if i == 0 {
                    break
                }
                
                path.addLine(to: pt)
            case .curved:
                if i == 0 {
                    break
                }
                
                let previousPoint = getPointPosition(self.points[i - 1], ptIndex: i - 1, in: rect)
                let controlPt1 = CGPoint(x: previousPoint.x + (pt.x - previousPoint.x) * 0.5, y: previousPoint.y)
                let controlPt2 = CGPoint(x: pt.x - (pt.x - previousPoint.x) * 0.5, y: pt.y)
                
                path.addCurve(to: pt, control1: controlPt1, control2: controlPt2)
            case .stepped:
                if i < points.count - 1 {
                    let nextPt = getPointPosition(self.points[i + 1], ptIndex: i + 1, in: rect)
                    let dir = nextPt - pt
                    path.addLine(to: .init(x: pt.x + dir.x * 0.5, y: pt.y))
                    path.addLine(to: .init(x: pt.x + dir.x * 0.5, y: nextPt.y))
                }
                else {
                    path.addLine(to: pt)
                }
            }
        }
        
        if isFilled {
            path.addLine(to: .init(x: path.currentPoint!.x, y: rect.height))
            path.addLine(to: .init(x: firstPoint.x, y: rect.height))
            path.closeSubpath()
        }
        
        return path
    }
}

internal struct AnyPointsShape: Shape {
    /// The points of the line.
    var points: [DataPoint]
    
    /// The point shape.
    let pointShape: PointStyle.PointShape
    
    /// The point size.
    let pointSize: CGFloat
    
    /// The animation progress.
    var animationProgress: Double
    var animationOffsets: [Double]
    
    /// The x-axis configuration.
    let xAxisParams: ComputedChartAxisData
    
    /// The lower bound of the y-axis.
    var yBoundLower: Double
    
    /// The upper bound of the y-axis.
    var yBoundUpper: Double
    
    /// The animation progress.
    var animatableData: AnimatablePair<Double, AnimatableVector>
    {
        get {
            .init(animationProgress, .init(values: animationOffsets))
        }
        set {
            animationProgress = newValue.first
            animationOffsets = newValue.second.values
        }
    }
    
    /// Memberwise initializer.
    internal init(points: [DataPoint],
                  pointShape: PointStyle.PointShape,
                  pointSize: CGFloat,
                  xAxisParams: ComputedChartAxisData,
                  yBoundLower: Double,
                  yBoundUpper: Double,
                  animationProgress: Double,
                  animationOffsets: [Double]) {
        self.points = points
        self.pointShape = pointShape
        self.pointSize = pointSize
        self.xAxisParams = xAxisParams
        self.yBoundLower = yBoundLower
        self.yBoundUpper = yBoundUpper
        self.animationProgress = animationProgress
        self.animationOffsets = animationOffsets
    }
    
    private func getPointPosition(_ pt: DataPoint, ptIndex: Int, in rect: CGRect) -> CGPoint {
        let x = (pt.x - xAxisParams.lowerBound) / (xAxisParams.upperBound - xAxisParams.lowerBound)
        let y = (((pt.y - yBoundLower) / (yBoundUpper - yBoundLower)) * animationProgress) + animationOffsets[ptIndex]
        
        return .init(x: x * rect.width, y: (1 - y) * rect.height)
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for i in 0..<points.count {
            let pt = getPointPosition(self.points[i], ptIndex: i, in: rect)
            let ptRect = CGRect(origin: pt - .init(x: pointSize * 0.5, y: pointSize * 0.5),
                                size: .init(width: pointSize, height: pointSize))
            let subpath = pointShape.path(in: ptRect)
            
            path.addPath(subpath)
        }
        
        return path
    }
}
