//// Types for handling transaction errors in adapter implementations.
////
//// Each adapter (pog, sqlight, shork) exposes a `with_transaction` function
//// that wraps a callback in a database transaction. Use `TransactionError`
//// to handle the two failure cases uniformly across adapters.
////

pub type TransactionError(error) {
  TransactionQueryError(error)
  TransactionRolledBack(error)
}
