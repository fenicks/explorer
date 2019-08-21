record Block {
  index : Number,
  transactions : Array(Transaction),
  nonce : Number,
  prevHash : String using "prev_hash",
  merkleTreeRoot : String using "merkle_tree_root",
  timestamp : Time,
  difficulty : Number
}
