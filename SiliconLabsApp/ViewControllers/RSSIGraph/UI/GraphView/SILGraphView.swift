//
//  SILGraphView.swift
//  BlueGecko
//
//  Created by Grzegorz Janosz on 18/02/2022.
//  Copyright © 2022 SiliconLabs. All rights reserved.
//

import UIKit
import Charts
import RxSwift
import RxRelay

class SILGraphView: UIView {
    
    private var referenceDate = Date()
    
    var refresh: PublishRelay<Void> = PublishRelay()
    var input: PublishRelay<[SILRSSIGraphDiscoveredPeripheralData]> = PublishRelay()

    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var chartView: RSSIGraphLineChartView!
    
    private let rightArrowButton = SILBigButton()
    private let leftArrowButton = SILBigButton()

    private var minimumYValue: Double = RSSIConstants.startYAxisMinimum
    private var maximumYValue: Double = RSSIConstants.startYAxisMaximum
    
    deinit {
        debugPrint("SILGraphView deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("SILGraphView", owner: self, options: nil)
        addSubview(contentView)
        contentView.backgroundColor = .clear
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        setupInput()
        setupLeftArrowButton()
        setupRightArrowButton()
    }
    // GRAPH DATA //
    private func setupInput() {
        input.asObservable()
            .flatMap { Observable.from($0) }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { _self, cellData in
                guard _self.chartView != nil else { return }
                _self.updateExistingDataSetAppearance(for: cellData)
            }
            .disposed(by: disposeBag)
        
        input.asObservable()
            .flatMap { Observable.from($0) }
            .observe(on: MainScheduler.instance)
            .filter { [weak self] (dataSet) in
                guard let self = self, self.chartView != nil else { return false }
                return self.chartView.checkIfDataSetExist(withLabel: dataSet.uuid)
            }
            .do(onNext: { [weak self] data in
                guard let self = self, self.chartView != nil else { return }
                let historical = data.peripheral.rssiMeasurementTable.rssiMeasurements.value
                self.bulkAddHistoricalDataForPeripheral(data.peripheral.identityKey,
                                                       measurements: historical,
                                                       color: data.color)
            })
            .flatMap { data -> Observable<(String, SILRSSIMeasurement, UIColor)> in
                return data.peripheral.rssiMeasurementTable.rssiMeasurements.asObservable()
                    .skip(1) // skip initial replay; already bulk-added
                    .compactMap { $0.last }
                    .map { (data.peripheral.identityKey, $0, data.color) }
            }
            .map { (id: $0, measurement: $1, color: $2) }
            .observe(on: MainScheduler.instance)
            .bind(with: self) { _self, val in
                guard _self.chartView != nil else { return }
                let (id, measurement, color) = val
                _self.addOrUpdateDataForPeripheral(id, measurement: measurement, withColor: color)
            }
            .disposed(by: disposeBag)
        
        refresh.asObservable()
            .throttle(.milliseconds(300), scheduler: MainScheduler.instance)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { _self, _ in
                guard _self.chartView != nil else { return }
                _self.refreshGraph()
            }
            .disposed(by: disposeBag)
    }
    
    private func updateExistingDataSetAppearance(for cellData: SILRSSIGraphDiscoveredPeripheralData) {
        guard let dataSet = chartView.lineData?.dataSets.first(where: { $0.label == cellData.uuid }) as? LineChartDataSet else {
            return
        }
        let targetLineWidth = cellData.isSelected ? RSSIConstants.selectedLineWidth : RSSIConstants.unselectedLineWidth
        let currentColor = dataSet.colors.first
        if currentColor != cellData.color {
            dataSet.setColor(cellData.color)
        }
        if dataSet.lineWidth != targetLineWidth {
            dataSet.lineWidth = targetLineWidth
        }
        if cellData.isSelected {
            // Reorder selected line on top only if not already last.
            if let last = chartView.lineData?.dataSets.last as? LineChartDataSet,
               last.label != dataSet.label {
                chartView.lineData?.removeDataSet(dataSet)
                chartView.lineData?.append(dataSet)
            }
        }
    }
    
    private func bulkAddHistoricalDataForPeripheral(_ identifier: String,
                                                    measurements: [SILRSSIMeasurement],
                                                    color: UIColor) {
        guard chartView != nil else { return }
        guard !measurements.isEmpty else { return }
        
        var entries: [ChartDataEntry] = []
        entries.reserveCapacity(measurements.count)
        var localMax = maximumYValue
        var localMin = minimumYValue
        for m in measurements {
            let yValue = m.rssi.doubleValue
            entries.append(ChartDataEntry(x: m.date.timeIntervalSince(referenceDate), y: yValue))
            if yValue > localMax { localMax = yValue }
            if yValue < localMin { localMin = yValue }
        }
        maximumYValue = localMax
        minimumYValue = localMin
        
        if let dataSet = chartView.lineData?.dataSets.first(where: { $0.label == identifier }) as? LineChartDataSet {
            for entry in entries { dataSet.append(entry) }
        } else {
            chartView.addDataSetFor(entries, identifier: identifier, color: color)
        }
    }
    
    func startChart() {
        DispatchQueue.main.async {
            self.chartView.resetChart()
        }
    }
    
    func redrawChart() {
        self.chartView.resetChart()
        self.disposeBag = DisposeBag()
        self.setupInput()
    }
    
    func setStartTime(time : Date) {
        self.referenceDate = time
    }
    
    func refreshGraph() {
        let now = Double(Date().timeIntervalSince(referenceDate))
        
        chartView.xAxis.axisMinimum = RSSIConstants.startXAxisMinimum
        chartView.xAxis.axisMaximum = max(now, RSSIConstants.maxNumberOfVisibleXValues)
        
        chartView.leftAxis.axisMinimum = minimumYValue
        chartView.leftAxis.axisMaximum = maximumYValue
        chartView.setVisibleXRangeMinimum(RSSIConstants.minNumberOfVisibleXValues)
        chartView.setVisibleXRangeMaximum(RSSIConstants.maxNumberOfVisibleXValues)
        chartView.setVisibleYRangeMinimum(RSSIConstants.minNumberOfVisibleYValues, axis: .left)
        chartView.setVisibleYRangeMaximum(RSSIConstants.maxNumberOfVisibleYValues, axis: .left)

        chartView.updateXAxisGridLines()
        chartView.updateViewPosition()

        let axisMaximum = chartView.xAxis.axisMaximum
        
        rightArrowButton.isHidden = !(chartView.highestVisibleX + RSSIConstants.approximationError  < axisMaximum)
        leftArrowButton.isHidden = chartView.lowestVisibleX == chartView.xAxis.axisMinimum
        
        chartView.lineData?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    private func setupRightArrowButton() {
        addSubview(rightArrowButton)
        let arrowSystemImage = UIImage(systemName: "chevron.right")?.withRenderingMode(.alwaysTemplate)
        rightArrowButton.isHidden = true
        rightArrowButton.setImage(arrowSystemImage, for: .normal)
        rightArrowButton.tintColor = .black
        rightArrowButton.translatesAutoresizingMaskIntoConstraints = false
        rightArrowButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12).isActive = true
        rightArrowButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        rightArrowButton.extendLeft = RSSIConstants.extendedButtonOffset
    
        rightArrowButton.addTarget(self, action: #selector(backToCurrentPosition), for: .touchUpInside)
    }
    
    private func setupLeftArrowButton() {
        addSubview(leftArrowButton)
        let arrowSystemImage = UIImage(systemName: "chevron.left")?.withRenderingMode(.alwaysTemplate)
        leftArrowButton.isHidden = true
        leftArrowButton.setImage(arrowSystemImage, for: .normal)
        leftArrowButton.tintColor = .black
        leftArrowButton.translatesAutoresizingMaskIntoConstraints = false
        leftArrowButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 56).isActive = true
        leftArrowButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5).isActive = true
        
        leftArrowButton.extendRight = RSSIConstants.extendedButtonOffset

        leftArrowButton.addTarget(self, action: #selector(backToOriginPosition), for: .touchUpInside)
    }
    
    @objc private func backToCurrentPosition() {
        let now = Double(Date().timeIntervalSince(referenceDate))
        chartView.moveViewToX(now)
    }
    
    @objc private func backToOriginPosition() {
        chartView.moveViewToX(0.0)
    }
    
    func addOrUpdateDataForPeripheral(_ identifier: String, measurement: SILRSSIMeasurement, withColor color: UIColor) {
        guard chartView != nil else { return }
        
        let yValue = measurement.rssi.doubleValue
        let entry = ChartDataEntry(x: measurement.date.timeIntervalSince(referenceDate), y: yValue )
        
        self.maximumYValue = yValue > maximumYValue ? yValue : maximumYValue
        self.minimumYValue = yValue < minimumYValue ? yValue : minimumYValue
        if let dataSet = chartView.lineData?.dataSets.first(where: { $0.label == identifier }) as? LineChartDataSet {
            
            //print(" dataSet ==== \(dataSet)")
            
            dataSet.append(entry)
        } else {
            chartView.addDataSetFor([entry], identifier: identifier, color: color)
        }
    }
}

struct RSSIConstants {
    static let axisBlack = UIColor.black
    
    static let graphLineDisabled = UIColor.lightGray
    
    static func randomColor() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
    
    static let minNumberOfVisibleXValues: Double = xAxisGranularity
    static let maxNumberOfVisibleXValues: Double = 30
    static let maxNumberOfVisibleXValuesInt: Int = Int(maxNumberOfVisibleXValues)
    
    static let minNumberOfVisibleYValues: Double = 20
    static let maxNumberOfVisibleYValues: Double = 100

    static let unselectedLineWidth = 1.0
    static let selectedLineWidth = 3.0
    
    static let startYAxisMinimum = -100.0
    static let startYAxisMaximum = 0.0
    static let yAxisGranularity = 20.0
    
    static let startXAxisMinimum = 0.0
    static let startXAxisMaximum = 30.0
    static let xAxisGranularity = 5.0
    static let xAxisGranularityInt = Int(yAxisGranularity)
    
    static let approximationError: Double = 2.0
    static let extendedButtonOffset: Double = 15
}
