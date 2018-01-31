/*

  EndianTraversal.swift
  BitArray

  Created by Daryle Walker on 1/29/18.
  Copyright (c) 2018 Daryle Walker.
  Distributed under the MIT License.

  An enumeration describing how to iterate over the bits of a binary integer.

 */


/// Ways the bits of a binary integer can be visited in a single pass.
public enum EndianTraversal {

    /// Start from the most-significant bits and go towards the lower orders.
    case hi2lo
    /// Start from the least-significant bits and go towards the higher orders.
    case lo2hi

}
