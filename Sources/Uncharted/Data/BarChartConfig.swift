
import SwiftUI

/// Provides additional configuration options for ``BarChart``s.
public class BarChartConfig: ChartConfig {
    /// Whether or not to stack the bars in this chart.
    public var isStacked: Bool
    
    /// The preferred width of bars.
    public var preferredBarWidth: CGFloat?
    
    /// The maximum bar width.
    public var maxBarWidth: CGFloat?
    
    /// Whether the bars should be centered within their space.
    public var centerBars: Bool
    
    /// Whether or not the data for this chart is accumulated by its x-value.
    public override var cumulateYValuesPerSeries: Bool { isStacked }
    
    /// Create a bar chart config.
    ///
    /// - Parameters:
    ///   - isStacked: Whether or not to stack the bars in this chart.
    ///   - preferredBarWidth: The preferred width of bars.
    ///   - maxBarWidth: The maximum bar width.
    ///   - centerBars: Whether the bars should be centered within their space.
    ///   - xAxisConfig: <#xAxisConfig description#>
    ///   - yAxisConfig: <#yAxisConfig description#>
    ///   - tapActions: <#tapActions description#>
    ///   - initialXValue: <#initialXValue description#>
    ///   - padding: <#padding description#>
    ///   - animation: <#animation description#>
    ///   - noDataAvailableText: <#noDataAvailableText description#>
    public init(isStacked: Bool = true,
                preferredBarWidth: CGFloat? = nil,
                maxBarWidth: CGFloat? = nil,
                centerBars: Bool = false,
                xAxisConfig: ChartAxisConfig = .xAxis(),
                yAxisConfig: ChartAxisConfig = .yAxis(),
                tapActions: [ChartTapAction] = [.highlightSingle],
                initialXValue: Double? = nil,
                padding: EdgeInsets = .init(),
                animation: Animation? = .easeInOut,
                noDataAvailableText: String = "") {
        self.isStacked = isStacked
        self.centerBars = centerBars
        
        self.preferredBarWidth = preferredBarWidth
        self.maxBarWidth = maxBarWidth
        
        super.init(xAxisConfig: xAxisConfig, yAxisConfig: yAxisConfig,
                   tapActions: tapActions, initialXValue: initialXValue, padding: padding,
                   animation: animation, noDataAvailableText: noDataAvailableText)
    }
    
    /// Create a bar chart config by cloning an existing configuration.
    ///
    /// - Parameters:
    ///   - isStacked: Whether or not to stack the bars in this chart.
    ///   - preferredBarWidth: The preferred width of bars.
    ///   - maxBarWidth: The maximum bar width.
    ///   - centerBars: Whether the bars should be centered within their space.
    ///   - config: The configuration to clone.
    public convenience init(isStacked: Bool = true,
                            preferredBarWidth: CGFloat? = nil,
                            maxBarWidth: CGFloat? = nil,
                            centerBars: Bool = false,
                            config: ChartConfig) {
        self.init(isStacked: isStacked,
                  preferredBarWidth: preferredBarWidth,
                  maxBarWidth: maxBarWidth,
                  centerBars: centerBars,
                  xAxisConfig: config.xAxisConfig,
                  yAxisConfig: config.yAxisConfig,
                  tapActions: config.tapActions,
                  initialXValue: config.initialXValue,
                  padding: config.padding,
                  animation: config.animation,
                  noDataAvailableText: config.noDataAvailableText)
    }
}
