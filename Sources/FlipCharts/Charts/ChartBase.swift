
import SwiftUI
import Toolbox
import Panorama

fileprivate struct ChartYAxisLabel: Identifiable {
    let chartId: Int
    let label: String
    let labelIndex: Int
    
    var id: String { "\(chartId)_yaxislabel_\(label)" }
}

fileprivate struct ChartXAxisLabel: Identifiable {
    let chartId: Int
    let label: String
    let labelIndex: Int
    
    var id: String { "\(chartId)_xaxislabel_\(labelIndex)" }
}

fileprivate struct ChartYAxisGridline: Identifiable {
    let chartId: Int
    let label: String
    let labelIndex: Int
    
    var id: String { "\(chartId)_yaxisgridline_\(label)" }
}

public struct ChartBase<Content: View>: View {
    /// The full chart data.
    let fullData: ChartData
    
    /// The chart content builder.
    let chartContent: (ChartState, ChartData, CGSize) -> Content
    
    /// The current data subset.
    @StateObject var state: ChartState = .init()
    
    /// The unique identifier of this chart.
    let chartId: Int
    
    /// Default initializer.
    init(data: ChartData, @ViewBuilder content: @escaping (ChartState, ChartData, CGSize) -> Content) {
        self.fullData = data
        self.chartContent = content
        self.chartId = ObjectIdentifier(fullData).hashValue
    }
    
    /// Build the x-axis of this chart.
    static func xAxisLabels(data: ChartData, chartId: Int) -> some View {
        let axisConfig = data.config.xAxisConfig
        let xAxisParams = data.computedParameters.xAxisParams
        let height = ChartState.xAxisHeight(for: axisConfig)
        
        let labels = xAxisParams.labels.enumerated().map {
            ChartXAxisLabel(chartId: chartId, label: $0.element, labelIndex: $0.offset)
        }
        
        return GeometryReader { geometry in
            let labelCount = xAxisParams.labels.count == 1 ? 1 : xAxisParams.labels.count - 1
            if labelCount >= 1 {
                let spacePerLabel = geometry.size.width / CGFloat(labelCount)
                HStack(spacing: 0) {
                    ForEach(labels) { (label: ChartXAxisLabel) in
                        HStack(spacing: 0) {
                            if label.labelIndex == 0 {
                                LineShape(edge: .leading)
                                    .stroke(axisConfig.gridStyle.lineColor, style: axisConfig.gridStyle.swiftUIStrokeStyle)
                                    .frame(width: axisConfig.gridStyle.lineWidth)
                            }
                            
                            Group {
                                Text(verbatim: label.label)
                                    .foregroundColor(axisConfig.labelFontColor)
                                    .font(axisConfig.labelFont.monospacedDigit())
                                    .padding(.leading, 4)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.75)
                            }
                            .frame(height: height)
                            
                            Spacer()
                            
                            LineShape(edge: .leading)
                                .stroke(axisConfig.gridStyle.lineColor, style: axisConfig.gridStyle.swiftUIStrokeStyle)
                                .frame(width: axisConfig.gridStyle.lineWidth)
                        }
                        .frame(width: spacePerLabel, height: height)
                    }
                }
            }
        }
        .frame(height: height)
        .padding(EdgeInsets(top: 0, leading: data.config.padding.leading,
                            bottom: 0, trailing: data.config.padding.trailing))
    }
    
    /// Build the x-axis grid lines.
    static func xAxisGrid(data: ChartData, size: CGSize) -> some View {
        let axisConfig = data.config.xAxisConfig
        let gridStyle = axisConfig.gridStyle
        let xAxisParams = data.computedParameters.xAxisParams
        
        let labelCount = data.isEmpty ? 3 : xAxisParams.labels.count - 1
        let spacePerLabel = size.width / CGFloat(labelCount)
        
        return HStack(spacing: 0) {
            if labelCount >= 1 {
                ForEach(0..<labelCount, id: \.self) { labelIndex in
                    HStack(spacing: 0) {
                        if labelIndex == 0 {
                            LineShape(edge: .leading)
                                .stroke(gridStyle.lineColor, style: gridStyle.swiftUIStrokeStyle)
                                .frame(width: gridStyle.lineWidth)
                        }
                        
                        Spacer()
                        
                        LineShape(edge: .leading)
                            .stroke(gridStyle.lineColor, style: gridStyle.swiftUIStrokeStyle)
                            .frame(width: gridStyle.lineWidth)
                    }
                    .frame(width: spacePerLabel, height: size.height)
                }
            }
        }
        .padding(EdgeInsets(top: 0, leading: data.config.padding.leading,
                            bottom: 0, trailing: data.config.padding.trailing))
    }
    
    /// Required spacing to make the y-axis not extend below the x-axis.
    var xAxisSpacer: some View {
        Rectangle()
            .frame(width: 0, height: 4)
            .opacity(0)
    }
    
    /// Build the y-axis of this chart.
    func yAxisLabels(data: ChartData, yAxisParams: ComputedChartAxisData) -> some View {
        let axisConfig = data.config.yAxisConfig
        let labels = yAxisParams.labels.reversed().enumerated().map {
            ChartYAxisLabel(chartId: self.chartId, label: $0.element, labelIndex: $0.offset)
        }
        
        return ZStack {
            Text(verbatim: self.state.longestYLabel)
                .font(axisConfig.labelFont.monospacedDigit())
                .padding(.leading, 2)
                .opacity(0)
            
            VStack(spacing: 0) {
                ForEach(labels) { label in
                    if label.labelIndex > 0 {
                        Spacer()
                    }
                    
                    Text(verbatim: label.label)
                        .foregroundColor(axisConfig.labelFontColor)
                        .font(axisConfig.labelFont.monospacedDigit())
                        .padding(.leading, 2)
                        .relativeOffset(y: -0.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(EdgeInsets(top: data.config.padding.top, leading: 0,
                                bottom: data.config.padding.bottom, trailing: 0))
        }
    }
    
    /// Build the y-axis grid lines.
    static func yAxisGrid(data: ChartData, yAxisParams: ComputedChartAxisData, chartId: Int) -> some View {
        let gridStyle = data.config.yAxisConfig.gridStyle
        let labels = yAxisParams.labels.reversed().enumerated().map {
            ChartYAxisGridline(chartId: chartId, label: $0.element, labelIndex: $0.offset)
        }
        
        return VStack {
            ForEach(labels) { label in
                if label.labelIndex > 0 {
                    Spacer()
                }
                
                LineShape(edge: .top)
                    .stroke(gridStyle.lineColor, style: gridStyle.swiftUIStrokeStyle)
                    .frame(height: gridStyle.lineWidth)
            }
        }
        .padding(EdgeInsets(top: data.config.padding.top, leading: 0,
                            bottom: data.config.padding.bottom, trailing: 0))
    }
    
    /// Build the complete y-axis.
    func yAxis(data: ChartData, yAxisParams: ComputedChartAxisData) -> some View {
        VStack(spacing: 0) {
            yAxisLabels(data: data, yAxisParams: yAxisParams)
            xAxisSpacer
        }
    }
    
    /// Build the markers view.
    func markersView(data: ChartData,
                     yAxisParams: ComputedChartAxisData,
                     widthMultiplier: CGFloat) -> some View {
        let dataRect = CGRect(x: data.computedParameters.xAxisParams.lowerBound, y: data.computedParameters.yAxisParams.lowerBound,
                              width: data.computedParameters.xAxisParams.upperBound - data.computedParameters.xAxisParams.lowerBound,
                              height: data.computedParameters.yAxisParams.upperBound - data.computedParameters.yAxisParams.lowerBound)
        
        let viewRect = CGRect(x: 0, y: 0,
                              width: state.chartAreaSizeWithPadding.width * widthMultiplier,
                              height: state.chartAreaSizeWithPadding.height)
        
        return ZStack {
            ForEach(0..<data.series.count, id: \.self) { seriesIndex in
                let series = data.series[seriesIndex]
                ForEach(0..<series.markers.count, id: \.self) { markerIndex in
                    let marker = series.markers[markerIndex]
                    marker.view(dataRect: dataRect, viewRect: viewRect)
                }
            }
        }
        .frame(width: viewRect.width, height: viewRect.height)
    }
    
    /// Build the x-axis, the data grid and the chart content.
    func xAxisAndContent(data: ChartData, yAxisParams: ComputedChartAxisData,
                         widthMultiplier: CGFloat = 1,
                         onContentAppear: Optional<() -> Void> = nil) -> some View {
        VStack(spacing: 0) {
            ZStack {
                if state.chartAreaSize.magnitudeSquared.isZero {
                    GeometryReader { geometry in
                        ZStack {}
                        .onAppear {
                            state.chartAreaSize = geometry.size
                        }
                    }
                }
                else {
                    ZStack {
                        Self.xAxisGrid(data: data, size: .init(width: state.chartAreaSize.width * widthMultiplier,
                                                               height: state.chartAreaSize.height))
                        Self.yAxisGrid(data: data, yAxisParams: yAxisParams, chartId: self.chartId)
                        
                        if !data.isEmpty {
                            self.chartContent(state, data,
                                              .init(width: state.chartAreaSizeWithPadding.width * widthMultiplier,
                                                    height: state.chartAreaSizeWithPadding.height))
                            .onAppear {
                                onContentAppear?()
                            }
                            
                            self.markersView(data: data, yAxisParams: yAxisParams,
                                             widthMultiplier: widthMultiplier)
                        }
                    }
                }
            }
            
            if data.config.xAxisConfig.visible {
                Self.xAxisLabels(data: data, chartId: self.chartId)
            }
        }
    }

    /// Build the drag gesture for scrolling.
    var scrollingDragGesture: some Gesture {
        DragGesture().onChanged { action in
            guard !state.isTransitioning else {
                return
            }
            
            guard fullData.config.isHorizontallySegmented else {
                return
            }
            
            withAnimation(.linear(duration: 0.05)) {
                state.currentChartOffset = .init(width: action.translation.width, height: 0)
            }
        }
        .onEnded { action in
            guard !state.isTransitioning else {
                return
            }
            
            guard fullData.config.isHorizontallySegmented else {
                return
            }
            
            let translation = action.translation.width
            let threshold = fullData.config.xAxisConfig.scrollingThresholdTranslation
            
            if translation < -threshold {
                state.initiateForwardScroll()
            }
            else if translation > threshold {
                state.initiateBackwardScroll()
            }
            else {
                withAnimation {
                    state.currentChartOffset = .zero
                }
            }
        }
    }
    
    /// The chart body while no scrolling action is active.
    func segmentedChartBody(yAxisParams: ComputedChartAxisData) -> some View {
        ZStack {
            if !state.chartAreaSize.magnitudeSquared.isZero {
                let size = state.chartAndxAxisAreaSize
                ZStack {
                    HStack(spacing: 0) {
                        self.xAxisAndContent(data: state.previousDataSubset, yAxisParams: yAxisParams)
                        self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams)
                        self.xAxisAndContent(data: state.nextDataSubset, yAxisParams: yAxisParams)
                    }
                    .frame(width: 3 * state.chartAreaSize.width)
                }
                .frame(width: size.width, height: size.height)
                .onAppear {
                    guard state.appearanceAnimationProgress.isZero else {
                        return
                    }
                    
                    if let animation = fullData.config.animation {
                        withAnimation(animation) {
                            state.appearanceAnimationProgress = 1
                        }
                    }
                    else {
                        state.appearanceAnimationProgress = 1
                    }
                }
            }
            else {
                self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams)
            }
        }
        .contentShape(Rectangle())
        .highPriorityGesture(self.scrollingDragGesture)
    }
    
    func staticChartBody(yAxisParams: ComputedChartAxisData) -> some View {
        ZStack {
            if !state.chartAreaSize.magnitudeSquared.isZero {
                let size = state.chartAndxAxisAreaSize
                self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams)
                    .frame(width: size.width, height: size.height)
                    .onAppear {
                        guard state.appearanceAnimationProgress.isZero else {
                            return
                        }
                        
                        if let animation = fullData.config.animation {
                            withAnimation(animation) {
                                state.appearanceAnimationProgress = 1
                            }
                        }
                        else {
                            state.appearanceAnimationProgress = 1
                        }
                    }
            }
            else {
                self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams)
            }
        }
    }
    
    func continuousChartBody(yAxisParams: ComputedChartAxisData) -> some View {
        guard case .continuous(let visibleValueRange_) = fullData.config.xAxisConfig.scrollingBehaviour else {
            fatalError("chart is not continuously scrollable")
        }
        
        let valueCount = state.currentDataSubset.computedParameters.sortedXValues.count
        let visibleValueRange = min(visibleValueRange_, Double(valueCount))
        
        return ZStack {
            if visibleValueRange.isZero || state.chartAreaSize.magnitudeSquared.isZero {
                self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams)
            }
            else {
                let size = state.chartAndxAxisAreaSize
                let lower = fullData.computedParameters.xAxisParams.lowerBound
                let labelCount = max(0, state.currentDataSubset.computedParameters.xAxisParams.labels.count - 1)
                
                let availableWidth = size.width
                let spacePerLabel = availableWidth / CGFloat(visibleValueRange)
                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        ZStack {
                            self.xAxisAndContent(data: state.currentDataSubset, yAxisParams: yAxisParams,
                                                 widthMultiplier: Double(valueCount) / Double(visibleValueRange))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            // Place markers with IDs for skipping to a particular data point
                            if labelCount > 0 {
                                HStack(spacing: 0) {
                                    ForEach(0..<labelCount, id: \.self) { labelIndex in
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: spacePerLabel, height: 5)
                                            .id("_xaxis_label_\(labelIndex)")
                                    }
                                }
                                .onAppear {
                                    guard let initialXValue = fullData.config.initialXValue else {
                                        return
                                    }
                                    
                                    let labelOffset = initialXValue.rounded() - lower
                                    let labelIndex = Int(labelOffset / state.currentDataSubset.computedParameters.xAxisParams.stepSize)
                                    
                                    proxy.scrollTo("_xaxis_label_\(labelIndex)")
                                }
                            }
                        }
                    }
                }
                .frame(width: size.width, height: size.height)
                .onAppear {
                    guard state.appearanceAnimationProgress.isZero else {
                        return
                    }
                    
                    if let animation = fullData.config.animation {
                        withAnimation(animation) {
                            state.appearanceAnimationProgress = 1
                        }
                    }
                    else {
                        state.appearanceAnimationProgress = 1
                    }
                }
            }
        }
    }
    
    func chartBody(yAxisParams: ComputedChartAxisData) -> some View {
        HStack(spacing: 0) {
            ZStack {
                switch fullData.config.xAxisConfig.scrollingBehaviour {
                case .noScrolling:
                    staticChartBody(yAxisParams: yAxisParams)
                case .segmented:
                    segmentedChartBody(yAxisParams: yAxisParams)
                case .continuous:
                    continuousChartBody(yAxisParams: yAxisParams)
                }
                
                if state.currentDataSubset.isEmpty {
                    Text(verbatim: fullData.config.noDataAvailableText)
                        .font(fullData.config.xAxisConfig.titleFont)
                        .foregroundColor(fullData.config.xAxisConfig.titleFontColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .compositingGroup()
            .offset(x: state.currentChartOffset.width)
            .clipShape(Rectangle())
            .contentShape(Rectangle())
            
            if state.fullData.config.yAxisConfig.visible {
                self.yAxis(data: state.currentDataSubset, yAxisParams: yAxisParams)
            }
        }
    }
    
    public var body: some View {
        ZStack {
            if state.initialized, let yAxisParams = state.yAxisParams {
                self.chartBody(yAxisParams: yAxisParams)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            state.initialize(data: fullData)
        }
        .id(chartId)
    }
}
