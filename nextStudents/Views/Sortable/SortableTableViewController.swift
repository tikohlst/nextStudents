//
//  SortableTableViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//

import UIKit

class SortableTableViewController: UITableViewController {
    
    // MARK: - Variables
    
    var containerController: ContainerViewController?
    var sortingOption: SortOption?
    
    // MARK: - Helper methods
    
    func sort<T>(_ entities: T, by option: SortOption?) -> T {
        var result = entities
        switch option {
        case .firstName:
            if entities is [User] {
                result = (entities as! [User]).sorted(by: { (u1, u2) -> Bool in
                    let name1 = u1.firstName
                    let name2 = u2.firstName
                    return (name1.localizedCaseInsensitiveCompare(name2)) == .orderedAscending
                }) as! T
            } else if entities is [Chat] {
                result = (entities as! [Chat]).sorted(by: { (u1, u2) -> Bool in
                    let name1 = u1.chatPartner.firstName
                    let name2 = u2.chatPartner.firstName
                    return (name1.localizedCaseInsensitiveCompare(name2)) == .orderedAscending
                }) as! T
            }
        case .lastName:
            if entities is [User] {
                result = (entities as! [User]).sorted(by: { (u1, u2) -> Bool in
                    let name1 = u1.lastName
                    let name2 = u2.lastName
                    return (name1.localizedCaseInsensitiveCompare(name2)) == .orderedAscending
                }) as! T
            } else if entities is [Chat] {
                result = (entities as! [Chat]).sorted(by: { (u1, u2) -> Bool in
                    let name1 = u1.chatPartner.lastName
                    let name2 = u2.chatPartner.lastName
                    return (name1.localizedCaseInsensitiveCompare(name2)) == .orderedAscending
                }) as! T
            }
        case .distance:
            break
        case .title:
            if entities is [Offer] {
                result = (entities as! [Offer]).sorted(by: { (o1, o2) -> Bool in
                    let title1 = o1.title
                    let title2 = o2.title
                    return title1.localizedCaseInsensitiveCompare(title2) == .orderedAscending
                }) as! T
            }
        case .type:
            if entities is [Offer] {
                result = (entities as! [Offer]).sorted(by: { (o1, o2) -> Bool in
                    let type1 = o1.type
                    let type2 = o2.type
                    return type1.localizedCaseInsensitiveCompare(type2) == .orderedAscending
                }) as! T
            }
        case .time:
            if entities is [Chat] {
                result = (entities as! [Chat]).sorted(by: { (c1, c2) -> Bool in
                    return c1.timestampOfTheLatestMessage.compare(c2.timestampOfTheLatestMessage) == .orderedAscending
                }) as! T
            }
        case .duration:
            if entities is [Offer] {
                result = (entities as! [Offer]).sorted(by: { (o1, o2) -> Bool in
                    let duration1 = o1.duration
                    let duration2 = o2.duration
                    return duration1.localizedCaseInsensitiveCompare(duration2) == .orderedAscending
                }) as! T
            }
        case .date:
            if entities is [Offer] {
                result = (entities as! [Offer]).sorted(by: { (o1, o2) -> Bool in
                    let date1 = o1.date
                    let date2 = o2.date
                    return date1.compare(date2) == .orderedDescending
                }) as! T
            }
        case nil:
            break
        }
        return result
    }
}
