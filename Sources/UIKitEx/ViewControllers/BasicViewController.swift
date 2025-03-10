//
//  BasicViewController.swift
//  Rocket Insights
//
//  Created by Ilya Belenkiy on 03/30/21.
//  Copyright © 2021 Rocket Insights. All rights reserved.
//

#if canImport(UIKit)

import UIKit
import Combine
import CombineEx
import ReducerArchitecture

public enum UIEndValue {
    case fromUI
    case fromCode

    public var isFromUI: Bool {
        switch self {
        case .fromUI: return true
        case .fromCode: return false
        }
    }
}

open class BasicViewController: UIViewController {
    open var viewClass = UIKitEx.env.vcViewClass

    public private(set) var scrollView: RootScrollView?
    public private(set) var contentView: UIView?

    public private(set) var availableSize: CGSize = .zero

    // MARK: - Common Elements

    private var _ended = PassthroughSubject<UIEndValue, Never>()
    public var ended: AnySingleValuePublisher<UIEndValue, Never> {
        _ended.first().eraseType()
    }

    public var endValue: UIEndValue = .fromUI
    // only the cancellation of the first VC in the flow should really cancel the flow
    open var ignoreCancel = true

    public private(set) var appearanceCount = 0
    public private(set) var isLayoutConfigured = false

    public var isFirstAppearance: Bool {
        appearanceCount == 1
    }

    @discardableResult
    public func makeContentScrollable() -> UIView {
        let scrollView = RootScrollView()
        self.scrollView = scrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        self.contentView = contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        var layout = Layout()
        layout.add(scrollView.align(to: view))
        layout.add(contentView.align(to: scrollView))
        layout.add(UIView.constraint(contentView.widthAnchor, to: view.widthAnchor))
        layout.activate()

        return contentView
    }

    // MARK: - Layout

    // override in subclasses
    /// Returns the main content view. Override in subclasses
    @discardableResult
    open func updateMainContentLayout(traits: Styling.Traits, availableSize: CGSize) -> UIView? {
        return nil
    }

    private func updateMainContentLayoutIfNeeded() {
        guard availableSize.width > 0 else { return }
        updateMainContentLayout(traits: .traits(traitCollection), availableSize: availableSize)
    }

    open override func viewWillLayoutSubviews() {
        availableSize = view.bounds.size
        updateMainContentLayoutIfNeeded()
        super.viewWillLayoutSubviews()
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if let vc = self as? ConfigurableViewController {
            guard isLayoutConfigured else { return }
            vc.updateLayout()
            updateMainContentLayoutIfNeeded()
        }
        else {
            updateMainContentLayoutIfNeeded()
        }
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard isViewLoaded else { return }

        availableSize = size
        let traits: Styling.Traits = .traits(traitCollection)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            (self as? ConfigurableViewController)?.updateLayout()
            self.updateMainContentLayout(traits: traits, availableSize: size)?.layoutIfNeeded()
        })
    }

    // MARK: - Comon Callbacks

    open override func loadView() {
        view = viewClass.init(frame: .zero)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        (self as? ConfigurableViewController)?.configure()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if appearanceCount == 0, let vc = self as? ConfigurableViewController {
            vc.configureLayout()
            isLayoutConfigured = true
            vc.configureAfterLayout()
            vc.updateLayout()
        }
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView?.trackKeyboard(enabled: true)
        appearanceCount += 1
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scrollView?.trackKeyboard(enabled: false)
    }

    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if parent == nil {
            _ended.send(endValue)
        }
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        let dismissingSelf = (presentingViewController != nil)
        if dismissingSelf {
            _ended.send(endValue)
        }
        super.dismiss(animated: flag, completion: completion)
    }
}

#endif
