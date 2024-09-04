import converter
import gleam/bit_array
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn no_padding_encode_test() {
  "we gleaming!"
  |> bit_array.from_string
  |> converter.to_base64
  |> should.equal("d2UgZ2xlYW1pbmch")
}

pub fn no_padding_decode_test() {
  "d2UgZ2xlYW1pbmch"
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok("we gleaming!"))
}

pub fn no_padding_full_test() {
  let input = "we gleaming!"
  input
  |> bit_array.from_string
  |> converter.to_base64
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok(input))
}

pub fn one_padding_encode_test() {
  "gleam"
  |> bit_array.from_string
  |> converter.to_base64
  |> should.equal("Z2xlYW0=")
}

pub fn one_padding_decode_test() {
  "Z2xlYW0="
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok("gleam"))
}

pub fn one_padding_full_test() {
  let input = "gleam"
  input
  |> bit_array.from_string
  |> converter.to_base64
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok(input))
}

pub fn two_padding_encode_test() {
  "gleam is awesome"
  |> bit_array.from_string
  |> converter.to_base64
  |> should.equal("Z2xlYW0gaXMgYXdlc29tZQ==")
}

pub fn two_padding_decode_test() {
  "Z2xlYW0gaXMgYXdlc29tZQ=="
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok("gleam is awesome"))
}

pub fn two_padding_full_test() {
  let input = "gleam is awesome"
  input
  |> bit_array.from_string
  |> converter.to_base64
  |> converter.from_base64
  |> bit_array.to_string
  |> should.equal(Ok(input))
}

pub fn empty_string_encode_test() {
  ""
  |> bit_array.from_string
  |> converter.to_base64
  |> should.equal("")
}

pub fn empty_string_decode_test() {
  ""
  |> converter.from_base64
  |> should.equal(<<>>)
}
