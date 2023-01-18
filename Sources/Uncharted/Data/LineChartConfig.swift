
import SwiftUI

public class LineChartConfig: ChartConfig {
    /// Whether or not the first data point of the next subset should be considered for axis bounds calculations, e.g. for line graphs.
    public override var considerNextDataPointForYBounds: Bool { true }
    
    /// Default initializer.
    public override init(xAxisConfig: ChartAxisConfig = .xAxis(),
                         yAxisConfig: ChartAxisConfig = .yAxis(),
                         tapActions: [ChartTapAction] = [.highlightSingle],
                         initialXValue: Double? = nil,
                         padding: EdgeInsets = .init(),
                         animation: Animation? = .easeInOut,
                         noDataAvailableText: String = "") {
        super.init(xAxisConfig: xAxisConfig, yAxisConfig: yAxisConfig,
                   tapActions: tapActions, initialXValue: initialXValue, padding: padding,
                   animation: animation, noDataAvailableText: noDataAvailableText)
    }
    
    /// Initialize from any other config.
    public convenience init(config: ChartConfig) {
        self.init(xAxisConfig: config.xAxisConfig,
                  yAxisConfig: config.yAxisConfig,
                  tapActions: config.tapActions,
                  initialXValue: config.initialXValue,
                  padding: config.padding,
                  animation: config.animation,
                  noDataAvailableText: config.noDataAvailableText)
    }
}
