# ``Uncharted``

Uncharted is a Charts library for SwiftUI Apps. You can use it to create charts that are similar in appearance to those produced by Swift Charts. In contrast to Swift Charts, it features an imperative API and is available starting from iOS 15.

## Overview

Uncharted currently supports bar charts (``BarChart``) as well as line charts (``LineChart``). To create a chart, you need to create an instance of ``ChartData``. `ChartData` provides the chart's configuration via ``ChartConfig`` as well as its data using one or more ``DataSeries``. 

Charts are higly customizable. For bar charts, you can configure the bar width, color, and stacking behaviour using ``BarChartConfig``. For line charts, you can configure line and point styles (``LineStyle``, ``PointStyle``). All charts support different segmentation and scrolling behaviours (``ChartScrollingBehaviour``), custom data labels (``DataFormatter``), axis and grid styles (``ChartAxisConfig``, ``GridStyle``), customizable tap actions (``ChartTapAction``), as well as markers (``ChartMarker``).

Both chart types can also be represented as a time series (``TimeSeriesView``), which aggregates and visualizes data in customizable date ranges.

The following gallery shows some examples of charts you can create with `Uncharted`.

![An exemplary bar chart](BarChartExample1)
![An exemplary bar chart](BarChartExample3)
![An exemplary bar chart](BarChartExample4)

![An exemplary line chart](LineChartExample1)
![An exemplary line chart](LineChartExample5)
![An exemplary line chart](LineChartExample7)

![An exemplary time series chart](TimeSeriesBarMonth)
![An exemplary time series chart](TimeSeriesTransitionWeek)


## Topics

### Charts

- ``BarChart``
- ``LineChart``
- ``RandomizableChart``

### Time Series

- ``TimeSeriesData``
- ``TimeSeriesDataSource``
- ``SummingTimeSeriesDataSource``
- ``AveragingTimeSeriesDataSource``
- ``TimeSeriesScope``
- ``TimeSeriesScopeFormat``
- ``TimeSeriesView``
- ``TimeSeriesDefaultIntervalPickerView``

### Data

- ``ChartData``
- ``DataSeries``
- ``DataPoint``
- ``DataFormatter``
- ``IntegerFormatter``
- ``FloatingPointFormatter``
- ``DateFormatter``
- ``CustomDataFormatter``

### Chart Configuration

- ``ChartConfig``
- ``LineChartConfig``
- ``BarChartConfig``
- ``ChartAxisConfig``

### Chart Customization

- ``GridStyle``
- ``LineStyle``
- ``PointStyle``
- ``ColorStyle``
- ``ChartScrollingBehaviour``
- ``ChartAxisBaseline``
- ``ChartAxisTopline``
- ``ChartAxisStep``
- ``ChartMarker``
- ``ChartTapAction``
- ``ChartStateProxy``
- ``ChartStateReader``
