import argv
import converter
import gleam/bit_array
import gleam/io
import gleam/list

pub fn main() {
  let argv.Argv(_, _, args) = argv.load()
  case args {
    [] -> print_help()
    [input] -> {
      input
      |> bit_array.from_string
      |> converter.to_base64
      |> io.println
    }
    _ -> {
      use input <- list.each(args)
      io.print(input <> ": ")
      input
      |> bit_array.from_string
      |> converter.to_base64
      |> io.println
    }
  }
}

fn print_help() {
  io.println("Usage:")
  io.println(
    "'base64enc <input_string>' -> will print the base64 representation of <input_string>",
  )
  io.println(
    "'base64enc input1 input2 input3 ...' -> will print the base64 representation of each input like:",
  )
  io.println("\tinput1: <base64>")
  io.println("\tinput2: <base64>")
  io.println("\tinput3: <base64>")
}
