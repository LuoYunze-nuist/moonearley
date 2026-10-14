///|
test "tokens allow gaps and zero width but reject overlap and empty kinds" {
  assert_eq(
    validate_tokens([token("id", "x", 0, 1), token("end", "", 3, 3)]),
    Ok(()),
  )
  assert_true(validate_tokens([token("", "", 0, 0)]) is Err(InvalidToken(0, _)))
  assert_true(validate_tokens([token("id", "x", 2, 1)]) is Err(_))
  assert_true(
    validate_tokens([token("id", "x", 0, 2), token("id", "y", 1, 2)]) is Err(_),
  )
}
