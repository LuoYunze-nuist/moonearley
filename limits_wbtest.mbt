///|
test "limits bound arithmetic and permit an empty-token budget" {
  assert_eq(default_limits().validate(), Ok(()))
  let d = default_limits()
  assert_eq(({ ..d, tokens: 0, } : Limits).validate(), Ok(()))
  assert_eq(
    ({ ..d, nodes: 0, } : Limits).validate(),
    Err(InvalidLimit("nodes")),
  )
  assert_eq(
    ({ ..d, work: 10000001, } : Limits).validate(),
    Err(InvalidLimit("work")),
  )
  assert_eq(
    ({ ..d, tokens: -1, } : Limits).validate(),
    Err(InvalidLimit("tokens")),
  )
}
