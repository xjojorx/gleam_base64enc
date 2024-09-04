import gleam/bit_array
import gleam/int
import gleam/string
import gleam/list
import gleam/string_builder.{type StringBuilder}

pub fn to_base64(input: BitArray) -> String {
  do_to_base64(input, GroupResult([], 0, 0), string_builder.new())
}

fn do_to_base64(input: BitArray, prev_group: GroupResult, builder: StringBuilder) -> String {
  case pop_byte(input) {
    Error(_) -> {
      case prev_group {
        GroupResult(_, _, 0) -> builder
        GroupResult(_, r, l) -> {
          let padded_group = extract_group(0, r, l) 
          // let assert GroupResult([c], _, _) = padded_group
          let c = case padded_group {
            GroupResult([c], _, _) -> c
            GroupResult([c, _], _, _) -> c
            _ -> panic
          }

          let padding = case l {
            2 -> "=="
            4 -> "="
            _ -> panic
          }
          
          c
          |> encode_group
          |> string_builder.append(builder, _)
          |> string_builder.append(padding)
        }
      }|> string_builder.to_string
    }
    Ok(#(curr_byte, rest)) -> {
      let GroupResult(_, rem, rem_len) = prev_group
      let group = extract_group(curr_byte, rem, rem_len)
      let new_builder = group.vals 
        |> list.fold(builder, fn(acc, curr){
          curr
          |> encode_group
          |> string_builder.append(acc, _)
        })
      do_to_base64(rest, group, new_builder)
    }
  }

}

fn pop_byte(b_arr: BitArray) -> Result(#(Int, BitArray), Nil) {
  case bit_array.byte_size(b_arr) {
    0 -> Error(Nil)
    1 -> {
      let assert <<byte>> = b_arr
      Ok(#(byte, <<>>))
    }
    n -> {
      let assert Ok(<<byte>>) = bit_array.slice(b_arr, 0, 1)
      let assert Ok(rest) = bit_array.slice(b_arr, 1, n-1)
      Ok(#(byte, rest))
    }
  }
}

type GroupResult {
  GroupResult(vals: List(Int), remainder: Int, rem_bits: Int)
}
fn extract_group(byte: Int, rem: Int, rem_bits: Int) -> GroupResult {
  //remainder can be:
  // 0    -> 0 bits 
  // 0-3  -> 2 bits (8-6)
  // 0-15 -> 4 bits (8-2)

  case rem_bits {
    0 ->  {
      let group_val = int.bitwise_shift_right(byte, 2)
      let mask = 3
      let remainder = int.bitwise_and(byte, mask)
      GroupResult([group_val], remainder, 2)
    }
    2 -> {
      let group_part = 
        byte                           // abcdefgh
        |> int.bitwise_shift_right(4)  // 0000abcd
      let new_rem = int.bitwise_and(byte, 15) // 0000efgh
      let chained = rem               // 000000xx
        |> int.bitwise_shift_left(4)  // 00xx0000
        |> int.bitwise_or(group_part) // 00xxabcd
      GroupResult([chained], new_rem, 4)
    }
    4 -> {
      let g1_pre = int.bitwise_shift_left(rem, 2) //    0000xxxx -> 00xxxx00
      let g1_part = int.bitwise_shift_right(byte, 6) // abcdefgh -> 000000ab
      let g1_val = int.bitwise_or(g1_pre, g1_part) //   00xxxxab

      let g2 = int.bitwise_and(byte, 63)         // abcdefgh -> 00cdefgh

      GroupResult([g1_val, g2], 0, 0)
    }
    _ -> panic as "remainder is not [0,2,4] smh"
  }
}

pub fn from_base64(input: String) -> BitArray {
  input
  |> string.to_graphemes
  |> list.sized_chunk(into: 4)
  |> list.map(fn(quartet) {
    case quartet {
      [c1, c2, "=", "="] -> { // 2 pads, 1 byte as result
        let c1_val = decode_group(c1)   //00abcdef
          |> int.bitwise_shift_left(2)  //abcdef00
        let c2_val = decode_group(c2)   //00gh0000
          |> int.bitwise_shift_right(4) //000000gh

        let byte = int.bitwise_or(c1_val, c2_val)
        <<byte>>
      }
      [c1, c2, c3, "="] -> { //1 pad, 2 bytes at result
        let c1_val = decode_group(c1)   //00abcdef
          |> int.bitwise_shift_left(2)  //abcdef00
        let c2_val = decode_group(c2)   //00gh0000
          |> int.bitwise_shift_right(4) //000000gh

        let byte1 = int.bitwise_or(c1_val, c2_val)
        let c2_val = decode_group(c2)   //00abcdef
          |> int.bitwise_and(15)        //0000cdef
          |> int.bitwise_shift_left(4)  //cdef0000
        let c3_val = decode_group(c3)   //00hijk00
          |> int.bitwise_shift_right(2) //0000hijk

        let byte2 = int.bitwise_or(c2_val, c3_val)

        //join the values in a single int
        <<byte1, byte2>>
      }
      _ -> {
        let triple_byte = list.fold(quartet, 0, fn(acc, curr){
          let curr_val = decode_group(curr)
          acc                          // 00abcdef
          |> int.bitwise_shift_left(6) // abcdef000000
          |> int.bitwise_or(curr_val)      //|____00xxxxxx
        })
        <<triple_byte:size(24)>>
        
      }
    }
    
  })
  |> bit_array.concat
}

fn encode_group(group: Int) -> String {
  case group {
    0 ->  "A"  
    1 ->  "B"
    2 ->  "C"
    3 ->  "D"
    4 ->  "E"
    5 ->  "F"
    6 ->  "G"
    7 ->  "H"
    8 ->  "I"
    9 ->  "J"
    10 -> "K"
    11 -> "L"
    12 -> "M"
    13 -> "N"
    14 -> "O"
    15 -> "P"
    16 -> "Q"
    17 -> "R"
    18 -> "S"
    19 -> "T"
    20 -> "U"
    21 -> "V"
    22 -> "W"
    23 -> "X"
    24 -> "Y"
    25 -> "Z"
    26 -> "a"
    27 -> "b"
    28 -> "c"
    29 -> "d"
    30 -> "e"
    31 -> "f"
    32 -> "g"
    33 -> "h"
    34 -> "i"
    35 -> "j"
    36 -> "k"
    37 -> "l"
    38 -> "m"
    39 -> "n"
    40 -> "o"
    41 -> "p"
    42 -> "q"
    43 -> "r"
    44 -> "s"
    45 -> "t"
    46 -> "u"
    47 -> "v"
    48 -> "w"
    49 -> "x"
    50 -> "y"
    51 -> "z"
    52 -> "0"
    53 -> "1"
    54 -> "2"
    55 -> "3"
    56 -> "4"
    57 -> "5"
    58 -> "6"
    59 -> "7"
    60 -> "8"
    61 -> "9"
    62 -> "+"
    63 -> "/"
    _ -> panic
  }
}

fn decode_group(group: String) -> Int {
  case group {
    "A"->  0 
    "B"->  1 
    "C"->  2 
    "D"->  3 
    "E"->  4 
    "F"->  5 
    "G"->  6 
    "H"->  7 
    "I"->  8 
    "J"->  9 
    "K"-> 10 
    "L"-> 11 
    "M"-> 12 
    "N"-> 13 
    "O"-> 14 
    "P"-> 15 
    "Q"-> 16 
    "R"-> 17 
    "S"-> 18 
    "T"-> 19 
    "U"-> 20 
    "V"-> 21 
    "W"-> 22 
    "X"-> 23 
    "Y"-> 24 
    "Z"-> 25 
    "a"-> 26 
    "b"-> 27 
    "c"-> 28 
    "d"-> 29 
    "e"-> 30 
    "f"-> 31 
    "g"-> 32 
    "h"-> 33 
    "i"-> 34 
    "j"-> 35 
    "k"-> 36 
    "l"-> 37 
    "m"-> 38 
    "n"-> 39 
    "o"-> 40 
    "p"-> 41 
    "q"-> 42 
    "r"-> 43 
    "s"-> 44 
    "t"-> 45 
    "u"-> 46 
    "v"-> 47 
    "w"-> 48 
    "x"-> 49 
    "y"-> 50 
    "z"-> 51 
    "0"-> 52 
    "1"-> 53 
    "2"-> 54 
    "3"-> 55 
    "4"-> 56 
    "5"-> 57 
    "6"-> 58 
    "7"-> 59 
    "8"-> 60 
    "9"-> 61 
    "+"-> 62 
    "/"-> 63 
    _ -> panic
  }
}
