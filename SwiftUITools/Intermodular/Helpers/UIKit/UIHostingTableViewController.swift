//
// Copyright (c) Vatsal Manot
//

import Swift
import SwiftUI

#if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)

public class UIHostingTableViewController<SectionModel: Identifiable, Item: Identifiable, Data: RandomAccessCollection, SectionHeader: View, SectionFooter: View, RowContent: View>: UITableViewController where Data.Element == ListSection<SectionModel, Item> {
    var _isDataDirty: Bool = false {
        didSet {
            isContentOffsetDirty = _isDataDirty
        }
    }

    var data: Data {
        didSet {
            if !data.isIdentical(to: oldValue) {
                _isDataDirty = true
            }
        }
    }
    
    var sectionHeader: (SectionModel) -> SectionHeader
    var sectionFooter: (SectionModel) -> SectionFooter
    var rowContent: (Item) -> RowContent
    
    var scrollViewConfiguration = CocoaScrollViewConfiguration<AnyView>() {
        didSet {
            #if os(iOS) || targetEnvironment(macCatalyst)
            if scrollViewConfiguration.setupRefreshControl == nil {
                scrollViewConfiguration.setupRefreshControl = { [weak self] in
                    guard let `self` = self else  {
                        return
                    }
                    
                    $0.addTarget(
                        self,
                        action: #selector(self.refreshChanged),
                        for: .valueChanged
                    )
                }
            }
            #endif
            
            tableView?.configure(with: scrollViewConfiguration)
        }
    }
    
    var initialContentAlignment: Alignment! {
        didSet {
            guard oldValue != initialContentAlignment else {
                return
            }
            
            if isContentOffsetCorrectionEnabled {
                if !isObservingContentSize {
                    tableView.addObserver(self, forKeyPath: "contentSize", options: [.old, .new], context: nil)
                    
                    isObservingContentSize = true
                }
            } else {
                if isObservingContentSize {
                    tableView.removeObserver(self, forKeyPath: "contentSize")
                    
                    isObservingContentSize = false
                }
            }
        }
    }
    
    var isInitialContentAlignmentSet: Bool = false
    
    var isContentOffsetCorrectionEnabled: Bool {
        if initialContentAlignment.horizontal == .trailing || initialContentAlignment.vertical == .bottom {
            return true
        } else {
            return false
        }
    }
    
    var isObservingContentSize: Bool = false
    
    var lastContentSize: CGSize? = nil
    var lastContentOffset: CGPoint? = nil
    
    var isContentOffsetDirty: Bool = false {
        didSet {
            if isContentOffsetDirty {
                lastContentSize = tableView.contentSize
                lastContentOffset = tableView.contentOffset
            } else {
                lastContentSize = nil
                lastContentOffset = nil
            }
        }
    }
        
    var _estimatedContentSizeCache: CGSize?
    
    private var _sectionHeaderContentHeightCache: [SectionModel.ID: CGFloat] = [:]
    private var _sectionFooterContentHeightCache: [SectionModel.ID: CGFloat] = [:]
    private var _rowContentHeightCache: [Item.ID: CGFloat] = [:]
    
    private var _prototypeSectionHeader: UIHostingTableViewHeaderFooterView<SectionModel, SectionHeader>?
    private var _prototypeSectionFooter: UIHostingTableViewHeaderFooterView<SectionModel, SectionFooter>?
    private var _prototypeCell: UIHostingTableViewCell<Item, RowContent>?
    
    private var prototypeSectionHeader: UIHostingTableViewHeaderFooterView<SectionModel, SectionHeader> {
        guard let _prototypeSectionHeader = _prototypeSectionHeader else {
            self._prototypeSectionHeader = .some(tableView.dequeueReusableHeaderFooterView(withIdentifier: .hostingTableViewHeaderViewIdentifier) as! UIHostingTableViewHeaderFooterView<SectionModel, SectionHeader>)
            
            return self._prototypeSectionHeader!
        }
        
        return _prototypeSectionHeader
    }
    
    private var prototypeSectionFooter: UIHostingTableViewHeaderFooterView<SectionModel, SectionFooter> {
        guard let _prototypeSectionFooter = _prototypeSectionFooter else {
            self._prototypeSectionFooter = .some(tableView.dequeueReusableHeaderFooterView(withIdentifier: .hostingTableViewFooterViewIdentifier) as! UIHostingTableViewHeaderFooterView<SectionModel, SectionFooter>)
            
            return self._prototypeSectionFooter!
        }
        
        return _prototypeSectionFooter
    }
    
    private var prototypeCell: UIHostingTableViewCell<Item, RowContent> {
        guard let _prototypeCell = _prototypeCell else {
            self._prototypeCell = .some(tableView.dequeueReusableCell(withIdentifier: .hostingTableViewCellIdentifier) as! UIHostingTableViewCell<Item, RowContent>)
            
            return self._prototypeCell!
        }
        
        return _prototypeCell
    }
    
    public init(
        _ data: Data,
        style: UITableView.Style,
        sectionHeader: @escaping (SectionModel) -> SectionHeader,
        sectionFooter: @escaping (SectionModel) -> SectionFooter,
        rowContent: @escaping (Item) -> RowContent
    ) {
        self.data = data
        self.sectionHeader = sectionHeader
        self.sectionFooter = sectionFooter
        self.rowContent = rowContent
        
        super.init(style: style)
        
        tableView.backgroundView = .init()
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.separatorInset = .zero
        
        tableView.register(UIHostingTableViewHeaderFooterView<SectionModel, SectionHeader>.self, forHeaderFooterViewReuseIdentifier: .hostingTableViewHeaderViewIdentifier)
        tableView.register(UIHostingTableViewHeaderFooterView<SectionModel, SectionFooter>.self, forHeaderFooterViewReuseIdentifier: .hostingTableViewFooterViewIdentifier)
        tableView.register(UIHostingTableViewCell<Item, RowContent>.self, forCellReuseIdentifier: .hostingTableViewCellIdentifier)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if let change = change, let oldContentSize = change[.oldKey] as? CGSize, let newContentSize = change[.newKey] as? CGSize, keyPath == "contentSize" {
            correctContentOffset(oldContentSize: oldContentSize, newContentSize: newContentSize)
        }
    }
    
    // MARK: - Data Source -
    
    override public func numberOfSections(in tableView: UITableView) -> Int {
        data.count
    }
    
    override public func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        data[data.index(data.startIndex, offsetBy: section)].items.count
    }
    
    // MARK: - Delegate -
    
    override public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard SectionHeader.self != Never.self else {
            return 0
        }
        
        let model = data[data.index(data.startIndex, offsetBy: section)].model
        
        if let cachedHeight = _sectionHeaderContentHeightCache[model.id] {
            return cachedHeight
        }
        
        prototypeSectionHeader.parent = self
        prototypeSectionHeader.item = model
        prototypeSectionHeader.makeContent = sectionHeader
        
        prototypeSectionHeader.update()
        
        let height = prototypeSectionHeader
            .contentView
            .systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            .height
        
        _sectionHeaderContentHeightCache[model.id] = height
        
        return max(1, height)
    }
    
    override public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard SectionHeader.self != Never.self else {
            return nil
        }
        
        let model = data[data.index(data.startIndex, offsetBy: section)].model
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: .hostingTableViewHeaderViewIdentifier) as! UIHostingTableViewHeaderFooterView<SectionModel, SectionHeader>
        
        if let oldModelId = view.item?.id, model.id == oldModelId {
            return view
        }
        
        view.parent = self
        view.item = model
        view.makeContent = sectionHeader
        
        view.update()
        
        return view
    }
    
    override public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard SectionFooter.self != Never.self else {
            return 0
        }
        
        let model = data[data.index(data.startIndex, offsetBy: section)].model
        
        if let cachedHeight = _sectionFooterContentHeightCache[model.id] {
            return cachedHeight
        }
        
        prototypeSectionFooter.parent = self
        prototypeSectionFooter.item = model
        prototypeSectionFooter.makeContent = sectionFooter
        
        prototypeSectionFooter.update()
        
        let height = prototypeSectionFooter
            .contentView
            .systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            .height
        
        _sectionFooterContentHeightCache[model.id] = height
        
        return max(1, height)
    }
    
    override public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard SectionFooter.self != Never.self else {
            return nil
        }
        
        let model = data[data.index(data.startIndex, offsetBy: section)].model
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: .hostingTableViewFooterViewIdentifier) as! UIHostingTableViewHeaderFooterView<SectionModel, SectionFooter>
        
        if let oldModelId = view.item?.id, model.id == oldModelId {
            return view
        }
        
        view.parent = self
        view.item = model
        view.makeContent = sectionFooter
        
        view.update()
        
        return view
    }
    
    override public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = data[indexPath]
        
        if let cachedHeight = _rowContentHeightCache[item.id] {
            return cachedHeight
        }
        
        prototypeCell.tableViewController = self
        prototypeCell.item = data[indexPath]
        prototypeCell.makeContent = rowContent
        
        prototypeCell.update()
        
        let height = prototypeCell
            .contentView
            .systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
            .height
        
        _rowContentHeightCache[item.id] = height
        
        return max(1, height)
    }
    
    override public func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let item =  data[indexPath]
        let cell = tableView.dequeueReusableCell(withIdentifier: .hostingTableViewCellIdentifier) as! UIHostingTableViewCell<Item, RowContent>
        
        if let oldItemID = cell.item?.id, item.id == oldItemID {
            return cell
        }
        
        cell.tableViewController = self
        cell.indexPath = indexPath
        cell.item = data[indexPath]
        cell.makeContent = rowContent
        
        cell.update()
        
        return cell
    }
    
    override public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isContentOffsetCorrectionEnabled {
            guard !isContentOffsetDirty else {
                return
            }
        }
        
        scrollViewConfiguration.onOffsetChange(
            scrollView.contentOffset(forContentType: AnyView.self)
        )
    }
    
    override public func tableView(
        _ tableView: UITableView,
        shouldHighlightRowAt indexPath: IndexPath
    ) -> Bool {
        false
    }
    
    override public func tableView(
        _ tableView: UITableView,
        willSelectRowAt indexPath: IndexPath
    ) -> IndexPath? {
        nil
    }
    
    #if !os(tvOS)
    @objc public func refreshChanged(_ control: UIRefreshControl) {
        control.refreshChanged(with: scrollViewConfiguration)
    }
    #endif
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let lastContentSize = lastContentSize {
            if initialContentAlignment.horizontal == .trailing {
                tableView.contentOffset.x += tableView.contentSize.width - lastContentSize.width
            }
            
            if initialContentAlignment.vertical == .bottom {
                tableView.contentOffset.y += tableView.contentSize.height - lastContentSize.height
            }
        }
    }
}

extension UIHostingTableViewController {
    var _estimatedContentSize: CGSize {
        let originalContentSize = tableView.contentSize
        
        var height: CGFloat = 0
        
        for section in 0..<numberOfSections(in: tableView) {
            height += tableView(tableView, heightForHeaderInSection: section)
            height += tableView(tableView, heightForFooterInSection: section)
            
            for row in 0..<tableView(tableView, numberOfRowsInSection: section) {
                height += tableView(tableView, heightForRowAt: IndexPath(row: row, section: section))
            }
        }
        
        if height > originalContentSize.height {
            return .init(width: tableView.contentSize.width, height: height)
        } else {
            return originalContentSize
        }
    }
    
    var estimatedContentSize: CGSize {
        if let estimatedContentSize = _estimatedContentSizeCache {
            return estimatedContentSize
        } else {
            let result = _estimatedContentSize
            
            _estimatedContentSizeCache = result
            
            return result
        }
    }
}

extension UIHostingTableViewController {
    public func reloadData() {
        guard _isDataDirty else {
            return updateVisibleRows()
        }
        
        tableView.reloadData()
    }
    
    private func updateVisibleRows() {
        tableView.beginUpdates()
        
        for indexPath in indexPathsForVisibleRows ?? [] {
            if let cell = tableView(tableView, cellForRowAt: indexPath) as? UIHostingTableViewCell<Item, RowContent> {
                cell.update()
            } else {
                assertionFailure()
            }
        }
        
        tableView.endUpdates()
    }
}

extension UIHostingTableViewController {
    func correctContentOffset(
        oldContentSize: CGSize,
        newContentSize: CGSize
    ) {
        guard isContentOffsetDirty else {
            return
        }
        
        guard oldContentSize.maximumDimensionLength < newContentSize.maximumDimensionLength else {
            return
        }
        
        guard newContentSize.minimumDimensionLength != .zero else {
            return
        }
        
        defer {
            lastContentSize = newContentSize
        }
        
        if !isInitialContentAlignmentSet {
            tableView.setContentAlignment(initialContentAlignment, animated: false)
            
            isInitialContentAlignmentSet = true
            isContentOffsetDirty = false
        } else {
            guard let lastContentOffset = lastContentOffset, oldContentSize.minimumDimensionLength != .zero else {
                return
            }
            
            var newContentOffset = lastContentOffset
            
            if initialContentAlignment.horizontal == .trailing {
                newContentOffset.x += newContentSize.width - oldContentSize.width
            }
            
            if initialContentAlignment.vertical == .bottom {
                newContentOffset.y += newContentSize.height - oldContentSize.height
            }
            
            tableView.contentOffset = newContentOffset
            
            self.lastContentOffset = newContentOffset
            
            DispatchQueue.main.async {
                self.tableView.contentOffset = newContentOffset
                self.isContentOffsetDirty = false
            }
        }
    }
}

#endif
