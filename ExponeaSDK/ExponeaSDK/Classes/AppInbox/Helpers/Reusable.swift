//
//  Reusable.swift
//  ExponeaSDK
//
//  Created by Ankmara on 24.02.2023.
//  Copyright © 2023 Exponea. All rights reserved.
//

import UIKit

protocol KeyRepresentable {

    var key: String { get }
}

protocol ValueRepresentable {

    var value: String? { get }
}

protocol KeyValueRepresentable: KeyRepresentable, ValueRepresentable {

}

extension KeyRepresentable where Self: RawRepresentable, Self.RawValue == String {

    var key: String {
        return rawValue
    }
}


/**
 The kind of supplementary view to retrieve. This value is defined by the layout object.
 - Footer
 - Header
 */
enum CollectionElementKindSection: KeyRepresentable {

    /// Collection footer view.
    case footer
    /// Collection header view.
    case header

    var key: String {
        switch self {
        case .footer:
            return UICollectionView.elementKindSectionFooter
        case .header:
            return UICollectionView.elementKindSectionHeader
        }
    }
}

/**
 Reusable Protocol.
 */
protocol Reusable {

    /// Identifier for view recycling.
    static var reuseIdentifier: String { get }
}

/**
 Default implementation for all UIView.
 */
extension Reusable where Self: UIView {

    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

// MARK: - UITableView
extension UITableView {

    /**
     Returns a reusable table-view cell object for the specified reuse identifier and adds it to the
     table.
     - Parameters:
        - style: A constant indicating a cell style. Just for creating new cells. See
            UITableViewCellStyle for descriptions of these constants.
        - reuseIdentifier: A string identifying the cell object to be reused.
        - initializationCallback: Callback which is called when cell is being initialized.
     - Returns: A cell object with the associated default reuse identifier. This method always
        returns a valid cell.
     */
    func dequeueReusableCell<T: UITableViewCell>(
        style: UITableViewCell.CellStyle = .default,
        reuseIdentifier: String = T.reuseIdentifier,
        initializationCallback: TypeBlock<T>? = nil
    ) -> T {
        guard let cell = self.dequeueReusableCell(withIdentifier: reuseIdentifier) as? T else {
            let cell = T(style: style, reuseIdentifier: reuseIdentifier)
            initializationCallback?(cell)
            return cell
        }
        return cell
    }

    /**
     Returns a reusable table-view cell object for the specified reuse identifier and adds it to the
     table.
     - Parameters:
        - indexPath: The index path specifying the location of the cell. The data source receives
            this information when it is asked for the cell and should just pass it along. This
            method uses the index path to perform additional configuration based on the cell’s
            position in the table view.
        - style: A constant indicating a cell style. Just for creating new cells. See
            UITableViewCellStyle for descriptions of these constants.
     - Returns: A cell object with the associated default reuse identifier. This method always
        returns a valid cell.
     */
    func dequeueReusableCell<T: UITableViewCell>(
        forIndexPath indexPath: IndexPath,
        style: UITableViewCell.CellStyle = .default
    ) -> T {
        guard let cell = self.dequeueReusableCell(
            withIdentifier: T.reuseIdentifier,
            for: indexPath
        ) as? T else {
            return T(style: style, reuseIdentifier: T.reuseIdentifier)
        }
        return cell
    }

    /**
     Registers a class for use in creating new table cells.
     - Parameters
        - cellClass: The class of a cell that you want to use in the table.
        - reuseIdentifier: A string identifying the cell object to be reused.
     */
    func register<T: UITableViewCell>(
        _ cellClass: T.Type,
        reuseIdentifier: String = T.reuseIdentifier
    ) {
        self.register(cellClass.classForCoder(), forCellReuseIdentifier: reuseIdentifier)
    }
}

// MARK: UITableViewCell
extension UITableViewCell: Reusable {

}

// MARK: - UICollectionView
extension UICollectionView {

    /**
      Returns a reusable cell object located by its identifier.
      - Parameters:
        - indexPath: The index path specifying the location of the cell. The data source receives
            this information when it is asked for the cell and should just pass it along. This
            method uses the index path to perform additional configuration based on the cell’s
            position in the collection view.
        - reuseIdentifier: A string identifying the cell object to be reused.
      - Returns: A valid cell object.
     */
    func dequeueReusableCell<T: UICollectionViewCell>(
        forIndexPath indexPath: IndexPath,
        reuseIdentifier: String = T.reuseIdentifier
    ) -> T {
        guard let cell = self.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("Unable to dequeue cell \(T.reuseIdentifier)")
        }
        return cell
    }

    /**
     Returns a reusable header view located by its identifier and kind.
     - Parameters:
        - indexPath: The index path specifying the location of the header view in the collection
            view. The data source receives this information when it is asked for the view and should
            just pass it along. This method uses the information to perform additional configuration
            based on the view’s position in the collection view.
        - reuseIdentifier: A string identifying the header object to be reused.
     - Returns: A valid footer view.
     */
    func dequeueHeader<T: UICollectionReusableView>(
        forIndexPath indexPath: IndexPath,
        reuseIdentifier: String = T.reuseIdentifier
    ) -> T {
        return dequeueHeaderOrFooter(
            forIndexPath: indexPath,
            forSupplementaryViewOfKind: .header,
            reuseIdentifier: reuseIdentifier
        )
    }

    /**
     Returns a reusable footer view located by its identifier and kind.
     - Parameters:
        - indexPath: The index path specifying the location of the footer view in the collection
            view. The data source receives this information when it is asked for the view and should
            just pass it along. This method uses the information to perform additional configuration
            based on the view’s position in the collection view.
        - reuseIdentifier: A string identifying the footer object to be reused.
     - Returns: A valid footer view.
     */
    func dequeueFooter<T: UICollectionReusableView>(
        forIndexPath indexPath: IndexPath,
        reuseIdentifier: String = T.reuseIdentifier
    ) -> T {
        return dequeueHeaderOrFooter(
            forIndexPath: indexPath,
            forSupplementaryViewOfKind: .footer,
            reuseIdentifier: reuseIdentifier
        )
    }

    /**
     Returns a reusable supplementary view located by its identifier and kind.
     - Parameters:
        - indexPath: The index path specifying the location of the supplementary view in the
            collection view. The data source receives this information when it is asked for the view
            and should just pass it along. This method uses the information to perform additional
            configuration based on the view’s position in the collection view.
        - kind: The kind of supplementary view to retrieve.
        - reuseIdentifier: A string identifying the header or footer object to be reused.
     - Returns: A valid header or footer view.
     */
    fileprivate func dequeueHeaderOrFooter<T: UICollectionReusableView>(
        forIndexPath indexPath: IndexPath,
        forSupplementaryViewOfKind kind: CollectionElementKindSection,
        reuseIdentifier: String = T.reuseIdentifier
    ) -> T {
        guard let headerOrFooter = dequeueReusableSupplementaryView(
            ofKind: kind.key,
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as? T else {
            fatalError("Unable to dequeue header or footer \(T.reuseIdentifier)")
        }
        return headerOrFooter
    }

    /**
     Register a class for use in creating new collection view cells.
     - Parameters:
        - cellClass: The class of a cell that you want to use in the collection view.
        - reuseIdentifier: A string identifying the cell object to be reused.
     */
    func register<T: UICollectionViewCell>(
        _ cellClass: T.Type,
        reuseIdentifier: String? = nil
    ) {
        register(
            cellClass.classForCoder(),
            forCellWithReuseIdentifier: reuseIdentifier ?? cellClass.reuseIdentifier
        )
    }

    /**
     Registers a class for use as header view for the collection view.
     - Parameters:
        - header: The class to use for the header view.
        - reuseIdentifier: A string identifying the header object to be reused.
     */
    func register<T: UICollectionReusableView>(
        header: T.Type,
        reuseIdentifier: String? = nil
    ) {
        register(
            headerOrFooter: header,
            forSupplementaryViewOfKind: .header,
            reuseIdentifier: reuseIdentifier
        )
    }

    /**
     Registers a class for use as footer view for the collection view.
     - Parameters:
        - footer: The class to use for the footer view.
        - reuseIdentifier: A string identifying the footer object to be reused.
     */
    func register<T: UICollectionReusableView>(
        footer: T.Type,
        reuseIdentifier: String? = nil
    ) {
        register(
            headerOrFooter: footer,
            forSupplementaryViewOfKind: .footer,
            reuseIdentifier: reuseIdentifier
        )
    }

    /**
     Registers a class for use in creating supplementary views for the collection view.
     - Parameters:
        - headerOrFooter: The class to use for the supplementary view.
        - kind: The kind of supplementary view to create.
        - reuseIdentifier: A string identifying the header or footer object to be reused.
     */
    fileprivate func register<T: UICollectionReusableView>(
        headerOrFooter: T.Type,
        forSupplementaryViewOfKind kind: CollectionElementKindSection,
        reuseIdentifier: String? = nil
    ) {
        register(
            headerOrFooter.classForCoder(),
            forSupplementaryViewOfKind: kind.key,
            withReuseIdentifier: reuseIdentifier ?? headerOrFooter.reuseIdentifier
        )
    }
}

// MARK: UICollectionReusableView
extension UICollectionReusableView: Reusable {

}

