#!/usr/bin/env ruby

require 'RubyPDB'
require 'lib/common.rb'

class PartyRecord < RecordEntry
  def initialize(*args)
    super(*args)
  end

  def post_load(superclass)

  end
end

eval make_dump_and_load("pcash_party_fmt.yaml")

class PCashParty < PalmPDB
  def initialize()
    super()
    @recordclass = PartyRecord
  end

  def parse_app_info(data)
  end
end

a = PCashParty.new()
a.open_PDB_file("/home/socket/archives/palm/anna/PCSH-Party.pdb")


a.records.each_with_index { |r,i|
  puts "#{i}: #{r.party}"
}

class AccountRecord < RecordEntry
  def initialize(*args)
    super(*args)
  end

  def post_load(superclass)

  end
end

eval make_dump_and_load("pcash_acct_fmt.yaml")

class PCashAcct < PalmPDB
  def initialize()
    super()
    @recordclass = AccountRecord
  end

  def parse_app_info(data)
  end
end

a = PCashAcct.new()
a.open_PDB_file("/home/socket/archives/palm/anna/PCSH-Acct.pdb")


a.records.each_with_index { |r,i|
  puts "#{i}: #{r.balance}\t#{r.checkno}\t#{r.name}\t#{r.source}"
}

class TransactionRecord < RecordEntry
  def initialize(*args)
    super(*args)
  end

  def post_load(superclass)
    @date = convert_from_palm_date(@date)
  end
end

eval make_dump_and_load("pcash_trans_fmt.yaml")

class PCashTrans < PalmPDB
  def initialize()
    super()
    @recordclass = TransactionRecord
  end

  def parse_app_info(data)
  end
end

a = PCashTrans.new()
a.open_PDB_file("/home/socket/archives/palm/anna/PCSH-Tx0.pdb")

a.records.each_with_index {|r,i|
  puts "#{i}: #{r.account}\t#{r.amount}\t#{r.date}\t#{r.transtype.to_i}\t#{r.party}\t#{r.note}"
}
