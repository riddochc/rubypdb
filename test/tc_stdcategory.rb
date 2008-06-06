#!/usr/bin/env ruby


require 'rubypdb.rb'

require 'test/unit'
require 'yaml'
require 'parsedate'
require 'stringio'
require 'tempfile'

$datadir = File.join(File.dirname(__FILE__), 'data')

class PDBCategoryTest < Test::Unit::TestCase
    def test_existing_categories
        a = PDB::FuelLog.new()
        f = File.open($datadir + "/fuelLogDB.pdb")
        a.load(f)
        
        x = a.appinfo.category(17)
        assert_equal x.name, "Corolla"
        assert_equal x.id, 17
        assert_equal x.renamed, true
        
        y = a.appinfo.category(0)
        assert_equal y.name, "Unfiled"
        assert_equal y.id, 0
        assert_equal y.renamed, true
        
        assert_equal a.records.length, 21
        
        assert_equal a.appinfo.categories, [y, x]

        r = a.records[249881]
        assert_equal r.category.name, "Corolla"
        r.category = a.appinfo.category("Unfiled")  # Change the category to another existing one.
        assert_equal r.category.name, "Unfiled"
        assert_equal a.appinfo.data.last_unique_id, 17
    end
end
