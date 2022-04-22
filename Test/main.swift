//
//  main.swift
//  Test
//
//  Created by ldc on 2022/4/21.
//

import Foundation

print("Hello, World!")

let price = [1, 2, 3]
//let price = [3, 2, 6, 5, 0, 3, 0, 5, 7, 6, 3, 4, 5]

typealias Item = (start: Int, end: Int)

var items = [Item]()

var change_list = [Int]()

for i in 1..<price.count {
    change_list.append(price[i] - price[i - 1])
}

var last_start_index = -1

for i in 0..<change_list.count - 1 {
    if i == 0 {
        if change_list[i] < 0 {
            last_start_index = 0
        }
    }else {
        if change_list[i] < 0 {
            if last_start_index != -1 {
                let item = (last_start_index + 1, i)
                items.append(item)
                last_start_index = -1
            }else {
                last_start_index = i
            }
        }else {
            if last_start_index == -1 {
                last_start_index = i - 1
            }
        }
    }
}

if last_start_index != -1 {
    
    let item = (last_start_index + 1, change_list.count + (change_list[change_list.count - 1] > 0 ? 0 : -1))
    items.append(item)
}else {
    if change_list[change_list.count - 1] > 0 {
        let item = (change_list.count - 1, change_list.count)
        items.append(item)
    }
}

print(items)
