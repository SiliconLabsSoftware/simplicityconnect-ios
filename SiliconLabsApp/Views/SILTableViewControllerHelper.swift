//
//  SILTableViewControllerHelper.swift
//  BlueGeckoTests
//
//  Created by Grzegorz Janosz on 23/03/2021.
//  Copyright © 2021 SiliconLabs. All rights reserved.
//

import Foundation

@objc
@objcMembers
class SILTableViewWithShadowCells: NSObject {

    private enum CellShadowRole: Int { case top, mid, bottom, alone }
    private static let roleKey = malloc(1)!
    private static let boundsKey = malloc(1)!

    private class func storedState(for cell: UITableViewCell) -> (role: CellShadowRole, bounds: CGSize)? {
        guard let raw = objc_getAssociatedObject(cell, roleKey) as? Int,
              let role = CellShadowRole(rawValue: raw),
              let value = objc_getAssociatedObject(cell, boundsKey) as? NSValue else { return nil }
        return (role, value.cgSizeValue)
    }
    private class func setStoredState(_ role: CellShadowRole, bounds: CGSize, for cell: UITableViewCell) {
        objc_setAssociatedObject(cell, roleKey, role.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(cell, boundsKey, NSValue(cgSize: bounds), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    @objc class func invalidateCellShadowRole(_ cell: UITableViewCell) {
        objc_setAssociatedObject(cell, roleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(cell, boundsKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    class func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Determine the cell's role within its section.
        let rowCount = tableView.numberOfRows(inSection: indexPath.section)
        let role: CellShadowRole
        if indexPath.row == 0 {
            role = rowCount > 1 ? .top : .alone
        } else if rowCount - 1 == indexPath.row {
            role = .bottom
        } else {
            role = .mid
        }

         if let first = tableView.indexPathsForVisibleRows?.first, first == indexPath,
           cell.superview?.subviews.last !== cell {
            tableView.bringSubviewToFront(cell)
        }

        // Skip re-applying shadow/mask only when BOTH role and bounds match.
        // Variable-height cells (e.g. IOP test scenario cells) keep the same role on reuse
        // but get different heights; without bounds in the cache, the mask path stays sized
        // to the previous cell and the new bottom corners get clipped.
        let cellBounds = cell.bounds.size
        if let stored = storedState(for: cell), stored.role == role, stored.bounds == cellBounds {
            if cell.clipsToBounds { cell.clipsToBounds = false }
            return
        }
        setStoredState(role, bounds: cellBounds, for: cell)

        switch role {
        case .top:
            cell.addShadowWhenAtTop()
            cell.roundCornersTop()
        case .alone:
            cell.addShadowWhenAlone()
            cell.roundCornersAll()
        case .bottom:
            cell.addShadowWhenAtBottom()
            cell.roundCornersBottom()
        case .mid:
            cell.roundCornersNone()
            cell.addShadowWhenInMid()
        }
        cell.clipsToBounds = false
    }
    
    class func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int, withHeight height: CGFloat) -> UIView? {
        let size = CGRect(origin: tableView.bounds.origin, size: CGSize(width: tableView.bounds.size.width, height: height))
        let view = UIView(frame: size)
        view.backgroundColor = .clear
        return view
    }
    
    class func tableView(_ tableView: UITableView, viewForFooterInSection section: Int, withHeight height: CGFloat) -> UIView? {
        let size = CGRect(origin: tableView.bounds.origin, size: CGSize(width: tableView.bounds.size.width, height: height))
        let view = UIView(frame: size)
        view.backgroundColor = .clear
        return view
    }
}
