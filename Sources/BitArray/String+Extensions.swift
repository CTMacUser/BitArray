/*

  String+Extensions.swift
  BitArray

  Created by Daryle Walker on 2/11/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

  Method for string-padding.

 */


extension String {

    /**
     Returns this string left-filled with the given character to the given count.

     If `count` already matches or exceeds `totalCount`, then no copies of `fill` are added to the returned string.

     - Parameter fill: The character to possibly prepend (multiple times) to this string.
     - Parameter totalCount: The length of returned string.

     - Returns: `s + self`, where *s* is *n* copies of `fill`, where *n* is `max(totalCount - count, 0)`.
     */
    func paddingPrepended(_ fill: Character, totalCount: Int) -> String {
        return String(repeating: fill, count: max(0, totalCount - count)) + self
    }

}
