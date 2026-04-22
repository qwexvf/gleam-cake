pub type TransactionError(error) {
  TransactionQueryError(error)
  TransactionRolledBack(error)
}
